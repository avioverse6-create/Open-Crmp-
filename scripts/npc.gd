extends CharacterBody3D

var target := Vector3.ZERO
var walk_speed := 1.5
var change_timer := 0.0
var walk_phase := 0.0
var visual_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.72
	shape.shape = capsule
	shape.position.y = 0.86
	add_child(shape)
	visual_root = Node3D.new()
	visual_root.name = "PedestrianVisual"
	add_child(visual_root)

	var clothing_colors := [
		Color(0.12, 0.25, 0.48), Color(0.52, 0.16, 0.12),
		Color(0.13, 0.34, 0.23), Color(0.48, 0.34, 0.16),
		Color(0.27, 0.22, 0.39), Color(0.32, 0.35, 0.36),
		Color(0.58, 0.54, 0.43)
	]
	var shirt := _make_material(clothing_colors[randi() % clothing_colors.size()], 0.9)
	var pants := _make_material(Color(0.07, 0.085, 0.10), 0.94)
	var skin := _make_material(Color(0.65, 0.43, 0.31), 0.96)
	var hair_colors := [Color(0.035,0.03,0.025), Color(0.18,0.11,0.06), Color(0.34,0.27,0.17)]
	var hair := _make_material(hair_colors[randi() % hair_colors.size()], 0.96)
	var shoe_mat := _make_material(Color(0.025,0.03,0.035), 0.86)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.29
	torso_mesh.height = 0.94
	torso.mesh = torso_mesh
	torso.position.y = 1.08
	torso.material_override = shirt
	visual_root.add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.38
	head.mesh = head_mesh
	head.position.y = 1.78
	head.material_override = skin
	visual_root.add_child(head)

	var hair_cap := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.198
	hair_mesh.height = 0.22
	hair_cap.mesh = hair_mesh
	hair_cap.scale = Vector3(1.0, 0.58, 1.0)
	hair_cap.position = Vector3(0, 1.91, 0.02)
	hair_cap.material_override = hair
	visual_root.add_child(hair_cap)

	left_arm = _make_limb(Vector3(-0.34, 1.35, 0), 0.11, 0.58, shirt)
	right_arm = _make_limb(Vector3(0.34, 1.35, 0), 0.11, 0.58, shirt)
	left_leg = _make_limb(Vector3(-0.14, 0.65, 0), 0.135, 0.68, pants)
	right_leg = _make_limb(Vector3(0.14, 0.65, 0), 0.135, 0.68, pants)
	_add_shoe(Vector3(0, -0.61, -0.07), shoe_mat, left_leg)
	_add_shoe(Vector3(0, -0.61, -0.07), shoe_mat, right_leg)
	_pick_target()

func _make_material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material

func _make_limb(at: Vector3, radius: float, length: float, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	visual_root.add_child(pivot)
	var mesh_instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.78
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh_instance.mesh = cylinder
	mesh_instance.position.y = -length * 0.5
	mesh_instance.material_override = material
	pivot.add_child(mesh_instance)
	return pivot

func _add_shoe(at: Vector3, material: Material, parent: Node3D) -> void:
	var shoe := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.23, 0.12, 0.34)
	shoe.mesh = mesh
	shoe.position = at
	shoe.material_override = material
	parent.add_child(shoe)

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
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 5.0)
		walk_phase += delta * 7.4
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * delta)
		walk_phase = move_toward(walk_phase, 0.0, delta * 4.0)
	var swing := sin(walk_phase) * 0.43 if moving else 0.0
	left_arm.rotation.x = swing
	right_arm.rotation.x = -swing
	left_leg.rotation.x = -swing
	right_leg.rotation.x = swing
	if moving and is_on_floor():
		visual_root.position.y = abs(sin(walk_phase * 2.0)) * 0.035
	else:
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.2)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _pick_target() -> void:
	target = global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	change_timer = randf_range(3.0, 7.0)
