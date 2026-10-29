extends Control
## Hand-built wood, with only the foliage regions of the supplied logo sprite.
## All lettering is rendered by separate Labels; the source's words are excluded.
const ORNAMENT := preload("res://assets/menu/provided/logo_ornament_source.png")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var outline := PackedVector2Array([Vector2(26,10),Vector2(w-26,10),Vector2(w-12,20),Vector2(w-12,30),Vector2(w,30),Vector2(w,104),Vector2(w-12,114),Vector2(w-24,128),Vector2(24,128),Vector2(12,114),Vector2(0,104),Vector2(0,30),Vector2(12,30),Vector2(12,20)])
	var shadow := PackedVector2Array()
	for p in outline: shadow.append(p+Vector2(2,7))
	draw_colored_polygon(shadow,Color(0.13,0.1,0.13,0.55))
	draw_colored_polygon(outline,Color("#40292c"))
	var face := PackedVector2Array([Vector2(28,17),Vector2(w-28,17),Vector2(w-19,29),Vector2(w-7,35),Vector2(w-7,99),Vector2(w-27,118),Vector2(27,118),Vector2(7,99),Vector2(7,35),Vector2(19,29)])
	draw_colored_polygon(face,Color("#8c5c3b"))
	face.append(face[0])
	draw_polyline(face,Color("#c9975e"),2)
	draw_line(Vector2(28,24),Vector2(w-28,24),Color("#b67f49"),4)
	draw_line(Vector2(20,108),Vector2(w-20,108),Color("#613f31"),4)
	for i in range(8):
		var x := 35.0 + i * 67.0
		var y := 29.0 + posmod(i*11,14)
		draw_line(Vector2(x,y),Vector2(x+29,y),Color("#a27045"),2)
		draw_line(Vector2(x+12,101),Vector2(x+44,101),Color("#7c4d35"),2)
	var crest := PackedVector2Array()
	for i in range(20):
		crest.append((Vector2(w/2,-6)+Vector2.from_angle(float(i)/20*TAU)*39).snapped(Vector2(2,2)))
	draw_colored_polygon(crest,Color("#8b5739"))
	crest.append(crest[0])
	draw_polyline(crest,Color("#3f2b2c"),6)
	draw_polyline(crest,Color("#d2a26a"),2)
	# Narrow regions contain vines/flowers only, no title or subtitle glyphs.
	draw_texture_rect_region(ORNAMENT,Rect2(-14,6,34,112),Rect2(0,0,34,112))
	draw_texture_rect_region(ORNAMENT,Rect2(w-17,6,28,112),Rect2(288,0,28,112))
