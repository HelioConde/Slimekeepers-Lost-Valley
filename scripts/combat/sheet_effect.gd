extends Node2D
## Efeito de uma folha em grade (exportada do VFX Creator do PixelLab): toca uma vez e some.
## `anchor` é o ponto do quadro que fica na posição do nó (o pé das raízes, o centro da poeira).

var texture: Texture2D
var frame_size := Vector2i(64, 64)
var count := 1
var columns := 1
var fps := 14.0
var anchor := Vector2.ZERO
var _t := 0.0


static func make(sheet: Texture2D, size: Vector2i, frames: int, cols: int, speed: float, origin: Vector2) -> Node2D:
	var fx: Node2D = load("res://scripts/combat/sheet_effect.gd").new()
	fx.texture = sheet
	fx.frame_size = size
	fx.count = frames
	fx.columns = cols
	fx.fps = speed
	fx.anchor = origin
	return fx


func _process(delta: float) -> void:
	_t += delta
	if int(_t * fps) >= count:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var i := mini(int(_t * fps), count - 1)
	var src := Rect2(Vector2((i % columns) * frame_size.x, (i / columns) * frame_size.y), Vector2(frame_size))
	draw_texture_rect_region(texture, Rect2(-anchor, Vector2(frame_size)), src)
