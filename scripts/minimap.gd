extends Control

var target: Node3D
var refresh_timer: float = 0.0
const MAP_SIZE := 172.0
const MAP_CENTER := Vector2(86.0, 86.0)
const WORLD_TO_MAP := 0.91

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)

func _process(delta: float) -> void:
	refresh_timer -= delta
	if refresh_timer <= 0.0:
		refresh_timer = 0.08
		queue_redraw()

func _world_point(world_x: float, world_z: float) -> Vector2:
	return MAP_CENTER + Vector2(world_x, world_z) * WORLD_TO_MAP

func _draw() -> void:
	var bounds := Rect2(Vector2(2, 2), Vector2(168, 168))
	draw_rect(bounds, Color(0.035, 0.045, 0.055, 0.94), true)
	draw_rect(bounds, Color(0.72, 0.78, 0.82, 0.75), false, 1.5)

	# River and bridge.
	draw_rect(Rect2(_world_point(-75, -8.5), Vector2(150, 17) * WORLD_TO_MAP), Color(0.055, 0.25, 0.36, 0.95), true)
	draw_rect(Rect2(_world_point(-5.5, -12), Vector2(11, 24) * WORLD_TO_MAP), Color(0.42, 0.43, 0.42), true)

	# Main roads and side streets.
	for road_z in [-34.0, 34.0]:
		var road_rect := Rect2(_world_point(-75, road_z - 5), Vector2(150, 10) * WORLD_TO_MAP)
		draw_rect(road_rect, Color(0.22, 0.24, 0.25), true)
		for road_x in [-52.0, -26.0, 26.0, 52.0]:
			draw_rect(Rect2(_world_point(road_x - 3.5, road_z - 29), Vector2(7, 58) * WORLD_TO_MAP), Color(0.20, 0.22, 0.23), true)

	# Building blocks.
	for district_z in [-34.0, 34.0]:
		for x in range(-5, 6):
			for side in [-1.0, 1.0]:
				var p := _world_point(float(x) * 13.0, district_z + side * 20.0)
				draw_rect(Rect2(p - Vector2(3.2, 3.2), Vector2(6.4, 6.4)), Color(0.48, 0.49, 0.46), true)

	# Live player marker.
	if is_instance_valid(target):
		var p := _world_point(target.global_position.x, target.global_position.z)
		draw_circle(p, 5.2, Color(0.08, 0.55, 1.0))
		draw_arc(p, 7.0, 0.0, TAU, 24, Color(0.85, 0.94, 1.0), 1.5)
		draw_line(p + Vector2(0, -8), p + Vector2(0, -14), Color.WHITE, 2.0)

	draw_string(ThemeDB.fallback_font, Vector2(12, 17), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.88, 0.92, 0.95))
