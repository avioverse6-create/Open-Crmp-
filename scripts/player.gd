extends CharacterBody3D

const PlayerModel: PackedScene = preload("res://assets/models/people/citizen_bryce.glb")
const MixamoAnimations: PackedScene = preload("res://assets/models/people/mixamo_animation_library.glb")
const FootstepSounds: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/01-footstep.ogg"),
	preload("res://assets/audio/footsteps/02-footstep.ogg"),
	preload("res://assets/audio/footsteps/03-footstep.ogg"),
	preload("res://assets/audio/footsteps/04-footstep.ogg"),
	preload("res://assets/audio/footsteps/05-footstep.ogg"),
	preload("res://assets/audio/footsteps/06-footstep.ogg")
]

@export var walk_speed: float = 4.2
@export var run_speed: float = 7.0
@export var jump_velocity: float = 6.8
@export var gravity: float = 22.0

var camera_pivot: Node3D
var camera: Camera3D
var active_vehicle: Node3D = null
var saved_collision_layer: int = 1
var saved_collision_mask: int = 1
var visual_root: Node3D
var animation_player: AnimationPlayer
var idle_clip: StringName = &""
var walk_clip: StringName = &""
var run_clip: StringName = &""
var mobile_input_vector := Vector2.ZERO
var camera_yaw := 0.0
var footstep_player: AudioStreamPlayer3D
var footstep_timer := 0.0

func _ready() -> void:
	name = "Player"
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.82
	collision.shape = capsule
	collision.position.y = 0.91
	add_child(collision)
	saved_collision_layer = collision_layer
	saved_collision_mask = collision_mask

	visual_root = Node3D.new()
	visual_root.name = "CharacterVisual"
	visual_root.rotation.y = PI
	add_child(visual_root)
	var character := PlayerModel.instantiate() as Node3D
	visual_root.add_child(character)
	_setup_mixamo_animations(character)
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "FootstepAudio"
	footstep_player.position = Vector3(0, 0.12, 0)
	footstep_player.volume_db = -10.0
	footstep_player.unit_size = 3.5
	footstep_player.max_distance = 20.0
	add_child(footstep_player)

	camera_pivot = Node3D.new()
	camera_pivot.name = "IndependentCameraPivot"
	camera_pivot.top_level = true
	camera_pivot.global_position = global_position + Vector3(0, 2.0, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.05, 4.9)
	camera.rotation_degrees.x = -12.0
	camera.fov = 72.0
	camera.current = true
	camera_pivot.add_child(camera)

func set_mobile_input(value: Vector2) -> void:
	mobile_input_vector = value.limit_length(1.0)

func _setup_mixamo_animations(character: Node3D) -> void:
	var source_scene := MixamoAnimations.instantiate()
	var source_players := source_scene.find_children("*", "AnimationPlayer", true, false)
	if source_players.is_empty():
		source_scene.queue_free()
		return
	var source_player := source_players[0] as AnimationPlayer
	animation_player = AnimationPlayer.new()
	animation_player.name = "CharacterAnimationPlayer"
	animation_player.root_node = NodePath("..")
	character.add_child(animation_player)
	for library_name in source_player.get_animation_library_list():
		var source_library := source_player.get_animation_library(library_name)
		if source_library != null:
			var copied_library := source_library.duplicate(true) as AnimationLibrary
			if copied_library != null:
				_retarget_animation_library(copied_library, character)
				animation_player.add_animation_library(library_name, copied_library)
	for clip in animation_player.get_animation_list():
		var lower := String(clip).to_lower()
		if lower.ends_with("/idle") or lower == "idle":
			idle_clip = clip
		elif lower.ends_with("/walk") or lower == "walk":
			walk_clip = clip
		elif lower.ends_with("/run") or lower == "run":
			run_clip = clip
	if walk_clip == &"":
		walk_clip = run_clip
	if idle_clip != &"":
		animation_player.play(idle_clip)
	source_scene.queue_free()

func _retarget_animation_library(library: AnimationLibrary, character: Node3D) -> void:
	var skeletons := character.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_warning("No Skeleton3D found for player animation retargeting.")
		return
	var retargeted := 0
	for clip_name in library.get_animation_list():
		var clip := library.get_animation(clip_name)
		if clip == null:
			continue
		for track_index in range(clip.get_track_count()):
			var old_path := clip.track_get_path(track_index)
			var bone_name := ""
			for name_index in range(old_path.get_name_count()):
				var candidate := old_path.get_name(name_index)
				for skeleton_node in skeletons:
					var skeleton := skeleton_node as Skeleton3D
					if skeleton.find_bone(candidate) >= 0:
						bone_name = candidate
						break
				if not bone_name.is_empty():
					break
			if bone_name.is_empty():
				for sub_index in range(old_path.get_subname_count()):
					var candidate := old_path.get_subname(sub_index)
					for skeleton_node in skeletons:
						var skeleton := skeleton_node as Skeleton3D
						if skeleton.find_bone(candidate) >= 0:
							bone_name = candidate
							break
					if not bone_name.is_empty():
						break
			if bone_name.is_empty():
				continue
			for skeleton_node in skeletons:
				var skeleton := skeleton_node as Skeleton3D
				if skeleton.find_bone(bone_name) >= 0:
					var relative_path := character.get_path_to(skeleton)
					clip.track_set_path(track_index, NodePath(String(relative_path) + ":" + bone_name))
					retargeted += 1
					break
	if retargeted == 0:
		push_warning("Mixamo animation tracks did not match the player skeleton.")
	else:
		print("Retargeted ", retargeted, " Mixamo animation tracks for player.")

func _play_footstep() -> void:
	if footstep_player == null or FootstepSounds.is_empty():
		return
	footstep_player.stream = FootstepSounds[randi() % FootstepSounds.size()]
	footstep_player.pitch_scale = randf_range(0.94, 1.06)
	footstep_player.play()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var screen_width := get_viewport().get_visible_rect().size.x
		if event.position.x > screen_width * 0.42:
			camera_pivot.rotate_y(-event.relative.x * 0.004)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - event.relative.y * 0.003, deg_to_rad(-28.0), deg_to_rad(20.0))
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_pivot.rotate_y(-event.relative.x * 0.004)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - event.relative.y * 0.003, deg_to_rad(-28.0), deg_to_rad(20.0))

func _physics_process(delta: float) -> void:
	if camera_pivot.top_level:
		camera_pivot.global_position = global_position + Vector3(0, 2.0, 0)

	var input_dir := mobile_input_vector
	if input_dir.length() < 0.05:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw := camera_pivot.global_rotation.y
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).rotated(Vector3.UP, yaw)
	direction.y = 0.0
	var moving := direction.length() > 0.05
	var running := Input.is_action_pressed("run")
	if moving:
		direction = direction.normalized()
		var current_speed := run_speed if running else walk_speed
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 8.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 7.0 * delta)

	if animation_player != null:
		var desired_clip := run_clip if running and moving else (walk_clip if moving else idle_clip)
		if desired_clip != &"" and animation_player.current_animation != desired_clip:
			animation_player.play(desired_clip, 0.2)
		if moving and desired_clip == walk_clip:
			animation_player.speed_scale = 0.72 if not running else 1.12
		else:
			animation_player.speed_scale = 1.0

	if moving and is_on_floor() and active_vehicle == null:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			_play_footstep()
			footstep_timer = 0.34 if running else 0.49
	else:
		footstep_timer = 0.08

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)
	move_and_slide()

func enter_vehicle(vehicle: Node3D) -> void:
	active_vehicle = vehicle
	var start_path := "res://assets/audio/car_start.wav"
	if ResourceLoader.exists(start_path):
		var start_audio := AudioStreamPlayer.new()
		start_audio.stream = load(start_path)
		start_audio.volume_db = -5.0
		add_child(start_audio)
		start_audio.finished.connect(start_audio.queue_free)
		start_audio.play()
	vehicle.set("is_player_driven", true)
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	camera_pivot.reparent(vehicle)
	camera_pivot.top_level = false
	camera_pivot.position = Vector3(0, 2.7, 7.2)
	camera_pivot.rotation_degrees = Vector3(-12, 0, 0)

func exit_vehicle() -> void:
	if active_vehicle == null:
		return
	var vehicle := active_vehicle
	vehicle.set("is_player_driven", false)
	global_position = vehicle.global_position + vehicle.global_basis.x * 2.0
	camera_pivot.reparent(self)
	camera_pivot.top_level = true
	camera_pivot.global_position = global_position + Vector3(0, 2.0, 0)
	camera_pivot.global_rotation = Vector3.ZERO
	active_vehicle = null
	visible = true
	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask
	set_physics_process(true)
