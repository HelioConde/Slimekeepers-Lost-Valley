extends Node2D
## Arena do primeiro boss (docs/gameplay/BOSS_BROTINHO.md), no Mirante Rochoso (local
## escolhido pelo usuário em 2026-11-27; platô ampliado por tools/combat/grow_lookout.gd).
## Regra do usuário (Bíblia): o boss aparece pela magia acumulada no ambiente, e o que
## define essa energia são os cristais de energia; onde o boss surge há pelo menos 1
## cristal, e o boss sai dele.
## Liberada: ao entrar, o anel de raízes fecha e o Brotinho Gigante surge (chance
## pequena do Musguinho Gigante). Perdeu: acorda em casa com metade da vida, sem perder
## itens; o boss volta cheio. Venceu: orbe de energia, o boss volta a ser um slime e a
## área fica pacífica.

const BOSS := preload("res://scripts/combat/slime_boss.gd")
const HEALTH := preload("res://scripts/systems/health_state.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const HOUSE := preload("res://scripts/systems/house_state.gd")
const FONT := preload("res://assets/fonts/ui_font.tres")
const UNLOCK_KEY := "boss_floresta_unlocked"  ## liberado (gatilho provisório ou depuração)
const DEFEATED_KEY := "bosses_defeated"  ## {região: true}
const PACIFIED_KEY := "pacified_areas"  ## {habitat: true}: slimes mais pacíficos
const THREAT := preload("res://scripts/combat/forest_threat.gd")  ## pontos e dificuldade
const MUSGUINHO_CHANCE := 0.1
const REGION_ID := "floresta"
const AREA := "floresta"  ## área que fica pacífica com a vitória (Mapa 1)
## Cristal escuro feito no PixelLab (escolha do usuário, 2026-11-27).
const CRYSTAL_ART := preload("res://assets/objects/pixellab_exports/magic_crystal_detailed_64x96_ae2e88e2/magic_crystal_detailed_64x96.png")
const CRYSTAL_OFFSET := Vector2(0, -178)  ## na ponta do platô (borda de trás)

var region: Node2D
var radii := Vector2(300, 190)  ## elipse da arena (dentro do platô de 330x215)
var radius := 300.0  ## maior raio (sementes somem além dele)
var crystal: Node2D
var boss: Node2D
var fighting := false
var _left_since_defeat := true  ## depois de perder, só reabre ao sair e voltar
var _ui: CanvasLayer
var _bar: ProgressBar
var _name: Label
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "BossArena"
	y_sort_enabled = true  # cristal ordenado com o jogador; o anel vai na camada de chão
	var ground := preload("res://scripts/combat/ground_layer.gd").new()
	ground.painter = _draw_ring
	get_parent().add_child.call_deferred(ground)
	rng.randomize()
	_place_crystal()


## Cristal de energia no local do boss (regra do usuário): brilha devagar.
func _place_crystal() -> void:
	crystal = Node2D.new()
	crystal.name = "EnergyCrystal"
	crystal.add_to_group("energy_crystal")
	crystal.position = CRYSTAL_OFFSET
	var sprite := Sprite2D.new()
	sprite.texture = CRYSTAL_ART
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2, 2)  # como os outros objetos do mapa
	sprite.offset = Vector2(0, -22)  # base no chão
	crystal.add_child(sprite)
	add_child(crystal)
	var glow := create_tween().set_loops()
	glow.tween_property(sprite, "modulate", Color(1.4, 1.6, 1.5), 1.2).set_trans(Tween.TRANS_SINE)
	glow.tween_property(sprite, "modulate", Color.WHITE, 1.2).set_trans(Tween.TRANS_SINE)


## Dentro da elipse da arena (k < 1 = dentro; 1 = na borda).
func _k(point: Vector2) -> float:
	return ((point - global_position) / radii).length()


static func unlocked(tree: SceneTree) -> bool:
	if bool(tree.get_meta(UNLOCK_KEY, false)): return true
	return THREAT.points(tree, AREA) >= THREAT.UNLOCK_POINTS  # regra provisória: matar 1, domar 5, total 20


static func defeated_here(tree: SceneTree) -> bool:
	return bool((tree.get_meta(DEFEATED_KEY, {}) as Dictionary).get(REGION_ID, false))


func _process(_delta: float) -> void:
	queue_redraw()
	var player: Node2D = region.get("player") if region else null
	if not is_instance_valid(player): return
	var inside := _k(player.global_position) < 0.85
	if not inside: _left_since_defeat = true
	if fighting:
		# Anel fechado: o jogador não sai da arena durante a luta.
		var k := _k(player.global_position)
		if k > 0.96: player.global_position = global_position + (player.global_position - global_position) / k * 0.96
		if HEALTH.current(get_tree()) <= 0: _lose(player)
		return
	if inside and _left_since_defeat and not defeated_here(get_tree()) and unlocked(get_tree()):
		start(player)


func start(player: Node2D) -> void:
	fighting = true
	var net := get_node_or_null("/root/NetSession")
	var duo := net != null and bool(net.get("connected"))
	boss = BOSS.new()
	boss.configure(player, global_position, radius, "musguinho" if rng.randf() < MUSGUINHO_CHANCE else "brotinho", duo, float(THREAT.BOSS_HP[THREAT.difficulty(get_tree(), AREA)]))
	boss.position = global_position + CRYSTAL_OFFSET + Vector2(0, 40) - region.global_position  # sai do cristal
	region.add_child(boss)
	boss.hp_changed.connect(_on_hp)
	boss.defeated.connect(_win)
	_build_ui()
	_name.text = str(boss.display_name)
	_on_hp(boss.hp, boss.max_hp)  # o boss avisou a vida antes da barra existir
	_fade_trees(true)
	if region.has_method("_notify"): region.call("_notify", "Raízes fecham a clareira! Espaço rola para desviar.")


func _on_hp(hp: int, max_hp: int) -> void:
	if is_instance_valid(_bar):
		_bar.max_value = max_hp
		_bar.value = hp


func _lose(player: Node2D) -> void:
	fighting = false
	_fade_trees(false)
	_left_since_defeat = false
	if is_instance_valid(boss): boss.queue_free()
	_close_ui()
	player.global_position = _wake_spot()
	HEALTH.change(get_tree(), HEALTH.MAX / 2)
	if region.has_method("_notify"): region.call("_notify", "Você desmaiou... e acordou em casa. Nada foi perdido.")


## Na cama da casa (se houver nesta região) ou no ponto de início.
func _wake_spot() -> Vector2:
	var house: Dictionary = HOUSE.data(get_tree())
	if HOUSE.region_of(get_tree()) == REGION_ID:
		for origin in house.get("furniture", {}):
			if str(house.furniture[origin]) == "cama": return Vector2(origin * 32) + Vector2(16, 48)
	return preload("res://scripts/world/forest_layout.gd").SPAWN


func _win() -> void:
	fighting = false
	_fade_trees(false)
	_close_ui()
	var tree := get_tree()
	var beaten: Dictionary = (tree.get_meta(DEFEATED_KEY, {}) as Dictionary).duplicate()
	beaten[REGION_ID] = true
	tree.set_meta(DEFEATED_KEY, beaten)
	var calm: Dictionary = (tree.get_meta(PACIFIED_KEY, {}) as Dictionary).duplicate()
	calm[AREA] = true
	tree.set_meta(PACIFIED_KEY, calm)
	BAG.add_item(tree, "orbe_energia", 1)
	if is_instance_valid(boss):
		var fade := boss.create_tween()  # o slime volta ao normal e vai embora para o habitat
		fade.tween_interval(1.2)
		fade.tween_property(boss, "modulate:a", 0.0, 0.8)
		fade.tween_callback(boss.queue_free)
	if region.has_method("_notify"): region.call("_notify", "A magia virou um orbe de energia! Os slimes desta área ficaram tranquilos.")


## Durante a luta, as copas dentro da arena ficam translúcidas (como o telhado da casa):
## sem isso as árvores do Campo dos Brotos escondiam o boss, os avisos e o jogador.
var _faded: Array = []


func _fade_trees(on: bool) -> void:
	for node: CanvasItem in _faded:
		if is_instance_valid(node): node.modulate.a = 1.0
	_faded.clear()
	if not on: return
	for node in region.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.texture == null or not sprite.is_visible_in_tree(): continue
		if sprite.get_rect().size.y * sprite.global_scale.y < 90.0: continue  # só o que é alto (árvores)
		if sprite.global_position.distance_to(global_position) > radius + 90.0: continue
		var holder: CanvasItem = sprite
		holder.modulate.a = 0.28
		_faded.append(holder)


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 15
	add_child(_ui)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.offset_left = -220
	box.offset_right = 220
	box.offset_top = 44
	_ui.add_child(box)
	_name = Label.new()
	_name.add_theme_font_override("font", FONT)
	_name.add_theme_font_size_override("font_size", 16)
	_name.add_theme_color_override("font_outline_color", Color("#2a1a14"))
	_name.add_theme_constant_override("outline_size", 5)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_name)
	_bar = ProgressBar.new()
	_bar.name = "BossHealth"
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(440, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#c8463a")
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#2a1a14")
	back.set_border_width_all(2)
	back.border_color = Color("#f6e8c2")
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", back)
	box.add_child(_bar)
	for control: Control in [box, _name, _bar]:  # a barra não pode comer o clique no boss
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _close_ui() -> void:
	if is_instance_valid(_ui): _ui.queue_free()


func _draw_ring(layer: Node2D) -> void:
	if not fighting: return
	# Anel de raízes fechando a clareira (provisório, sem arte), no chão.
	layer.draw_set_transform(layer.to_local(global_position), 0.0, Vector2(1.0, radii.y / radii.x))
	for i in 56:
		var angle := TAU * i / 56.0
		layer.draw_circle(Vector2.from_angle(angle) * radii.x, 7.0 + 2.0 * sin(i * 1.7), Color("#5a3d24"))
	layer.draw_arc(Vector2.ZERO, radii.x, 0.0, TAU, 112, Color("#7a5634"), 3.0)
	layer.draw_set_transform(Vector2.ZERO)
