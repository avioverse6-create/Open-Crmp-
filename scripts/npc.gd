extends CharacterBody3D

const PedestrianModels: Array[PackedScene] = [
	preload("res://assets/models/people/citizen_bryce.glb"),
	preload("res://assets/models/people/citizen_sophie.glb"),
	preload("res://assets/models/people/citizen_remy.glb"),
	preload("res://assets/models/people/citizen_shannon.glb")
]
const MixamoAnimations: PackedScene = preload("res://assets/models/people/mixamo_animation_library.glb")
const FootstepSounds: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/01-footstep.ogg"),
	preload("res://assets/audio/footsteps/02-footstep.ogg"),
	preload("res://assets/audio/footsteps/03-footstep.ogg"),
	preload("res://assets/audio/footsteps/04-footstep.ogg"),
	preload("res://assets/audio/footsteps/05-footstep.ogg"),
	preload("res://assets/audio/footsteps/06-footstep.ogg")
]

var target := Vector3.ZERO
var walk_speed := 1.25
var change_timer := 0.0
var district_center_z: float = -34.0
var sidewalk_side: float = -1.0
var character_visual: Node3D
var animation_player: AnimationPlayer
var idle_clip: StringName = &""
var walk_clip: StringName = &""
var run_clip: StringName = &""
var footstep_player: AudioStreamPlayer3D
var chatter_player: AudioStreamPlayer3D
var footstep_timer := randf_range(0.15, 0.55)

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
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "NPCFootsteps"
	footstep_player.position = Vector3(0, 0.12, 0)
	footstep_player.volume_db = -17.0
	footstep_player.unit_size = 2.8
	footstep_player.max_distance = 13.0
	add_child(footstep_player)
	if randi() % 4 == 0 and ResourceLoader.exists("res://assets/audio/pedestrian_chatter.mp3"):
		chatter_player = AudioStreamPlayer3D.new()
		chatter_player.name = "LocalConversation"
		chatter_player.stream = load("res://assets/audio/pedestrian_chatter.mp3")
		if chatter_player.stream is AudioStreamMP3:
			(chatter_player.stream as AudioStreamMP3).loop = true
		chatter_player.volume_db = -29.0
		chatter_player.pitch_scale = randf_range(0.94, 1.07)
		chatter_player.unit_size = 3.0
		chatter_player.max_distance = 12.0
		add_child(chatter_player)
		chatter_player.play(randf_range(0.0, 18.0))
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
				_retarget_animation_library(copied_library, model)
				animation_player.add_animation_library(library_name, copied_library)
	for clip in animation_player.get_animation_list():
		var lower := String(clip).to_lower()
		if lower.ends_with("/idle") or lower == "idle":
			idle_clip = clip
		elif lower.ends_with("/walk") or lower == "walk":
			walk_clip = clip
		elif lower.ends_with("/run") or lower == "run":
			run_clip = clip
	if walk_clip == &"":
		walk_clip = run_clip
	if idle_clip != &"":
		animation_player.play(idle_clip)
	source_scene.queue_free()

func _retarget_animation_library(library: AnimationLibrary, model: Node3D) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_warning("No Skeleton3D found for pedestrian animation retargeting.")
		return
	var retargeted := 0
	for clip_name in library.get_animation_list():
		var clip := library.get_animation(clip_name)
		if clip == null:
			continue
		for track_index in range(clip.get_track_count()):
			var old_path := clip.track_get_path(track_index)
			var bone_name := ""
			for name_index in range(old_path.get_name_count()):
				var candidate := old_path.get_name(name_index)
				for skeleton_node in skeletons:
					var skeleton := skeleton_node as Skeleton3D
					if skeleton.find_bone(candidate) >= 0:
						bone_name = candidate
						break
				if not bone_name.is_empty():
					break
			if bone_name.is_empty():
				for sub_index in range(old_path.get_subname_count()):
					var candidate := old_path.get_subname(sub_index)
					for skeleton_node in skeletons:
						var skeleton := skeleton_node as Skeleton3D
						if skeleton.find_bone(candidate) >= 0:
							bone_name = candidate
							break
					if not bone_name.is_empty():
						break
			if bone_name.is_empty():
				continue
			for skeleton_node in skeletons:
				var skeleton := skeleton_node as Skeleton3D
				if skeleton.find_bone(bone_name) >= 0:
					var relative_path := model.get_path_to(skeleton)
					clip.track_set_path(track_index, NodePath(String(relative_path) + ":" + bone_name))
					retargeted += 1
					break
	if retargeted == 0:
		push_warning("Mixamo animation tracks did not match this pedestrian skeleton.")
	else:
		print("Retargeted ", retargeted, " Mixamo animation tracks for pedestrian.")

func _play_footstep() -> void:
	if footstep_player == null or FootstepSounds.is_empty():
		return
	footstep_player.stream = FootstepSounds[randi() % FootstepSounds.size()]
	footstep_player.pitch_scale = randf_range(0.92, 1.08)
	footstep_player.play()

func _physics_process(delta: float) -> void:
	change_timer -= delta
	if change_timer <= 0.0 or global_position.distance_to(target) < 1.0:
		_pick_target()
	var direction := target - global_position
	direction.y = 0.0
	var moving := direction.length() > 0.1
	if moving:
		direction = direction.normalized()
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 4.5)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * delta)

	if animation_player != null:
		var desired_clip := walk_clip if moving else idle_clip
		if desired_clip != &"" and animation_player.current_animation != desired_clip:
			animation_player.play(desired_clip, 0.2)
		animation_player.speed_scale = 0.70 if moving else 1.0

	if moving and is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			_play_footstep()
			footstep_timer = randf_range(0.48, 0.58)
	else:
		footstep_timer = 0.16

	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _pick_target() -> void:
	target = Vector3(
		randf_range(-65.0, 65.0),
		global_position.y,
		district_center_z + sidewalk_side * 6.35 + randf_range(-0.65, 0.65)
	)
	change_timer = randf_range(5.0, 10.0)
