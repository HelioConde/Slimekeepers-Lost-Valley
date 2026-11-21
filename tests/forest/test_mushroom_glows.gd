extends GdUnitTestSuite

## Brilho dos cogumelos (V9): poças de luz no chão nos cogumelos reais mais
## próximos; ciano só à noite, quente já ao entardecer; nada sobre as copas.

const Glows := preload("res://scripts/world/mushroom_glows.gd")


func _rig() -> Array:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var glow := Sprite2D.new()
	glow.texture = load("res://assets/world/forest/mushroom_glow.png")
	glow.position = Vector2(100, 0)
	region.add_child(glow)
	var red := Sprite2D.new()
	red.texture = load("res://assets/world/forest/mushroom_red.png")
	red.position = Vector2(-100, 0)
	region.add_child(red)
	var hidden := Sprite2D.new()
	hidden.texture = load("res://assets/world/forest/mushroom_glow.png")
	hidden.position = Vector2(0, 50)
	hidden.visible = false
	region.add_child(hidden)
	var glows: Node2D = Glows.new()
	glows.setup(region)
	region.add_child(glows)
	return [glows, glow, red]


func _visible(glows: Node2D) -> Array:
	return glows.pools.filter(func(p): return p.visible)


func test_only_real_visible_mushrooms_get_halos() -> void:
	var glows: Node2D = _rig()[0]
	glows.apply_time(23 * 60, Vector2.ZERO, 0.1)
	assert_int(_visible(glows).size()).is_equal(2)


func test_cyan_at_night_warm_from_dusk() -> void:
	var glows: Node2D = _rig()[0]
	glows.apply_time(12 * 60, Vector2.ZERO, 0.1)
	for p in _visible(glows): assert_float(p.modulate.a).is_equal(0.0)
	glows.apply_time(18 * 60, Vector2.ZERO, 0.1)
	var warm: Array = _visible(glows).filter(func(p): return p.get_meta("warm"))
	assert_float(warm[0].modulate.a).is_greater(0.05)
	glows.apply_time(23 * 60, Vector2.ZERO, 0.1)
	for p in _visible(glows): assert_float(p.modulate.a).is_greater(0.1)


func test_halos_never_draw_over_canopy_and_cast_no_shadow() -> void:
	var glows: Node2D = _rig()[0]
	for cap in glows.caps: assert_int(cap.z_index).is_less(0)
	for p in glows.pools:
		assert_int(p.z_index).is_less(0)
		assert_bool(p.has_meta("no_shadow")).is_true()


func test_only_some_flowers_are_magic_and_glow_at_their_base() -> void:
	var region: Node2D = auto_free(Node2D.new())
	add_child(region)
	var magic := 0
	for i in 40:
		var flower := Sprite2D.new()
		flower.texture = load("res://assets/world/forest/wildflowers_cluster.png")
		flower.centered = false
		flower.position = Vector2(i * 37, 0)
		region.add_child(flower)
		if Glows.magic_flower(flower.global_position): magic += 1
	var glows: Node2D = Glows.new()
	glows.setup(region)
	region.add_child(glows)
	glows.apply_time(23 * 60, Vector2(700, 0), 0.1)
	var lit: Array = glows.pools.filter(func(p): return p.visible)
	assert_int(lit.size()).is_equal(magic)
	assert_int(magic).is_between(4, 20)
	for p in lit:
		# Na base do desenho (sprite não centrado): ~40 px abaixo da origem.
		assert_float(p.position.y).is_greater(20.0)
