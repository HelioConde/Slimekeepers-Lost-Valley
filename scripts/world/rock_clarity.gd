extends RefCounted
## Replace the soft illustrated tall rock without changing feet or solid bases.
const SOFT_ROCK := "res://assets/world/forest/mossy_rock_tall.png"
const CRISP_ROCK := "res://assets/menu/environment/stone.png"
const FERN := "res://assets/world/forest/fern.png"

func apply(scene: Node2D) -> int:
	var replaced := 0
	var texture: Texture2D = load(CRISP_ROCK)
	var used := texture.get_image().get_used_rect()
	for prop: Node2D in scene.get_node("Decorations").get_children():
		var sprite := prop.get_node_or_null("Sprite") as Sprite2D
		if sprite == null or sprite.texture.resource_path != SOFT_ROCK:
			continue
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2(2,2)
		var middle := float(used.position.x)+float(used.size.x)*0.5
		if sprite.flip_h:
			middle = texture.get_width()-middle
		sprite.position = -Vector2(middle,used.end.y-2)*2
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var fern := Sprite2D.new()
		fern.name = "RockFern"
		fern.texture = load(FERN)
		var fern_bounds := fern.texture.get_image().get_used_rect()
		fern.offset = fern.texture.get_size()*0.5-Vector2(fern_bounds.position.x+fern_bounds.size.x*0.5,fern_bounds.end.y)
		fern.position = Vector2(-8,-31)
		fern.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		prop.add_child(fern)
		fern.owner = scene
		prop.move_child(fern,sprite.get_index())
		prop.set_meta("crisp_rock",true)
		replaced += 1
	return replaced
