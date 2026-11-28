extends SceneTree
## Aumenta o Mirante Rochoso para a arena do primeiro boss (autorização do usuário,
## 2026-11-27: "se o espaço estiver muito pequeno autorizo aumentar"). Edita só o platô
## na cena da Floresta: elipse de 235x155 -> RADII, mesmas regras de encaixe dos
## penhascos de tools/build_forest_v2.gd, colisão refeita com a abertura da escada,
## escada e pedras laterais descem SHIFT, e somem as árvores/plantas que ficaram dentro.
## Uso: godot --headless --path . --script res://tools/combat/grow_lookout.gd

const SCENE := "res://scenes/regions/FlorestaDoDespertarV2.tscn"
const CENTER := Vector2(5110, 1240)
const OLD_RADII := Vector2(235, 155)
const RADII := Vector2(330, 215)
const SHIFT := Vector2(0, 60)  ## a borda de baixo desce 60 px
const PROPS := ["ForestTree", "Wildflowers", "Fern", "Shrub", "Bush", "Mushroom", "Flower", "Grass", "Plant", "Clover", "Pebble", "Stone"]

var _tiles: Array


func _initialize() -> void:
	var packed: PackedScene = load(SCENE)
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var ledges: Node2D = root.get_node("NorthernLedges")
	var wall: TileMapLayer = ledges.get_node("LowCliffs")
	_tiles = (JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/valley/cliffs_low.json")) as Dictionary).tileset_data.tiles
	for child in ledges.get_children():  # colisões antigas do penhasco
		if child is StaticBody2D:
			ledges.remove_child(child)
			child.free()
	var lo := Vector2i(((CENTER - RADII) / 64.0).floor()) - Vector2i(2, 2)
	var hi := Vector2i(((CENTER + RADII) / 64.0).ceil()) + Vector2i(2, 2)
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1): wall.erase_cell(Vector2i(x, y))
	var aperture := _box(Rect2(Vector2(5050, 1320) + SHIFT, Vector2(120, 240)))  # passagem da escada
	var bodies := 0
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			var cell := Vector2i(x, y)
			var values := [_hill(cell), _hill(cell + Vector2i.RIGHT), _hill(cell + Vector2i.DOWN), _hill(cell + Vector2i.ONE)]
			if values == [0, 0, 0, 0]: continue
			var coord := _hill_tile(cell)
			if coord.x < 0:
				push_error("padrão de penhasco faltando: %s" % cell)
				continue
			wall.set_cell(cell, 0, coord)
			if values != [1, 1, 1, 1]:
				for polygon in Geometry2D.clip_polygons(_box(Rect2(Vector2(cell) * 64, Vector2(64, 64))), aperture):
					var body := StaticBody2D.new()
					body.collision_layer = 2
					ledges.add_child(body)
					body.owner = root
					var shape := CollisionPolygon2D.new()
					shape.polygon = polygon
					body.add_child(shape)
					shape.owner = root
					bodies += 1
	var moved := 0
	var removed := 0
	var doomed: Array[Node] = []
	for node in root.find_children("*", "Node2D", true, false):
		if doomed.any(func(d: Node) -> bool: return d.is_ancestor_of(node)): continue
		var n := str(node.name)
		if n.begins_with("LookoutSteps") or n.begins_with("LookoutShoulder"):
			(node as Node2D).position += SHIFT
			moved += 1
			continue
		if not PROPS.any(func(p: String) -> bool: return n.begins_with(p)): continue
		if node.get_parent() == null or node.get_parent().name.begins_with("Lookout"): continue
		var at: Vector2 = (node as Node2D).global_position if node.is_inside_tree() else _world_pos(node)
		if ((at - CENTER) / (RADII * 0.98)).length() < 1.0: doomed.append(node)
	for node in doomed:
		node.get_parent().remove_child(node)
		node.free()
		removed += 1
	var out := PackedScene.new()
	var err := out.pack(root)
	if err == OK: err = ResourceSaver.save(out, SCENE)
	print("GROW_LOOKOUT: corpos=%d movidos=%d removidos=%d salvo=%s" % [bodies, moved, removed, err == OK])
	root.free()
	quit(0 if err == OK else 1)


## Posição no mundo somando as posições dos pais (a cena não está na árvore).
func _world_pos(node: Node) -> Vector2:
	var at := Vector2.ZERO
	var current := node
	while current != null and current is Node2D:
		at += (current as Node2D).position
		current = current.get_parent()
	return at


func _hill(cell: Vector2i) -> int:
	return 1 if ((Vector2(cell) * 64 - CENTER) / RADII).length() < 1.0 else 0


func _hill_tile(cell: Vector2i) -> Vector2i:
	var best := -1
	var found := Vector2i(-1, -1)
	for tile: Dictionary in _tiles:
		var valid := true
		var specificity := 0
		for row in 4:
			var pattern: Array = tile.pattern_4x4["row_" + str(row)]
			for col in 4:
				if int(pattern[col]) == 255: continue
				if int(pattern[col]) != _hill(cell + Vector2i(col - 1, row - 1)): valid = false
				specificity += 1
		if valid and specificity > best:
			best = specificity
			found = Vector2i(int(tile.bounding_box.x) / 32, int(tile.bounding_box.y) / 32)
	return found


func _box(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
