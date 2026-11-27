extends Node3D

@export var speed: float = 5.0
@export var lane_z: float = 0.0
@export var start_x: float = -65.0
@export var end_x: float = 65.0
var direction: float = 1.0
var is_player_driven: bool = false
var drive_speed: float = 0.0

func _ready() -> void:
	position.x = start_x
	position.z = lane_z

func _process(delta: float) -> void:
	if is_player_driven:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if abs(input_dir.x) > 0.05 or abs(input_dir.y) > 0.05:
			drive_speed = move_toward(drive_speed, 12.0, 10.0 * delta)
		else:
			drive_speed = move_toward(drive_speed, 0.0, 7.0 * delta)
		translate(Vector3(input_dir.x, 0, input_dir.y) * drive_speed * delta)
		if input_dir.length() > 0.05:
			rotation.y = lerp_angle(rotation.y, atan2(-input_dir.x, -input_dir.y), delta * 4.0)
		return

	position.x += speed * direction * delta
	if position.x > end_x:
		position.x = start_x
	elif position.x < start_x:
		position.x = end_x
