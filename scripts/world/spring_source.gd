extends Node2D
## Pixel-step motion respects the existing accessibility setting.
var elapsed := 0.0
var _step := 0.0
var _reduced_motion := false

func _ready() -> void:
	add_to_group("water_sources")
	var preferences := ConfigFile.new()
	if preferences.load("user://presentation.cfg") == OK:
		_reduced_motion = bool(preferences.get_value("accessibility","reduce_motion",false))
	set_process(not _reduced_motion)

func _process(delta: float) -> void:
	_step += delta
	if _step < 0.125:
		return
	elapsed += _step
	_step = 0.0
	($Pool/Water.material as ShaderMaterial).set_shader_parameter("elapsed",elapsed)

func can_examine(at: Vector2) -> bool:
	return at.distance_to($InteractionPoint.global_position) < 65.0
