# addons/JehenoSimpleFPSWeaponSystem/Weapons/Scripts/Camera/viewport_camera_script.gd
# Weapon tracker: mirrors eye-camera transform each physics tick so WeaponManager can
# read global_rotation for weapon orientation. Never calls make_current() — the eye-camera
# (Camera node under CameraRecoilHolder) is the sole current camera; world + weapon render
# together on a single pass (weapon mesh on layer 1, same as world).
extends Camera3D

class_name ViewportCamera

@onready var cam: Camera3D = $"../../CameraHolder/CameraRecoilHolder/Camera"


func _ready() -> void:
	# Do NOT call make_current() — this node is a transform proxy only.
	# Eye-camera stays current; stealing current causes black screen (only layer-20 rendered).
	pass


func _physics_process(_delta: float) -> void:
	global_transform = cam.global_transform
