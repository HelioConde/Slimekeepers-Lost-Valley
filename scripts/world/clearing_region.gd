extends "res://scripts/world.gd"
## The editable map is baked in ClareiraDoDespertar.tscn. Reuse existing friendship/HUD.
const PauseOverlay := preload("res://scripts/ui/pause_overlay.gd")
const Layout = preload("res://scripts/world/clearing_layout.gd")
var _visited_exits: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = true
	add_child(PauseOverlay.new())
	player = $Player
	player.position = $SpawnPoints/PlayerSpawn.position
	player.world_bounds = Rect2(Vector2(24, 44), Layout.WORLD_SIZE - Vector2(48, 68))
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(Layout.WORLD_SIZE.x)
	camera.limit_bottom = int(Layout.WORLD_SIZE.y)
	camera.reset_smoothing()
	for i in Layout.SLIME_POSITIONS.size():
		_spawn_slime(["gelito", "brotinho", "brasinha"][i], Layout.SLIME_POSITIONS[i])
	_create_hud()
	_compact_hud()
	hud_title.text = "CLAREIRA DO DESPERTAR"
	_update_hud()
	for exit_area: Area2D in $Exits.get_children():
		exit_area.body_entered.connect(_on_exit_entered.bind(exit_area.name))
	preload("res://scripts/world/region_travel.gd").restore_clearing(self)

func _process(delta: float) -> void:
	super._process(delta)
	if player.position.distance_to(Vector2(1610,3120)) < 110:
		hud_hint.text = "[E] Viajar para o Vale das Nascentes"
		if Input.is_action_just_pressed("interact"):
			var travel = preload("res://scripts/world/region_travel.gd")
			travel.travel(self,travel.VALLEY,"valley_north")
			return
	var spring := get_node_or_null("NaturalSpring")
	if spring != null and _closest_slime() == null and spring.can_examine(player.global_position):
		hud_hint.text = "[E] Examinar lago"
		if Input.is_action_just_pressed("interact"):
			_notify("Um pequeno lago de água cristalina repousa entre as árvores.")

func _on_exit_entered(body: Node2D, exit_name: StringName) -> void:
	if body != player or _visited_exits.has(exit_name):
		return
	_visited_exits[exit_name] = true
	var messages := {
		"North": "Trilha das montanhas · esta região chegará em uma próxima etapa.",
		"East": "Trilha dos slimes · mais descobertas chegarão em uma próxima etapa.",
		"South": "Vale das Nascentes · pressione E para seguir pelas águas."
	}
	_notify(messages[exit_name])

func _update_hud() -> void:
	# Sem missões: o jogo é livre (cultivar, explorar, fazer amizades no seu ritmo).
	pass

func _compact_hud() -> void:
	var panel: PanelContainer = $HUD/Interface/MissionPanel
	panel.anchor_right = 0.0
	panel.offset_right = 18
	panel.offset_bottom = 16
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.set_content_margin_all(6)
	style.content_margin_left = 9
	style.content_margin_right = 9
	panel.add_theme_stylebox_override("panel",style)
	hud_title.add_theme_font_size_override("font_size",15)
	hud_goal.add_theme_font_size_override("font_size",13)
	# O painel encolhe até o texto: sem quebra automática (senão vira uma coluna).
	hud_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	hud_goal.autowrap_mode = TextServer.AUTOWRAP_OFF
	# Linha de objetivos removida: o painel mostra só o nome do lugar.
	hud_goal.hide()
	# Painéis ficam translúcidos quando o jogador passa por baixo deles.
	var fade := preload("res://scripts/ui/hud_overlap_fade.gd").new()
	fade.name = "HudOverlapFade"
	fade.target = player
	$HUD/Interface.add_child(fade)
	# Barra rápida de itens (ferramentas, sementes, colheitas) acima da linha de dicas.
	$HUD/Interface.add_child(preload("res://scripts/ui/hotbar_hud.gd").new())
	var hint: PanelContainer = $HUD/Interface/InteractionHint
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.offset_left = -292
	hint.offset_right = 292
	hint.offset_top = -44
	hint.offset_bottom = -12
	var hint_style := hint.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	hint_style.set_content_margin_all(7)
	hint.add_theme_stylebox_override("panel",hint_style)
	hud_hint.add_theme_font_size_override("font_size",14)
	popup.offset_top = 90
	popup.offset_bottom = 138
	popup.add_theme_font_size_override("font_size",18)
