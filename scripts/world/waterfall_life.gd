extends Node2D
## Broken stepped arcs are clipped to the actual connected water outline.
@export var shores:Array[PackedVector2Array]=[]
@export var width:=48.0
var elapsed:=0.0
var reduce_motion:=false
var frame:=-1
var _lip_shapes: Array[PackedVector2Array] = []

func _ready() -> void:
	# Six quiet teal bands physically bridge the horizontal source and the sheet.
	# Clip once to the actual source water, rather than painting over bank rocks.
	for band in 6:
		var top:float=-98+band*7
		var half:float=30+band*2
		var polygon:=PackedVector2Array([Vector2(-half,top),Vector2(half,top),Vector2(half+2,top+7),Vector2(-half-2,top+7)])
		var world_polygon:=PackedVector2Array()
		for point in polygon:world_polygon.append(point+get_parent().position)
		for shore in shores:
			for clipped in Geometry2D.intersect_polygons(world_polygon,shore):
				var local:=PackedVector2Array()
				for point in clipped:local.append(point-get_parent().position)
				_lip_shapes.append(local)
func set_reduced_motion(value:bool) -> void:
	reduce_motion=value
	set_process(not value)
	queue_redraw()
func _process(delta:float) -> void:
	if reduce_motion:return
	elapsed+=delta
	var next:=int(elapsed*8)
	if next!=frame:
		frame=next
		queue_redraw()
func is_water(at:Vector2) -> bool:
	for shore in shores:
		if Geometry2D.is_point_in_polygon(at,shore):return true
	return false
func ripple_pixels(time:float) -> PackedVector2Array:
	var pixels:=PackedVector2Array()
	for ring in 3:
		var progress:=fposmod(time*.22+ring/3.0,1.0)
		var radius:=width*.75+progress*65
		for step in range(2,29):
			if (step+ring)%7<2:continue
			var a:=PI*step/30.0
			var p:Vector2=Vector2(cos(a)*radius,108+sin(a)*(9+progress*25)).snapped(Vector2(2,2))
			if is_water(p+get_parent().position) and is_water(p+get_parent().position+Vector2(6,2)):pixels.append(p)
	return pixels
func _draw() -> void:
	var time:=floorf(elapsed*8)/8
	for polygon in _lip_shapes:
		var depth:=clampf((polygon[0].y+98.0)/42.0,0,1)
		draw_colored_polygon(polygon,Color(.37,.63,.61,.24).lerp(Color(.43,.69,.65,.85),depth))
	# Sparse accelerating streaks, ending in broken foam at the lip.
	for i in 10:
		var progress:=fposmod(time*.42+i*.19,1.0)
		var p:=Vector2(sin(i*7.7)*26,-94+progress*progress*39).snapped(Vector2(2,2))
		if is_water(p+get_parent().position):draw_rect(Rect2(p,Vector2(2,4)),Color(.68,.83,.76,.3+progress*.18))
	for i in 9:
		var p:=Vector2(-34+i*8,-55+(i%2)*2)
		if is_water(p+get_parent().position):draw_rect(Rect2(p,Vector2(4,2)),Color(.78,.90,.82,.55))
	for p in ripple_pixels(time):draw_rect(Rect2(p,Vector2(6,2)),Color(.63,.87,.81,.46))
	for i in 24:
		var cycle:=fposmod(time*.75+i*.137,1.0)
		var x:=sin(i*7.13)*width
		var p:=Vector2(x,99+cos(i*3.4)*6+cycle*12).snapped(Vector2(2,2))
		if is_water(p+get_parent().position):draw_rect(Rect2(p,Vector2(4+i%3*2,2)),Color(.76,.94,.87,.7*(1.0-cycle)))
	for i in 9:
		var cycle:=fposmod(time*.9+i*.173,1.0)
		var p:=Vector2(sin(i*4.7)*(width-8),100-sin(cycle*PI)*16).snapped(Vector2(2,2))
		if is_water(p+get_parent().position):draw_rect(Rect2(p,Vector2(2,4)),Color(.79,.97,.91,.65*(1.0-cycle)))
