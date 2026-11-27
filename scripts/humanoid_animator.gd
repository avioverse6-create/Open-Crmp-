extends RefCounted
# Procedural Mixamo-compatible locomotion. No cross-rig track retargeting.
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
	for node in character_root.find_children("*", "Skeleton3D", true, false):
		var skeleton := node as Skeleton3D
		var bones: Dictionary = {}
		for bone_name in BONE_NAMES:
			var index := skeleton.find_bone(bone_name)
			if index >= 0:
				bones[bone_name] = {
					"index": index,
					"base": skeleton.get_bone_pose_rotation(index)
				}
		if not bones.is_empty():
			_rigs.append({"skeleton": skeleton, "bones": bones})
	if _rigs.is_empty():
		push_warning("HumanoidAnimator: no Mixamo bones found on character.")

func update(delta: float, moving: bool, running: bool) -> void:
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
		_set_pose(skeleton, bones, "mixamorigLeftUpLeg", swing)
		_set_pose(skeleton, bones, "mixamorigRightUpLeg", -swing)
		_set_pose(skeleton, bones, "mixamorigLeftLeg", left_knee)
		_set_pose(skeleton, bones, "mixamorigRightLeg", right_knee)
		_set_pose(skeleton, bones, "mixamorigLeftFoot", -left_knee * 0.28)
		_set_pose(skeleton, bones, "mixamorigRightFoot", -right_knee * 0.28)
		# Mixamo legs swing around local X. Arms swing around local Z;
		# the previous X-axis rotation rolled the shoulders instead of swinging them.
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
