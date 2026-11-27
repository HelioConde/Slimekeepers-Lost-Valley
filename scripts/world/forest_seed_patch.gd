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

## Playtest ID 41: o desenho antigo era de retângulos (parecia um objeto bugado); usa a arte
## existente das flores silvestres.
const ART := preload("res://assets/world/forest/wildflowers_cluster.png")


func _draw() -> void:
	if collected:
		return
	draw_texture(ART, Vector2(-ART.get_width() * 0.5, -ART.get_height() + 4))
