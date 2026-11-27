extends Control
## Barrinha de durabilidade sob o ícone de uma ferramenta (playtest ID 43): verde,
## depois amarela, depois vermelha. Some para ferramenta nova e para itens sem desgaste.

const WEAR := preload("res://scripts/systems/tool_wear.gd")
const GREEN := Color("#6fcf4a")
const YELLOW := Color("#f2c94c")
const RED := Color("#e0483a")

var ratio := 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Mostra o desgaste de `item` na bolsa; esconde se não for ferramenta ou estiver nova.
func show_for(tree: SceneTree, item: String) -> void:
	var shown := WEAR.MAX_USES.has(item) and WEAR.ratio(tree, item) < 1.0
	ratio = WEAR.ratio(tree, item) if shown else 1.0
	visible = shown
	queue_redraw()


static func color_for(value: float) -> Color:
	if value > 0.5: return GREEN
	if value > 0.25: return YELLOW
	return RED


func _draw() -> void:
	var bar := Rect2(1, size.y - 4, size.x - 2, 3)
	draw_rect(bar.grow(1), Color("#2b1d16"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), color_for(ratio))
