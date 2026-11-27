extends CharacterBody3D

const PlayerModel: PackedScene = preload("res://assets/models/people/citizen_bryce.glb")
const MixamoAnimations: PackedScene = preload("res://assets/models/people/mixamo_animation_library.glb")

@export var walk_speed: float = 5.2
@export var run_speed: float = 8.0
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
var run_clip: StringName = &""

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

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 2.2, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 3.0, 7.5)
	camera.rotation_degrees.x = -17
	camera.current = true
	camera_pivot.add_child(camera)

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
			animation_player.add_animation_library(library_name, source_library.duplicate(true))
	for clip in animation_player.get_animation_list():
		var lower := String(clip).to_lower()
		if lower.ends_with("/idle") or lower == "idle":
			idle_clip = clip
		elif lower.ends_with("/run") or lower == "run":
			run_clip = clip
	if idle_clip != &"":
		animation_player.play(idle_clip)
	source_scene.queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var screen_width := get_viewport().get_visible_rect().size.x
		if event.position.x > screen_width * 0.42:
			camera_pivot.rotate_y(-event.relative.x * 0.004)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - event.relative.y * 0.003, deg_to_rad(-35.0), deg_to_rad(25.0))

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_basis := camera_pivot.global_basis
	var direction := camera_basis * Vector3(input_dir.x, 0, input_dir.y)
	direction.y = 0
	var moving := direction.length() > 0.05
	var running := Input.is_action_pressed("run")
	if moving:
		direction = direction.normalized()
		var current_speed := run_speed if running else walk_speed
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 10.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 7.0 * delta)

	if animation_player != null:
		var desired_clip := run_clip if moving else idle_clip
		if desired_clip != &"" and animation_player.current_animation != desired_clip:
			animation_player.play(desired_clip, 0.18)
		if moving and run_clip != &"":
			animation_player.speed_scale = 1.0 if running else 0.62
		else:
			animation_player.speed_scale = 1.0

	if moving and is_on_floor():
		visual_root.position.y = abs(sin(Time.get_ticks_msec() * (0.012 if running else 0.008))) * (0.035 if running else 0.018)
	else:
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.25)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)
	move_and_slide()

func enter_vehicle(vehicle: Node3D) -> void:
	active_vehicle = vehicle
	vehicle.set("is_player_driven", true)
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	camera_pivot.reparent(vehicle)
	camera_pivot.position = Vector3(0, 3.0, 8.0)
	camera_pivot.rotation_degrees = Vector3(-15, 0, 0)

func exit_vehicle() -> void:
	if active_vehicle == null:
		return
	var vehicle := active_vehicle
	vehicle.set("is_player_driven", false)
	global_position = vehicle.global_position + vehicle.global_basis.x * 2.0
	camera_pivot.reparent(self)
	camera_pivot.position = Vector3(0, 2.2, 0)
	camera_pivot.rotation = Vector3.ZERO
	active_vehicle = null
	visible = true
	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask
	set_physics_process(true)
