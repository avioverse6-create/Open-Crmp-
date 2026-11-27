extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const CarScript = preload("res://scripts/traffic_car.gd")
const NpcScript = preload("res://scripts/npc.gd")
const MinimapScript = preload("res://scripts/minimap.gd")
const HouseScene: PackedScene = preload("res://assets/models/casa_simples.glb")
const MarketScene: PackedScene = preload("res://assets/models/mercado.glb")
const VehicleScenes: Array[PackedScene] = [
	preload("res://assets/models/vehicles/sedan.glb"),
	preload("res://assets/models/vehicles/suv.glb"),
	preload("res://assets/models/vehicles/taxi.glb"),
	preload("res://assets/models/vehicles/police.glb"),
	preload("res://assets/models/vehicles/delivery.glb"),
	preload("res://assets/models/vehicles/truck.glb"),
	preload("res://assets/models/vehicles/firetruck.glb"),
	preload("res://assets/models/vehicles/garbage_truck.glb"),
	preload("res://assets/models/vehicles/hatchback_sports.glb"),
	preload("res://assets/models/vehicles/sedan_sports.glb"),
	preload("res://assets/models/vehicles/ambulance.glb")
]
const VehicleScales: Array[float] = [1.5, 1.45, 1.45, 1.5, 1.35, 1.3, 1.3, 1.25, 1.5, 1.5, 1.35]
const TreeScene: PackedScene = preload("res://assets/models/ipe_amarelo.glb")
const StreetLightScene: PackedScene = preload("res://assets/models/poste_luz.glb")
const BushScene: PackedScene = preload("res://assets/models/nature/bush.glb")
const BushFlowersScene: PackedScene = preload("res://assets/models/nature/bush_flowers.glb")
const GrassClumpScene: PackedScene = preload("res://assets/models/nature/grass.glb")

const RoadCrossingScene: PackedScene = preload("res://assets/models/city/roads/road-crossing.glb")
const RoadCrossroadScene: PackedScene = preload("res://assets/models/city/roads/road-crossroad.glb")
const RoadBridgeScene: PackedScene = preload("res://assets/models/city/roads/road-bridge.glb")
const RoadStraightScene: PackedScene = preload("res://assets/models/city/roads/road-straight.glb")
const TrafficLightScene: PackedScene = preload("res://assets/models/city/roads/light-square-cross.glb")
const HighwaySignScene: PackedScene = preload("res://assets/models/city/roads/sign-highway.glb")
const ConstructionConeScene: PackedScene = preload("res://assets/models/city/roads/construction-cone.glb")
const ConstructionBarrierScene: PackedScene = preload("res://assets/models/city/roads/construction-barrier.glb")
const BridgePillarScene: PackedScene = preload("res://assets/models/city/roads/bridge-pillar.glb")

const CityBuildingScenes: Array[PackedScene] = [
	preload("res://assets/models/city/suburban/building_a.glb"),
	preload("res://assets/models/city/suburban/building_b.glb"),
	preload("res://assets/models/city/suburban/building_c.glb"),
	preload("res://assets/models/city/suburban/building_d.glb"),
	preload("res://assets/models/city/suburban/building_e.glb"),
	preload("res://assets/models/city/suburban/building_f.glb"),
	preload("res://assets/models/city/suburban/building_g.glb"),
	preload("res://assets/models/city/suburban/building_h.glb"),
	preload("res://assets/models/city/suburban/building_i.glb"),
	preload("res://assets/models/city/suburban/building_j.glb"),
	preload("res://assets/models/city/suburban/building_k.glb"),
	preload("res://assets/models/city/suburban/building_l.glb"),
	preload("res://assets/models/city/suburban/building_m.glb"),
	preload("res://assets/models/city/suburban/building_n.glb"),
	preload("res://assets/models/city/suburban/building_o.glb"),
	preload("res://assets/models/city/suburban/building_p.glb"),
	preload("res://assets/models/city/suburban/building_q.glb"),
	preload("res://assets/models/city/suburban/building_r.glb"),
	preload("res://assets/models/city/suburban/building_s.glb"),
	preload("res://assets/models/city/suburban/building_t.glb"),
	preload("res://assets/models/city/suburban/building_u.glb")
]
const PlasterTexture: Texture2D = preload("res://assets/textures/wall_plaster.svg")
const BrickTexture: Texture2D = preload("res://assets/textures/brick_ambientcg.png")
const ConcreteTexture: Texture2D = preload("res://assets/textures/concrete_ambientcg.png")
const RoofTexture: Texture2D = preload("res://assets/textures/roof_tiles.svg")
const AsphaltTexture: Texture2D = preload("res://assets/textures/asphalt_ambientcg.png")
const GrassTexture: Texture2D = preload("res://assets/textures/grass_ambientcg.png")
const AsphaltNormalTexture: Texture2D = preload("res://assets/textures/asphalt_normal.svg")
const AsphaltRoughnessTexture: Texture2D = preload("res://assets/textures/asphalt_roughness.svg")
const ConcreteNormalTexture: Texture2D = preload("res://assets/textures/concrete_normal.svg")
const ConcreteRoughnessTexture: Texture2D = preload("res://assets/textures/concrete_roughness.svg")
const GrassNormalTexture: Texture2D = preload("res://assets/textures/grass_normal.svg")
const GrassRoughnessTexture: Texture2D = preload("res://assets/textures/grass_roughness.svg")

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
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
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
	env.ambient_light_energy = 0.78
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	_make_box("Mainland", Vector3(0, -0.6, 0), Vector3(150, 1, 150), Color(0.28, 0.39, 0.27), true)
	_make_box("River", Vector3(0, -0.05, 0), Vector3(150, 0.15, 17), Color(0.08, 0.30, 0.48), false)

	# Main road, two districts and the bridge connecting them.
	_make_box("West road", Vector3(0, 0.02, -34), Vector3(150, 0.12, 10), Color(0.12, 0.13, 0.15), true)
	_make_box("East road", Vector3(0, 0.02, 34), Vector3(150, 0.12, 10), Color(0.12, 0.13, 0.15), true)
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
	# Low vegetation breaks up the bare river banks and roadside green strips.
	for x in [-62.0, -46.0, -30.0, -14.0, 14.0, 30.0, 46.0, 62.0]:
		_spawn_prop(BushScene, Vector3(x, 0.0, -10.0), 1.05)
		_spawn_prop(BushFlowersScene, Vector3(x + 4.0, 0.0, 10.0), 0.95)
		_spawn_prop(GrassClumpScene, Vector3(x - 2.0, 0.0, -12.0), 1.25)
		_spawn_prop(GrassClumpScene, Vector3(x + 2.0, 0.0, 12.0), 1.25)
	for x in range(-5, 6):
		_spawn_prop(StreetLightScene, Vector3(float(x) * 13.0, 0.0, -27.0), 2.5)
		_spawn_prop(StreetLightScene, Vector3(float(x) * 13.0, 0.0, 27.0), 2.5)

	# Side streets and sidewalks.
	for x in [-52.0, -26.0, 26.0, 52.0]:
		_make_box("Side street", Vector3(x, 0.015, -34), Vector3(7, 0.1, 58), Color(0.16,0.17,0.18), false)
		_make_box("Side street", Vector3(x, 0.015, 34), Vector3(7, 0.1, 58), Color(0.16,0.17,0.18), false)

	_add_sidewalks()
	_add_road_markings()
	_add_city_road_assets()



func _add_city_road_assets() -> void:
	# Imported modular road kit pieces add real mesh detail to key intersections.
	_spawn_city_asset(RoadBridgeScene, Vector3(0, 0.20, 0), Vector3(11.0, 1.0, 24.0))
	for road_z in [-34.0, 34.0]:
		_spawn_city_asset(RoadCrossingScene, Vector3(0, 0.105, road_z), Vector3(10.0, 1.0, 10.0), Vector3(0, deg_to_rad(90.0), 0))
		for road_x in [-52.0, -26.0, 26.0, 52.0]:
			_spawn_city_asset(RoadCrossroadScene, Vector3(road_x, 0.105, road_z), Vector3(10.0, 1.0, 10.0), Vector3(0, deg_to_rad(90.0), 0))
			if absf(road_x) == 52.0:
				_spawn_city_asset(TrafficLightScene, Vector3(road_x + 5.2, 0.0, road_z + 5.2), Vector3.ONE * 3.2)
	# Imported straight road tiles cover the four side streets in each district.
	for road_x in [-52.0, -26.0, 26.0, 52.0]:
		for road_z in [-54.0, -44.0, -24.0, -14.0, 14.0, 24.0, 44.0, 54.0]:
			_spawn_city_asset(RoadStraightScene, Vector3(road_x, 0.11, road_z), Vector3(7.0, 1.0, 10.0))
	# Bridge supports and readable roadside signs make the crossing feel like a built place.
	for side in [-1.0, 1.0]:
		_spawn_city_asset(BridgePillarScene, Vector3(side * 4.1, -1.15, -7.0), Vector3.ONE * 2.2)
		_spawn_city_asset(BridgePillarScene, Vector3(side * 4.1, -1.15, 7.0), Vector3.ONE * 2.2)
	_spawn_city_asset(HighwaySignScene, Vector3(-61.0, 0.0, -27.0), Vector3.ONE * 1.8)
	_spawn_city_asset(HighwaySignScene, Vector3(61.0, 0.0, 27.0), Vector3.ONE * 1.8, Vector3(0, PI, 0))
	# A small roadwork pocket at the far edge adds a few non-building props.
	_spawn_city_asset(ConstructionBarrierScene, Vector3(62.0, 0.0, -18.0), Vector3.ONE * 1.7)
	for cone_x in [58.0, 62.0, 66.0]:
		_spawn_city_asset(ConstructionConeScene, Vector3(cone_x, 0.0, -21.0), Vector3.ONE * 1.5)

func _spawn_city_asset(scene: PackedScene, at: Vector3, target_scale: Vector3, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var instance := scene.instantiate() as Node3D
	instance.position = at
	instance.scale = target_scale
	instance.rotation = rotation_value
	add_child(instance)

func _add_sidewalks() -> void:
	for road_z in [-34.0, 34.0]:
		for side in [-1.0, 1.0]:
			var sidewalk_z := road_z + side * 6.35
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

func _spawn_asset_building(_requested_scene: PackedScene, at: Vector3, _scale_factor: float) -> void:
	# Use complete imported Kenney building meshes with their original color atlas.
	# The wrapper supplies a simple mobile-friendly collision volume.
	var model_scene: PackedScene = CityBuildingScenes[randi() % CityBuildingScenes.size()]
	var root := StaticBody3D.new()
	root.name = "ImportedCityBuilding"
	root.position = at
	root.scale = Vector3.ONE * randf_range(7.6, 9.2)
	root.rotation.y = randf_range(0.0, TAU)
	var model := model_scene.instantiate() as Node3D
	root.add_child(model)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.36, 0.90, 1.10)
	collision.shape = shape
	collision.position.y = 0.45
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
		var water_shader := Shader.new()
		water_shader.code = """
shader_type spatial;
void fragment() {
	float a = sin(UV.x * 52.0 + TIME * 0.72) * 0.5 + 0.5;
	float b = sin(UV.y * 39.0 - TIME * 0.51 + UV.x * 13.0) * 0.5 + 0.5;
	float shimmer = smoothstep(0.58, 0.96, a * 0.56 + b * 0.44);
	ALBEDO = mix(vec3(0.018, 0.105, 0.17), vec3(0.075, 0.29, 0.36), shimmer * 0.62);
	METALLIC = 0.12;
	ROUGHNESS = 0.19;
}
"""
		var water_material := ShaderMaterial.new()
		water_material.shader = water_shader
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
	# Spread imported vehicles across both districts and both directions.
	# Stagger spawn positions so cars never begin stacked on top of each other.
	for i in range(VehicleScenes.size()):
		var car: Variant = CharacterBody3D.new()
		car.set_script(CarScript)
		car.speed = randf_range(3.2, 5.4)
		car.direction = 1.0 if int(i / 2) % 2 == 0 else -1.0
		var road_z := -34.0 if i % 2 == 0 else 34.0
		var lane_offset := -1.9 if car.direction > 0.0 else 1.9
		var spawn_group := int(i / 4)
		car.start_x = -65.0 + float(spawn_group) * 24.0 if car.direction > 0.0 else 65.0 - float(spawn_group) * 24.0
		car.end_x = 65.0 if car.direction > 0.0 else -65.0
		car.lane_z = road_z + lane_offset
		add_child(car)
		_make_car_visual(car, i)
		cars.append(car)

func _make_car_visual(car: Node3D, model_index: int) -> void:
	# Each traffic vehicle gets a distinct textured GLB from the Kenney Car Kit.
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
	# Keep pedestrians on the two sidewalk strips beside each district road.
	for i in range(16):
		var npc := CharacterBody3D.new()
		npc.set_script(NpcScript)
		var district_z := -34.0 if i < 8 else 34.0
		var sidewalk_side := -1.0 if i % 8 < 4 else 1.0
		npc.district_center_z = district_z
		npc.sidewalk_side = sidewalk_side
		npc.position = Vector3(
			randf_range(-58.0, 58.0),
			0.1,
			district_z + sidewalk_side * 6.35 + randf_range(-0.55, 0.55)
		)
		add_child(npc)

func _setup_mobile_ui() -> void:
	controls_layer = CanvasLayer.new()
	add_child(controls_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_layer.add_child(root)

	var minimap := Control.new()
	minimap.name = "Minimap"
	minimap.set_script(MinimapScript)
	minimap.set("target", player)
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.position = Vector2(-190, 18)
	minimap.size = Vector2(172, 172)
	root.add_child(minimap)

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

	var jump_button := Button.new()
	jump_button.text = "ПРЫЖОК"
	jump_button.position = Vector2(-150, -168)
	jump_button.size = Vector2(126, 54)
	jump_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump_button.add_theme_font_size_override("font_size", 15)
	root.add_child(jump_button)
	jump_button.button_down.connect(func(): Input.action_press("jump"))
	jump_button.button_up.connect(func(): Input.action_release("jump"))

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
