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
var traffic_current_speed := 0.0
var _traffic_turn_active := false
var _traffic_turn_elapsed := 0.0
var _traffic_turn_duration := 1.35
var _traffic_turn_start := Vector3.ZERO
var _traffic_turn_control_a := Vector3.ZERO
var _traffic_turn_control_b := Vector3.ZERO
var _traffic_turn_end := Vector3.ZERO
var _traffic_turn_exit_direction := Vector3.ZERO
var _traffic_turn_serial := 0

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
	traffic_current_speed = speed
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
		var target_traffic_speed := _get_safe_traffic_speed()
		var traffic_rate := braking if target_traffic_speed < traffic_current_speed else acceleration
		traffic_current_speed = move_toward(traffic_current_speed, target_traffic_speed, traffic_rate * delta)
		var traffic_speed := traffic_current_speed
		speed_kmh = absf(traffic_speed) * 3.6
		if _traffic_turn_active:
			_process_traffic_turn(delta, traffic_speed)
		elif target_traffic_speed > speed * 0.65:
			_try_begin_traffic_turn()
		if _traffic_turn_active:
			pass
		elif vertical_traffic:
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


func _try_begin_traffic_turn() -> void:
	# A subset of AI vehicles takes a smooth quarter-turn at city grid junctions.
	# This keeps traffic circulating without sending every car down the same route.
	if position.x < -70.0 or position.x > 70.0 or position.z < 86.0 or position.z > 224.0:
		return
	var intersection_x_values := [-64.0, -32.0, 0.0, 32.0, 64.0]
	var intersection_z_values := [91.0, 123.0, 155.0, 187.0, 219.0]
	for ix in intersection_x_values:
		for iz in intersection_z_values:
			var distance_to_line := (iz - global_position.z) * direction if vertical_traffic else (ix - global_position.x) * direction
			if distance_to_line < 4.5 or distance_to_line > 6.5:
				continue
			_traffic_turn_serial += 1
			if (int(get_instance_id()) + _traffic_turn_serial * 3) % 5 != 0:
				return
			var junction := Vector3(ix, global_position.y, iz)
			if not _is_intersection_clear(junction):
				return
			var incoming := Vector3(0.0, 0.0, direction) if vertical_traffic else Vector3(direction, 0.0, 0.0)
			var turn_left := (int(get_instance_id()) + _traffic_turn_serial) % 2 == 0
			var outgoing := Vector3(-incoming.z, 0.0, incoming.x) if turn_left else Vector3(incoming.z, 0.0, -incoming.x)
			var lane_offset := Vector3(-2.0 if outgoing.z > 0.0 else 2.0, 0.0, 0.0) if absf(outgoing.z) > 0.5 else Vector3(0.0, 0.0, -2.0 if outgoing.x > 0.0 else 2.0)
			_traffic_turn_start = global_position
			_traffic_turn_control_a = global_position + incoming * 3.0
			_traffic_turn_end = junction + outgoing * 5.5 + lane_offset
			_traffic_turn_control_b = _traffic_turn_end - outgoing * 3.0
			_traffic_turn_exit_direction = outgoing
			_traffic_turn_duration = maxf(1.5, _traffic_turn_start.distance_to(_traffic_turn_end) / maxf(speed, 2.5) * 1.3)
			_traffic_turn_elapsed = 0.0
			_traffic_turn_active = true
			return


func _is_intersection_clear(junction: Vector3) -> bool:
	# Do not begin a curved path while another vehicle occupies the junction.
	for other in get_tree().get_nodes_in_group("traffic_vehicles"):
		if other == self or not is_instance_valid(other):
			continue
		var other_position: Vector3 = other.global_position
		var flat_distance := Vector2(other_position.x - junction.x, other_position.z - junction.z).length()
		if flat_distance < 7.2:
			return false
	return true


func _process_traffic_turn(delta: float, traffic_speed: float) -> void:
	var turn_speed_factor := clampf(traffic_speed / maxf(speed, 0.1), 0.15, 1.1)
	_traffic_turn_elapsed = minf(_traffic_turn_elapsed + delta * turn_speed_factor, _traffic_turn_duration)
	var t := _traffic_turn_elapsed / _traffic_turn_duration
	var one_minus_t := 1.0 - t
	var next_position := one_minus_t * one_minus_t * one_minus_t * _traffic_turn_start
	next_position += 3.0 * one_minus_t * one_minus_t * t * _traffic_turn_control_a
	next_position += 3.0 * one_minus_t * t * t * _traffic_turn_control_b
	next_position += t * t * t * _traffic_turn_end
	var tangent := (_traffic_turn_end - _traffic_turn_control_b) * (3.0 * t * t)
	tangent += (_traffic_turn_control_b - _traffic_turn_control_a) * (6.0 * one_minus_t * t)
	tangent += (_traffic_turn_control_a - _traffic_turn_start) * (3.0 * one_minus_t * one_minus_t)
	global_position = next_position
	if tangent.length_squared() > 0.001:
		var forward := tangent.normalized()
		rotation.y = atan2(-forward.x, -forward.z)
	velocity = tangent.normalized() * traffic_speed
	_spin_wheels(delta, traffic_speed)
	if _traffic_turn_elapsed >= _traffic_turn_duration:
		_traffic_turn_active = false
		if absf(_traffic_turn_exit_direction.x) > 0.5:
			vertical_traffic = false
			direction = signf(_traffic_turn_exit_direction.x)
			lane_z = global_position.z
			start_x = -64.0 if direction > 0.0 else 64.0
			end_x = 64.0 if direction > 0.0 else -64.0
		else:
			vertical_traffic = true
			direction = signf(_traffic_turn_exit_direction.z)
			lane_x = global_position.x
			start_z = 91.0 if direction > 0.0 else 219.0
			end_z = 219.0 if direction > 0.0 else 91.0


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
		if bool(other.get("vertical_traffic")) != vertical_traffic:
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
			# Leave a longer buffer behind the player-controlled car.
			var safe_gap := 4.2 if bool(other.get("is_player_driven")) else 3.2
			var following_factor := clampf((gap - safe_gap) / 8.0, 0.0, 1.0)
			safe_speed = minf(safe_speed, speed * following_factor)

	# Downtown intersections use a predictable right-of-way rule: through traffic
	# on the east-west avenue goes first; north-south traffic yields. Every AI car
	# also yields to the player vehicle, regardless of approach direction.
	safe_speed = minf(safe_speed, _get_intersection_speed_limit())
	return safe_speed


func _get_intersection_speed_limit() -> float:
	var safe_speed := speed
	var intersection_x_values := [-64.0, -32.0, 0.0, 32.0, 64.0]
	var intersection_z_values := [91.0, 123.0, 155.0, 187.0, 219.0]
	for intersection_x in intersection_x_values:
		for intersection_z in intersection_z_values:
			var distance_to_line := INF
			if vertical_traffic:
				distance_to_line = (intersection_z - global_position.z) * direction
			else:
				distance_to_line = (intersection_x - global_position.x) * direction
			if distance_to_line < 0.0 or distance_to_line > 13.0:
				continue

			var conflict := false
			for other in get_tree().get_nodes_in_group("traffic_vehicles"):
				if other == self or not is_instance_valid(other):
					continue
				var other_vertical := bool(other.get("vertical_traffic"))
				var other_is_player := bool(other.get("is_player_driven"))
				if other_vertical == vertical_traffic and not other_is_player:
					continue
				# The crossing vehicle must actually be close to this junction.
				var cross_distance := Vector2(other.global_position.x - intersection_x, other.global_position.z - intersection_z).length()
				if cross_distance > 8.5:
					continue
				# Player has priority. Otherwise only north-south AI yields to
				# east-west AI, preventing both directions from deadlocking.
				if other_is_player or vertical_traffic:
					conflict = true
					break
			if conflict:
				var approach_factor := clampf((distance_to_line - 4.8) / 5.0, 0.0, 1.0)
				safe_speed = minf(safe_speed, speed * approach_factor)
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
