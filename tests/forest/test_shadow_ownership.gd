extends GdUnitTestSuite

## Toda sombra precisa de dono: pedras da borda das cachoeiras e a fogueira projetam
## sombra própria; blobs pintados sob objetos que boiam (vitórias-régias) somem.

const Shadows := preload("res://scripts/world/day_shadows.gd")
const STONE := "res://assets/world/forest/mossy_rock.png"
const LILY := "res://assets/world/valley/lily_pad.png"


func _anchored(parent: Node, at: Vector2, texture: String, with_blob := true) -> Array:
	var anchor := Node2D.new()
	anchor.position = at
	parent.add_child(anchor)
	var blob := Polygon2D.new()
	blob.name = "ContactShadow"
	blob.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(0, -3), Vector2(10, 0), Vector2(0, 3)])
	if with_blob: anchor.add_child(blob)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load(texture)
	sprite.offset.y = -sprite.texture.get_height() / 2.0
	anchor.add_child(sprite)
	return [sprite, blob]


func _rig() -> Dictionary:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var falls := Node2D.new()
	falls.name = "Waterfalls"
	region.add_child(falls)
	var fall := Node2D.new()
	fall.name = "Waterfall1"
	falls.add_child(fall)
	var cascade := Sprite2D.new()
	cascade.name = "Cascade"
	cascade.texture = load("res://assets/world/valley/waterfall_medium.png")
	fall.add_child(cascade)
	var lip: Array = _anchored(fall, Vector2(30, -90), STONE)
	var water := Node2D.new()
	water.name = "WaterDecorations"
	region.add_child(water)
	var lily: Array = _anchored(water, Vector2(200, 200), LILY)
	var station: Node2D = preload("res://scripts/world/valley_cooking_station.gd").new()
	station.position = Vector2(400, 300)
	region.add_child(station)
	var holder := Node2D.new()
	region.add_child(holder)
	var shadows: Node2D = Shadows.new()
	holder.add_child(shadows)
	return {"shadows": shadows, "lip": lip, "lily": lily, "cascade": cascade, "station": station}


func test_waterfall_lip_stones_cast_and_replace_their_blob() -> void:
	var rig := _rig()
	await await_idle_frame()
	var shadows: Node2D = rig.shadows
	assert_bool(shadows.has_caster(rig.lip[0])).is_true()
	assert_bool(shadows.has_contact(rig.lip[0])).is_true()
	assert_bool((rig.lip[1] as Polygon2D).visible).is_false()
	# O véu d'água não é sólido: não projeta silhueta no chão.
	assert_bool(shadows.has_caster(rig.cascade)).is_false()


func test_cooking_station_fire_pit_casts_a_shadow() -> void:
	var rig := _rig()
	await await_idle_frame()
	var art: Sprite2D = (rig.station as Node2D).get_node("Art")
	assert_bool(rig.shadows.has_caster(art)).is_true()
	assert_bool(rig.shadows.has_contact(art)).is_true()


func test_floating_lily_pads_lose_their_painted_blob() -> void:
	var rig := _rig()
	await await_idle_frame()
	assert_bool(rig.shadows.has_caster(rig.lily[0])).is_false()
	assert_bool((rig.lily[1] as Polygon2D).visible).is_false()
	rig.shadows.get_parent().remove_child(rig.shadows)
	assert_bool((rig.lily[1] as Polygon2D).visible).is_true()
	rig.shadows.free()


func test_tree_shadow_stays_under_its_own_canopy() -> void:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var art := Node2D.new()
	art.name = "MapArt"
	region.add_child(art)
	var tree := Node2D.new()
	tree.position = Vector2(400, 400)
	art.add_child(tree)
	var oak := Sprite2D.new()
	oak.name = "Sprite"
	oak.texture = load("res://assets/menu/environment/oak.png")
	oak.centered = false
	oak.scale = Vector2(2, 2)
	oak.position = Vector2(-96, -182)
	tree.add_child(oak)
	var holder := Node2D.new()
	region.add_child(holder)
	var shadows: Node2D = Shadows.new()
	holder.add_child(shadows)
	await await_idle_frame()
	for minutes in [7 * 60, 12 * 60, 16 * 60 + 30, 18 * 60 + 30]:
		GameClock.set_time(minutes / 60, minutes % 60)
		shadows.update_for_time(0.016)
		var direction: Vector2 = shadows.cast_direction(oak)
		var height := oak.get_rect().size.y * oak.global_scale.y
		# Deslocamento do topo da copa: curto, a sombra fica colada ao tronco.
		assert_float((direction * height).length()).is_less_equal(Shadows.MAX_TREE_CAST + 0.5)
	# Personagens continuam com a altura inteira (a sombra do jogador não muda).
	assert_float(Shadows.height_factor("player", "")).is_equal(1.0)
	assert_float(Shadows.height_factor("tree", "oak.png")).is_less(0.5)
	assert_float(Shadows.height_factor("object", "mossy_rock.png")).is_less(0.4)


func test_code_drawn_garden_bed_casts_a_box_shadow() -> void:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var bed: Node2D = preload("res://scripts/world/valley_garden_bed.gd").new()
	bed.position = Vector2(300, 300)
	region.add_child(bed)
	var holder := Node2D.new()
	region.add_child(holder)
	var shadows: Node2D = Shadows.new()
	holder.add_child(shadows)
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(bed.is_in_group("shadow_boxes")).is_true()
	assert_bool(shadows.has_box(bed)).is_true()
	var footprint: Rect2 = bed.shadow_footprint()
	assert_float(footprint.size.x).is_greater(40.0)
