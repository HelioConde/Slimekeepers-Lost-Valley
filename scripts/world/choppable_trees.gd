extends Node
## Árvores cortáveis (CRIACAO.md, etapa 3). Com o machado selecionado, [F] perto do
## tronco dá um golpe; após HITS_TO_FELL golpes a árvore cai: fica um toco e um
## tronco caído ao lado. [F] com o machado no tronco o processa em madeira. A árvore
## volta a crescer após REGROW_DAYS dias. Não podem ser cortadas: árvores perto de
## habitats de slimes, pontos de interesse (inclui a Árvore Centenária) e as que o
## `protected` da região marcar. Estado salvo em CHOPPED_KEY (sessão + save).

const BAG := preload("res://scripts/systems/forest_bag.gd")
const CHOPPED_KEY := "chopped_trees"
const HITS_TO_FELL := 3
const HITS_TO_PROCESS := 2
const WOOD_PER_LOG := 4
const REGROW_DAYS := 3
const REACH := 46.0
const CELL := 128.0
const STUMP := preload("res://assets/objects/tree_stump_small_cut_oak_stu/rotations/tree_stump_small_cut_oak_stu.png")
const LOG := preload("res://assets/sprites/objects/fallen_log_mossy_fallen_oak/rotations/fallen_log_mossy_fallen_oak.png")
const LOG_OFFSET := Vector2(54, 10)  # tronco cai ao lado do toco (árvore escala 2)
## Altura visível (px) até a qual a árvore é pequena: o machado de pedra só corta
## estas (pedido do usuário, 2026-11-22); as grandes pedem machados futuros.
const SMALL_TREE_MAX_HEIGHT := 120.0
## Toco e tronco proporcionais à árvore: fração da escala do sprite da árvore.
const STUMP_SCALE := 0.48
const LOG_SCALE := 0.7

var trees: Dictionary = {}  # key -> Node2D
## Solta a madeira no chão (item, quantidade, ponto); vazio = direto na bolsa.
var drop: Callable
var _grid: Dictionary = {}  # Vector2i -> Array[key]
var _hits: Dictionary = {}  # key -> golpes nesta árvore/tronco (não salvo)
var _extras: Dictionary = {}  # key -> [stump, log]


## prefix separa o estado salvo de cada mapa ("" = Floresta, chaves antigas).
## all_children: grupos só de árvores (Vale), sem a marca metadata/tree.
func setup(groups: Array, protected: Callable, prefix: String = "", all_children: bool = false) -> void:
	name = "ChoppableTrees"
	for group: Node in groups:
		for node in group.get_children():  # marca metadata/tree do próprio nó da árvore
			if not (node is Node2D) or not node.has_node("Sprite"): continue
			if not all_children and not node.get_meta("tree", false): continue
			var at: Vector2 = (node as Node2D).global_position
			if protected.call(at): continue
			var key := "%s%s/%s" % [prefix, group.name, node.name]
			trees[key] = node
			var cell := Vector2i((at / CELL).floor())
			if not _grid.has(cell): _grid[cell] = []
			_grid[cell].append(key)


static func state(tree: SceneTree) -> Dictionary:
	return tree.get_meta(CHOPPED_KEY, {})


## Aplica o estado salvo: árvores cortadas viram toco (+ tronco se não processado);
## as que já cresceram de novo voltam e saem do registro.
func apply_day(day: int) -> void:
	var chopped: Dictionary = state(get_tree()).duplicate(true)
	var changed := false
	for key in chopped.keys():
		if not trees.has(key):
			continue
		if day - int(chopped[key].day) >= REGROW_DAYS:
			chopped.erase(key)
			changed = true
			_restore(key)
		else:
			_fell_visual(key, bool(chopped[key].get("processed", false)))
	if changed:
		get_tree().set_meta(CHOPPED_KEY, chopped)


## Alvo ao alcance dos pés: {"key", "kind": "tree"|"log"} ou {}.
func target(at: Vector2) -> Dictionary:
	var chopped := state(get_tree())
	var best: Dictionary = {}
	var best_d := REACH
	var base := Vector2i((at / CELL).floor())
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for key: String in _grid.get(base + Vector2i(dx, dy), []):
				var tree: Node2D = trees[key]
				if chopped.has(key):
					if bool(chopped[key].get("processed", false)): continue
					var d_log := at.distance_to(log_position(key))
					if d_log < best_d:
						best = {"key": key, "kind": "log"}
						best_d = d_log
				else:
					var d := at.distance_to(tree.global_position)
					if d < best_d:
						best = {"key": key, "kind": "tree"}
						best_d = d
	return best


## Escala do desenho da árvore (1 = pequena, 2 = grande nos mapas atuais).
func tree_scale(key: String) -> float:
	var sprite := (trees[key] as Node2D).get_node("Sprite") as Node2D
	return absf(sprite.global_scale.y) / absf((trees[key] as Node2D).global_scale.y)


var _used_height := {}  # textura -> altura visível (get_image é caro)


## Pequena = cortável com o machado de pedra.
func is_small(key: String) -> bool:
	var sprite := (trees[key] as Node2D).get_node("Sprite") as Sprite2D
	if not _used_height.has(sprite.texture):
		_used_height[sprite.texture] = sprite.texture.get_image().get_used_rect().size.y
	return float(_used_height[sprite.texture]) * absf(sprite.global_scale.y) <= SMALL_TREE_MAX_HEIGHT


## Onde o tronco cai (ao lado do toco, proporcional ao tamanho da árvore).
func log_position(key: String) -> Vector2:
	return (trees[key] as Node2D).global_position + LOG_OFFSET * (tree_scale(key) * 0.5)


func hits(key: String) -> int:
	return int(_hits.get(key, 0))


## Golpes para derrubar: a árvore grande (só machado de pedra polida) pede o dobro.
func fell_hits(key: String) -> int:
	return HITS_TO_FELL * (1 if is_small(key) else 2)


## Madeira por tronco: a árvore grande rende o dobro.
func wood(key: String) -> int:
	return WOOD_PER_LOG * (1 if is_small(key) else 2)


## Um golpe de machado (power: quantos golpes vale; pedra polida = 2).
## Devolve "hit", "felled" ou "processed".
func strike(t: Dictionary, day: int, power: int = 1) -> String:
	var key: String = t.key
	_hits[key] = hits(key) + power
	var tree: Node2D = trees[key]
	_shake(tree.get_node("Sprite") if t.kind == "tree" else _extras[key][1])
	if t.kind == "tree":
		if hits(key) < fell_hits(key): return "hit"
		_hits.erase(key)
		var chopped := state(get_tree()).duplicate(true)
		chopped[key] = {"day": day, "processed": false}
		get_tree().set_meta(CHOPPED_KEY, chopped)
		_fell_visual(key, false)
		return "felled"
	if hits(key) < HITS_TO_PROCESS: return "hit"
	_hits.erase(key)
	var chopped := state(get_tree()).duplicate(true)
	chopped[key]["processed"] = true
	get_tree().set_meta(CHOPPED_KEY, chopped)
	if drop.is_valid(): drop.call("madeira", wood(key), log_position(key))  # cai no chão
	else: BAG.add_item(get_tree(), "madeira", wood(key))
	_fell_visual(key, true)
	return "processed"


func _fell_visual(key: String, processed: bool) -> void:
	var tree: Node2D = trees[key]
	for part in ["Sprite", "ContactShadow"]:
		if tree.has_node(part): (tree.get_node(part) as CanvasItem).visible = false
	var body := tree.get_node_or_null("SolidBase")
	if body is CollisionObject2D: (body as CollisionObject2D).collision_layer = 0
	if not _extras.has(key):
		var s := tree_scale(key)
		var stump := _sprite(tree, STUMP, Vector2(0, -22), STUMP_SCALE * s)
		var log := _sprite(tree, LOG, Vector2(0, -20), LOG_SCALE * s)
		log.position = log_position(key) - tree.global_position
		_extras[key] = [stump, log]
	(_extras[key][1] as Sprite2D).visible = not processed


func _restore(key: String) -> void:
	var tree: Node2D = trees[key]
	for part in ["Sprite", "ContactShadow"]:
		if tree.has_node(part): (tree.get_node(part) as CanvasItem).visible = true
	var body := tree.get_node_or_null("SolidBase")
	if body is CollisionObject2D: (body as CollisionObject2D).collision_layer = 2
	if _extras.has(key):
		for extra in _extras[key]: (extra as Node).queue_free()
		_extras.erase(key)


func _sprite(parent: Node2D, texture: Texture2D, offset: Vector2, size: float = 1.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * size
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = offset
	sprite.set_meta("no_shadow", true)
	parent.add_child(sprite)
	return sprite


func _shake(item: CanvasItem) -> void:
	if not (item is Node2D): return
	var node := item as Node2D
	var origin := node.position
	var tween := node.create_tween()
	for i in 3:
		tween.tween_property(node, "position", origin + Vector2(2 if i % 2 == 0 else -2, 0), 0.04)
	tween.tween_property(node, "position", origin, 0.04)
