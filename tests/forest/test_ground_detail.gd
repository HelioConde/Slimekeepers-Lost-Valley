extends GdUnitTestSuite

## GroundDetail (V6): detalhe de chão por terreno, sem cobrir caminhos, o ponto
## de início, os slimes ou os troncos; o mesmo mapa sempre recebe o mesmo arranjo.

const Detail := preload("res://scripts/world/ground_detail.gd")
const Layout := preload("res://scripts/world/clearing_layout.gd")
const AREA := Rect2(1230, 1280, 380, 640)


func _build(feet: Array[Vector2] = []) -> Node2D:
	var detail: Node2D = auto_free(Detail.new())
	detail.area = AREA
	detail.tree_feet = feet
	detail.build()
	return detail


func test_keeps_paths_spawn_slimes_and_trunks_clear() -> void:
	var feet: Array[Vector2] = [Vector2(1300, 1500), Vector2(1280, 1700)]
	var detail := _build(feet)
	assert_int(detail.placed.size()).is_greater(20)
	var paths := Layout.trails()
	for item in detail.placed:
		var at: Vector2 = item.at
		# Grupos espalham até ~15 px em volta do ponto da célula.
		assert_float(Layout.trail_distance(at, paths)).is_greater(Detail.TRAIL_FREE - 16.0)
		assert_float(at.distance_to(Layout.SPAWN)).is_greater(Detail.SPAWN_FREE - 16.0)
		for foot in feet:
			assert_float(at.distance_to(foot)).is_greater(26.0 - 16.0)


func test_zones_choose_kinds_by_terrain() -> void:
	var feet: Array[Vector2] = [Vector2(1300, 1500)]
	var detail := _build(feet)
	var paths := Layout.trails()
	assert_str(detail.zone_at(Layout.SPAWN, paths)).is_equal("")
	assert_str(detail.zone_at(Vector2(1300, 1550), paths)).is_equal("root")
	var kinds := {}
	for item in detail.placed:
		kinds[item.kind] = true
	# Flores em grupo na clareira aberta e folhas caídas junto às raízes.
	assert_bool(kinds.has("fallen_leaves") or kinds.has("clover_sprig")).is_true()
	assert_bool(kinds.has("wildflower_yellow") or kinds.has("wildflower_lilac")).is_true()


func test_is_deterministic_and_not_uniform() -> void:
	var a := _build()
	var b := _build()
	assert_int(a.placed.size()).is_equal(b.placed.size())
	for i in a.placed.size():
		assert_vector(a.placed[i].at).is_equal(b.placed[i].at)
	# Não uniforme: há células vazias (a clareira mantém espaços abertos).
	var cells := (AREA.size / Detail.CELL).ceil()
	assert_int(a.placed.size()).is_less(int(cells.x * cells.y) * 2)


func test_sits_below_characters() -> void:
	var detail := _build()
	assert_int(detail.z_index).is_less(0)
	assert_vector(detail.position).is_equal(Vector2(1600, 1600))


func test_bushes_only_frame_the_clearing_and_avoid_props() -> void:
	var holder: Node2D = auto_free(Node2D.new())
	var rock := Node2D.new()
	rock.position = Vector2(1600, 1290)  # pedra já existente perto da borda norte
	holder.add_child(rock)
	var detail: Node2D = auto_free(Detail.new())
	detail.bush_parent = holder
	detail.build()
	var paths := Layout.trails()
	var bushes: Array = detail.placed.filter(func(item): return item.kind == "bush")
	assert_int(bushes.size()).is_greater(0)
	for item in bushes:
		var at: Vector2 = item.at
		# Moldura: dentro da borda da clareira, fora do miolo aberto e longe de caminhos.
		assert_bool(Layout.inside_clearing(at, 40.0)).is_true()
		assert_bool(Layout.inside_clearing(at, 40.0 - Detail.RIM_DEPTH)).is_false()
		assert_float(Layout.trail_distance(at, paths)).is_greater(80.0)
		assert_float(at.distance_to(rock.position)).is_greater_equal(70.0)


func test_open_clearing_stays_mostly_open() -> void:
	var detail := _build()
	var flowers: Array = detail.placed.filter(func(item): return str(item.kind).begins_with("wildflower"))
	# Flores são destaque, não tapete: minoria do que foi posto.
	assert_float(float(flowers.size()) / maxf(1.0, detail.placed.size())).is_less(0.5)


func test_nothing_is_placed_in_reserved_water() -> void:
	var detail: Node2D = auto_free(Detail.new())
	var pond := {"center": Vector2(1905, 1425), "radius": Vector2(86, 46)}
	detail.avoid.append(pond)
	detail.build()
	for item in detail.placed:
		var at: Vector2 = item.at
		assert_float(((at - pond.center) / (pond.radius + Vector2(70, 60))).length()).is_greater_equal(0.9)
