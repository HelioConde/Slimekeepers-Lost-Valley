extends GdUnitTestSuite

## A estação de culinária reutiliza a fogueira PixelLab já exportada (sem nova
## geração), em pixel art nítida e sem colisão.

const Station := preload("res://scripts/world/valley_cooking_station.gd")
const ART := "res://assets/objects/pixellab_exports/campfire_unlit_compact_64x48_292e36a0/campfire_unlit_compact_64x48.png"


func _spawn() -> Node2D:
	var station: Node2D = Station.new()
	add_child(station)
	auto_free(station)
	return station


func test_station_uses_existing_pixellab_campfire() -> void:
	var station := _spawn()
	var sprite := station.get_node_or_null("Art") as Sprite2D
	assert_object(sprite).is_not_null()
	assert_str(sprite.texture.resource_path).is_equal(ART)
	assert_int(station.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)


func test_station_base_sits_on_its_origin_for_y_sort() -> void:
	var station := _spawn()
	var sprite := station.get_node("Art") as Sprite2D
	var rect := sprite.get_rect()
	var bottom := rect.position.y + rect.size.y + sprite.position.y
	assert_float(bottom).is_between(8.0, 20.0)


func test_station_keeps_name_and_has_no_collision() -> void:
	var station := _spawn()
	assert_str(station.name).is_equal("CookingStation")
	assert_array(station.find_children("*", "CollisionObject2D", true, false)).is_empty()
