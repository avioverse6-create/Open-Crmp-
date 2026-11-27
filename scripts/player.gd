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

func _input(event: InputEvent) -> void:
	# Swipe on the right side of the screen to orbit the third-person camera.
	if event is InputEventScreenDrag:
		var screen_width := get_viewport().get_visible_rect().size.x
		if event.position.x > screen_width * 0.42:
			camera_pivot.rotate_y(-event.relative.x * 0.004)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - event.relative.y * 0.003, deg_to_rad(-35.0), deg_to_rad(25.0))

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y)
	if direction.length() > 0.05:
		direction = direction.normalized()
		var current_speed := run_speed if Input.is_action_pressed("run") else walk_speed
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
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
	vehicle.set("is_player_driven", true)
	visible = false
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
	set_physics_process(true)
