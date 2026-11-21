extends Node2D
## Broto coletavel sem colisor; usa pintura pixel-art simples, sem substituir o cenario.
const BAG := preload("res://scripts/systems/forest_bag.gd")
var patch_id := ""
var collected := false

func configure(id: String, location: Vector2) -> void:
	patch_id = id
	position = location
	name = "SeedPatch_" + id

func _ready() -> void:
	add_to_group("shadow_boxes")
	collected = BAG.is_collected(get_tree(), patch_id)
	queue_redraw()

## Tufo baixo de flores e sementes: sombra só enquanto não foi colhido.
func shadow_footprint() -> Rect2: return Rect2(-11, -3, 22, 5) if not collected else Rect2()
func shadow_height() -> float: return 6.0

func harvest() -> bool:
	if collected or not BAG.harvest(get_tree(), patch_id):
		return false
	collected = true
	queue_redraw()
	return true

func _draw() -> void:
	if collected:
		return
	# Flores e sementes silvestres discretas, em pixels inteiros.
	draw_rect(Rect2(-11, -3, 22, 5), Color("#283b28"))
	draw_rect(Rect2(-2, -18, 4, 15), Color("#69523a"))
	draw_rect(Rect2(-11, -17, 10, 8), Color("#4c8a55"))
	draw_rect(Rect2(1, -22, 11, 10), Color("#5f9f58"))
	draw_rect(Rect2(-7, -24, 6, 6), Color("#b7c86b"))
	draw_rect(Rect2(5, -12, 5, 4), Color("#e0c16e"))
	draw_rect(Rect2(-8, -9, 4, 4), Color("#d6b86b"))
