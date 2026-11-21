extends CanvasLayer
## Grade de cor do mundo sobre a camada do jogo e abaixo do HUD (camada 2).
## Perfis por horário do GameClock, interpolados sem saltos: manhã dourada, meio-dia
## neutro, tarde quente, anoitecer laranja-violeta, noite azul com magia destacada.

const SHADER := preload("res://scripts/world/world_grade.gdshader")
## minuto, vibração, contraste, realce (rgb), sombra (rgb), força, vinheta
const STOPS := [
	# Noite (ref. V9): meios-tons verde-água mais claros e saturados, vinheta leve.
	[0.0, 0.75, 0.12, Color(0.96, 1.08, 1.20), Color(0.84, 1.06, 1.38), 0.85, 0.18],
	[300.0, 0.62, 0.13, Color(0.97, 1.08, 1.12), Color(0.84, 1.04, 1.24), 0.80, 0.20],
	[390.0, 0.40, 0.10, Color(1.12, 1.03, 0.84), Color(0.94, 0.97, 1.06), 0.70, 0.18],
	[540.0, 0.40, 0.10, Color(1.09, 1.03, 0.86), Color(0.93, 0.99, 1.05), 0.65, 0.16],
	[720.0, 0.32, 0.08, Color(1.03, 1.02, 0.95), Color(0.96, 0.99, 1.03), 0.45, 0.12],
	[990.0, 0.46, 0.16, Color(1.1, 1.05, 0.9), Color(0.86, 0.95, 1.1), 0.72, 0.17],
	[1110.0, 0.5, 0.26, Color(1.3, 1.0, 0.7), Color(0.92, 0.84, 1.0), 0.88, 0.22],
	[1200.0, 0.65, 0.13, Color(0.98, 1.08, 1.12), Color(0.84, 1.04, 1.26), 0.80, 0.20],
	[1440.0, 0.75, 0.12, Color(0.96, 1.08, 1.20), Color(0.84, 1.06, 1.38), 0.85, 0.18],
]

var rect: ColorRect
var material: ShaderMaterial


func _ready() -> void:
	name = "WorldGrade"
	layer = 1
	material = ShaderMaterial.new()
	material.shader = SHADER
	rect = ColorRect.new()
	rect.name = "Grade"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = material
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
	apply(GameClock.get_hour() * 60.0 + GameClock.get_minute())


func _process(_delta: float) -> void:
	apply(GameClock.get_hour() * 60.0 + GameClock.get_minute())


func apply(minutes: float) -> void:
	var profile := profile_at(minutes)
	for key in profile:
		material.set_shader_parameter(key, profile[key])


static func profile_at(minutes: float) -> Dictionary:
	var m := fposmod(minutes, 1440.0) if is_finite(minutes) else 540.0
	for i in range(STOPS.size() - 1):
		var a: Array = STOPS[i]
		var b: Array = STOPS[i + 1]
		if m <= b[0]:
			var t := smoothstep(float(a[0]), float(b[0]), m)
			var hi: Color = (a[3] as Color).lerp(b[3], t)
			var lo: Color = (a[4] as Color).lerp(b[4], t)
			return {
				"vibrance": lerpf(a[1], b[1], t), "contrast": lerpf(a[2], b[2], t),
				"highlight_tint": Vector3(hi.r, hi.g, hi.b), "shadow_tint": Vector3(lo.r, lo.g, lo.b),
				"tint_strength": lerpf(a[5], b[5], t), "vignette": lerpf(a[6], b[6], t),
			}
	return {}
