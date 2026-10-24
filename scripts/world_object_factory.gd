extends RefCounted
## Exemplo: WorldObjectFactory.place($WorldObjects, "rock_small_...", Vector2(100, 80), true)
## Todas as instancias usam o mesmo dimensionamento da vitrine.
const Scene: PackedScene = preload("res://scenes/world_object.tscn")

static func place(parent: Node2D, folder_or_id: String, at: Vector2, with_collision: bool = false, variation: float = 1.0) -> Node2D:
	var item: Node2D = Scene.instantiate() as Node2D
	item.set("asset_folder", folder_or_id)
	item.set("solid", with_collision)
	item.set("variation", variation)
	item.position = at
	parent.add_child(item)
	return item
