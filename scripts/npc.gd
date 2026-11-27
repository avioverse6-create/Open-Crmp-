extends CharacterBody3D

var target := Vector3.ZERO
var walk_speed := 1.5
var change_timer := 0.0
var walk_phase := 0.0
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.65
	shape.shape = capsule
	shape.position.y = 0.82
	add_child(shape)

	var clothing_colors := [
		Color(0.18, 0.38, 0.68),
		Color(0.68, 0.22, 0.16),
		Color(0.22, 0.48, 0.32),
		Color(0.58, 0.43, 0.22),
		Color(0.34, 0.30, 0.48)
	]
	var clothing := StandardMaterial3D.new()
	clothing.albedo_color = clothing_colors[randi() % clothing_colors.size()]
	clothing.roughness = 0.9

	var body_visual := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.29
	body_mesh.height = 1.35
	body_visual.mesh = body_mesh
	body_visual.position.y = 0.86
	body_visual.material_override = clothing
	add_child(body_visual)

	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.72, 0.52, 0.38)
	skin.roughness = 0.95
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position.y = 1.68
	head.material_override = skin
	add_child(head)

	left_arm = _make_limb(Vector3(-0.37, 1.02, 0), 0.14, 0.62, skin)
	right_arm = _make_limb(Vector3(0.37, 1.02, 0), 0.14, 0.62, skin)
	left_leg = _make_limb(Vector3(-0.15, 0.38, 0), 0.17, 0.68, clothing)
	right_leg = _make_limb(Vector3(0.15, 0.38, 0), 0.17, 0.68, clothing)
	_pick_target()

func _make_limb(at: Vector3, radius: float, length: float, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	add_child(pivot)
	var mesh_instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.72
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh_instance.mesh = cylinder
	mesh_instance.position.y = -length * 0.5
	mesh_instance.material_override = material
	pivot.add_child(mesh_instance)
	return pivot

func _physics_process(delta: float) -> void:
	change_timer -= delta
	if change_timer <= 0.0 or global_position.distance_to(target) < 1.2:
		_pick_target()
	var direction := target - global_position
	direction.y = 0
	var moving := direction.length() > 0.1
	if moving:
		direction = direction.normalized()
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
		rotation.y = atan2(-direction.x, -direction.z)
		walk_phase += delta * 8.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * delta)
		walk_phase = move_toward(walk_phase, 0.0, delta * 5.0)
	var swing := sin(walk_phase) * 0.48 if moving else 0.0
	left_arm.rotation.x = swing
	right_arm.rotation.x = -swing
	left_leg.rotation.x = -swing
	right_leg.rotation.x = swing
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _pick_target() -> void:
	target = global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	change_timer = randf_range(3.0, 7.0)
