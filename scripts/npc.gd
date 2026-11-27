extends CharacterBody3D

const PedestrianModels: Array[PackedScene] = [
	preload("res://assets/models/people/citizen_bryce.glb"),
	preload("res://assets/models/people/citizen_sophie.glb"),
	preload("res://assets/models/people/citizen_remy.glb"),
	preload("res://assets/models/people/citizen_shannon.glb")
]
const MixamoAnimations: PackedScene = preload("res://assets/models/people/mixamo_animation_library.glb")

var target := Vector3.ZERO
var walk_speed := 1.35
var change_timer := 0.0
var district_center_z: float = -34.0
var sidewalk_side: float = -1.0
var character_visual: Node3D
var animation_player: AnimationPlayer
var idle_clip: StringName = &""
var run_clip: StringName = &""

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.30
	capsule.height = 1.76
	shape.shape = capsule
	shape.position.y = 0.88
	add_child(shape)

	character_visual = Node3D.new()
	character_visual.name = "RiggedPedestrian"
	character_visual.rotation.y = PI
	add_child(character_visual)
	var model_scene := PedestrianModels[randi() % PedestrianModels.size()]
	var model := model_scene.instantiate() as Node3D
	character_visual.add_child(model)
	_setup_mixamo_animations(model)
	_pick_target()

func _setup_mixamo_animations(model: Node3D) -> void:
	var source_scene := MixamoAnimations.instantiate()
	var source_players := source_scene.find_children("*", "AnimationPlayer", true, false)
	if source_players.is_empty():
		source_scene.queue_free()
		return
	var source_player := source_players[0] as AnimationPlayer
	animation_player = AnimationPlayer.new()
	animation_player.name = "PedestrianAnimationPlayer"
	animation_player.root_node = NodePath("..")
	model.add_child(animation_player)
	for library_name in source_player.get_animation_library_list():
		var source_library := source_player.get_animation_library(library_name)
		if source_library != null:
			var copied_library := source_library.duplicate(true) as AnimationLibrary
			if copied_library != null:
				animation_player.add_animation_library(library_name, copied_library)
	for clip in animation_player.get_animation_list():
		var lower := String(clip).to_lower()
		if lower.ends_with("/idle") or lower == "idle":
			idle_clip = clip
		elif lower.ends_with("/run") or lower == "run":
			run_clip = clip
	if idle_clip != &"":
		animation_player.play(idle_clip)
	source_scene.queue_free()

func _physics_process(delta: float) -> void:
	change_timer -= delta
	if change_timer <= 0.0 or global_position.distance_to(target) < 1.0:
		_pick_target()
	var direction := target - global_position
	direction.y = 0
	var moving := direction.length() > 0.1
	if moving:
		direction = direction.normalized()
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 5.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * delta)

	if animation_player != null:
		var desired_clip := run_clip if moving else idle_clip
		if desired_clip != &"" and animation_player.current_animation != desired_clip:
			animation_player.play(desired_clip, 0.2)
		animation_player.speed_scale = 0.42 if moving else 1.0

	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _pick_target() -> void:
	# Patrol along the sidewalk instead of wandering through buildings or water.
	target = Vector3(
		randf_range(-65.0, 65.0),
		global_position.y,
		district_center_z + sidewalk_side * 6.35 + randf_range(-0.65, 0.65)
	)
	change_timer = randf_range(5.0, 10.0)
