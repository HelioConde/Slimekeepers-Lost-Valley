extends Camera2D
## Camera do Player: unico ponto de configuracao de zoom e seguimento.
## As cenas so informam os limites de seu mapa; nunca criam outra camera.
@export_range(0.25, 1.0, 0.05) var overview_zoom_multiplier: float = 0.65

var _player_zoom: Vector2 = Vector2.ONE
var _overview_enabled: bool = false

func _ready() -> void:
	# Captura diretamente o zoom definido no Inspector de scenes/player.tscn.
	_player_zoom = zoom
	enabled = true
	make_current()

func configure_world_bounds(world_bounds: Rect2) -> void:
	# Altera apenas o limite; zoom/offset/seguimento continuam os do Player.
	limit_left = floori(world_bounds.position.x)
	limit_top = floori(world_bounds.position.y)
	limit_right = ceili(world_bounds.end.x)
	limit_bottom = ceili(world_bounds.end.y)
	reset_smoothing()

func set_overview_enabled(value: bool) -> void:
	_overview_enabled = value
	zoom = _player_zoom * overview_zoom_multiplier if value else _player_zoom
	reset_smoothing()

func is_overview_enabled() -> bool:
	return _overview_enabled

func reset_to_player_view() -> void:
	set_overview_enabled(false)

func get_player_zoom() -> Vector2:
	return _player_zoom
