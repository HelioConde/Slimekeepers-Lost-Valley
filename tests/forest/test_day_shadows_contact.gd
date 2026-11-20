extends GdUnitTestSuite

## DayShadows: sombras de contato com a silhueta da base (tronco, pedra, pés),
## curtas ao meio-dia e longas com sol baixo; substituem os blobs elípticos fixos.

const Shadows := preload("res://scripts/world/day_shadows.gd")
const PINE := "res://assets/world/forest/pine_crisp.png"
const ROCK := "res://assets/world/forest/mossy_rock.png"
const FLOWERS := "res://assets/menu/environment/flowers.png"


func _rig() -> Array:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var art := Node2D.new()
	art.name = "MapArt"
	region.add_child(art)
	var tree := Node2D.new()
	tree.position = Vector2(400, 300)
	art.add_child(tree)
	var blob := Polygon2D.new()
	blob.name = "ContactShadow"
	blob.polygon = PackedVector2Array([Vector2(-20, 0), Vector2(0, -6), Vector2(20, 0), Vector2(0, 6)])
	tree.add_child(blob)
	var pine := Sprite2D.new()
	pine.name = "Sprite"
	pine.texture = load(PINE)
	pine.centered = false
	pine.scale = Vector2(2, 2)
	pine.position = Vector2(-96, -182)
	tree.add_child(pine)
	var rock := Sprite2D.new()
	rock.texture = load(ROCK)
	rock.position = Vector2(200, 200)
	art.add_child(rock)
	var flowers := Sprite2D.new()
	flowers.texture = load(FLOWERS)
	flowers.position = Vector2(260, 200)
	art.add_child(flowers)
	var holder := Node2D.new()
	region.add_child(holder)
	var shadows: Node2D = Shadows.new()
	holder.add_child(shadows)
	return [region, shadows, pine, rock, flowers, blob]


func test_contact_is_short_at_noon_long_at_dawn_and_dusk() -> void:
	var noon: Vector2 = Shadows.contact_profile(12 * 60)["vector"]
	var dawn: Vector2 = Shadows.contact_profile(7 * 60)["vector"]
	var dusk: Vector2 = Shadows.contact_profile(18 * 60 + 30)["vector"]
	assert_float(dawn.length()).is_greater(noon.length() * 1.5)
	assert_float(dusk.length()).is_greater(noon.length() * 1.5)
	assert_float(dawn.x).is_less(0.0)
	assert_float(dusk.x).is_greater(0.0)


func test_contact_is_darker_than_cast_shadow_and_continuous() -> void:
	for minute in range(0, 1440, 10):
		var contact: Dictionary = Shadows.contact_profile(minute)
		assert_float(contact["opacity"]).is_greater(Shadows.profile_at(minute)["opacity"])
	for minute in 1440:
		var a: Dictionary = Shadows.contact_profile(minute)
		var b: Dictionary = Shadows.contact_profile(minute + 1)
		assert_float((a["vector"] as Vector2).distance_to(b["vector"])).is_less(0.09)
		assert_float(absf(a["opacity"] - b["opacity"])).is_less(0.02)


func test_contact_strip_is_the_visual_base_of_the_silhouette() -> void:
	var parts := _rig()
	await await_idle_frame()
	var shadows: Node2D = parts[1]
	var pine: Sprite2D = parts[2]
	var strip: Rect2 = shadows.contact_strip(pine)
	assert_float(strip.end.y).is_equal_approx(shadows.ground_bottom(pine), 0.01)
	var world_height := strip.size.y * pine.global_scale.y
	assert_float(world_height).is_between(6.0, 18.0)


func test_solid_objects_get_contact_but_ground_flowers_do_not() -> void:
	var parts := _rig()
	await await_idle_frame()
	var shadows: Node2D = parts[1]
	assert_bool(shadows.has_contact(parts[2])).is_true()
	assert_bool(shadows.has_contact(parts[3])).is_true()
	assert_bool(shadows.has_contact(parts[4])).is_false()


func test_generic_blob_is_replaced_and_restored_on_exit() -> void:
	var parts := _rig()
	await await_idle_frame()
	var shadows: Node2D = parts[1]
	var blob: Polygon2D = parts[5]
	assert_bool(blob.visible).is_false()
	shadows.get_parent().remove_child(shadows)
	assert_bool(blob.visible).is_true()
	shadows.free()


func test_loose_sprite_shadow_starts_at_visible_base_not_padding() -> void:
	var parts := _rig()
	var fern := Sprite2D.new()
	fern.texture = load("res://assets/world/forest/fern.png")
	fern.position = Vector2(500, 500)
	fern.offset.y = -fern.texture.get_height() / 2.0
	(parts[0] as Node2D).get_node("MapArt").add_child(fern)
	await await_idle_frame()
	var shadows: Node2D = parts[1]
	var base_y: float = (fern.global_transform * Vector2(0, shadows.source_bottom(fern))).y
	assert_float(shadows.foot_for(fern).y).is_equal_approx(base_y, 0.01)
	assert_float(base_y).is_less(fern.global_position.y)


func test_running_shadow_keeps_one_ground_line_across_frames() -> void:
	var parts := _rig()
	var body := CharacterBody2D.new()
	body.position = Vector2(600, 400)
	(parts[0] as Node2D).add_child(body)
	var sprite := AnimatedSprite2D.new()
	sprite.position = Vector2(0, -34)
	sprite.scale = Vector2(0.65, 0.65)
	var frames := SpriteFrames.new()
	frames.add_animation("run_north-east")
	for i in 8:
		frames.add_frame("run_north-east", load("res://assets/player/animations/Running/north-east/frame_%03d.png" % i))
	sprite.sprite_frames = frames
	sprite.animation = "run_north-east"
	body.add_child(sprite)
	await await_idle_frame()
	var shadows: Node2D = parts[1]
	var lines: Array[float] = []
	var bottoms: Array[float] = []
	for i in 8:
		sprite.frame = i
		lines.append(shadows.ground_bottom(sprite))
		bottoms.append(shadows.source_bottom(sprite))
	# A base de cada quadro varia (pés no ar), a linha do chão não.
	assert_float(bottoms.max() - bottoms.min()).is_greater(5.0)
	assert_float(lines.max() - lines.min()).is_equal(0.0)
	assert_float(lines[0]).is_equal(bottoms.max())
