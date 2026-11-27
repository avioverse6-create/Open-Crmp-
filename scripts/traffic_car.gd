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
var vehicle_wheels: Array[Node3D] = []
var vehicle_wheel_radius: float = 0.45
var engine_audio: AudioStreamPlayer3D
var passby_audio: AudioStreamPlayer3D
var _last_listener_distance := INF
var _passby_played := false
var mobile_input_vector := Vector2.ZERO
var mobile_steer := 0.0
var mobile_throttle := 0.0
var mobile_brake := false
var mobile_drive_controls_active := false
var fuel_capacity := 60.0
var fuel_liters := 60.0
var speed_kmh := 0.0

func set_mobile_input(value: Vector2) -> void:
	mobile_input_vector = value.limit_length(1.0)

func set_mobile_steer(value: float) -> void:
	mobile_steer = clampf(value, -1.0, 1.0)
	_update_mobile_control_state()

func set_mobile_throttle(value: float) -> void:
	mobile_throttle = clampf(value, -1.0, 1.0)
	_update_mobile_control_state()

func set_mobile_brake(value: bool) -> void:
	mobile_brake = value
	_update_mobile_control_state()

func _update_mobile_control_state() -> void:
	mobile_drive_controls_active = absf(mobile_steer) > 0.01 or absf(mobile_throttle) > 0.01 or mobile_brake

func register_vehicle_visual(model: Node3D, wheel_radius: float = 0.45) -> void:
	vehicle_wheels.clear()
	vehicle_wheel_radius = maxf(wheel_radius, 0.1)
	for node in model.find_children("*", "Node3D", true, false):
		if String(node.name).to_lower().begins_with("wheel"):
			vehicle_wheels.append(node)

func _spin_wheels(delta: float, signed_speed: float) -> void:
	if vehicle_wheels.is_empty():
		return
	var angle := signed_speed * delta / vehicle_wheel_radius
	for wheel in vehicle_wheels:
		wheel.rotate_object_local(Vector3.RIGHT, angle)

var vertical_traffic := false
var lane_x := 0.0
var start_z := 99.0
var end_z := 219.0

func _ready() -> void:
	add_to_group("traffic_vehicles")
	if vertical_traffic:
		position.x = lane_x
		position.z = start_z
	else:
		position.x = start_x
		position.z = lane_z
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.35, 1.65, 4.7)
	collision.shape = shape
	collision.position.y = 0.82
	add_child(collision)

	var engine_path := "res://assets/audio/car_engine_loop.wav"
	if ResourceLoader.exists(engine_path):
		engine_audio = AudioStreamPlayer3D.new()
		engine_audio.name = "EngineAudio"
		engine_audio.stream = load(engine_path)
		engine_audio.volume_db = -11.0
		engine_audio.unit_size = 3.5
		engine_audio.max_distance = 100.0
		engine_audio.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
		add_child(engine_audio)
		if engine_audio.stream is AudioStreamWAV:
			(engine_audio.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		engine_audio.play()

	var passby_path := "res://assets/audio/car_passby.wav"
	if ResourceLoader.exists(passby_path):
		passby_audio = AudioStreamPlayer3D.new()
		passby_audio.name = "PassByAudio"
		passby_audio.stream = load(passby_path)
		passby_audio.volume_db = -1.0
		passby_audio.unit_size = 4.0
		passby_audio.max_distance = 48.0
		passby_audio.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
		add_child(passby_audio)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if is_player_driven:
		_drive_player(delta)
	else:
		var traffic_speed := _get_safe_traffic_speed()
		speed_kmh = absf(traffic_speed) * 3.6
		if vertical_traffic:
			velocity.x = 0.0
			velocity.z = traffic_speed * direction
			rotation.y = PI if direction > 0.0 else 0.0
			move_and_slide()
			_spin_wheels(delta, traffic_speed * direction)
			if direction > 0.0 and position.z > end_z:
				position.z = start_z
			elif direction < 0.0 and position.z < end_z:
				position.z = start_z
		else:
			velocity.x = traffic_speed * direction
			velocity.z = 0.0
			rotation.y = -PI * 0.5 if direction > 0.0 else PI * 0.5
			move_and_slide()
			_spin_wheels(delta, traffic_speed * direction)
			if direction > 0.0 and position.x > end_x:
				position.x = start_x
			elif direction < 0.0 and position.x < end_x:
				position.x = start_x

	_update_engine_audio()
	_update_passby_audio()
	_update_vehicle_camera_collision()


func _update_vehicle_camera_collision() -> void:
	# The player camera is reparented to the vehicle while driving.
	# Pull it forward when a wall or building blocks the view.
	if not is_player_driven:
		return
	var active_camera := get_viewport().get_camera_3d()
	if active_camera == null:
		return
	var camera_origin := global_position + Vector3(0.0, 1.75, 1.2)
	var desired_camera_position := to_global(Vector3(0.0, 1.75, 1.2) + Vector3(0.0, 0.9, 4.7).rotated(Vector3.RIGHT, deg_to_rad(-12.0)))
	var camera_query := PhysicsRayQueryParameters3D.create(camera_origin, desired_camera_position)
	camera_query.exclude = [get_rid()]
	camera_query.collide_with_areas = false
	var camera_hit := get_world_3d().direct_space_state.intersect_ray(camera_query)
	if camera_hit.is_empty():
		active_camera.global_position = desired_camera_position
	else:
		active_camera.global_position = camera_hit.position + camera_hit.normal * 0.18

func _drive_player(delta: float) -> void:
	var input_dir := mobile_input_vector
	if input_dir.length() < 0.05:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var throttle := mobile_throttle if mobile_drive_controls_active else -input_dir.y
	var steer := mobile_steer if mobile_drive_controls_active else input_dir.x
	if fuel_liters <= 0.0:
		throttle = 0.0
	if mobile_brake:
		drive_speed = move_toward(drive_speed, 0.0, braking * 1.55 * delta)
	elif absf(throttle) > 0.05:
		drive_speed = move_toward(drive_speed, throttle * max_drive_speed, acceleration * delta)
	else:
		drive_speed = move_toward(drive_speed, 0.0, braking * delta)

	if absf(drive_speed) > 0.15:
		rotation.y -= steer * steering_speed * delta * sign(drive_speed)

	fuel_liters = maxf(0.0, fuel_liters - absf(drive_speed) * 0.00008 * delta)
	speed_kmh = absf(drive_speed) * 3.6
	var forward := -global_basis.z
	velocity.x = forward.x * drive_speed
	velocity.z = forward.z * drive_speed
	move_and_slide()
	_spin_wheels(delta, drive_speed)

func _get_safe_traffic_speed() -> float:
	# Same-lane traffic slows down behind a vehicle instead of driving through it.
	var safe_speed := speed
	for other in get_tree().get_nodes_in_group("traffic_vehicles"):
		if other == self or not is_instance_valid(other):
			continue
		if other.get("is_player_driven") or bool(other.get("vertical_traffic")) != vertical_traffic:
			continue
		if absf(float(other.get("direction")) - direction) > 0.01:
			continue
		var gap := INF
		if vertical_traffic:
			if absf(float(other.global_position.x) - global_position.x) > 1.8:
				continue
			gap = (other.global_position.z - global_position.z) * direction
		else:
			if absf(float(other.global_position.z) - global_position.z) > 1.8:
				continue
			gap = (other.global_position.x - global_position.x) * direction
		if gap > 0.0:
			var following_factor := clampf((gap - 3.2) / 8.0, 0.0, 1.0)
			safe_speed = minf(safe_speed, speed * following_factor)
	return safe_speed


func _update_engine_audio() -> void:
	if engine_audio == null:
		return
	var current_speed := absf(drive_speed) if is_player_driven else speed_kmh / 3.6
	engine_audio.pitch_scale = clampf(0.82 + current_speed / max_drive_speed * 0.55, 0.82, 1.38)
	engine_audio.volume_db = -12.0 + clampf(current_speed / max_drive_speed, 0.0, 1.0) * 4.0

func _update_passby_audio() -> void:
	if passby_audio == null:
		return
	var listener := get_viewport().get_camera_3d()
	if listener == null:
		return
	var distance := global_position.distance_to(listener.global_position)
	if distance > 34.0:
		_passby_played = false
	elif distance < 22.0 and distance < _last_listener_distance and not _passby_played:
		passby_audio.play()
		_passby_played = true
	_last_listener_distance = distance
