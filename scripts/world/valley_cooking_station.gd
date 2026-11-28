extends Node2D
## Estação de preparo do protótipo de culinária no Vale.
## Reutiliza a fogueira apagada PixelLab já exportada (sem nova geração).
## Sem colisão e fora da área de interação dos dois canteiros.
const ART := preload("res://assets/objects/pixellab_exports/campfire_unlit_compact_64x48_292e36a0/campfire_unlit_compact_64x48.png")
## A base da fogueira fica perto da origem para o y-sort com o jogador.
const ART_OFFSET := Vector2(0, -10)


func _ready() -> void:
	name = "CookingStation"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite := Sprite2D.new()
	sprite.name = "Art"
	sprite.texture = ART
	sprite.position = ART_OFFSET
	add_child(sprite)
