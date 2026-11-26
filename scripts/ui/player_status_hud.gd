extends Control
## Status no canto superior esquerdo (referência do usuário, 2026-11-23): retrato
## redondo do protagonista, coração com a barra de vida (vermelha) e raio com a de
## energia (azul). No multijogador um segundo cartão, menor e mais apagado, mostra o
## outro jogador logo abaixo (o foco continua no seu).

const ENERGY := preload("res://scripts/systems/energy_state.gd")
const HEALTH := preload("res://scripts/systems/health_state.gd")
const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const SKIN := preload("res://scripts/ui/hud_skin.gd")
const FRAME := Color("#5a3a26")
const BACK := Color("#24301f")

var _own: Dictionary = {}
var _other: Dictionary = {}
var _session: Node
## Último estado recebido do outro jogador: {"h": vida, "e": energia}.
var other_stats: Dictionary = {}
var force_other := false
## Aviso de pouca energia (balance-check 2026-11-23): uma vez ao cair abaixo de LOW;
## a barra pisca enquanto estiver baixa.
const LOW := 25


## Dica de pouca energia conforme a casa (playtest IDs 47 e 48): sem cama, construir uma;
## com cama, ir dormir.
static func low_energy_tip(tree: SceneTree) -> String:
	var furniture: Dictionary = preload("res://scripts/systems/house_state.gd").data(tree).furniture
	if furniture.values().has("cama"):
		return "Pouca energia! Vá dormir na sua cama (ou coma algo)."
	return "Pouca energia! Construa uma cama (bancada → Construção → Móveis) ou coma algo."
var _warned := false  ## testes e capturas: mostra o cartão sem conexão


func _ready() -> void:
	name = "PlayerStatus"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(10, 8)
	size = Vector2(210, 56)  # área para o hud_overlap_fade
	_own = _card(PROTAGONIST.current(get_tree()), false)
	_own.root.position = Vector2.ZERO
	add_child(_own.root)
	_session = get_node_or_null("/root/NetSession")
	if _session and _session.has_signal("message"): _session.message.connect(_on_message)
	refresh()


## Cartão: retrato redondo + duas barras. compact = outro jogador (menor, apagado, com nome).
func _card(who: String, compact: bool) -> Dictionary:
	var k := 0.72 if compact else 1.0
	var root := PanelContainer.new()  # fundo escuro translúcido: lê sobre a floresta
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.08, 0.06, 0.05, 0.55 if not compact else 0.45)
	plate.set_corner_radius_all(int(30 * k))
	plate.content_margin_left = 3
	plate.content_margin_top = 3
	plate.content_margin_bottom = 3
	plate.content_margin_right = 10 * k
	root.add_theme_stylebox_override("panel", plate)
	var line_up := HBoxContainer.new()
	line_up.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_up.add_theme_constant_override("separation", int(6 * k))
	root.add_child(line_up)
	var ring := Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var size := 52.0 * k
	ring.custom_minimum_size = Vector2(size, size)
	var style := StyleBoxFlat.new()
	style.bg_color = BACK
	style.border_color = FRAME if not compact else Color("#7a6a58")
	style.set_border_width_all(3 if not compact else 2)
	style.set_corner_radius_all(int(size))
	ring.add_theme_stylebox_override("panel", style)
	ring.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var face := TextureRect.new()
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.texture = _portrait(who)
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.add_child(face)
	var border := Panel.new()  # borda por cima do rosto (o recorte esconde a do anel)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := style.duplicate() as StyleBoxFlat
	line.bg_color = Color(0, 0, 0, 0)
	line.set_border_width_all(3 if not compact else 2)
	border.add_theme_stylebox_override("panel", line)
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.add_child(border)
	line_up.add_child(ring)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", int(4 * k))
	line_up.add_child(column)
	var name_label: Label
	if compact:
		name_label = SKIN.label(str(PROTAGONIST.ALL.get(who, {}).get("name", who.capitalize())), 11, Color("#f3e2c8"))
		name_label.add_theme_constant_override("outline_size", 3)
		name_label.add_theme_color_override("font_outline_color", Color("#1d140e"))
		column.add_child(name_label)
	var health := _bar_row(column, SKIN.heart(true), Color("#d8434a"), k)
	var energy := _bar_row(column, load("res://assets/ui/hud/icon_energy.png") if ResourceLoader.exists("res://assets/ui/hud/icon_energy.png") else null, Color("#3f8fe0"), k)
	if compact: root.modulate = Color(1, 1, 1, 0.82)
	return {"root": root, "face": face, "health": health, "energy": energy, "name": name_label}


func _bar_row(column: VBoxContainer, icon: Texture2D, color: Color, k: float) -> ProgressBar:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", int(5 * k))
	var pic := TextureRect.new()
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.texture = icon
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(16, 16) * k
	row.add_child(pic)
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.max_value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(118, 11) * k
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#2b1d16")
	back.border_color = Color("#1a120d")
	back.set_border_width_all(2)
	back.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", back)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.border_color = color.lightened(0.35)
	fill.border_width_top = 2  # brilho no alto, como na referência
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	column.add_child(row)
	return bar


## Rosto recortado da rotação de frente (sem arte nova): quadrado em volta da cabeça.
static func _portrait(who: String) -> Texture2D:
	var data: Dictionary = PROTAGONIST.ALL.get(who, PROTAGONIST.ALL[PROTAGONIST.DEFAULT])
	var path := "%s/rotations/south.png" % str(data.art)
	if not ResourceLoader.exists(path): return null
	var tex: Texture2D = load(path)
	var used := tex.get_image().get_used_rect()
	var side := 30
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(used.position.x + used.size.x / 2 - side / 2, used.position.y - 1, side, side)
	return atlas


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if not is_inside_tree(): return
	_own.health.value = HEALTH.current(get_tree())
	var energy := ENERGY.current(get_tree())
	_own.energy.value = energy
	_own.energy.modulate.a = (0.55 + 0.45 * absf(sin(Time.get_ticks_msec() / 250.0))) if energy < LOW else 1.0
	if energy < LOW and not _warned:
		_warned = true
		var scene := get_tree().current_scene
		if scene and scene.has_method("_notify"):
			scene.call("_notify", low_energy_tip(get_tree()))
	elif energy >= LOW:
		_warned = false
	var connected: bool = _session != null and bool(_session.get("connected"))
	if connected and _other.is_empty() and not str(_session.get("remote_protagonist")).is_empty():
		show_other(str(_session.get("remote_protagonist")))
	if not _other.is_empty():
		_other.root.visible = connected or force_other
		size = Vector2(210, 104 if _other.root.visible else 56)
		_other.health.value = float(other_stats.get("h", HEALTH.MAX))
		_other.energy.value = float(other_stats.get("e", ENERGY.MAX))


## Cartão do outro jogador (multijogador), abaixo e recuado: o seu fica em destaque.
func show_other(who: String) -> void:
	if not _other.is_empty(): _other.root.queue_free()
	_other = _card(who, true)
	add_child(_other.root)
	_other.root.position = Vector2(14, 66)


func _on_message(data: Dictionary) -> void:
	if str(data.get("t", "")) == "state":
		other_stats = {"h": int(data.get("h", HEALTH.MAX)), "e": int(data.get("e", ENERGY.MAX))}
