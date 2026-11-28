extends Node3D

class VirtualJoystick extends Control:
	signal changed(value: Vector2)
	var _finger := -1
	var _mouse_down := false
	var _value := Vector2.ZERO
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		queue_redraw()
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and _finger == -1:
				_finger = event.index
				_set_value(event.position)
				accept_event()
			elif not event.pressed and event.index == _finger:
				_finger = -1
				_set_value(size * 0.5)
				accept_event()
		elif event is InputEventScreenDrag and event.index == _finger:
			_set_value(event.position)
			accept_event()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_down = event.pressed
			_set_value(event.position if event.pressed else size * 0.5)
			accept_event()
		elif event is InputEventMouseMotion and _mouse_down:
			_set_value(event.position)
			accept_event()
	func _set_value(point: Vector2) -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.36
		_value = ((point - center) / radius).limit_length(1.0)
		changed.emit(_value)
		queue_redraw()
	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.36
		draw_circle(center, radius + 5.0, Color(0.02, 0.03, 0.04, 0.25))
		draw_circle(center, radius, Color(0.75, 0.82, 0.9, 0.16))
		draw_arc(center, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.42), 1.5, true)
		draw_circle(center + _value * radius, radius * 0.43, Color(0.92, 0.95, 1.0, 0.72))
		draw_arc(center + _value * radius, radius * 0.43, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 1.4, true)

const PlayerScript = preload("res://scripts/player.gd")
const CarScript = preload("res://scripts/traffic_car.gd")
const NpcScript = preload("res://scripts/npc.gd")
const MinimapScript = preload("res://scripts/minimap.gd")
const HouseScene: PackedScene = preload("res://assets/models/casa_simples.glb")
const MarketScene: PackedScene = preload("res://assets/models/mercado.glb")
# Realistic CC0 vehicle GLBs are downloaded by the Android build workflow.
# Keep these as paths rather than preload() so the editor can still open the project
# before the optional external asset download step has run.
var VehicleScenes: Array[PackedScene] = []
const VehicleScenePaths: Array[String] = [
	"res://assets/models/vehicles/realistic_sedan.glb",
	"res://assets/models/vehicles/realistic_suv.glb",
	"res://assets/models/vehicles/realistic_taxi.glb",
	"res://assets/models/vehicles/realistic_police.glb",
	"res://assets/models/vehicles/realistic_pickup.glb",
	"res://assets/models/vehicles/realistic_firetruck.glb",
	"res://assets/models/vehicles/realistic_sports.glb",
	"res://assets/models/vehicles/realistic_ambulance.glb"
]
const VehicleScales: Array[float] = [2.45, 2.35, 2.45, 2.45, 2.4, 2.4, 2.35, 2.3]
const TreeScene: PackedScene = preload("res://assets/models/ipe_amarelo.glb")
const StreetLightScene: PackedScene = preload("res://assets/models/poste_luz.glb")
const BushScene: PackedScene = preload("res://assets/models/nature/bush.glb")
const BushFlowersScene: PackedScene = preload("res://assets/models/nature/bush_flowers.glb")
const GrassClumpScene: PackedScene = preload("res://assets/models/nature/grass.glb")

const PlasterTexture: Texture2D = preload("res://assets/textures/wall_plaster.svg")
const BrickTexture: Texture2D = preload("res://assets/textures/brick_ambientcg.png")
const ConcreteTexture: Texture2D = preload("res://assets/textures/pbr/concrete_color.jpg")
const RoofTexture: Texture2D = preload("res://assets/textures/roof_tiles.svg")
const AsphaltTexture: Texture2D = preload("res://assets/textures/pbr/road_color.jpg")
const GrassTexture: Texture2D = preload("res://assets/textures/pbr/grass_color.jpg")
const AsphaltNormalTexture: Texture2D = preload("res://assets/textures/pbr/road_normal.jpg")
const AsphaltRoughnessTexture: Texture2D = preload("res://assets/textures/pbr/road_roughness.jpg")
const ConcreteNormalTexture: Texture2D = preload("res://assets/textures/pbr/concrete_normal.jpg")
const ConcreteRoughnessTexture: Texture2D = preload("res://assets/textures/pbr/concrete_roughness.jpg")
const GrassNormalTexture: Texture2D = preload("res://assets/textures/pbr/grass_normal.jpg")
const GrassRoughnessTexture: Texture2D = preload("res://assets/textures/pbr/grass_roughness.jpg")

var player: Variant
var cars: Array[Node3D] = []
var status_label: Label
var enter_button: Button
var controls_layer: CanvasLayer
var menu_layer: CanvasLayer
var menu_music: AudioStreamPlayer
var settings_panel: PanelContainer
var home_panel: PanelContainer
var fps_value_label: Label
var selected_fps := 60
var vehicle_hud: PanelContainer
var vehicle_hud_label: Label
var vehicle_fuel_label: Label
var movement_joystick: VirtualJoystick
var jump_button: Button
var run_button: Button
var driving_controls: Control
var minimap_control: Control
var _minimap_tracks_vehicle := false
var waypoint_label: Label
var waypoint_position := Vector3.ZERO
var has_waypoint := false

func _ready() -> void:
	randomize()
	# Create the player and active camera first. If world asset setup reports an
	# error on a device, the app must not remain on the default blue clear color.
	_setup_player()
	_setup_world()
	_setup_traffic()
	_setup_audio()
	_setup_people()
	_setup_mobile_ui()
	_setup_main_menu()

func _process(delta: float) -> void:
	if vehicle_hud != null and is_instance_valid(player):
		var driving := player.active_vehicle != null
		if minimap_control != null and driving != _minimap_tracks_vehicle:
			minimap_control.set("target", player.active_vehicle if driving else player)
			_minimap_tracks_vehicle = driving
		vehicle_hud.visible = driving
		if driving_controls != null:
			driving_controls.visible = driving
		if movement_joystick != null:
			movement_joystick.visible = not driving
		if jump_button != null:
			jump_button.visible = not driving
		if run_button != null:
			run_button.visible = not driving
		if driving:
			var car = player.active_vehicle
			vehicle_hud_label.text = "%03d" % int(car.get("speed_kmh"))
			vehicle_fuel_label.text = "БЕНЗИН  %.1f L" % float(car.get("fuel_liters"))
		if enter_button != null:
			if driving:
				enter_button.visible = true
				enter_button.text = "ВЫЙТИ"
			else:
				var nearby_vehicle := false
				for candidate in cars:
					if is_instance_valid(candidate) and player.global_position.distance_to(candidate.global_position) <= 5.0:
						nearby_vehicle = true
						break
				enter_button.visible = nearby_vehicle
				enter_button.text = "СЕСТЬ"
		if waypoint_label != null:
			waypoint_label.visible = has_waypoint
			if has_waypoint:
				var waypoint_target: Node3D = player.active_vehicle if driving else player
				var distance_to_waypoint := waypoint_target.global_position.distance_to(waypoint_position)
				waypoint_label.text = "МЕТКА  •  %d м" % int(round(distance_to_waypoint))

func _on_minimap_destination_changed(world_position: Vector3) -> void:
	waypoint_position = world_position
	has_waypoint = true
	if waypoint_label != null:
		waypoint_label.visible = true
		waypoint_label.text = "МЕТКА  •  РАСЧЁТ..."


func _setup_audio() -> void:
	# Authentic field-recorded city traffic and distant crowd chatter, downloaded by CI.
	var traffic_path := "res://assets/audio/city_traffic.mp3"
	if ResourceLoader.exists(traffic_path):
		var traffic_ambience := AudioStreamPlayer.new()
		traffic_ambience.name = "CityTrafficAmbience"
		traffic_ambience.stream = load(traffic_path)
		if traffic_ambience.stream is AudioStreamMP3:
			(traffic_ambience.stream as AudioStreamMP3).loop = true
		traffic_ambience.volume_db = -23.0
		add_child(traffic_ambience)
		traffic_ambience.play()

	var river_path := "res://assets/audio/river_ambience.mp3"
	if ResourceLoader.exists(river_path):
		var river_audio := AudioStreamPlayer3D.new()
		river_audio.name = "RiverAmbience3D"
		river_audio.stream = load(river_path)
		if river_audio.stream is AudioStreamMP3:
			(river_audio.stream as AudioStreamMP3).loop = true
		river_audio.position = Vector3(0, 0.25, 0)
		river_audio.volume_db = -14.0
		river_audio.unit_size = 7.0
		river_audio.max_distance = 72.0
		add_child(river_audio)
		river_audio.play()

	var chatter_path := "res://assets/audio/pedestrian_chatter.mp3"
	if ResourceLoader.exists(chatter_path):
		for district_z in [-34.0, 34.0]:
			var chatter := AudioStreamPlayer3D.new()
			chatter.name = "PedestrianChatter"
			chatter.stream = load(chatter_path)
			if chatter.stream is AudioStreamMP3:
				(chatter.stream as AudioStreamMP3).loop = true
			chatter.position = Vector3(0, 1.0, district_z + 6.0)
			chatter.volume_db = -25.0
			chatter.unit_size = 8.0
			chatter.max_distance = 42.0
			add_child(chatter)
			chatter.play()


func _setup_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = false
	sun.shadow_bias = 0.05
	add_child(sun)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	# Neutral overcast daylight sky; no snow particles or winter weather effects.
	sky_mat.sky_top_color = Color(0.24, 0.34, 0.45)
	sky_mat.sky_horizon_color = Color(0.70, 0.78, 0.84)
	var hdri_path := "res://assets/sky/cloudy_day_1k.hdr"
	if ResourceLoader.exists(hdri_path):
		var panorama_material := PanoramaSkyMaterial.new()
		panorama_material.panorama = load(hdri_path) as Texture2D
		sky.sky_material = panorama_material
	else:
		sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.92
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = false
	environment.environment = env
	add_child(environment)

	_make_box("Mainland West", Vector3(0, -0.6, -41.25), Vector3(150, 1, 67.5), Color(0.28, 0.39, 0.27), true)
	_make_box("Mainland East", Vector3(0, -0.6, 41.25), Vector3(150, 1, 67.5), Color(0.28, 0.39, 0.27), true)
	_make_box("River", Vector3(0, -0.05, 0), Vector3(150, 0.15, 17), Color(0.08, 0.30, 0.48), false)

	# Main road, two districts and the bridge connecting them.
	if ResourceLoader.exists("res://assets/models/vinish_city/road-straight.glb"):
		_setup_vinish_district_roads()
	else:
		_make_box("West road", Vector3(0, 0.02, -34), Vector3(150, 0.12, 10), Color(0.12, 0.13, 0.15), true)
		_make_box("East road", Vector3(0, 0.02, 34), Vector3(150, 0.12, 10), Color(0.12, 0.13, 0.15), true)
	_make_box("Bridge", Vector3(0, 0.18, 0), Vector3(11, 0.45, 24), Color(0.25, 0.26, 0.28), true)
	_make_box("Bridge rail left", Vector3(-5.4, 1.0, 0), Vector3(0.35, 1.5, 24), Color(0.55, 0.58, 0.6), true)
	_make_box("Bridge rail right", Vector3(5.4, 1.0, 0), Vector3(0.35, 1.5, 24), Color(0.55, 0.58, 0.6), true)

	for district_z in [-34.0, 34.0]:
		# Keep buildings inside the blocks between the new modular side streets.
		for block_x in [-65.0, -32.0, 0.0, 32.0, 65.0]:
			for side in [-1.0, 1.0]:
				var bx: float = block_x + randf_range(-1.2, 1.2)
				var bz: float = district_z + side * randf_range(15.0, 23.0)
				var chosen_scene: PackedScene = HouseScene if randf() < 0.72 else MarketScene
				_spawn_asset_building(chosen_scene, Vector3(bx, 0.0, bz), 3.4)

	# Imported CC0 trees and street lights.
	for x in [-58.0, -42.0, -16.0, 16.0, 42.0, 58.0]:
		_spawn_prop(TreeScene, Vector3(x, 0.0, -49.0), 3.0)
		_spawn_prop(TreeScene, Vector3(x + 5.0, 0.0, 49.0), 3.0)
	# Low vegetation breaks up the bare river banks and roadside green strips.
	for x in [-62.0, -46.0, -30.0, -14.0, 14.0, 30.0, 46.0, 62.0]:
		_spawn_prop(BushScene, Vector3(x, 0.0, -10.0), 1.05)
		_spawn_prop(BushFlowersScene, Vector3(x + 4.0, 0.0, 10.0), 0.95)
		_spawn_prop(GrassClumpScene, Vector3(x - 2.0, 0.0, -12.0), 1.25)
		_spawn_prop(GrassClumpScene, Vector3(x + 2.0, 0.0, 12.0), 1.25)
	for x in range(-5, 6):
		_spawn_prop(StreetLightScene, Vector3(float(x) * 13.0, 0.0, -27.0), 2.5)
		_spawn_prop(StreetLightScene, Vector3(float(x) * 13.0, 0.0, 27.0), 2.5)

	# Side streets use the same textured 16 m GLB kit when it is available.
	if not ResourceLoader.exists("res://assets/models/vinish_city/road-straight.glb"):
		for x in [-52.0, -26.0, 26.0, 52.0]:
			_make_box("Side street", Vector3(x, 0.015, -34), Vector3(7, 0.1, 58), Color(0.16,0.17,0.18), false)
			_make_box("Side street", Vector3(x, 0.015, 34), Vector3(7, 0.1, 58), Color(0.16,0.17,0.18), false)

	if not ResourceLoader.exists("res://assets/models/vinish_city/road-straight.glb"):
		_add_sidewalks()
		_add_road_markings()

	# Downtown setup is required whether the modular road kit exists or not.
	_setup_downtown()


func _setup_vinish_district_roads() -> void:
	# Textured 16 m road modules replace the old plain side-road boxes.
	var road_scene := load("res://assets/models/vinish_city/road-straight.glb") as PackedScene
	var cross_scene := load("res://assets/models/vinish_city/road-crossroads.glb") as PackedScene
	if road_scene == null:
		push_warning("Vinish road mesh could not be loaded; building the complete procedural road fallback")
		_make_box("West road", Vector3(0, 0.02, -34), Vector3(150, 0.12, 10), Color(0.12, 0.13, 0.15), true)
		_make_box("East road", Vector3(0, 0.02, 34), Vector3(150, 0.12, 10), Color(0.12, 0.13, 0.15), true)
		for street_x in [-52.0, -26.0, 26.0, 52.0]:
			_make_box("Side street", Vector3(street_x, 0.015, -34), Vector3(7, 0.1, 58), Color(0.16, 0.17, 0.18), false)
			_make_box("Side street", Vector3(street_x, 0.015, 34), Vector3(7, 0.1, 58), Color(0.16, 0.17, 0.18), false)
		_add_sidewalks()
		_add_road_markings()
		return

	# Four side-road junctions on each district boulevard use proper crossroads.
	var side_street_x := [-48.0, -16.0, 16.0, 48.0]
	for road_z in [-34.0, 34.0]:
		for tile_index in range(9):
			var road_x := -64.0 + float(tile_index) * 16.0
			var is_intersection := side_street_x.has(road_x)
			var selected_scene: PackedScene = cross_scene if is_intersection and cross_scene != null else road_scene
			_spawn_vinish_road_tile(selected_scene, Vector3(road_x, -0.42, road_z), PI * 0.5)

	# Continue each side street away from the boulevard using straight GLB segments.
	for street_x in side_street_x:
		for segment_z in [-66.0, -50.0, -18.0, 18.0, 50.0, 66.0]:
			_spawn_vinish_road_tile(road_scene, Vector3(street_x, -0.42, segment_z), 0.0)


func _spawn_vinish_apartment(at: Vector3, variant_index: int) -> void:
	var use_first := variant_index % 2 == 0
	var model_path := "res://assets/models/vinish_city/apartment-block-01.glb" if use_first else "res://assets/models/vinish_city/apartment-block-02.glb"
	if not ResourceLoader.exists(model_path):
		push_warning("Required downtown apartment asset is missing: " + model_path)
		return
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_warning("Downtown apartment asset could not be loaded: " + model_path)
		return
	var root := StaticBody3D.new()
	root.name = "VinishBrickApartment"
	root.position = at
	var model := packed.instantiate() as Node3D
	if model == null:
		root.queue_free()
		push_warning("Downtown apartment model could not be instantiated: " + model_path)
		return
	root.add_child(model)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(14.5, 23.2, 13.5) if use_first else Vector3(11.0, 20.0, 12.5)
	collision.shape = shape
	collision.position.y = shape.size.y * 0.5
	root.add_child(collision)
	add_child(root)


func _setup_downtown() -> void:
	# Downtown uses a 16 m modular grid so the detailed GLB road tiles fit edge-to-edge.
	_make_box("Mainland Downtown", Vector3(0, -0.6, 155), Vector3(150, 1, 160), Color(0.28, 0.39, 0.27), true)

	var detailed_roads := ResourceLoader.exists("res://assets/models/vinish_city/road-crossroads.glb") and ResourceLoader.exists("res://assets/models/vinish_city/road-straight.glb")
	if detailed_roads:
		detailed_roads = _setup_vinish_downtown_roads()
	if not detailed_roads:
		# Safe fallback if a downloaded model is missing or cannot be loaded in the Android export.
		_make_box("Downtown Boulevard Road", Vector3(0, 0.025, 155), Vector3(13, 0.14, 160), Color(0.12, 0.13, 0.15), true)
		for street_x in [-60.0, -30.0, 30.0, 60.0]:
			_make_box("Downtown Street", Vector3(street_x, 0.02, 155), Vector3(8.5, 0.13, 160), Color(0.13, 0.14, 0.16), true)
		for street_z in [95.0, 135.0, 175.0, 215.0]:
			_make_box("Downtown Cross Street", Vector3(0, 0.02, street_z), Vector3(132, 0.13, 9.5), Color(0.13, 0.14, 0.16), true)
			for side in [-1.0, 1.0]:
				_make_box("Downtown Sidewalk", Vector3(0, 0.045, street_z + side * 6.0), Vector3(132, 0.18, 2.7), Color(0.43, 0.44, 0.42), true)
		for street_x in [-60.0, -30.0, 0.0, 30.0, 60.0]:
			for side in [-1.0, 1.0]:
				_make_box("Downtown Sidewalk", Vector3(street_x + side * (7.5 if street_x == 0.0 else 5.8), 0.045, 155), Vector3(2.4, 0.18, 160), Color(0.43, 0.44, 0.42), true)

	# One full-size brick apartment fits each 16 x 16 city block.
	var block_x_centers := [-48.0, -16.0, 16.0, 48.0]
	var block_z_centers := [107.0, 139.0, 171.0, 203.0]
	var detailed_buildings := ResourceLoader.exists("res://assets/models/vinish_city/apartment-block-01.glb") and ResourceLoader.exists("res://assets/models/vinish_city/apartment-block-02.glb")
	if not detailed_buildings:
		push_warning("Downtown apartment kit is incomplete; skipping those blocks rather than substituting small-house placeholders.")
	else:
		for row_index in range(block_z_centers.size()):
			for column_index in range(block_x_centers.size()):
				var center := Vector3(block_x_centers[column_index], 0.0, block_z_centers[row_index])
				_spawn_vinish_apartment(center, row_index + column_index)

	# Textured street furniture from the same kit, with a mobile-friendly count.
	if detailed_roads and ResourceLoader.exists("res://assets/models/vinish_city/street-light.glb"):
		var lamp_scene := load("res://assets/models/vinish_city/street-light.glb") as PackedScene
		if lamp_scene != null:
			for row_index in range(4):
				for street_x in [-64.0, -32.0, 0.0, 32.0, 64.0]:
					var lamp := lamp_scene.instantiate() as Node3D
					if lamp != null:
						lamp.position = Vector3(street_x + (7.1 if row_index % 2 == 0 else -7.1), 0.0, 107.0 + float(row_index) * 32.0)
						add_child(lamp)

	if detailed_roads and ResourceLoader.exists("res://assets/models/vinish_city/traffic-signal.glb"):
		var signal_scene := load("res://assets/models/vinish_city/traffic-signal.glb") as PackedScene
		if signal_scene != null:
			# Put a signal at each of the four main downtown junctions.
			# Keeping them on the same corner offset prevents them from sitting in the road center.
			for intersection in [
				Vector2(-32.0, 123.0),
				Vector2(32.0, 123.0),
				Vector2(-32.0, 187.0),
				Vector2(32.0, 187.0)
			]:
				var signal_model := signal_scene.instantiate() as Node3D
				if signal_model != null:
					signal_model.position = Vector3(intersection.x + 6.5, 0.0, intersection.y + 6.5)
					add_child(signal_model)

	# Fire hydrants add small, recognizable street-level details to the sidewalks.
	if detailed_roads and ResourceLoader.exists("res://assets/models/vinish_city/fire-hydrant.glb"):
		var hydrant_scene := load("res://assets/models/vinish_city/fire-hydrant.glb") as PackedScene
		if hydrant_scene != null:
			for hydrant_position in [
				Vector3(-41.0, 0.0, 114.0),
				Vector3(41.0, 0.0, 114.0),
				Vector3(-41.0, 0.0, 178.0),
				Vector3(41.0, 0.0, 178.0),
				Vector3(-9.0, 0.0, 146.0),
				Vector3(9.0, 0.0, 146.0)
			]:
				var hydrant := hydrant_scene.instantiate() as Node3D
				if hydrant != null:
					hydrant.position = hydrant_position
					add_child(hydrant)



func _setup_vinish_downtown_roads() -> bool:
	# Each GLB is a 16 x 16 m tile. Crossroads sit at 32 m intervals;
	# straight tiles fill the exact 16 m gaps, avoiding overlaps and mismatched seams.
	var straight_scene := load("res://assets/models/vinish_city/road-straight.glb") as PackedScene
	var cross_scene := load("res://assets/models/vinish_city/road-crossroads.glb") as PackedScene
	if straight_scene == null or cross_scene == null:
		push_warning("Vinish downtown road scenes unavailable; procedural road fallback will be used")
		return false

	var intersection_x := [-64.0, -32.0, 0.0, 32.0, 64.0]
	var intersection_z := [91.0, 123.0, 155.0, 187.0, 219.0]
	for street_z in intersection_z:
		for street_x in intersection_x:
			_spawn_vinish_road_tile(cross_scene, Vector3(street_x, -0.42, street_z), 0.0)
		for segment_x in [-48.0, -16.0, 16.0, 48.0]:
			_spawn_vinish_road_tile(straight_scene, Vector3(segment_x, -0.42, street_z), PI * 0.5)

	for street_x in intersection_x:
		for segment_z in [107.0, 139.0, 171.0, 203.0]:
			_spawn_vinish_road_tile(straight_scene, Vector3(street_x, -0.42, segment_z), 0.0)
	return true


func _spawn_vinish_road_tile(scene: PackedScene, at: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = "VinishTexturedRoadTile"
	body.position = at
	body.rotation.y = yaw
	var model := scene.instantiate() as Node3D
	if model == null:
		body.queue_free()
		return
	body.add_child(model)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(16.0, 0.45, 16.0)
	collision.shape = shape
	# Road mesh bounds are 0.45 m high; align collision top to the surface.
	collision.position.y = 0.225
	body.add_child(collision)
	add_child(body)


func _spawn_optional_city_model(path: String, at: Vector3, model_scale: Vector3, collision_size: Vector3, rotation_value: Vector3 = Vector3.ZERO) -> void:
	if not ResourceLoader.exists(path):
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Could not load optional city model: " + path)
		return
	var body := StaticBody3D.new()
	body.name = "DetailedDowntownBuilding"
	body.position = at
	body.rotation = rotation_value
	var model := packed.instantiate() as Node3D
	if model == null:
		body.queue_free()
		return
	model.scale = model_scale
	body.add_child(model)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = collision_size
	collision.shape = shape
	collision.position.y = collision_size.y * 0.5
	body.add_child(collision)
	add_child(body)


func _add_sidewalks() -> void:
	for road_z in [-34.0, 34.0]:
		for side in [-1.0, 1.0]:
			var sidewalk_z: float = road_z + side * 6.35
			_make_box("Sidewalk", Vector3(0, 0.035, sidewalk_z), Vector3(150, 0.20, 2.45), Color(0.43, 0.44, 0.42), true)
			_make_box("Curb", Vector3(0, 0.15, road_z + side * 5.12), Vector3(150, 0.28, 0.22), Color(0.57, 0.57, 0.53), true)

func _add_road_markings() -> void:
	var paint := _make_color_material(Color(0.82, 0.81, 0.73), 0.88)
	for road_z in [-34.0, 34.0]:
		for x in range(-70, 71, 9):
			var dash := MeshInstance3D.new()
			var dash_mesh := BoxMesh.new()
			dash_mesh.size = Vector3(4.0, 0.025, 0.16)
			dash.mesh = dash_mesh
			dash.position = Vector3(float(x), 0.091, road_z)
			dash.material_override = paint
			add_child(dash)
		for side in [-1.0, 1.0]:
			var edge := MeshInstance3D.new()
			var edge_mesh := BoxMesh.new()
			edge_mesh.size = Vector3(150, 0.018, 0.10)
			edge.mesh = edge_mesh
			edge.position = Vector3(0, 0.088, road_z + side * 4.55)
			edge.material_override = paint
			add_child(edge)
	for street_x in [-52.0, -26.0, 26.0, 52.0]:
		for district_z in [-34.0, 34.0]:
			for offset in range(-24, 25, 9):
				var dash := MeshInstance3D.new()
				var dash_mesh := BoxMesh.new()
				dash_mesh.size = Vector3(0.14, 0.022, 4.0)
				dash.mesh = dash_mesh
				dash.position = Vector3(street_x, 0.085, district_z + float(offset))
				dash.material_override = paint
				add_child(dash)

func _spawn_asset_building(requested_scene: PackedScene, at: Vector3, scale_factor: float) -> void:
	# Use the authored house/market model requested by the district generator.
	# Legacy low-poly building collections are never substituted here.
	if requested_scene == null:
		push_warning("Building scene missing at %s; skipping rather than showing a placeholder." % at)
		return
	var root := StaticBody3D.new()
	root.name = "ImportedBuilding"
	root.position = at
	var model := requested_scene.instantiate() as Node3D
	if model == null:
		root.queue_free()
		push_warning("Building model failed to instantiate at %s." % at)
		return
	model.scale = Vector3.ONE * scale_factor
	root.add_child(model)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.6, 2.4, 3.2) * scale_factor
	collision.shape = shape
	collision.position.y = shape.size.y * 0.5
	root.add_child(collision)
	add_child(root)
func _make_texture_material(texture: Texture2D, tint: Color, uv_scale: Vector3) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.roughness = 0.88
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.uv1_scale = uv_scale
	return material

func _make_color_material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material

func _add_textured_box(parent: Node3D, label: String, dimensions: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var box := BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.position = at
	parent.add_child(mesh_instance)
	return mesh_instance

func _add_window(parent: Node3D, at: Vector3, window_size: Vector2, storefront: bool) -> void:
	var frame_mat := _make_color_material(Color(0.20, 0.19, 0.17), 0.72)
	var glass_mat := _make_color_material(Color(0.10, 0.19, 0.23, 1), 0.18)
	glass_mat.metallic = 0.22
	glass_mat.metallic_specular = 0.65
	var frame_depth := 0.12
	var pane := BoxMesh.new()
	pane.size = Vector3(window_size.x, window_size.y, 0.07)
	var glass := MeshInstance3D.new()
	glass.mesh = pane
	glass.material_override = glass_mat
	glass.position = at
	parent.add_child(glass)
	var bar_w := 0.10 if not storefront else 0.07
	_add_textured_box(parent, "WindowFrame", Vector3(bar_w, window_size.y + 0.16, frame_depth), at + Vector3(-window_size.x * 0.5, 0, 0), frame_mat)
	_add_textured_box(parent, "WindowFrame", Vector3(bar_w, window_size.y + 0.16, frame_depth), at + Vector3(window_size.x * 0.5, 0, 0), frame_mat)
	_add_textured_box(parent, "WindowSill", Vector3(window_size.x + 0.18, 0.11, frame_depth), at + Vector3(0, -window_size.y * 0.5, 0), frame_mat)
	_add_textured_box(parent, "WindowLintel", Vector3(window_size.x + 0.18, 0.11, frame_depth), at + Vector3(0, window_size.y * 0.5, 0), frame_mat)
	if not storefront:
		_add_textured_box(parent, "WindowMullion", Vector3(0.07, window_size.y, 0.10), at, frame_mat)

func _add_side_window(parent: Node3D, at: Vector3, window_size: Vector2) -> void:
	var frame_mat := _make_color_material(Color(0.20, 0.19, 0.17), 0.72)
	var glass_mat := _make_color_material(Color(0.10, 0.19, 0.23), 0.2)
	var pane := BoxMesh.new()
	pane.size = Vector3(0.07, window_size.y, window_size.x)
	var glass := MeshInstance3D.new()
	glass.mesh = pane
	glass.material_override = glass_mat
	glass.position = at
	parent.add_child(glass)
	_add_textured_box(parent, "SideWindowFrame", Vector3(0.12, window_size.y + 0.16, 0.10), at + Vector3(0, 0, -window_size.x * 0.5), frame_mat)
	_add_textured_box(parent, "SideWindowFrame", Vector3(0.12, window_size.y + 0.16, 0.10), at + Vector3(0, 0, window_size.x * 0.5), frame_mat)


func _spawn_prop(scene: PackedScene, at: Vector3, scale_factor: float) -> void:
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.position = at
	model.scale = Vector3.ONE * scale_factor
	add_child(model)

func _make_box(label: String, at: Vector3, dimensions: Vector3, color: Color, solid: bool) -> Node3D:
	var root: Node3D
	var mesh_instance := MeshInstance3D.new()
	if solid:
		root = StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = dimensions
		collision.shape = box_shape
		root.add_child(collision)
		root.add_child(mesh_instance)
	else:
		root = mesh_instance
	root.name = label
	root.position = at
	var box := BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	if label.to_lower().contains("road") or label.to_lower().contains("street"):
		# AmbientCG Asphalt021 albedo: repeated at street scale, not stretched over the full district.
		material.albedo_texture = AsphaltTexture
		material.normal_enabled = true
		material.normal_texture = AsphaltNormalTexture
		material.normal_scale = 0.16
		material.roughness_texture = AsphaltRoughnessTexture
		material.roughness = 0.96
		material.uv1_scale = Vector3(14, 14, 1)
		material.uv1_triplanar = true
		material.uv1_triplanar_sharpness = 4.0
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif label.to_lower().contains("sidewalk") or label.to_lower().contains("curb") or label.to_lower().contains("bridge"):
		# Concrete012 keeps sidewalks, curbs and bridge surfaces in one material family.
		material.albedo_texture = ConcreteTexture
		material.normal_enabled = true
		material.normal_texture = ConcreteNormalTexture
		material.normal_scale = 0.12
		material.roughness_texture = ConcreteRoughnessTexture
		material.roughness = 0.94
		material.uv1_scale = Vector3(7, 7, 1)
		material.uv1_triplanar = true
		material.uv1_triplanar_sharpness = 4.0
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif label.to_lower().contains("mainland"):
		# Grass004 covers the walkable terrain around both districts.
		material.albedo_texture = GrassTexture
		material.normal_enabled = true
		material.normal_texture = GrassNormalTexture
		material.normal_scale = 0.08
		material.roughness_texture = GrassRoughnessTexture
		material.roughness = 0.98
		material.uv1_scale = Vector3(28, 28, 1)
		material.uv1_triplanar = true
		material.uv1_triplanar_sharpness = 4.0
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif label == "River":
		var water_plane := PlaneMesh.new()
		water_plane.size = Vector2(dimensions.x, dimensions.z)
		water_plane.subdivide_width = 16
		water_plane.subdivide_depth = 2
		mesh_instance.mesh = water_plane
		root.position.y = at.y + dimensions.y * 0.5
		var water_material := StandardMaterial3D.new()
		water_material.albedo_color = Color(0.035, 0.16, 0.22, 1.0)
		water_material.metallic = 0.12
		water_material.roughness = 0.28
		water_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = water_material
		add_child(root)
		return root
	mesh_instance.material_override = material
	add_child(root)
	return root

func _add_building_windows(building: Node3D, width: float, height: float, depth: float) -> void:
	var window_material := StandardMaterial3D.new()
	window_material.albedo_color = Color(0.12, 0.2, 0.25)
	window_material.metallic = 0.12
	window_material.roughness = 0.28
	var columns: int = maxi(1, int(width / 2.8))
	var rows: int = maxi(1, int(height / 3.0))
	for row in range(rows):
		var y: float = minf(2.0 + float(row) * 2.7, height - 1.0)
		for column in range(columns):
			var x := -width * 0.5 + (float(column) + 0.5) * (width / float(columns))
			for side in [-1.0, 1.0]:
				var window := MeshInstance3D.new()
				var pane := BoxMesh.new()
				pane.size = Vector3(1.05, 1.25, 0.07)
				window.mesh = pane
				window.position = Vector3(x, y, side * (depth * 0.5 + 0.045))
				window.material_override = window_material
				building.add_child(window)

func _setup_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.1, -24)
	add_child(player)

func _setup_traffic() -> void:
	_load_realistic_vehicle_scenes()
	if VehicleScenes.is_empty():
		push_warning("Realistic vehicle GLBs are missing; traffic spawning is skipped instead of using low-poly placeholders.")
		return
	# Spread imported vehicles across both districts and both directions.
	# Stagger spawn positions so cars never begin stacked on top of each other.
	for i in range(mini(VehicleScenes.size(), 4)):
		var car: Variant = CharacterBody3D.new()
		car.set_script(CarScript)
		car.speed = randf_range(3.2, 5.4)
		car.direction = 1.0 if int(i / 2) % 2 == 0 else -1.0
		var road_z := -34.0 if i % 2 == 0 else 34.0
		var lane_offset := 1.9 if car.direction > 0.0 else -1.9
		var spawn_group := int(i / 4)
		car.start_x = -65.0 + float(spawn_group) * 24.0 if car.direction > 0.0 else 65.0 - float(spawn_group) * 24.0
		car.end_x = 65.0 if car.direction > 0.0 else -65.0
		car.lane_z = road_z + lane_offset
		add_child(car)
		_make_car_visual(car, i)
		cars.append(car)

	# Two-way traffic on all five east-west downtown roads.
	var downtown_cross_streets := [91.0, 155.0, 219.0]
	for street_index in range(downtown_cross_streets.size()):
		for lane_index in range(2):
			var downtown_car: Variant = CharacterBody3D.new()
			downtown_car.set_script(CarScript)
			downtown_car.speed = randf_range(3.8, 5.8)
			downtown_car.direction = 1.0 if lane_index == 0 else -1.0
			var road_z: float = downtown_cross_streets[street_index]
			downtown_car.start_x = -64.0 if downtown_car.direction > 0.0 else 64.0
			downtown_car.end_x = 64.0 if downtown_car.direction > 0.0 else -64.0
			downtown_car.lane_z = road_z + (2.0 if downtown_car.direction > 0.0 else -2.0)
			add_child(downtown_car)
			_make_car_visual(downtown_car, VehicleScenes.size() + street_index * 2 + lane_index)
			cars.append(downtown_car)

	# North-south traffic fills the five vertical streets in the downtown GLB grid.
	# Each street gets one car in each direction, separated into opposing lanes.
	var downtown_street_x := [-32.0, 32.0]
	for street_index in range(downtown_street_x.size()):
		for lane_index in range(2):
			var vertical_car: Variant = CharacterBody3D.new()
			vertical_car.set_script(CarScript)
			vertical_car.vertical_traffic = true
			vertical_car.speed = randf_range(3.5, 5.2)
			vertical_car.direction = 1.0 if lane_index == 0 else -1.0
			vertical_car.lane_x = downtown_street_x[street_index] + (-2.0 if lane_index == 0 else 2.0)
			vertical_car.start_z = 99.0 if lane_index == 0 else 211.0
			vertical_car.end_z = 219.0 if lane_index == 0 else 91.0
			add_child(vertical_car)
			_make_car_visual(vertical_car, VehicleScenes.size() + 4 + street_index * 2 + lane_index)
			cars.append(vertical_car)

func _load_realistic_vehicle_scenes() -> void:
	VehicleScenes.clear()
	for scene_path in VehicleScenePaths:
		if not ResourceLoader.exists(scene_path):
			continue
		var loaded_scene := load(scene_path) as PackedScene
		if loaded_scene != null:
			VehicleScenes.append(loaded_scene)
	if VehicleScenes.size() != VehicleScenePaths.size():
		push_warning("Realistic vehicle fleet incomplete (%d/%d); refusing to spawn placeholder or mismatched cars." % [VehicleScenes.size(), VehicleScenePaths.size()])
		VehicleScenes.clear()

func _make_car_visual(car: Node3D, model_index: int) -> void:
	# Use only detailed, textured CC0 vehicles. No Kenney/low-poly fallback.
	var safe_index := model_index % VehicleScenes.size()
	var model_scene: PackedScene = VehicleScenes[safe_index]
	var model := model_scene.instantiate() as Node3D
	if model == null:
		return
	var model_scale: float = VehicleScales[safe_index]
	model.scale = Vector3.ONE * model_scale
	model.position.y = 0.02
	car.add_child(model)
	car.call("register_vehicle_visual", model, 0.30 * model_scale)

func _setup_people() -> void:
	# Keep the existing suburban pedestrian budget, but distribute it across
	# BOTH districts. The old condition used i < 8 inside range(8), so every
	# suburban pedestrian spawned in the west district and the east felt empty.
	for i in range(8):
		var npc := CharacterBody3D.new()
		npc.set_script(NpcScript)
		var district_z := -34.0 if i < 4 else 34.0
		var local_index := i % 4
		var sidewalk_side := -1.0 if local_index < 2 else 1.0
		npc.district_center_z = district_z
		npc.sidewalk_side = sidewalk_side
		npc.position = Vector3(
			randf_range(-58.0, 58.0),
			0.1,
			district_z + sidewalk_side * 6.35 + randf_range(-0.55, 0.55)
		)
		add_child(npc)

	# Pedestrians use the textured sidewalk edges of all five east-west streets.
	var downtown_pedestrian_streets := [91.0, 123.0, 155.0, 187.0, 219.0]
	for i in range(8):
		var downtown_npc := CharacterBody3D.new()
		downtown_npc.set_script(NpcScript)
		downtown_npc.district_center_z = downtown_pedestrian_streets[i % downtown_pedestrian_streets.size()]
		downtown_npc.sidewalk_side = -1.0 if i % 2 == 0 else 1.0
		downtown_npc.sidewalk_offset = 6.0
		downtown_npc.position = Vector3(randf_range(-62.0, 62.0), 0.1, downtown_npc.district_center_z + downtown_npc.sidewalk_side * 6.0)
		add_child(downtown_npc)

	# Extra pedestrians walk the north-south sidewalks, completing both axes of the grid.
	var downtown_vertical_streets := [-64.0, -32.0, 0.0, 32.0, 64.0]
	for i in range(8):
		var vertical_npc := CharacterBody3D.new()
		vertical_npc.set_script(NpcScript)
		vertical_npc.vertical_route = true
		vertical_npc.district_center_x = downtown_vertical_streets[i % downtown_vertical_streets.size()]
		vertical_npc.sidewalk_side = -1.0 if i % 2 == 0 else 1.0
		vertical_npc.sidewalk_offset = 6.0
		vertical_npc.position = Vector3(vertical_npc.district_center_x + vertical_npc.sidewalk_side * 6.0, 0.1, randf_range(95.0, 215.0))
		add_child(vertical_npc)

func _setup_mobile_ui() -> void:
	controls_layer = CanvasLayer.new()
	controls_layer.layer = 10
	add_child(controls_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	controls_layer.add_child(root)

	var minimap := Control.new()
	minimap.name = "Minimap"
	minimap.set_script(MinimapScript)
	minimap_control = minimap
	minimap.set("target", player)
	minimap.destination_changed.connect(_on_minimap_destination_changed)
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.position = Vector2(-190, 18)
	minimap.size = Vector2(172, 172)
	root.add_child(minimap)

	status_label = Label.new()
	status_label.text = "OPEN CITY  •  район 01"
	status_label.position = Vector2(22, 18)
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(status_label)

	waypoint_label = Label.new()
	waypoint_label.name = "WaypointDistance"
	waypoint_label.position = Vector2(24, 46)
	waypoint_label.add_theme_font_size_override("font_size", 14)
	waypoint_label.add_theme_color_override("font_color", Color(0.55, 0.82, 1.0, 0.96))
	waypoint_label.visible = false
	root.add_child(waypoint_label)

	vehicle_hud = PanelContainer.new()
	vehicle_hud.name = "VehicleDashboard"
	vehicle_hud.set_anchors_preset(Control.PRESET_CENTER_TOP)
	vehicle_hud.position = Vector2(-132, 14)
	vehicle_hud.size = Vector2(264, 88)
	vehicle_hud.visible = false
	var dashboard_style := StyleBoxFlat.new()
	dashboard_style.bg_color = Color(0.018, 0.026, 0.034, 0.94)
	dashboard_style.border_color = Color(0.55, 0.72, 0.84, 0.52)
	dashboard_style.set_border_width_all(1)
	dashboard_style.set_corner_radius_all(16)
	dashboard_style.content_margin_left = 16
	dashboard_style.content_margin_right = 16
	dashboard_style.content_margin_top = 7
	dashboard_style.content_margin_bottom = 7
	vehicle_hud.add_theme_stylebox_override("panel", dashboard_style)
	var dashboard_stack := VBoxContainer.new()
	dashboard_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	dashboard_stack.add_theme_constant_override("separation", 0)
	vehicle_hud_label = Label.new()
	vehicle_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vehicle_hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vehicle_hud_label.text = "000"
	vehicle_hud_label.add_theme_font_size_override("font_size", 34)
	vehicle_hud_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	dashboard_stack.add_child(vehicle_hud_label)
	vehicle_fuel_label = Label.new()
	vehicle_fuel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vehicle_fuel_label.text = "KM/H     БЕНЗИН  60.0 L"
	vehicle_fuel_label.add_theme_font_size_override("font_size", 12)
	vehicle_fuel_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.80))
	dashboard_stack.add_child(vehicle_fuel_label)
	vehicle_hud.add_child(dashboard_stack)
	root.add_child(vehicle_hud)

	movement_joystick = VirtualJoystick.new()
	movement_joystick.name = "MovementJoystick"
	movement_joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	movement_joystick.position = Vector2(24, -190)
	movement_joystick.size = Vector2(160, 160)
	root.add_child(movement_joystick)
	movement_joystick.changed.connect(func(value: Vector2):
		player.set_mobile_input(value)
		if player.active_vehicle != null:
			player.active_vehicle.set_mobile_input(value)
	)

	jump_button = Button.new()
	jump_button.text = "ПРЫЖОК"
	jump_button.position = Vector2(-94, -164)
	jump_button.size = Vector2(66, 66)
	jump_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump_button.add_theme_font_size_override("font_size", 11)
	_style_action_button(jump_button, 33)
	root.add_child(jump_button)
	jump_button.button_down.connect(func(): Input.action_press("jump"))
	jump_button.button_up.connect(func(): Input.action_release("jump"))

	run_button = Button.new()
	run_button.text = "БЕГ"
	run_button.position = Vector2(-94, -88)
	run_button.size = Vector2(66, 66)
	run_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	run_button.add_theme_font_size_override("font_size", 13)
	_style_action_button(run_button, 33)
	root.add_child(run_button)
	run_button.button_down.connect(func(): Input.action_press("run"))
	run_button.button_up.connect(func(): Input.action_release("run"))

	enter_button = Button.new()
	enter_button.text = "СЕСТЬ"
	enter_button.position = Vector2(22, 78)
	enter_button.size = Vector2(146, 54)
	enter_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	enter_button.visible = false
	enter_button.add_theme_font_size_override("font_size", 16)
	_style_action_button(enter_button, 27)
	root.add_child(enter_button)
	enter_button.pressed.connect(_toggle_vehicle)

	var scanner_button := Button.new()
	scanner_button.name = "ScannerButton"
	scanner_button.text = "SCAN"
	scanner_button.position = Vector2(-94, -238)
	scanner_button.size = Vector2(66, 58)
	scanner_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	scanner_button.add_theme_font_size_override("font_size", 15)
	_style_action_button(scanner_button, 29)
	root.add_child(scanner_button)
	scanner_button.pressed.connect(func():
		if is_instance_valid(player) and player.has_method("scan_pulse"):
			player.scan_pulse()
	)

	driving_controls = Control.new()
	driving_controls.name = "VehicleTouchControls"
	driving_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	driving_controls.mouse_filter = Control.MOUSE_FILTER_PASS
	driving_controls.visible = false
	root.add_child(driving_controls)

	var steer_left := _make_drive_button(driving_controls, "◀", Control.PRESET_BOTTOM_LEFT, Vector2(24, -166))
	var steer_right := _make_drive_button(driving_controls, "▶", Control.PRESET_BOTTOM_LEFT, Vector2(112, -166))
	var gas_button := _make_drive_button(driving_controls, "ГАЗ", Control.PRESET_BOTTOM_RIGHT, Vector2(-190, -166))
	var brake_button := _make_drive_button(driving_controls, "ТОРМ", Control.PRESET_BOTTOM_RIGHT, Vector2(-102, -166))
	steer_left.button_down.connect(func():
		if is_instance_valid(player) and player.active_vehicle != null:
			player.active_vehicle.set_mobile_steer(-1.0)
	)
	steer_left.button_up.connect(func():
		if is_instance_valid(player) and player.active_vehicle != null:
			player.active_vehicle.set_mobile_steer(0.0)
	)
	steer_right.button_down.connect(func():
		if is_instance_valid(player) and player.active_vehicle != null:
			player.active_vehicle.set_mobile_steer(1.0)
	)
	steer_right.button_up.connect(func():
		if is_instance_valid(player) and player.active_vehicle != null:
			player.active_vehicle.set_mobile_steer(0.0)
	)
	gas_button.button_down.connect(func():
		if is_instance_valid(player) and player.active_vehicle != null:
			player.active_vehicle.set_mobile_throttle(1.0)
	)
	gas_button.button_up.connect(func():
		if is_instance_valid(player) and player.active_vehicle != null:
			player.active_vehicle.set_mobile_throttle(0.0)
	)
	brake_button.button_down.connect(func():
		if is_instance_valid(player) and player.active_vehicle != null:
			player.active_vehicle.set_mobile_brake(true)
	)
	brake_button.button_up.connect(func():
		if is_instance_valid(player) and player.active_vehicle != null:
			player.active_vehicle.set_mobile_brake(false)
	)


func _style_action_button(button: Button, corner_radius: int) -> void:
	# Unified translucent mobile action buttons with clear pressed feedback.
	button.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.045, 0.065, 0.82)
	normal.border_color = Color(0.82, 0.90, 0.98, 0.58)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(corner_radius)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.20, 0.28, 0.94)
	hover.border_color = Color(0.94, 0.97, 1.0, 0.88)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.22, 0.34, 0.45, 0.98)
	pressed.border_color = Color.WHITE
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_drive_button(parent: Control, caption: String, anchor, offset: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.set_anchors_preset(anchor)
	button.position = offset
	button.size = Vector2(76, 76)
	button.custom_minimum_size = Vector2(76, 76)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.045, 0.065, 0.78)
	normal.border_color = Color(0.82, 0.90, 0.98, 0.55)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(42)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.20, 0.32, 0.42, 0.92)
	pressed.border_color = Color(1.0, 1.0, 1.0, 0.92)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed)
	button.add_theme_stylebox_override("pressed", pressed)
	parent.add_child(button)
	return button


func _make_menu_panel(parent: Control, panel_size: Vector2, offset: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.position = offset
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.045, 0.91)
	style.border_color = Color(0.70, 0.79, 0.84, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _make_menu_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(310, 58)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.92, 0.95, 0.97))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.13, 0.16, 0.86)
	normal.border_color = Color(0.46, 0.55, 0.60, 0.42)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 18
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.24, 0.28, 0.98)
	hover.border_color = Color(0.82, 0.88, 0.91, 0.8)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.06, 0.08, 0.10, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	return button

func _setup_main_menu() -> void:
	get_tree().paused = true
	controls_layer.visible = false
	menu_layer = CanvasLayer.new()
	menu_layer.name = "MainMenuLayer"
	menu_layer.layer = 30
	menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_layer.add_child(root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.012, 0.02, 0.46)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	home_panel = _make_menu_panel(root, Vector2(390, 468), Vector2(38, -234))
	var home_content := VBoxContainer.new()
	home_content.add_theme_constant_override("separation", 13)
	home_panel.add_child(home_content)
	var brand := Label.new()
	brand.text = "OPEN CITY"
	brand.add_theme_font_size_override("font_size", 42)
	brand.add_theme_color_override("font_color", Color.WHITE)
	home_content.add_child(brand)
	var subtitle := Label.new()
	subtitle.text = "THE CITY IS YOURS"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.60, 0.72, 0.78))
	home_content.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 24
	home_content.add_child(spacer)
	var play_button := _make_menu_button("▶   ИГРАТЬ")
	home_content.add_child(play_button)
	play_button.pressed.connect(_start_game)
	var settings_button := _make_menu_button("⚙   НАСТРОЙКИ")
	home_content.add_child(settings_button)
	settings_button.pressed.connect(_show_settings)
	var version := Label.new()
	version.text = "OPEN CITY  •  MOBILE BUILD"
	version.add_theme_font_size_override("font_size", 11)
	version.add_theme_color_override("font_color", Color(0.47, 0.56, 0.61))
	home_content.add_child(version)

	settings_panel = _make_menu_panel(root, Vector2(390, 380), Vector2(38, -190))
	settings_panel.visible = false
	var settings_content := VBoxContainer.new()
	settings_content.add_theme_constant_override("separation", 16)
	settings_panel.add_child(settings_content)
	var settings_title := Label.new()
	settings_title.text = "НАСТРОЙКИ"
	settings_title.add_theme_font_size_override("font_size", 32)
	settings_title.add_theme_color_override("font_color", Color.WHITE)
	settings_content.add_child(settings_title)
	var fps_title := Label.new()
	fps_title.text = "ОГРАНИЧЕНИЕ FPS"
	fps_title.add_theme_font_size_override("font_size", 15)
	fps_title.add_theme_color_override("font_color", Color(0.65, 0.75, 0.80))
	settings_content.add_child(fps_title)
	fps_value_label = Label.new()
	fps_value_label.add_theme_font_size_override("font_size", 20)
	fps_value_label.add_theme_color_override("font_color", Color.WHITE)
	settings_content.add_child(fps_value_label)
	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 8)
	settings_content.add_child(fps_row)
	for fps in [60, 90, 120]:
		var fps_button := _make_menu_button("%d FPS" % fps)
		fps_button.custom_minimum_size = Vector2(96, 54)
		fps_button.add_theme_font_size_override("font_size", 17)
		fps_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		fps_row.add_child(fps_button)
		fps_button.pressed.connect(_set_fps_cap.bind(fps))
	var back_button := _make_menu_button("←   НАЗАД")
	settings_content.add_child(back_button)
	back_button.pressed.connect(_show_home)
	_set_fps_cap(60)

	menu_music = AudioStreamPlayer.new()
	menu_music.name = "MenuMusic"
	menu_music.process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists("res://assets/audio/menu_urban.mp3"):
		menu_music.stream = load("res://assets/audio/menu_urban.mp3")
		if menu_music.stream is AudioStreamMP3:
			(menu_music.stream as AudioStreamMP3).loop = true
		menu_music.volume_db = -13.0
		add_child(menu_music)
		menu_music.play()

func _set_fps_cap(value: int) -> void:
	selected_fps = value
	Engine.max_fps = value
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if fps_value_label != null:
		fps_value_label.text = "ТЕКУЩИЙ ЛИМИТ: %d FPS" % value

func _show_settings() -> void:
	home_panel.visible = false
	settings_panel.visible = true

func _show_home() -> void:
	settings_panel.visible = false
	home_panel.visible = true

func _start_game() -> void:
	menu_layer.visible = false
	controls_layer.visible = true
	get_tree().paused = false
	if menu_music != null:
		menu_music.stop()

func _toggle_vehicle() -> void:
	if player == null:
		return
	if player.active_vehicle != null:
		player.exit_vehicle()
		enter_button.text = "СЕСТЬ"
		return
	var nearest: Node3D = null
	var best := 5.0
	for car in cars:
		var distance: float = player.global_position.distance_to(car.global_position)
		if distance < best:
			best = distance
			nearest = car
	if nearest != null:
		player.enter_vehicle(nearest)
		enter_button.text = "ВЫЙТИ"
