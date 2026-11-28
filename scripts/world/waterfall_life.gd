extends Node2D
## Broken stepped arcs are clipped to the actual connected water outline.
@export var shores:Array[PackedVector2Array]=[]
@export var width:=48.0
var elapsed:=0.0
var reduce_motion:=false
var frame:=-1
var _lip_shapes: Array[PackedVector2Array] = []
const REFLECTIONS := preload("res://scripts/world/water_reflections.gd")
const LIGHTS := preload("res://scripts/world/ambient_lights.gd")
## Base da queda (px locais): onde a água bate no lago.
const IMPACT := Vector2(0, 100)
var _mist: CPUParticles2D
var _spray: CPUParticles2D
var _sparkles: CPUParticles2D
var _night := 0.0

func impact_mist() -> CPUParticles2D: return _mist
func impact_spray() -> CPUParticles2D: return _spray
func night_sparkles() -> CPUParticles2D: return _sparkles

func _ready() -> void:
	_build_particles()
	apply_time(GameClock.get_hour() * 60.0 + GameClock.get_minute())
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
	for particles in [_mist, _spray, _sparkles]:
		if is_instance_valid(particles): particles.emitting = not value and (particles != _sparkles or _night > 0.35)
	queue_redraw()

## Brilho do véu na cor refletida do horário; cintilação mágica só à noite.
func apply_time(minutes: float) -> void:
	# Céu único (Astronomy): cor do Sol de dia, prata do luar à noite.
	var clock_data: Dictionary = GameClock.get_save_data()
	var sky: Dictionary = preload("res://scripts/systems/astronomy.gd").sky(int(clock_data.day), minutes)
	var moon_color := Color(0.72, 0.85, 1.0)
	var profile := {"color": (sky.sun_color as Color).lerp(moon_color, 1.0 - float(sky.daylight)),
		"strength": maxf(float(sky.sun_reflection), float(sky.moon_reflection))}
	_night = LIGHTS.night_factor(minutes)
	var cascade := get_parent().get_node_or_null("Cascade") as CanvasItem if get_parent() else null
	if cascade and cascade.material is ShaderMaterial:
		var material := cascade.material as ShaderMaterial
		material.set_shader_parameter("glint_color", profile["color"])
		material.set_shader_parameter("glint_strength", clampf(0.35 + float(profile["strength"]) * 0.6, 0.35, 0.85))
	if is_instance_valid(_sparkles):
		_sparkles.emitting = not reduce_motion and _night > 0.35

func _build_particles() -> void:
	# Névoa: poucos pixels claros subindo devagar onde a água bate.
	_mist = _particles("ImpactMist", 14, 2.4, Vector2(width * 0.85, 5))
	_mist.direction = Vector2.UP
	_mist.spread = 25.0
	_mist.gravity = Vector2(0, -6)
	_mist.initial_velocity_min = 4.0
	_mist.initial_velocity_max = 10.0
	_mist.scale_amount_min = 2.0
	_mist.scale_amount_max = 3.0
	_mist.color_ramp = _ramp([Color(.88, .98, .97, 0), Color(.88, .98, .97, .5), Color(.82, .95, .96, 0)])
	# Respingos: gotas que saltam e caem de volta (impacto).
	_spray = _particles("ImpactSpray", 14, 0.75, Vector2(width * 0.65, 2))
	_spray.direction = Vector2.UP
	_spray.spread = 55.0
	_spray.gravity = Vector2(0, 90)
	_spray.initial_velocity_min = 22.0
	_spray.initial_velocity_max = 40.0
	_spray.color_ramp = _ramp([Color(.95, 1, .98, 1), Color(.82, .96, .93, .8), Color(.7, .9, .9, 0)])
	_spray.scale_amount_min = 1.0
	_spray.scale_amount_max = 2.0
	# Noite: cintilação azul-esverdeada sobre o lago, perto da queda.
	_sparkles = _particles("NightSparkles", 6, 2.6, Vector2(width * 1.4, 18))
	_sparkles.position = IMPACT + Vector2(0, 22)
	_sparkles.direction = Vector2.UP
	_sparkles.spread = 180.0
	_sparkles.gravity = Vector2(0, -3)
	_sparkles.initial_velocity_min = 1.0
	_sparkles.initial_velocity_max = 4.0
	_sparkles.color_ramp = _ramp([Color(.4, 1, .9, 0), Color(.5, .95, 1, .9), Color(.45, .8, 1, 0)])
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_sparkles.material = glow
	_sparkles.emitting = false

func _particles(node_name: String, amount: int, lifetime: float, extents: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = node_name
	particles.position = IMPACT
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.local_coords = true
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = extents
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(particles)
	return particles

func _ramp(colors: Array) -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray(colors)
	return gradient
func _process(delta:float) -> void:
	if reduce_motion:return
	elapsed+=delta
	apply_time(GameClock.get_hour() * 60.0 + GameClock.get_minute())
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
