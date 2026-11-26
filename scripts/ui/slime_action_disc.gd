extends Control
## Disco de ações do slime (pedido do usuário, 2026-11-23; referência: anel em fatias,
## translúcido para ver o jogo por trás). [F] num slime abre; cada fatia tem um ícone e o
## centro mostra o nome da ação apontada e o do slime.
## Ações: Carinho · Dar comida · Trabalho · Seguir/ficar (region.slime_action executa).
## Controle (Opções > Controles, user://presentation.cfg, controls/slime_disc):
##   "clique" (padrão): [F] abre, mouse/WASD aponta, clique ou [F] confirma, Esc fecha.
##   "segurar": segura [F], aponta, soltar [F] confirma.
## Dar comida: com mais de um tipo de comida na mochila abre a lista só de comidas; com
## um tipo só, dá direto. Trabalho do Carreguim: escolhe o baú de destino.

const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const FEEDING := preload("res://scripts/systems/slime_feeding.gd")
const SKIN := preload("res://scripts/ui/hud_skin.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const OUTER := 92.0
const INNER := 44.0
const RING := Color(0.12, 0.09, 0.07, 0.5)  ## translúcido: o jogo aparece por trás
const HOVER := Color(0.95, 0.85, 0.55, 0.55)
const EDGE := Color(0.95, 0.9, 0.8, 0.7)

var region: Node  ## clearing_region (slime_action, player)
var slime: Node2D
var actions: Array = []  ## [{id, name, icon, enabled}]
var hovered := -1
var hold_mode := false  ## "segurar": soltar [F] confirma
var _center := Vector2.ZERO
var _icons: Array[TextureRect] = []
var _title: Label
var _subtitle: Label
var _list: VBoxContainer  ## lista de comidas ou de baús (submenu)
var closed_frame := -10  ## quadro em que fechou (o mesmo [F] não reabre o disco)


func _ready() -> void:
	name = "SlimeDisc"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title = _label(13, Color("#fff3d6"))
	_subtitle = _label(10, Color("#e8d3a8"))
	for l in [_title, _subtitle]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color("#1d140e"))
		add_child(l)
	_list = VBoxContainer.new()
	_list.visible = false
	add_child(_list)


static func mode() -> String:
	var cfg := ConfigFile.new()
	if cfg.load("user://presentation.cfg") != OK: return "clique"
	return str(cfg.get_value("controls", "slime_disc", "clique"))


func open(target: Node2D) -> void:
	slime = target
	hold_mode = mode() == "segurar"
	var friend := bool(slime.get("befriended"))
	var species := str(slime.get("slime_type"))
	var at_farm := bool((get_tree().get_meta("slime_at_farm", {}) as Dictionary).get(species, true))
	var working := not bool((get_tree().get_meta("slime_work_off", {}) as Dictionary).get(species, false))
	actions = [
		{"id": "carinho", "name": "Carinho" if friend else "Ainda desconfiado", "icon": SKIN.heart(true), "enabled": friend},
		{"id": "comida", "name": "Dar comida", "icon": ITEMS.icon("cenoura_assada"), "enabled": true},
		{"id": "trabalho", "name": ("Escolher baú" if species == "carreguim" else ("Parar de trabalhar" if working else "Voltar a trabalhar")), "icon": ITEMS.icon("bau_campo" if species == "carreguim" else ("bancada" if species == "construlim" else "enxada")), "enabled": friend},
		{"id": "seguir", "name": "Ficar em casa" if at_farm else "Ir para a fazenda", "icon": _steps_icon(), "enabled": friend},
	]
	# Playtest ID 60: só as ações disponíveis agora (o slime ainda desconfiado só aceita comida).
	actions = actions.filter(func(a: Dictionary) -> bool: return bool(a.enabled))
	for icon in _icons: icon.queue_free()
	_icons.clear()
	for a: Dictionary in actions:
		var icon := TextureRect.new()
		icon.texture = a.icon
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(28, 28)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.modulate.a = 1.0 if a.enabled else 0.4
		add_child(icon)
		_icons.append(icon)
	_list.visible = false
	hovered = 0
	visible = true
	_layout()
	_freeze(true)


func close() -> void:
	closed_frame = Engine.get_process_frames()
	visible = false
	_list.visible = false
	_freeze(false)


func _freeze(on: bool) -> void:
	var player: Node = region.get("player") if region else null
	if is_instance_valid(player):
		player.set_physics_process(not on)
		if on and "velocity" in player: player.velocity = Vector2.ZERO


func _layout() -> void:
	_center = (get_viewport_rect().size * 0.5).round()
	var n := actions.size()
	for i in n:
		var mid := _angle_of(i)
		_icons[i].position = (_center + Vector2.from_angle(mid) * (INNER + OUTER) * 0.5 - _icons[i].size * 0.5).round()
	_title.size = Vector2(120, 0)
	_title.position = _center + Vector2(-60, -12)
	_subtitle.size = Vector2(120, 0)
	_subtitle.position = _center + Vector2(-60, 4)
	_update_texts()
	queue_redraw()


## Ângulo do meio da fatia i (a primeira em cima).
func _angle_of(i: int) -> float:
	return -PI * 0.5 + TAU * i / actions.size()


func _update_texts() -> void:
	_title.text = str(actions[hovered].name) if hovered >= 0 and hovered < actions.size() else ""
	_subtitle.text = str(slime.call("display_name")) if is_instance_valid(slime) else ""


func _draw() -> void:
	if not visible or actions.is_empty() or _list.visible: return
	var n := actions.size()
	var half := TAU / n * 0.5
	for i in n:
		var mid := _angle_of(i)
		var pts := PackedVector2Array()
		for k in 9:
			pts.append(_center + Vector2.from_angle(mid - half + 0.03 + (half * 2.0 - 0.06) * k / 8.0) * OUTER)
		for k in 9:
			pts.append(_center + Vector2.from_angle(mid + half - 0.03 - (half * 2.0 - 0.06) * k / 8.0) * INNER)
		draw_colored_polygon(pts, HOVER if i == hovered else RING)
		pts.append(pts[0])
		draw_polyline(pts, EDGE if i == hovered else Color(1, 1, 1, 0.25), 2.0 if i == hovered else 1.0)
	draw_circle(_center, INNER - 4.0, Color(0.1, 0.07, 0.05, 0.45))


func _gui_input(event: InputEvent) -> void:
	if _list.visible: return
	var motion := event as InputEventMouseMotion
	if motion:
		_hover_at(motion.position)
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_hover_at(click.position)
		_choose()
		accept_event()
	elif click and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		close()
		accept_event()


func _hover_at(at: Vector2) -> void:
	var d := at - _center
	if d.length() < INNER * 0.6: return
	var angle := fposmod(d.angle() + PI * 0.5 + TAU / actions.size() * 0.5, TAU)
	var i := int(angle / (TAU / actions.size())) % actions.size()
	if i != hovered:
		hovered = i
		_update_texts()
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if hold_mode and event.is_action_released("interact") and not _list.visible:
		_choose()
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	var n := actions.size()
	match key.keycode:
		KEY_ESCAPE, KEY_B:
			close()
		KEY_RIGHT, KEY_D, KEY_DOWN, KEY_S:
			if not _list.visible: hovered = (hovered + 1) % n
		KEY_LEFT, KEY_A, KEY_UP, KEY_W:
			if not _list.visible: hovered = posmod(hovered - 1, n)
		KEY_F, KEY_ENTER, KEY_KP_ENTER:
			if not _list.visible: _choose()
		_:
			return
	_update_texts()
	queue_redraw()
	get_viewport().set_input_as_handled()


func _choose() -> void:
	if hovered < 0 or hovered >= actions.size(): return
	var a: Dictionary = actions[hovered]
	if not bool(a.enabled):
		return
	match str(a.id):
		"comida":
			var foods := food_choices()
			if foods.is_empty():
				_finish("comida", "")
			elif foods.size() == 1:
				_finish("comida", str(foods[0]))
			else:
				_open_list(foods, "comida")
		"trabalho":
			if str(slime.get("slime_type")) == "carreguim":
				var options: Array = [""]
				for chest: Dictionary in preload("res://scripts/world/station_placer.gd").chests(get_tree()): options.append(str(chest.id))
				_open_list(options, "trabalho")
			else:
				_finish("trabalho", "")
		_:
			_finish(str(a.id), "")


## Tipos de comida na mochila (favorita do slime primeiro).
func food_choices() -> Array:
	var liked: String = FEEDING.LIKES.get(str(slime.get("slime_type")), "")
	var out: Array = []
	for item: String in BAG.inventory_snapshot(get_tree()):
		if FEEDING.is_food(item) and BAG.count_item(get_tree(), item) > 0: out.append(item)
	var species := str(slime.get("slime_type"))
	out.sort_custom(func(a: String, b: String) -> bool: return int(FEEDING.is_favorite(a, species)) > int(FEEDING.is_favorite(b, species)))
	return out


func _open_list(options: Array, action: String) -> void:
	for child in _list.get_children():
		_list.remove_child(child)  # sai já (queue_free deixaria os botões antigos na lista)
		child.queue_free()
	var liked: String = FEEDING.LIKES.get(str(slime.get("slime_type")), "")
	for option in options:
		var button := Button.new()
		button.add_theme_font_override("font", FONT)
		button.add_theme_font_size_override("font_size", 12)
		button.focus_mode = Control.FOCUS_ALL
		if action == "comida":
			button.icon = ITEMS.icon(str(option))
			button.expand_icon = false
			button.text = "%s ×%d%s" % [str(ITEMS.info(str(option)).name), BAG.count_item(get_tree(), str(option)), "  ★ favorita" if FEEDING.is_favorite(str(option), str(slime.get("slime_type"))) else ""]
		else:
			button.text = "Baú mais perto" if str(option).is_empty() else "Baú " + str(option).replace("_", " ")
		var chosen: String = str(option)
		button.pressed.connect(func() -> void: _finish(action, chosen))
		_list.add_child(button)
	var back := Button.new()
	back.text = "Voltar"
	back.add_theme_font_override("font", FONT)
	back.add_theme_font_size_override("font_size", 11)
	back.pressed.connect(func() -> void:
		_list.visible = false
		queue_redraw())
	_list.add_child(back)
	_list.visible = true
	_list.reset_size()
	_list.position = (_center - _list.size * 0.5).round()
	(_list.get_child(0) as Control).grab_focus.call_deferred()
	queue_redraw()


func _finish(action: String, arg: String) -> void:
	var target := slime
	close()
	if region and region.has_method("slime_action"): region.call("slime_action", target, action, arg)


static func _steps_icon() -> ImageTexture:
	var rows := ["..XX......", ".XXXX.....", ".XXXX.....", "..XX..XX..", "......XXXX", ".XX...XXXX", "XXXX...XX.", "XXXX......", ".XX......."]
	var image := Image.create(10, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 10:
			if str(rows[y][x]) == "X": image.set_pixel(x, y, Color("#e8d3a8"))
	return ImageTexture.create_from_image(image)


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
