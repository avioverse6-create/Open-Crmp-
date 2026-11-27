extends CharacterBody3D

@export var walk_speed: float = 5.2
@export var run_speed: float = 8.0
@export var gravity: float = 22.0
var camera_pivot: Node3D
var camera: Camera3D
var active_vehicle: Node3D = null

func _ready() -> void:
	name = "Player"
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.4
	mesh.height = 1.8
	body.mesh = mesh
	body.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.32, 0.72)
	body.material_override = mat
	add_child(body)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 2.2, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 3.0, 7.5)
	camera.rotation_degrees.x = -17
	camera.current = true
	camera_pivot.add_child(camera)

func _physics_process(delta: float) -> void:
	if active_vehicle != null:
		global_position = active_vehicle.global_position + Vector3(0, 1.0, 0)
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y)
	if direction.length() > 0.05:
		direction = direction.normalized()
		var speed := run_speed if Input.is_action_pressed("run") else walk_speed
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 10.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 7.0 * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func enter_vehicle(vehicle: Node3D) -> void:
	active_vehicle = vehicle
	visible = false
	set_physics_process(false)

func exit_vehicle() -> void:
	if active_vehicle == null:
		return
	global_position = active_vehicle.global_position + active_vehicle.global_basis.x * 2.0
	active_vehicle = null
	visible = true
	set_physics_process(true)
