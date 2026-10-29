extends Node
## A surface-only reflected light pass, clipped by each existing water polygon.
## The broad band is view-dependent; individual ripple pixels stay world-anchored.
const REFLECTION_SHADER = preload("res://scripts/world/water_reflections.gdshader")
const WATER_SHADERS := ["spring_water.gdshader", "valley_water.gdshader"]
const STOPS := [
	[0.0, Color(.72,.85,1.0), .55, .55],
	[180.0, Color(.64,.78,1.0), .38, .45],
	[300.0, Color(.75,.82,1.0), 0.0, .35],
	[360.0, Color(1.0,.69,.35), .35, .78],
	[420.0, Color(1.0,.83,.48), .62, .75],
	[720.0, Color(1.0,.97,.77), .30, .64],
	[990.0, Color(1.0,.76,.35), .70, .59],
	[1110.0, Color(1.0,.51,.26), .78, .56],
	[1170.0, Color(1.0,.49,.31), 0.0, .52],
	[1200.0, Color(.72,.85,1.0), .28, .75],
	[1320.0, Color(.72,.85,1.0), .62, .66],
	[1440.0, Color(.72,.85,1.0), .55, .55],
]
var material: ShaderMaterial
var surfaces: Array[Polygon2D] = []
var elapsed := 0.0
var reduce_motion := false

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://presentation.cfg") == OK:
		reduce_motion = cfg.get_value("accessibility", "reduce_motion", false)
	material = ShaderMaterial.new()
	material.shader = REFLECTION_SHADER
	var region := get_parent().get_parent()
	for node in region.find_children("*", "Polygon2D", true, false):
		if not node.material is ShaderMaterial or not node.material.shader: continue
		if not node.material.shader.resource_path.get_file() in WATER_SHADERS: continue
		var overlay := Polygon2D.new()
		overlay.name = "CelestialReflection"
		overlay.polygon = node.polygon
		overlay.polygons = node.polygons
		overlay.offset = node.offset
		overlay.material = material
		node.add_child(overlay)
		surfaces.append(overlay)
	update_for_time(0.0)

func update_for_time(delta: float) -> void:
	if not material: return
	if not reduce_motion: elapsed += maxf(delta, 0.0)
	var profile := profile_at(GameClock.get_save_data().minutes)
	material.set_shader_parameter("elapsed", floorf(elapsed * 8.0) / 8.0)
	material.set_shader_parameter("light_color", profile.color)
	material.set_shader_parameter("strength", profile.strength)
	material.set_shader_parameter("axis", profile.axis)

static func profile_at(minutes: float) -> Dictionary:
	var value := fposmod(minutes, 1440.0) if is_finite(minutes) else 420.0
	for i in range(STOPS.size()-1):
		var a: Array = STOPS[i]
		var b: Array = STOPS[i+1]
		if value <= b[0]:
			var t := smoothstep(float(a[0]), float(b[0]), value)
			return {"color": (a[1] as Color).lerp(b[1],t), "strength": lerpf(a[2],b[2],t), "axis": lerpf(a[3],b[3],t)}
	return {"color": Color.WHITE, "strength": 0.0, "axis": .5}
