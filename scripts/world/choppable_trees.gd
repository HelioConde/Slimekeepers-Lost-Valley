extends Node
## Árvores cortáveis (CRIACAO.md, etapa 3). Com o machado selecionado, [E] perto do
## tronco dá um golpe; após HITS_TO_FELL golpes a árvore cai: fica um toco e um
## tronco caído ao lado. [E] com o machado no tronco o processa em madeira. A árvore
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
const LOG_OFFSET := Vector2(54, 10)  # tronco cai ao lado do toco

var trees: Dictionary = {}  # key -> Node2D
var _grid: Dictionary = {}  # Vector2i -> Array[key]
var _hits: Dictionary = {}  # key -> golpes nesta árvore/tronco (não salvo)
var _extras: Dictionary = {}  # key -> [stump, log]


func setup(groups: Array, protected: Callable) -> void:
	name = "ChoppableTrees"
	for group: Node in groups:
		for node in group.get_children():  # marca metadata/tree do próprio nó da árvore
			if not (node is Node2D) or not node.get_meta("tree", false) or not node.has_node("Sprite"): continue
			var at: Vector2 = (node as Node2D).global_position
			if protected.call(at): continue
			var key := "%s/%s" % [group.name, node.name]
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
					var d_log := at.distance_to(tree.global_position + LOG_OFFSET)
					if d_log < best_d:
						best = {"key": key, "kind": "log"}
						best_d = d_log
				else:
					var d := at.distance_to(tree.global_position)
					if d < best_d:
						best = {"key": key, "kind": "tree"}
						best_d = d
	return best


func hits(key: String) -> int:
	return int(_hits.get(key, 0))


## Um golpe de machado. Devolve "hit", "felled" ou "processed".
func strike(t: Dictionary, day: int) -> String:
	var key: String = t.key
	_hits[key] = hits(key) + 1
	var tree: Node2D = trees[key]
	_shake(tree.get_node("Sprite") if t.kind == "tree" else _extras[key][1])
	if t.kind == "tree":
		if hits(key) < HITS_TO_FELL: return "hit"
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
	BAG.add_item(get_tree(), "madeira", WOOD_PER_LOG)
	_fell_visual(key, true)
	return "processed"


func _fell_visual(key: String, processed: bool) -> void:
	var tree: Node2D = trees[key]
	for part in ["Sprite", "ContactShadow"]:
		if tree.has_node(part): (tree.get_node(part) as CanvasItem).visible = false
	var body := tree.get_node_or_null("SolidBase")
	if body is CollisionObject2D: (body as CollisionObject2D).collision_layer = 0
	if not _extras.has(key):
		var stump := _sprite(tree, STUMP, Vector2(0, -22))
		var log := _sprite(tree, LOG, LOG_OFFSET + Vector2(0, -20))
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


func _sprite(parent: Node2D, texture: Texture2D, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
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
