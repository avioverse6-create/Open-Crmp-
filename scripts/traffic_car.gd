extends CharacterBody3D

@export var speed: float = 5.0
@export var lane_z: float = 0.0
@export var start_x: float = -65.0
@export var end_x: float = 65.0
@export var acceleration: float = 18.0
@export var braking: float = 24.0
@export var max_drive_speed: float = 15.0
@export var steering_speed: float = 1.8

var direction: float = 1.0
var is_player_driven: bool = false
var drive_speed: float = 0.0
var gravity: float = 24.0

func _ready() -> void:
	position.x = start_x
	position.z = lane_z
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.15, 1.35, 3.9)
	collision.shape = shape
	collision.position.y = 0.72
	add_child(collision)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if is_player_driven:
		_drive_player(delta)
	else:
		velocity.x = speed * direction
		velocity.z = 0.0
		rotation.y = PI * 0.5 if direction > 0.0 else -PI * 0.5
		move_and_slide()
		if position.x > end_x:
			position.x = start_x
		elif position.x < start_x:
			position.x = end_x

func _drive_player(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var throttle := -input_dir.y
	if abs(throttle) > 0.05:
		drive_speed = move_toward(drive_speed, throttle * max_drive_speed, acceleration * delta)
	else:
		drive_speed = move_toward(drive_speed, 0.0, braking * delta)

	if abs(drive_speed) > 0.15:
		rotation.y -= input_dir.x * steering_speed * delta * sign(drive_speed)

	var forward := -global_basis.z
	velocity.x = forward.x * drive_speed
	velocity.z = forward.z * drive_speed
	move_and_slide()
