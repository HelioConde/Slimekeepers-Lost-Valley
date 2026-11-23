extends SceneTree
## Diagnóstico: o que continua visível dentro da área da casa depois de construir.

const House := preload("res://scripts/systems/house_state.gd")
const Bag := preload("res://scripts/systems/forest_bag.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	for key in [House.KEY, Bag.INVENTORY_KEY]:
		if has_meta(key): remove_meta(key)
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	var house: Node2D = region.get("house")
	var player: Node2D = region.get("player")
	var rect := Rect2i(Vector2i(103, 98), Vector2i(7, 5))  # mesma casa de capture_house
	for item in House.rect_cost(rect): Bag.add_item(self, item, 99)
	print("build: ", House.build(self, "floresta", rect))
	house.rebuild()
	for i in 10: await process_frame
	var area := Rect2(Vector2(rect.position * 32), Vector2(rect.size * 32)).grow(8)
	for child in region.find_children("*", "", true, false):
		if child is Node2D and (child as Node2D).is_visible_in_tree() and (child is Sprite2D or child is AnimatedSprite2D):
			var at: Vector2 = (child as Node2D).global_position
			if area.has_point(at) and not house.is_ancestor_of(child) and child != player and not player.is_ancestor_of(child):
				print(region.get_path_to(child), " ", at)
		if child is TileMapLayer and (child as CanvasItem).is_visible_in_tree():
			var layer := child as TileMapLayer
			var n := 0
			for c in layer.get_used_cells():
				if area.has_point(layer.to_global(layer.map_to_local(c))): n += 1
			if n > 0: print("TILES ", region.get_path_to(layer), " ", n)
	quit()
