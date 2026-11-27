extends CharacterBody3D

@export var walk_speed: float = 5.2
@export var run_speed: float = 8.0
@export var gravity: float = 22.0
var camera_pivot: Node3D
var camera: Camera3D
var active_vehicle: Node3D = null
var saved_collision_layer: int = 1
var saved_collision_mask: int = 1
var walk_phase: float = 0.0
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D

func _ready() -> void:
	name = "Player"
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	saved_collision_layer = collision_layer
	saved_collision_mask = collision_mask

	var clothing := StandardMaterial3D.new()
	clothing.albedo_color = Color(0.12, 0.32, 0.72)
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.4
	torso_mesh.height = 1.25
	torso.mesh = torso_mesh
	torso.position.y = 1.0
	torso.material_override = clothing
	add_child(torso)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.72, 0.52, 0.38)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position.y = 1.72
	head.material_override = skin
	add_child(head)
	left_arm = _make_limb(Vector3(-0.43, 1.28, 0), 0.15, 0.68, skin)
	right_arm = _make_limb(Vector3(0.43, 1.28, 0), 0.15, 0.68, skin)
	left_leg = _make_limb(Vector3(-0.16, 0.58, 0), 0.18, 0.72, clothing)
	right_leg = _make_limb(Vector3(0.16, 0.58, 0), 0.18, 0.72, clothing)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 2.2, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 3.0, 7.5)
	camera.rotation_degrees.x = -17
	camera.current = true
	camera_pivot.add_child(camera)

func _make_limb(at: Vector3, radius: float, length: float, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	add_child(pivot)
	var limb := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.72
	cylinder.bottom_radius = radius
	cylinder.height = length
	limb.mesh = cylinder
	limb.position.y = -length * 0.5
	limb.material_override = material
	pivot.add_child(limb)
	return pivot

func _input(event: InputEvent) -> void:
	# Swipe on the right side of the screen to orbit the third-person camera.
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
	if moving:
		direction = direction.normalized()
		var current_speed := run_speed if Input.is_action_pressed("run") else walk_speed
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 10.0)
		walk_phase += delta * (12.0 if Input.is_action_pressed("run") else 8.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 7.0 * delta)
		walk_phase = move_toward(walk_phase, 0.0, delta * 5.0)
	var swing := sin(walk_phase) * 0.52 if moving else 0.0
	left_arm.rotation.x = swing
	right_arm.rotation.x = -swing
	left_leg.rotation.x = -swing
	right_leg.rotation.x = swing

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
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
