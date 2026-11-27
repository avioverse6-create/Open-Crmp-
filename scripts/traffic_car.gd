extends Node3D

@export var speed: float = 5.0
@export var lane_z: float = 0.0
@export var start_x: float = -65.0
@export var end_x: float = 65.0
var direction: float = 1.0

func _ready() -> void:
	position.x = start_x
	position.z = lane_z

func _process(delta: float) -> void:
	position.x += speed * direction * delta
	if position.x > end_x:
		position.x = start_x
	elif position.x < start_x:
		position.x = end_x
