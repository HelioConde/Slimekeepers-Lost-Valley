extends Node2D
## Native deterministic pixel art below the transparent water film.
@export var shores:Array[PackedVector2Array]=[]
@export var plants:PackedVector2Array=[]
@export var fish_centers:PackedVector2Array=[]
var elapsed:=0.0
var reduce_motion:=false
var frame:=-1
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
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
func is_water(at:Vector2,margin:float=0.0) -> bool:
	for shore in shores:
		if not Geometry2D.is_point_in_polygon(at,shore):continue
		if margin>0:
			for i in shore.size():
				if at.distance_to(Geometry2D.get_closest_point_to_segment(at,shore[i],shore[(i+1)%shore.size()]))<margin:return false
		return true
	return false
func fish_position(school:int,member:int,time:float) -> Vector2:
	var phase:=time*.24+school*1.71
	return (fish_centers[school]+Vector2(sin(phase)*19+member*22-22,cos(phase*.8)*8+member*12-12)).snapped(Vector2(2,2))
func pixel(at:Vector2,size:Vector2,color:Color) -> void:
	draw_rect(Rect2(at.snapped(Vector2(2,2)),size),color)
func _draw() -> void:
	var time:=floorf(elapsed*8)/8
	for i in plants.size():
		var at:=plants[i]
		var sway:=0.0 if reduce_motion else roundf(sin(time*.6+i)*1.2)*2
		for stem in 3:
			var base:=at+Vector2(stem*7-7,abs(stem-1)*3)
			var height:=12+(i+stem)%5*2
			pixel(base+Vector2(-3,0),Vector2(8,3),Color("477c70"))
			for step in range(0,height,4):
				var tip:=base+Vector2(sway*float(step)/height,-step)
				pixel(tip,Vector2(2,5),Color("345f52"))
				var reach:=4 if (step+stem+i)%3 else 6
				pixel(tip+Vector2(-reach,-2),Vector2(reach,2),Color("548562") if stem%2 else Color("659477"))
				pixel(tip+Vector2(-reach,-4),Vector2(2,2),Color("659477"))
				pixel(tip+Vector2(2,-1),Vector2(reach-1,2),Color("426f57"))
	for school in fish_centers.size():
		var phase:=time*.24+school*1.71
		var direction:=1.0 if cos(phase)>0 else -1.0
		for member in 3:
			var at:=fish_position(school,member,time)
			var silver:=school%3!=0
			var body:=Color("bed0ae") if silver else Color("c9af6d")
			pixel(at+Vector2(-4,5),Vector2(12,2),Color(.10,.29,.31,.28))
			pixel(at+Vector2(-6,-2),Vector2(12,4),Color("416d68"))
			pixel(at+Vector2(-4,-3),Vector2(8,4),body)
			pixel(at+Vector2(-2,-5),Vector2(4,2),body.darkened(.19))
			pixel(at+Vector2(-2,0),Vector2(6,2),Color("6b8c79") if silver else Color("8c8855"))
			var flick:=0 if reduce_motion else int(sin(time*3+member+school)>0)*2
			pixel(at+Vector2(-direction*8,-3+flick),Vector2(3,4),body.darkened(.12))
			pixel(at+Vector2(direction*4,-2),Vector2(2,2),Color("244e50"))
