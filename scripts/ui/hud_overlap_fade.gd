extends Node
## Deixa translúcidos os painéis permanentes do HUD enquanto o jogador (ou o que
## ele está prestes a usar) passa por baixo deles. Não esconde informação nem muda
## o layout: só o alfa, com transição suave. Painéis de leitura (receitas, pausa)
## ficam de fora.

const FADED_ALPHA := 0.28
const SPEED := 6.0
## Caixa do personagem em px do mundo a partir dos pés: largura e altura até a cabeça.
const BODY := Vector2(44, 70)
const PANELS := [&"MissionPanel", &"ForagingBagPanel", &"DayClock", &"CookingGuidance", &"Hotbar", &"EnergyBar", &"PlayerStatus"]

var target: Node2D


func _process(delta: float) -> void:
	step(delta)


static func player_screen_box(feet: Vector2, canvas: Transform2D) -> Rect2:
	var top_left: Vector2 = canvas * (feet + Vector2(-BODY.x * 0.5, -BODY.y))
	var bottom_right: Vector2 = canvas * (feet + Vector2(BODY.x * 0.5, 4))
	return Rect2(top_left, bottom_right - top_left).abs()


func step(delta: float) -> void:
	var interface := get_parent() as Control
	if not is_instance_valid(target) or not interface or not target.is_inside_tree():
		return
	var box := player_screen_box(target.global_position, target.get_viewport().get_canvas_transform())
	var weight := clampf(delta * SPEED, 0.0, 1.0)
	for panel_name in PANELS:
		var panel := interface.get_node_or_null(NodePath(panel_name)) as Control
		if not panel or not panel.visible:
			continue
		var goal := FADED_ALPHA if panel.get_global_rect().grow(6).intersects(box) else 1.0
		panel.modulate.a = lerpf(panel.modulate.a, goal, weight)
		if absf(panel.modulate.a - goal) < 0.01:
			panel.modulate.a = goal
