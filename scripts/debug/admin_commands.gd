extends CanvasLayer
## =====================================================================================
## COMANDOS DE ADMIN — SÓ PARA TESTE. REMOVER ANTES DE LANÇAR O JOGO.
## =====================================================================================
## Pedido do usuário (2026-11-23): atalhos para não refazer tudo a cada teste.
## Só existe em build de depuração (OS.is_debug_build()); a versão exportada sem
## depuração nunca cria este nó.
##
## Para remover tudo:
##   1. apague esta pasta (scripts/debug/);
##   2. apague em scripts/world/clearing_region.gd o bloco marcado "ADMIN (remover)";
##   3. apague tools/test_admin_commands.gd.
##
## Uso no jogo: [F1] abre a caixa de comando; digite e aperte Enter. [F1]/Esc fecha.
## Comandos (digite "ajuda" para ver a lista no jogo):
##   kit                  ferramentas, bancada e materiais para testar à vontade
##   item <id> [qtd]      dá um item (ex.: item madeira 20); ids em item_catalog.gd
##   energia | vida       enche a energia / a vida
##   hora <h> [min]       muda a hora (ex.: hora 18)
##   dia                  avança para o dia seguinte (6h)
##   tutorial <n|fim>     pula o tutorial para a dica n (0..) ou termina
##   amigos               todos os slimes da região ficam amigos
##   ir floresta|vale     viaja para a região
##   slimes               Colhita e Carreguim viram amigos e vão para a fazenda (o mundo
##                        deles ainda não existe)
## =====================================================================================

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const TUTORIAL := preload("res://scripts/ui/tutorial_hud.gd")
const REGIONS := {"floresta": "res://scenes/regions/FlorestaDoDespertarV2.tscn",
	"vale": "res://scenes/regions/ValeDasNascentes.tscn"}
## Kit de teste: o que o começo do jogo pede (machado, picareta, bancada e materiais).
## A mochila tem 10 espaços e já vem com 3 sementes: o kit ocupa os outros 7.
const KIT := {"machado": 1, "picareta": 1, "bancada": 1,
	"madeira": 20, "corda": 6, "pedra_pequena": 20, "graveto": 10}

var region: Node  ## clearing_region que criou este nó
var _box: LineEdit
var _log: Label


func _ready() -> void:
	name = "AdminCommands"
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 470)
	panel.visible = false
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	_log = Label.new()
	_log.add_theme_font_size_override("font_size", 12)
	column.add_child(_log)
	_box = LineEdit.new()
	_box.placeholder_text = "comando de admin (ajuda)"
	_box.custom_minimum_size = Vector2(360, 0)
	_box.text_submitted.connect(func(text: String) -> void:
		_log.text = run(text)
		_box.clear())
	column.add_child(_box)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	var panel := _box.get_parent().get_parent() as Control
	if key.physical_keycode == KEY_F1 or (panel.visible and key.physical_keycode == KEY_ESCAPE):
		panel.visible = not panel.visible and key.physical_keycode == KEY_F1
		if panel.visible: _box.grab_focus()
		else: _box.release_focus()
		get_viewport().set_input_as_handled()


## Executa um comando e devolve o texto de resposta (também usado pelo teste).
func run(line: String) -> String:
	var args := line.strip_edges().to_lower().split(" ", false)
	if args.is_empty(): return ""
	var tree := get_tree()
	match args[0]:
		"ajuda":
			return "kit · item <id> [qtd] · energia · vida · imortal · boss · hora <h> · dia · tutorial <n|fim> · amigos · slimes · ir floresta|vale"
		"kit":
			for id: String in KIT: BAG.add_item(tree, id, int(KIT[id]))
			_refresh()
			return "Kit de teste na mochila."
		"item":
			if args.size() < 2 or not ITEMS.ITEMS.has(args[1]): return "Item desconhecido."
			var amount := int(args[2]) if args.size() > 2 else 1
			var ok := BAG.add_item(tree, args[1], amount)
			_refresh()
			return ("+%d %s" % [amount, args[1]]) if ok else "Não coube na mochila."
		"energia":
			preload("res://scripts/systems/energy_state.gd").restore(tree)
			return "Energia cheia."
		"vida":
			tree.set_meta(preload("res://scripts/systems/health_state.gd").KEY, 100)
			return "Vida cheia."
		"boss":  # libera o primeiro boss (Mirante Rochoso) e dá armas e flechas para testar
			tree.set_meta(preload("res://scripts/combat/boss_arena.gd").UNLOCK_KEY, true)
			var bag := preload("res://scripts/systems/forest_bag.gd")
			for item in ["espada", "arco"]: if bag.count_item(tree, item) == 0: bag.add_item(tree, item, 1)
			bag.add_item(tree, "flecha", 30)
			_refresh()
			return "Boss liberado no Mirante Rochoso; espada, arco e 30 flechas na bolsa."
		"imortal":  # vida infinita para testar combate (liga/desliga)
			var key: String = preload("res://scripts/combat/player_combat.gd").GOD_KEY
			tree.set_meta(key, not bool(tree.get_meta(key, false)))
			return "Vida infinita: %s." % ("ligada" if tree.get_meta(key) else "desligada")
		"hora":
			if args.size() < 2: return "Uso: hora <h> [min]"
			tree.root.get_node("GameClock").set_time(int(args[1]), int(args[2]) if args.size() > 2 else 0)
			return "Hora: %s" % args[1]
		"dia":
			var clock: Node = tree.root.get_node("GameClock")
			clock.advance_minutes((1440.0 - (clock.get_hour() * 60.0 + clock.get_minute())) + 360.0)
			return "Dia seguinte, 6h."
		"tutorial":
			var step := TUTORIAL.STEPS.size() if args.size() < 2 or args[1] == "fim" else clampi(int(args[1]), 0, TUTORIAL.STEPS.size())
			tree.set_meta(TUTORIAL.KEY, step)
			return "Tutorial na dica %d." % step
		"amigos":
			var count := 0
			for slime in tree.get_nodes_in_group("living_slimes"):
				if slime.has_method("make_friend") and slime.call("make_friend"): count += 1
			return "%d slimes agora são amigos." % count
		"slimes":
			var friends: Dictionary = (tree.get_meta("forest_slime_friends", {}) as Dictionary).duplicate()
			friends["colhita/admin/0"] = true
			friends["carreguim/admin/0"] = true
			friends["construlim/admin/0"] = true
			tree.set_meta("forest_slime_friends", friends)
			return "Colhita, Carreguim e Construlim agora são amigos e vão para a fazenda."
		"ir":
			if args.size() < 2 or not REGIONS.has(args[1]): return "Uso: ir floresta|vale"
			tree.call_deferred("change_scene_to_file", REGIONS[args[1]])
			return "Indo para %s..." % args[1]
	return "Comando desconhecido (ajuda)."


func _refresh() -> void:
	var bag_hud: Variant = region.get("bag_hud") if region else null
	if bag_hud is Node and is_instance_valid(bag_hud): (bag_hud as Node).call("refresh")
