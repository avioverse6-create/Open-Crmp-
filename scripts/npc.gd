extends CharacterBody3D

const PedestrianModels: Array[PackedScene] = [
	preload("res://assets/models/people/citizen_bryce.glb"),
	preload("res://assets/models/people/citizen_sophie.glb"),
	preload("res://assets/models/people/citizen_remy.glb"),
	preload("res://assets/models/people/citizen_shannon.glb")
]
const FootstepSounds: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/01-footstep.ogg"),
	preload("res://assets/audio/footsteps/02-footstep.ogg"),
	preload("res://assets/audio/footsteps/03-footstep.ogg"),
	preload("res://assets/audio/footsteps/04-footstep.ogg"),
	preload("res://assets/audio/footsteps/05-footstep.ogg"),
	preload("res://assets/audio/footsteps/06-footstep.ogg")
]

var target := Vector3.ZERO
var walk_speed := 1.25
var change_timer := 0.0
var district_center_z: float = -34.0
var district_center_x: float = 0.0
var vertical_route := false
var sidewalk_side: float = -1.0
var sidewalk_offset: float = 6.35
var pause_timer := 0.0
var character_visual: Node3D
var humanoid_animator
var footstep_player: AudioStreamPlayer3D
var chatter_player: AudioStreamPlayer3D
var footstep_timer := randf_range(0.15, 0.55)
var _simulation_accumulator := 0.0

func _ready() -> void:
	add_to_group("pedestrians")
	walk_speed = randf_range(1.05, 1.48)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.30
	capsule.height = 1.76
	shape.shape = capsule
	shape.position.y = 0.88
	add_child(shape)

	character_visual = Node3D.new()
	character_visual.name = "RiggedPedestrian"
	character_visual.rotation.y = PI
	add_child(character_visual)
	var model_scene := PedestrianModels[randi() % PedestrianModels.size()]
	var model := model_scene.instantiate() as Node3D
	character_visual.add_child(model)
	humanoid_animator = preload("res://scripts/humanoid_animator.gd").new()
	humanoid_animator.bind(model)
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "NPCFootsteps"
	footstep_player.position = Vector3(0, 0.12, 0)
	footstep_player.volume_db = -17.0
	footstep_player.unit_size = 2.8
	footstep_player.max_distance = 13.0
	add_child(footstep_player)
	if randi() % 4 == 0 and ResourceLoader.exists("res://assets/audio/pedestrian_chatter.mp3"):
		chatter_player = AudioStreamPlayer3D.new()
		chatter_player.name = "LocalConversation"
		chatter_player.stream = load("res://assets/audio/pedestrian_chatter.mp3")
		if chatter_player.stream is AudioStreamMP3:
			(chatter_player.stream as AudioStreamMP3).loop = true
		chatter_player.volume_db = -29.0
		chatter_player.pitch_scale = randf_range(0.94, 1.07)
		chatter_player.unit_size = 3.0
		chatter_player.max_distance = 12.0
		add_child(chatter_player)
		chatter_player.play(randf_range(0.0, 18.0))
	_pick_target()

func _play_footstep() -> void:
	if footstep_player == null or FootstepSounds.is_empty():
		return
	footstep_player.stream = FootstepSounds[randi() % FootstepSounds.size()]
	footstep_player.pitch_scale = randf_range(0.92, 1.08)
	footstep_player.play()

func _physics_process(delta: float) -> void:
	# Distant pedestrians are hidden and frozen to avoid spending CPU/GPU on
	# characters the player cannot see. Nearby pedestrians retain smooth motion.
	var camera := get_viewport().get_camera_3d()
	var distance := 0.0
	if camera != null:
		distance = global_position.distance_to(camera.global_position)
		if distance > 82.0:
			character_visual.visible = false
			if footstep_player.playing:
				footstep_player.stop()
			if chatter_player != null and chatter_player.playing:
				chatter_player.stop()
			return
		else:
			character_visual.visible = true

	_simulation_accumulator += delta
	var interval := 0.033
	if distance > 50.0:
		interval = 0.20
	elif distance > 28.0:
		interval = 0.066
	if _simulation_accumulator < interval:
		return
	var step_delta := _simulation_accumulator
	_simulation_accumulator = 0.0

	change_timer -= step_delta
	if pause_timer > 0.0:
		pause_timer = maxf(0.0, pause_timer - step_delta)
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * step_delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * step_delta)
		if humanoid_animator != null:
			humanoid_animator.update(step_delta, false, false)
		if not is_on_floor():
			velocity.y -= 20.0 * step_delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return
	if change_timer <= 0.0 or global_position.distance_to(target) < 1.0:
		_pick_target()
		pause_timer = randf_range(0.65, 1.8)
		velocity.x = 0.0
		velocity.z = 0.0
		if humanoid_animator != null:
			humanoid_animator.update(step_delta, false, false)
		if not is_on_floor():
			velocity.y -= 20.0 * step_delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return
	var direction := target - global_position
	direction.y = 0.0
	var moving := direction.length() > 0.1
	if moving:
		direction = direction.normalized()
		# Light local avoidance keeps pedestrians from walking through one another.
		# Only nearby neighbours are considered; distant NPCs do not affect this route.
		var avoidance := Vector3.ZERO
		for neighbour in get_tree().get_nodes_in_group("pedestrians"):
			if neighbour == self or not is_instance_valid(neighbour):
				continue
			var offset: Vector3 = global_position - neighbour.global_position
			offset.y = 0.0
			var separation := offset.length()
			if separation > 0.01 and separation < 1.35:
				var strength := (1.35 - separation) / 1.35
				avoidance += offset.normalized() * strength
		if avoidance.length_squared() > 0.0001:
			direction = (direction + avoidance.normalized() * 0.72).normalized()
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), step_delta * 4.5)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * step_delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * step_delta)

	if humanoid_animator != null:
		humanoid_animator.update(step_delta, moving, false)

	if moving and is_on_floor():
		footstep_timer -= step_delta
		if footstep_timer <= 0.0:
			_play_footstep()
			footstep_timer = randf_range(0.48, 0.58)
	else:
		footstep_timer = 0.16

	if not is_on_floor():
		velocity.y -= 20.0 * step_delta
	else:
		velocity.y = 0.0
	move_and_slide()
	# If a pedestrian reaches a wall or gets blocked by another character,
	# choose a fresh sidewalk destination instead of pushing against it.
	if is_on_wall():
		_pick_target()
		pause_timer = randf_range(0.2, 0.55)

func _pick_target() -> void:
	if vertical_route:
		target = Vector3(
			district_center_x + sidewalk_side * sidewalk_offset + randf_range(-0.35, 0.35),
			global_position.y,
			randf_range(87.0, 223.0)
		)
	else:
		target = Vector3(
			randf_range(-65.0, 65.0),
			global_position.y,
			district_center_z + sidewalk_side * sidewalk_offset + randf_range(-0.45, 0.45)
		)
	change_timer = randf_range(5.0, 10.0)
