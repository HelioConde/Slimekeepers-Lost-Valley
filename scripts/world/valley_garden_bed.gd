extends Node2D
## Canteiro pequeno, sem colisao; mostra terra, broto e colheita pelo estado real.
const GARDEN := preload("res://scripts/systems/valley_starter_garden.gd")
var bed_id := ""
var _last_phase := ""

func configure(id: String, at: Vector2) -> void:
	bed_id = id
	position = at
	name = "GardenBed_" + id

func _ready() -> void:
	# Caixa de terra baixa: o DayShadows desenha a sombra dela (projetada + contato).
	add_to_group("shadow_boxes")
	GameClock.time_advanced.connect(_on_time_advanced)
	refresh()

## Pegada sólida (local) e altura em px para a sombra.
func shadow_footprint() -> Rect2: return Rect2(-27, -16, 54, 32)
func shadow_height() -> float: return 8.0

func phase() -> String:
	return GARDEN.phase(get_tree(), GameClock, bed_id)

func remaining_minutes() -> int:
	return GARDEN.minutes_remaining(get_tree(), GameClock, bed_id)

func interact() -> String:
	var current := phase()
	if current == "empty":
		if not GARDEN.plant(get_tree(), GameClock, bed_id):
			return "needs_seed"
		refresh()
		return "planted"
	if current == "ready":
		if not GARDEN.harvest(get_tree(), GameClock, bed_id):
			return "not_ready"
		refresh()
		return "collected"
	return current

func refresh() -> void:
	var current := phase()
	if _last_phase != current:
		_last_phase = current
		queue_redraw()

func _on_time_advanced(_minutes: float, _days: int) -> void:
	refresh()

func _draw() -> void:
	# Solo e bordas pixel-art discretos; nenhum sprite original e substituido.
	draw_rect(Rect2(-27, -16, 54, 32), Color("#614436"))
	draw_rect(Rect2(-23, -12, 46, 24), Color("#98704b"))
	draw_rect(Rect2(-19, -8, 38, 16), Color("#6c4936"))
	if _last_phase == "empty":
		draw_rect(Rect2(-11, -3, 6, 3), Color("#b99567"))
		draw_rect(Rect2(6, -3, 6, 3), Color("#b99567"))
	elif _last_phase == "growing":
		draw_rect(Rect2(-2, -13, 4, 13), Color("#568a49"))
		draw_rect(Rect2(-12, -16, 10, 6), Color("#73a965"))
		draw_rect(Rect2(2, -18, 12, 7), Color("#8fbf71"))
	elif _last_phase == "ready":
		draw_rect(Rect2(-3, -24, 6, 22), Color("#568448"))
		for leaf in [Rect2(-19, -23, 16, 9), Rect2(3, -29, 17, 11), Rect2(-16, -11, 15, 8), Rect2(3, -13, 12, 8)]:
			draw_rect(leaf, Color("#8bc66a"))
		draw_rect(Rect2(-4, -31, 7, 5), Color("#cbd985"))
	else:
		draw_rect(Rect2(-8, -4, 17, 4), Color("#b69b70"))
