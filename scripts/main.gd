extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const CarScript = preload("res://scripts/traffic_car.gd")
const NpcScript = preload("res://scripts/npc.gd")
const HouseScene: PackedScene = preload("res://assets/models/casa_simples.glb")
const MarketScene: PackedScene = preload("res://assets/models/mercado.glb")
const CarScene: PackedScene = preload("res://assets/models/carro.glb")
const TreeScene: PackedScene = preload("res://assets/models/ipe_amarelo.glb")
const StreetLightScene: PackedScene = preload("res://assets/models/poste_luz.glb")
const PlasterTexture: Texture2D = preload("res://assets/textures/wall_plaster.svg")
const BrickTexture: Texture2D = preload("res://assets/textures/brick_wall.svg")
const ConcreteTexture: Texture2D = preload("res://assets/textures/concrete.svg")
const RoofTexture: Texture2D = preload("res://assets/textures/roof_tiles.svg")
const AsphaltTexture: Texture2D = preload("res://assets/textures/asphalt.svg")

var player: Variant
var cars: Array[Node3D] = []
var status_label: Label
var enter_button: Button
var controls_layer: CanvasLayer

func _ready() -> void:
	randomize()
	_setup_world()
	_setup_player()
	_setup_traffic()
	_setup_people()
	_setup_mobile_ui()

func _setup_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.15
	add_child(sun)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.12, 0.28, 0.48)
	sky_mat.sky_horizon_color = Color(0.65, 0.78, 0.86)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	_make_box("Mainland", Vector3(0, -0.6, 0), Vector3(150, 1, 150), Color(0.28, 0.39, 0.27), true)
	_make_box("River", Vector3(0, -0.05, 0), Vector3(150, 0.15, 17), Color(0.08, 0.30, 0.48), false)

	# Main road, two districts and the bridge connecting them.
	_make_box("West road", Vector3(0, 0.02, -34), Vector3(150, 0.12, 10), Color(0.12, 0.13, 0.15), false)
	_make_box("East road", Vector3(0, 0.02, 34), Vector3(150, 0.12, 10), Color(0.12, 0.13, 0.15), false)
	_make_box("Bridge", Vector3(0, 0.18, 0), Vector3(11, 0.45, 24), Color(0.25, 0.26, 0.28), true)
	_make_box("Bridge rail left", Vector3(-5.4, 1.0, 0), Vector3(0.35, 1.5, 24), Color(0.55, 0.58, 0.6), true)
	_make_box("Bridge rail right", Vector3(5.4, 1.0, 0), Vector3(0.35, 1.5, 24), Color(0.55, 0.58, 0.6), true)

	for district_z in [-34.0, 34.0]:
		for x in range(-5, 6):
			for side in [-1.0, 1.0]:
				var bx := float(x) * 13.0 + randf_range(-2.0, 2.0)
				var bz := district_z + side * randf_range(13.0, 28.0)
				var chosen_scene: PackedScene = HouseScene if randf() < 0.72 else MarketScene
				_spawn_asset_building(chosen_scene, Vector3(bx, 0.0, bz), 3.4)

	# Imported CC0 trees and street lights.
	for x in [-58.0, -42.0, -16.0, 16.0, 42.0, 58.0]:
		_spawn_prop(TreeScene, Vector3(x, 0.0, -49.0), 3.0)
		_spawn_prop(TreeScene, Vector3(x + 5.0, 0.0, 49.0), 3.0)
	for x in range(-5, 6):
		_spawn_prop(StreetLightScene, Vector3(float(x) * 13.0, 0.0, -27.0), 2.5)
		_spawn_prop(StreetLightScene, Vector3(float(x) * 13.0, 0.0, 27.0), 2.5)

	# Side streets and sidewalks.
	for x in [-52.0, -26.0, 26.0, 52.0]:
		_make_box("Side street", Vector3(x, 0.015, -34), Vector3(7, 0.1, 58), Color(0.16,0.17,0.18), false)
		_make_box("Side street", Vector3(x, 0.015, 34), Vector3(7, 0.1, 58), Color(0.16,0.17,0.18), false)

func _spawn_asset_building(scene: PackedScene, at: Vector3, scale_factor: float) -> void:
	# Textured, GTA-SA-inspired original buildings. The imported CC0 kit remains
	# in the project as licensed source material; these buildings use UV-mapped
	# facade/roof textures so the result is consistent and readable on mobile.
	var is_market := scene == MarketScene
	var root := StaticBody3D.new()
	root.name = "TexturedMarket" if is_market else "TexturedHouse"
	root.position = at
	var width := randf_range(8.0, 10.5)
	var depth := randf_range(7.0, 9.0)
	var floors := randi_range(2, 4) if not is_market else 2
	var floor_height := 2.7
	var height := float(floors) * floor_height
	var wall_mat := _make_texture_material(BrickTexture if randf() < 0.32 else PlasterTexture, Color(1,1,1), Vector3(2.4, 2.4, 1))
	var side_mat := _make_texture_material(ConcreteTexture, Color(1,1,1), Vector3(2, 2, 1))
	var roof_mat := _make_texture_material(RoofTexture, Color(1,1,1), Vector3(2.2, 2.2, 1))
	_add_textured_box(root, "Facade", Vector3(width, height, depth), Vector3(0, height * 0.5, 0), wall_mat)
	_add_textured_box(root, "Roof", Vector3(width + 0.45, 0.28, depth + 0.45), Vector3(0, height + 0.14, 0), roof_mat)
	# Side concrete bands and roof parapet add architectural depth.
	for side in [-1.0, 1.0]:
		_add_textured_box(root, "SideBand", Vector3(0.16, height, 0.16), Vector3(side * (width * 0.5 - 0.08), height * 0.5, 0), side_mat)
		_add_textured_box(root, "Parapet", Vector3(0.22, 0.75, depth + 0.3), Vector3(side * (width * 0.5 - 0.08), height + 0.48, 0), side_mat)
	# Front and rear window rows, with frames and inset reflective glass.
	var columns := max(2, int(width / 2.0))
	for floor in range(floors):
		var y := 1.0 + float(floor) * floor_height
		for col in range(columns):
			var x := -width * 0.5 + (float(col) + 0.5) * width / float(columns)
			if is_market and floor == 0:
				_add_window(root, Vector3(x, y, depth * 0.5 + 0.055), Vector2(1.65, 1.85), true)
				_add_window(root, Vector3(x, y, -depth * 0.5 - 0.055), Vector2(1.65, 1.85), true)
			else:
				_add_window(root, Vector3(x, y, depth * 0.5 + 0.055), Vector2(1.05, 1.45), false)
				_add_window(root, Vector3(x, y, -depth * 0.5 - 0.055), Vector2(1.05, 1.45), false)
	# Ground-floor entrance and a colored shop fascia.
	if is_market:
		_add_textured_box(root, "ShopSign", Vector3(width * 0.82, 0.62, 0.18), Vector3(0, 2.28, depth * 0.5 + 0.14), _make_color_material(Color(0.58, 0.16, 0.10), 0.75))
		_add_textured_box(root, "ShopDoor", Vector3(0.9, 2.0, 0.12), Vector3(0, 1.0, depth * 0.5 + 0.12), _make_color_material(Color(0.10, 0.16, 0.19), 0.25))
	else:
		_add_textured_box(root, "Entrance", Vector3(0.95, 2.0, 0.12), Vector3(0, 1.0, depth * 0.5 + 0.12), _make_color_material(Color(0.18, 0.22, 0.23), 0.3))
	# Windows on both side elevations.
	for side in [-1.0, 1.0]:
		for floor in range(floors):
			var y := 1.0 + float(floor) * floor_height
			for z_index in range(2):
				var z := -depth * 0.28 + float(z_index) * depth * 0.56
				_add_side_window(root, Vector3(side * (width * 0.5 + 0.055), y, z), Vector2(1.0, 1.4))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height + 0.9, depth)
	collision.shape = shape
	collision.position.y = (height + 0.9) * 0.5
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
		material.albedo_texture = AsphaltTexture
		material.uv1_scale = Vector3(10, 10, 1)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mesh_instance.material_override = material
	add_child(root)
	return root

func _add_building_windows(building: Node3D, width: float, height: float, depth: float) -> void:
	var window_material := StandardMaterial3D.new()
	window_material.albedo_color = Color(0.12, 0.2, 0.25)
	window_material.metallic = 0.12
	window_material.roughness = 0.28
	var columns := max(1, int(width / 2.8))
	var rows := max(1, int(height / 3.0))
	for row in range(rows):
		var y := min(2.0 + float(row) * 2.7, height - 1.0)
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
	for i in range(5):
		var car: Variant = CharacterBody3D.new()
		car.set_script(CarScript)
		car.speed = randf_range(3.0, 6.0)
		car.start_x = -65.0 - float(i) * 22.0
		car.end_x = 65.0
		car.lane_z = -34.0 if i % 2 == 0 else 34.0
		add_child(car)
		_make_car_visual(car, i % 2 == 0)
		cars.append(car)

func _make_car_visual(car: Node3D, forward: bool) -> void:
	var model := CarScene.instantiate() as Node3D
	if model == null:
		return
	model.scale = Vector3.ONE * 2.0
	model.position.y = 0.05
	car.add_child(model)

func _setup_people() -> void:
	for i in range(16):
		var npc := CharacterBody3D.new()
		npc.set_script(NpcScript)
		npc.position = Vector3(randf_range(-58,58), 0.1, -34 + randf_range(-24,24)) if i < 8 else Vector3(randf_range(-58,58), 0.1, 34 + randf_range(-24,24))
		add_child(npc)

func _setup_mobile_ui() -> void:
	controls_layer = CanvasLayer.new()
	add_child(controls_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_layer.add_child(root)

	status_label = Label.new()
	status_label.text = "OPEN CITY  •  район 01"
	status_label.position = Vector2(22, 18)
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(status_label)

	var pad := GridContainer.new()
	pad.columns = 3
	pad.position = Vector2(24, -190)
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.add_theme_constant_override("h_separation", 8)
	pad.add_theme_constant_override("v_separation", 8)
	root.add_child(pad)
	_add_action_button(pad, "", "")
	_add_action_button(pad, "▲", "move_forward")
	_add_action_button(pad, "", "")
	_add_action_button(pad, "◀", "move_left")
	_add_action_button(pad, "▼", "move_back")
	_add_action_button(pad, "▶", "move_right")

	var run_button := Button.new()
	run_button.text = "БЕЖАТЬ"
	run_button.position = Vector2(-150, -105)
	run_button.size = Vector2(126, 54)
	run_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	run_button.add_theme_font_size_override("font_size", 17)
	root.add_child(run_button)
	run_button.button_down.connect(func(): Input.action_press("run"))
	run_button.button_up.connect(func(): Input.action_release("run"))

	enter_button = Button.new()
	enter_button.text = "МАШИНА"
	enter_button.position = Vector2(-150, -42)
	enter_button.size = Vector2(126, 54)
	enter_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	enter_button.add_theme_font_size_override("font_size", 17)
	root.add_child(enter_button)
	enter_button.pressed.connect(_toggle_vehicle)

func _add_action_button(parent: GridContainer, caption: String, action: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(62, 58)
	button.add_theme_font_size_override("font_size", 22)
	parent.add_child(button)
	if action != "":
		button.button_down.connect(func(): Input.action_press(action))
		button.button_up.connect(func(): Input.action_release(action))

func _toggle_vehicle() -> void:
	if player == null:
		return
	if player.active_vehicle != null:
		player.exit_vehicle()
		enter_button.text = "МАШИНА"
		return
	var nearest: Node3D = null
	var best := 5.0
	for car in cars:
		var distance := player.global_position.distance_to(car.global_position)
		if distance < best:
			best = distance
			nearest = car
	if nearest != null:
		player.enter_vehicle(nearest)
		enter_button.text = "ВЫЙТИ"
