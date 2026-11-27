extends Control

signal destination_changed(world_position: Vector3)

var target: Node3D
var refresh_timer: float = 0.0
var expanded := false
var destination := Vector3.ZERO
var has_destination := false
const WORLD_MIN := Vector2(-75.0, -65.0)
const WORLD_MAX := Vector2(75.0, 235.0)
const MINI_SIZE := Vector2(172.0, 172.0)
const MINI_MARGIN := 2.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = MINI_SIZE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _process(delta: float) -> void:
	refresh_timer -= delta
	if refresh_timer <= 0.0:
		refresh_timer = 0.12
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var pressed := false
	var point := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
		point = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
		point = event.position
	if not pressed:
		return
	if not expanded:
		expanded = true
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		position = Vector2.ZERO
		size = get_viewport_rect().size
		queue_redraw()
		accept_event()
		return
	if point.x > size.x - 92.0 and point.y < 76.0:
		expanded = false
		set_anchors_preset(Control.PRESET_TOP_RIGHT)
		position = Vector2(-190, 18)
		size = MINI_SIZE
		queue_redraw()
		accept_event()
		return
	var world := _screen_to_world(point)
	destination = Vector3(world.x, 0.0, world.y)
	has_destination = true
	destination_changed.emit(destination)
	queue_redraw()
	accept_event()

func _map_rect() -> Rect2:
	if expanded:
		var margin := 24.0
		var available := size - Vector2(margin * 2.0, margin * 2.0)
		var world_size := WORLD_MAX - WORLD_MIN
		var scale_value := minf(available.x / world_size.x, available.y / world_size.y)
		var drawn := world_size * scale_value
		return Rect2((size - drawn) * 0.5, drawn)
	return Rect2(Vector2(MINI_MARGIN, MINI_MARGIN), MINI_SIZE - Vector2(4, 4))

func _world_to_screen(world_x: float, world_z: float) -> Vector2:
	var rect := _map_rect()
	var normalized := (Vector2(world_x, world_z) - WORLD_MIN) / (WORLD_MAX - WORLD_MIN)
	return rect.position + Vector2(normalized.x * rect.size.x, normalized.y * rect.size.y)

func _screen_to_world(point: Vector2) -> Vector2:
	var rect := _map_rect()
	var normalized := (point - rect.position) / rect.size
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	return WORLD_MIN + normalized * (WORLD_MAX - WORLD_MIN)

func _draw() -> void:
	if expanded:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.018, 0.025, 0.034, 0.98), true)
	var rect := _map_rect()
	draw_rect(rect, Color(0.055, 0.075, 0.085, 0.98), true)
	draw_rect(rect, Color(0.72, 0.80, 0.86, 0.75), false, 1.5)

	# River, bridge and the two connected districts.
	var p1 := _world_to_screen(-75, -8.5)
	var p2 := _world_to_screen(75, 8.5)
	draw_rect(Rect2(p1, p2 - p1), Color(0.025, 0.20, 0.31), true)
	var bridge_a := _world_to_screen(-5.5, -12)
	var bridge_b := _world_to_screen(5.5, 12)
	draw_rect(Rect2(bridge_a, bridge_b - bridge_a), Color(0.48, 0.49, 0.47), true)

	# Main roads and side streets in the two districts, leaving the river clear.
	for road_z in [-34.0, 34.0]:
		var a := _world_to_screen(-75, road_z - 8.0)
		var b := _world_to_screen(75, road_z + 8.0)
		draw_rect(Rect2(a, b - a), Color(0.20, 0.22, 0.23), true)
	for road_x in [-48.0, -16.0, 16.0, 48.0]:
		for road_segment in [Vector2(-74.0, -10.0), Vector2(10.0, 74.0)]:
			var c := _world_to_screen(road_x - 8.0, road_segment.x)
			var d := _world_to_screen(road_x + 8.0, road_segment.y)
			draw_rect(Rect2(c, d - c), Color(0.19, 0.21, 0.22), true)

	# Downtown modular GLB grid: five north-south roads and five cross streets.
	# Each road tile is 16 m wide and intersections are centred on the same grid.
	for street_x in [-64.0, -32.0, 0.0, 32.0, 64.0]:
		var a := _world_to_screen(street_x - 8.0, 83.0)
		var b := _world_to_screen(street_x + 8.0, 227.0)
		draw_rect(Rect2(a, b - a), Color(0.19, 0.21, 0.22), true)
	for cross_z in [91.0, 123.0, 155.0, 187.0, 219.0]:
		var a := _world_to_screen(-72.0, cross_z - 8.0)
		var b := _world_to_screen(72.0, cross_z + 8.0)
		draw_rect(Rect2(a, b - a), Color(0.19, 0.21, 0.22), true)

	# Existing village plots and the 16 apartment blocks in the new downtown grid.
	for district_z in [-34.0, 34.0]:
		for block_x in [-65.0, -32.0, 0.0, 32.0, 65.0]:
			for side in [-1.0, 1.0]:
				var p := _world_to_screen(block_x, district_z + side * 20.0)
				var block := maxf(3.0, rect.size.x * 0.012)
				draw_rect(Rect2(p - Vector2(block, block), Vector2(block * 2, block * 2)), Color(0.49, 0.51, 0.48), true)
	for city_z in [107.0, 139.0, 171.0, 203.0]:
		for city_x in [-48.0, -16.0, 16.0, 48.0]:
			var p := _world_to_screen(city_x, city_z)
			var block := maxf(2.8, rect.size.x * 0.010)
			draw_rect(Rect2(p - Vector2(block, block), Vector2(block * 2, block * 2)), Color(0.56, 0.58, 0.55), true)

	if has_destination:
		var marker := _world_to_screen(destination.x, destination.z)
		draw_circle(marker, 7.0 if expanded else 5.0, Color(1.0, 0.30, 0.18))
		draw_arc(marker, 11.0 if expanded else 8.0, 0.0, TAU, 28, Color(1.0, 0.88, 0.82), 1.6)

	if is_instance_valid(target):
		var player_point := _world_to_screen(target.global_position.x, target.global_position.z)
		if has_destination:
			var marker_point := _world_to_screen(destination.x, destination.z)
			draw_line(player_point, marker_point, Color(0.25, 0.72, 1.0, 0.9), 2.0)
		# The marker points in the same direction as the player or active vehicle.
		var forward := -target.global_basis.z
		var heading := Vector2(forward.x, forward.z).normalized()
		var heading_length := 11.0 if expanded else 7.5
		var heading_width := 5.0 if expanded else 3.5
		var tip := player_point + heading * heading_length
		var rear := player_point - heading * heading_width
		var side := Vector2(-heading.y, heading.x) * heading_width
		draw_colored_polygon(PackedVector2Array([tip, rear + side, rear - side]), Color(0.08, 0.57, 1.0))
		draw_circle(player_point, 3.0 if expanded else 2.2, Color.WHITE)
		draw_arc(player_point, 9.0 if expanded else 7.0, 0.0, TAU, 24, Color.WHITE, 1.3)

	if expanded:
		draw_string(ThemeDB.fallback_font, Vector2(28, 38), "OPEN CITY  /  КАРТА МИРА", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.94, 0.97, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(28, size.y - 28), "Нажми на карту, чтобы поставить метку   •   Закрыть: ✕", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.72, 0.79, 0.86))
		draw_rect(Rect2(Vector2(size.x - 74, 20), Vector2(52, 42)), Color(0.18, 0.22, 0.27, 0.95), true)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 58, 48), "✕", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(12, 17), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.88, 0.92, 0.95))
