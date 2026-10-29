extends Node2D
## Small pixel fireflies near sheltered groves, updated only 8 times per second.
var _age := 0.0
var _step := 0.0
var _spots: Array[Vector2] = []
var _leaves: Array[Vector2] = []
var _reduced_motion := false

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 261026
	for centre in [Vector2(960, 1190), Vector2(2300, 1160), Vector2(2160, 2460), Vector2(1300, 1550)]:
		for i in 8:
			_spots.append(centre + Vector2(rng.randf_range(-90, 90), rng.randf_range(-70, 20)))
	for centre in [Vector2(1400,1490),Vector2(1790,1530),Vector2(1700,850),Vector2(2310,1490)]:
		for i in 5:
			_leaves.append(centre + Vector2(rng.randf_range(-90,90),rng.randf_range(-90,50)))
	var settings := ConfigFile.new()
	if settings.load("user://presentation.cfg") == OK:
		_reduced_motion = bool(settings.get_value("accessibility", "reduce_motion", false))
	queue_redraw()
	set_process(not _reduced_motion)

func _process(delta: float) -> void:
	_age += delta
	_step += delta
	if _step >= 0.125:
		_step = 0.0
		queue_redraw()

func _draw() -> void:
	for i in _spots.size():
		var phase := _age * 0.7 + float(i) * 1.7
		var at := (_spots[i] + Vector2(sin(phase) * 7.0, cos(phase * 0.7) * 4.0)).round()
		var brightness := 0.3 + maxf(0.0, sin(phase)) * 0.5
		draw_rect(Rect2(at - Vector2.ONE * 2, Vector2.ONE * 6), Color(0.7, 1.0, 0.5, brightness * 0.10))
		draw_rect(Rect2(at, Vector2(2, 2)), Color(0.94, 1.0, 0.57, brightness))
	for i in _leaves.size():
		var phase := fmod(_age * 0.035 + float(i) * 0.173, 1.0)
		var at := (_leaves[i] + Vector2(phase*38+sin(phase*TAU)*12,phase*96)).round()
		var alpha := sin(phase*PI)*0.65
		var color := Color(0.65,0.67,0.26,alpha)
		draw_rect(Rect2(at,Vector2(4,2)),color)
		draw_rect(Rect2(at+Vector2(1,-1),Vector2(2,4)),color)
		draw_rect(Rect2(at+Vector2(2,0),Vector2(1,2)),Color(0.9,0.8,0.42,alpha))
