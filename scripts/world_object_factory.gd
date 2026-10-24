extends RefCounted
const WorldObject = preload("res://scenes/world_object.tscn")

static func place(parent: Node2D, folder: String, position: Vector2, solid: bool = false, variation: float = 1.0) -> Node2D:
	var item: Node2D = WorldObject.instantiate() as Node2D
	item.set("asset_folder", folder)
	item.set("solid", solid)
	item.set("variation", variation)
	item.position = position
	parent.add_child(item)
	return item
