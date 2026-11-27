extends CharacterBody3D

const PlayerModel: PackedScene = preload("res://assets/models/people/citizen_bryce.glb")
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
var humanoid_animator
var in_water := false
const WATER_SURFACE_Y := 0.025
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
	humanoid_animator = preload("res://scripts/humanoid_animator.gd").new()
	humanoid_animator.bind(character)
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
	camera_pivot.global_position = global_position + Vector3(0, 1.78, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.98, 3.85)
	camera.rotation_degrees.x = -11.0
	camera.fov = 70.0
	camera.current = true
	camera_pivot.add_child(camera)

func set_mobile_input(value: Vector2) -> void:
	mobile_input_vector = value.limit_length(1.0)

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
		camera_pivot.global_position = global_position + Vector3(0, 1.78, 0)

	var input_dir := mobile_input_vector
	if input_dir.length() < 0.05:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw := camera_pivot.global_rotation.y
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).rotated(Vector3.UP, yaw)
	direction.y = 0.0
	var moving := direction.length() > 0.05
	var running := Input.is_action_pressed("run")
	set_in_water(absf(global_position.x) > 6.0 and absf(global_position.z) < 8.5 and global_position.y < 3.0)
	if moving:
		direction = direction.normalized()
		var current_speed := (run_speed if running else walk_speed) * (0.58 if in_water else 1.0)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 8.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 7.0 * delta)

	if humanoid_animator != null:
		humanoid_animator.update(delta, moving and not in_water, running)

	if moving and is_on_floor() and active_vehicle == null and not in_water:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			_play_footstep()
			footstep_timer = 0.34 if running else 0.49
	else:
		footstep_timer = 0.08

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if in_water:
		var buoyancy_target := clampf((WATER_SURFACE_Y - global_position.y) * 2.8, -1.5, 1.5)
		velocity.y = move_toward(velocity.y, buoyancy_target, 3.5 * delta)
	elif not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)
	move_and_slide()

func set_in_water(value: bool) -> void:
	if in_water == value:
		return
	in_water = value
	if value:
		var splash_path := "res://assets/audio/water_splash.wav"
		if ResourceLoader.exists(splash_path):
			var splash := AudioStreamPlayer3D.new()
			splash.stream = load(splash_path)
			splash.volume_db = -3.0
			splash.unit_size = 4.0
			splash.max_distance = 28.0
			splash.global_position = global_position
			get_tree().current_scene.add_child(splash)
			splash.finished.connect(splash.queue_free)
			splash.play()

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
	camera_pivot.global_position = global_position + Vector3(0, 1.78, 0)
	camera_pivot.global_rotation = Vector3.ZERO
	active_vehicle = null
	visible = true
	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask
	set_physics_process(true)
