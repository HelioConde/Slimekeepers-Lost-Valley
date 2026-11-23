extends PanelContainer
## Tutorial inicial (pedido do usuário, 2026-11-23): depois do despertar do Novo Jogo,
## uma dica por vez no alto da tela; cada uma passa sozinha quando o jogador faz o
## que ela pede. [Tab] pula a dica. O passo fica na sessão (KEY) e vai no save.

const KEY := "tutorial_step"
const BAG := preload("res://scripts/systems/forest_bag.gd")
const FONT := preload("res://assets/fonts/PixelifySans.ttf")
## [texto, condição para passar]. Condições em _done().
const STEPS := [
	["WASD ou setas para andar · Shift corre", "walk"],
	["Chegue perto de um graveto ou pedrinha e aperte F (ou clique nele) para pegar. Andar cancela.", "pick"],
	["E abre a mochila", "bag"],
	["B abre a fabricação: com fibra do mato você faz corda; com corda, graveto e pedra, um machado", "craft"],
	["Escolha a ferramenta na barra (teclas 1–0 ou roda do mouse). Segure F ou o clique para golpear árvores e pedras", "swing"],
	["Chegue perto de um slime e aperte F para fazer amizade", "friend"],
	["No B, \"Construir casa\" abre o modo construir. Dormir na cama salva o jogo", "read"],
]
const READ_SECONDS := 9.0
const WIDTH := 500.0

var region: Node  ## clearing_region: player, inventory_panel, crafting_panel
var _label: Label
var _walked := 0.0
var _time := 0.0


func _ready() -> void:
	name = "TutorialHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", preload("res://scripts/ui/inventory_panel.gd").panel_style())
	anchor_left = 0.5
	anchor_right = 0.5
	offset_top = 58
	_label = Label.new()
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color("#3d2a1e"))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(WIDTH - 70.0, 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	_show()


static func active(tree: SceneTree) -> bool:
	return tree.has_meta(KEY) and int(tree.get_meta(KEY)) < STEPS.size()


func step() -> int:
	return int(get_tree().get_meta(KEY, STEPS.size()))


func _show() -> void:
	visible = active(get_tree())
	if not visible: return
	_label.text = "%s\n[Tab] pular dica  ·  %d/%d" % [STEPS[step()][0], step() + 1, STEPS.size()]
	_walked = 0.0
	_time = 0.0
	offset_left = -WIDTH * 0.5  # fixa: centro do alto, sem cobrir o relógio
	offset_right = WIDTH * 0.5
	offset_bottom = offset_top


func advance() -> void:
	get_tree().set_meta(KEY, step() + 1)
	_show()


func _process(delta: float) -> void:
	if not active(get_tree()):
		visible = false
		return
	if not visible: _show()  # começou agora (fim do despertar)
	_time += delta
	if _done(str(STEPS[step()][1]), delta): advance()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if visible and key and key.pressed and not key.echo and key.physical_keycode == KEY_TAB:
		advance()
		get_viewport().set_input_as_handled()


func _done(kind: String, delta: float) -> bool:
	var tree := get_tree()
	match kind:
		"walk":
			var player: Node = region.get("player") if region else null
			if player is CharacterBody2D and (player as CharacterBody2D).velocity.length() > 10.0: _walked += delta
			return _walked > 1.5
		"pick":
			return BAG.count_item(tree, "graveto") + BAG.count_item(tree, "pedra_pequena") + BAG.count_item(tree, "fibra") > 0
		"bag":
			return _open("inventory_panel")
		"craft":
			return _open("crafting_panel")
		"swing":
			var player: Node = region.get("player") if region else null
			return (is_instance_valid(player) and player.has_method("is_using_tool") and player.is_using_tool() and str(player.get("current_animation")).begins_with("axe")) or _time > 20.0
		"friend":
			for key in ["forest_slime_friends", "valley_slime_friends"]:
				if not (tree.get_meta(key, {}) as Dictionary).is_empty(): return true
			return false
	return _time > READ_SECONDS


func _open(panel_name: String) -> bool:
	var panel: Variant = region.get(panel_name) if region else null
	return panel is Control and is_instance_valid(panel) and (panel as Control).visible
