extends CharacterBody3D

@export var walk_speed: float = 5.2
@export var run_speed: float = 8.0
@export var jump_velocity: float = 6.8
@export var gravity: float = 22.0

var camera_pivot: Node3D
var camera: Camera3D
var active_vehicle: Node3D = null
var saved_collision_layer: int = 1
var saved_collision_mask: int = 1
var walk_phase: float = 0.0
var visual_root: Node3D
var torso: MeshInstance3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D

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
	add_child(visual_root)

	var shirt := _make_material(Color(0.075, 0.22, 0.52), 0.82)
	var pants := _make_material(Color(0.075, 0.09, 0.12), 0.92)
	var skin := _make_material(Color(0.66, 0.43, 0.30), 0.9)
	var hair := _make_material(Color(0.055, 0.045, 0.035), 0.96)
	var shoes := _make_material(Color(0.025, 0.03, 0.035), 0.82)

	torso = MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.34
	torso_mesh.height = 1.02
	torso.mesh = torso_mesh
	torso.position.y = 1.13
	torso.material_override = shirt
	visual_root.add_child(torso)

	var neck := MeshInstance3D.new()
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = 0.105
	neck_mesh.bottom_radius = 0.12
	neck_mesh.height = 0.20
	neck.mesh = neck_mesh
	neck.position.y = 1.68
	neck.material_override = skin
	visual_root.add_child(neck)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.215
	head_mesh.height = 0.43
	head.mesh = head_mesh
	head.position.y = 1.84
	head.material_override = skin
	visual_root.add_child(head)

	var hair_cap := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.222
	hair_mesh.height = 0.24
	hair_cap.mesh = hair_mesh
	hair_cap.scale = Vector3(1.0, 0.62, 1.0)
	hair_cap.position = Vector3(0, 1.99, 0.025)
	hair_cap.material_override = hair
	visual_root.add_child(hair_cap)

	left_arm = _make_limb(Vector3(-0.39, 1.42, 0), 0.125, 0.62, shirt)
	right_arm = _make_limb(Vector3(0.39, 1.42, 0), 0.125, 0.62, shirt)
	left_leg = _make_limb(Vector3(-0.16, 0.70, 0), 0.15, 0.72, pants)
	right_leg = _make_limb(Vector3(0.16, 0.70, 0), 0.15, 0.72, pants)
	_add_hand(Vector3(-0.39, 0.76, 0), skin)
	_add_hand(Vector3(0.39, 0.76, 0), skin)
	_add_shoe(Vector3(-0.16, 0.07, -0.075), shoes)
	_add_shoe(Vector3(0.16, 0.07, -0.075), shoes)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 2.2, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 3.0, 7.5)
	camera.rotation_degrees.x = -17
	camera.current = true
	camera_pivot.add_child(camera)

func _make_material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material

func _make_limb(at: Vector3, radius: float, length: float, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	visual_root.add_child(pivot)
	var limb := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.78
	cylinder.bottom_radius = radius
	cylinder.height = length
	limb.mesh = cylinder
	limb.position.y = -length * 0.5
	limb.material_override = material
	pivot.add_child(limb)
	return pivot

func _add_hand(at: Vector3, material: Material) -> void:
	var hand := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.105
	hand.mesh = mesh
	hand.position = at
	hand.material_override = material
	visual_root.add_child(hand)

func _add_shoe(at: Vector3, material: Material) -> void:
	var shoe := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.27, 0.14, 0.42)
	shoe.mesh = mesh
	shoe.position = at
	shoe.material_override = material
	visual_root.add_child(shoe)

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
		walk_phase += delta * (14.0 if running else 9.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 7.0 * delta)
		walk_phase = move_toward(walk_phase, 0.0, delta * 5.0)

	var swing := sin(walk_phase) * (0.66 if running else 0.48) if moving else 0.0
	left_arm.rotation.x = swing
	right_arm.rotation.x = -swing
	left_leg.rotation.x = -swing
	right_leg.rotation.x = swing
	if moving and is_on_floor():
		visual_root.position.y = abs(sin(walk_phase * 2.0)) * (0.075 if running else 0.045)
		visual_root.rotation.z = sin(walk_phase) * 0.025
	else:
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.35)
		visual_root.rotation.z = move_toward(visual_root.rotation.z, 0.0, delta * 0.12)
		if not moving:
			torso.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.0018) * 0.012

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
