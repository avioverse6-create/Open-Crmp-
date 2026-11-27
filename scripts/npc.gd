extends CharacterBody3D

var target := Vector3.ZERO
var walk_speed := 1.5
var change_timer := 0.0

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.29
	mesh.height = 1.5
	visual.mesh = mesh
	visual.position.y = 0.75
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.75, 0.48, 0.24)
	visual.material_override = material
	add_child(visual)
	_pick_target()

func _physics_process(delta: float) -> void:
	change_timer -= delta
	if change_timer <= 0.0 or global_position.distance_to(target) < 1.2:
		_pick_target()
	var direction := target - global_position
	direction.y = 0
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
		rotation.y = atan2(-direction.x, -direction.z)
	else:
		velocity.x = 0
		velocity.z = 0
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0
	move_and_slide()

func _pick_target() -> void:
	target = global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	change_timer = randf_range(3.0, 7.0)
