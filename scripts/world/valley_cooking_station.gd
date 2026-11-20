extends Node2D
## Ponto visual leve para o prototipo de culinaria; nenhum asset PixelLab e substituido.
## Sem colisao e fora da area de interacao dos dois canteiros.
func _ready() -> void:
	name = "CookingStation"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _draw() -> void:
	# Base de pedra com recipiente/folhas em pixel art simples.
	draw_rect(Rect2(-29, -14, 58, 27), Color("#443b3d"))
	draw_rect(Rect2(-25, -12, 50, 23), Color("#8a7970"))
	draw_rect(Rect2(-20, -9, 40, 18), Color("#685451"))
	draw_rect(Rect2(-15, -6, 30, 13), Color("#302e31"))
	draw_rect(Rect2(-11, -6, 22, 6), Color("#476d40"))
	draw_rect(Rect2(-7, -10, 5, 6), Color("#9fb66a"))
	draw_rect(Rect2(3, -10, 5, 6), Color("#9fb66a"))
	draw_rect(Rect2(-17, -9, 3, 19), Color("#c3ac83"))
	draw_rect(Rect2(14, -9, 3, 19), Color("#c3ac83"))
