extends RefCounted
# Uses the real Mixamo idle/run clips already included with the project.
# The source library and citizen models share the same Mixamo bone naming.
const AnimationLibraryScene: PackedScene = preload("res://assets/models/people/mixamo_animation_library.glb")

var _animation_player: AnimationPlayer
var _current_animation := ""
var _rigs: Array[Dictionary] = []
var _phase := 0.0

const BONE_NAMES := [
	"mixamorigLeftUpLeg", "mixamorigRightUpLeg",
	"mixamorigLeftLeg", "mixamorigRightLeg",
	"mixamorigLeftFoot", "mixamorigRightFoot",
	"mixamorigLeftArm", "mixamorigRightArm",
	"mixamorigLeftForeArm", "mixamorigRightForeArm"
]

func bind(character_root: Node) -> void:
	_rigs.clear()
	_animation_player = null
	var target_skeletons := character_root.find_children("*", "Skeleton3D", true, false)
	if target_skeletons.is_empty():
		push_warning("HumanoidAnimator: target character has no Skeleton3D.")
		return
	var target_skeleton := target_skeletons[0] as Skeleton3D

	var source_instance := AnimationLibraryScene.instantiate() as Node
	var source_players := source_instance.find_children("*", "AnimationPlayer", true, false)
	var source_skeletons := source_instance.find_children("*", "Skeleton3D", true, false)
	if source_players.is_empty() or source_skeletons.is_empty():
		push_warning("HumanoidAnimator: Mixamo animation library has no AnimationPlayer/Skeleton3D.")
		source_instance.free()
		_bind_procedural_fallback(target_skeleton)
		return

	var source_player := source_players[0] as AnimationPlayer
	var source_skeleton := source_skeletons[0] as Skeleton3D
	var source_root := source_player.get_node_or_null(source_player.root_node)
	if source_root == null:
		source_root = source_instance
	var source_skeleton_path := source_root.get_path_to(source_skeleton)
	var target_skeleton_path := character_root.get_path_to(target_skeleton)

	var library := AnimationLibrary.new()
	for full_name in source_player.get_animation_list():
		var animation_name := String(full_name)
		if animation_name.contains("/"):
			animation_name = animation_name.get_slice("/", 1)
		if animation_name != "idle" and animation_name != "run":
			continue
		var source_animation := source_player.get_animation(full_name)
		if source_animation == null:
			continue
		var copied := source_animation.duplicate(true) as Animation
		copied.loop_mode = Animation.LOOP_LINEAR
		for track_index in range(copied.get_track_count()):
			var track_path := String(copied.track_get_path(track_index))
			track_path = track_path.replace(String(source_skeleton_path), String(target_skeleton_path))
			copied.track_set_path(track_index, NodePath(track_path))
		library.add_animation(animation_name, copied)

	source_instance.free()
	if not library.has_animation("idle") or not library.has_animation("run"):
		push_warning("HumanoidAnimator: imported idle/run clips could not be copied.")
		_bind_procedural_fallback(target_skeleton)
		return

	_animation_player = AnimationPlayer.new()
	_animation_player.name = "MixamoAnimationPlayer"
	_animation_player.root_node = NodePath("..")
	_animation_player.add_animation_library("", library)
	character_root.add_child(_animation_player)
	_animation_player.play("idle")
	_current_animation = "idle"

func _bind_procedural_fallback(skeleton: Skeleton3D) -> void:
	var bones: Dictionary = {}
	for bone_name in BONE_NAMES:
		var index := skeleton.find_bone(bone_name)
		if index >= 0:
			bones[bone_name] = {"index": index, "base": skeleton.get_bone_pose_rotation(index)}
	if not bones.is_empty():
		_rigs.append({"skeleton": skeleton, "bones": bones})

func update(delta: float, moving: bool, running: bool) -> void:
	if _animation_player != null:
		var desired := "run" if moving else "idle"
		if _current_animation != desired:
			_animation_player.play(desired, 0.14)
			_current_animation = desired
		_animation_player.speed_scale = 1.0 if running else 0.66
		return

	# Fallback only for a model whose imported skeleton does not match Mixamo.
	if moving:
		_phase = fposmod(_phase + delta * (10.4 if running else 7.2), TAU)
	var swing := sin(_phase) * (0.78 if running else 0.48) if moving else 0.0
	var left_knee := maxf(0.0, -sin(_phase)) * (0.95 if running else 0.62) if moving else 0.0
	var right_knee := maxf(0.0, sin(_phase)) * (0.95 if running else 0.62) if moving else 0.0
	for rig in _rigs:
		var skeleton := rig["skeleton"] as Skeleton3D
		if not is_instance_valid(skeleton):
			continue
		var bones: Dictionary = rig["bones"]
		_set_pose(skeleton, bones, "mixamorigLeftUpLeg", swing, Vector3.RIGHT)
		_set_pose(skeleton, bones, "mixamorigRightUpLeg", -swing, Vector3.RIGHT)
		_set_pose(skeleton, bones, "mixamorigLeftLeg", left_knee, Vector3.RIGHT)
		_set_pose(skeleton, bones, "mixamorigRightLeg", right_knee, Vector3.RIGHT)
		_set_pose(skeleton, bones, "mixamorigLeftArm", swing * 0.68, Vector3.FORWARD)
		_set_pose(skeleton, bones, "mixamorigRightArm", -swing * 0.68, Vector3.FORWARD)
		_set_pose(skeleton, bones, "mixamorigLeftForeArm", -0.16 - left_knee * 0.20, Vector3.FORWARD)
		_set_pose(skeleton, bones, "mixamorigRightForeArm", -0.16 - right_knee * 0.20, Vector3.FORWARD)

func _set_pose(skeleton: Skeleton3D, bones: Dictionary, bone_name: String, angle: float, axis: Vector3 = Vector3.RIGHT) -> void:
	if not bones.has(bone_name):
		return
	var info: Dictionary = bones[bone_name]
	var index: int = info["index"]
	var base: Quaternion = info["base"]
	skeleton.set_bone_pose_rotation(index, base * Quaternion(axis.normalized(), angle))
