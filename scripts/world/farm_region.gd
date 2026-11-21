extends "res://scripts/world/clearing_region.gd"
## Fazenda do jogador: casa (dormir), campo grande de cultivo, borda de árvores e
## caminho para o Vale. Mapa montado por código com arte já existente; a cena
## guarda só a raiz e o jogador.

const Travel = preload("res://scripts/world/region_travel.gd")
const FARM_FIELD := preload("res://scripts/world/farm_field.gd")
const ENERGY := preload("res://scripts/systems/energy_state.gd")
const SAVE := preload("res://scripts/systems/save_game.gd")
const BAG_HUD := preload("res://scripts/ui/forest_bag_hud.gd")
const SURFACE := preload("res://scripts/world/forest_surface.gdshader")
const ATLAS := preload("res://assets/tilesets/grass_dirt_v3_32x32.png")
const COTTAGE := preload("res://assets/menu/environment/cottage.png")
const FENCE := preload("res://assets/menu/environment/fence.png")
const SIGN := preload("res://assets/menu/provided/wood_sign.png")
const LANTERN := preload("res://assets/menu/environment/lantern.png")
const TREES := [
	preload("res://assets/menu/environment/oak.png"), preload("res://assets/menu/environment/oak_medium.png"),
	preload("res://assets/world/forest/oak_young.png"), preload("res://assets/world/forest/pine_crisp.png"),
]
const BUSH := preload("res://assets/sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png")
const FLOWERS := preload("res://assets/menu/environment/flowers.png")

const WORLD_SIZE := Vector2(1600, 1216)
const SPAWN := Vector2(520, 380)  # em frente à porta
const DOOR := Vector2(520, 330)
const WEST_GATE := Vector2(60, 640)
const FIELD_ORIGIN := Vector2i(20, 13)
const FIELD_SIZE := Vector2i(16, 10)
const GRASS_COLOR := Color(0.447, 0.553, 0.271)

var farm_field: Node2D
var bag_hud: Node


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = true
	add_child(PauseOverlay.new())
	player = $Player
	player.position = WEST_GATE + Vector2(60, 0) if get_tree().get_meta("region_arrival", "") == "farm_west" else SPAWN
	if get_tree().has_meta("region_arrival"): get_tree().remove_meta("region_arrival")
	player.world_bounds = Rect2(Vector2(24, 44), WORLD_SIZE - Vector2(48, 68))
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)
	_build_ground()
	_build_border_trees()
	_build_house()
	_build_decor()
	farm_field = FARM_FIELD.new()
	farm_field.field_id = "fazenda"
	farm_field.origin_cell = FIELD_ORIGIN
	farm_field.size_cells = FIELD_SIZE
	farm_field.player = player
	add_child(farm_field)
	_create_hud()
	_compact_hud()
	hud_title.text = "SUA FAZENDA"
	bag_hud = BAG_HUD.new()
	$HUD/Interface.add_child(bag_hud)
	camera.reset_smoothing()


func _process(delta: float) -> void:
	if message_time > 0:
		message_time -= delta
		if message_time <= 0: popup.text = ""
	hud_hint.text = "WASD / Setas: andar   •   1–0: item   •   E: usar"
	if player.global_position.distance_to(DOOR) < 46:
		hud_hint.text = "[E] Dormir até amanhã"
		if Input.is_action_just_pressed("interact"):
			sleep()
		return
	if player.global_position.distance_to(WEST_GATE) < 70:
		hud_hint.text = "[E] Ir para o Vale das Nascentes"
		if Input.is_action_just_pressed("interact"):
			Travel.travel(self, Travel.VALLEY, "valley_farm_gate")
		return
	if is_instance_valid(farm_field) and farm_field.has_target(player):
		hud_hint.text = farm_field.hint(player)
		if player.has_method("is_using_tool") and player.is_using_tool():
			return
		if Input.is_action_just_pressed("interact"):
			var message: String = farm_field.interact(player)
			if not message.is_empty(): _notify(message)


## Dorme até 06:00 do dia seguinte: o dia vira (culturas regadas crescem, terra
## seca) e a energia volta cheia.
func sleep() -> void:
	var minutes := GameClock.get_hour() * 60.0 + GameClock.get_minute()
	var until_morning := (1440.0 - minutes) + 360.0
	GameClock.advance_minutes(until_morning)
	ENERGY.restore(get_tree())
	if is_instance_valid(farm_field): farm_field.refresh()
	var saved := SAVE.save(get_tree(), GameClock, scene_file_path)
	_notify("Bom dia! Dia %d." % GameClock.day_number + ("  Jogo salvo." if saved else ""))


func _update_hud() -> void:
	pass


func _surface(color: Color, origin: Vector2) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("terrain_atlas", ATLAS)
	material.set_shader_parameter("atlas_origin", origin)
	material.set_shader_parameter("texture_strength", 0.48)
	return material


func _build_ground() -> void:
	var floor_node := Node2D.new()
	floor_node.name = "FarmFloor"
	floor_node.z_index = -19
	add_child(floor_node)
	var grass := Polygon2D.new()
	grass.color = GRASS_COLOR
	grass.material = _surface(GRASS_COLOR, Vector2.ZERO)
	grass.polygon = PackedVector2Array([Vector2.ZERO, Vector2(WORLD_SIZE.x, 0), WORLD_SIZE, Vector2(0, WORLD_SIZE.y)])
	floor_node.add_child(grass)
	# Caminho de terra: porta da casa -> portão oeste.
	var path := Polygon2D.new()
	path.name = "PathToValley"
	path.color = Color(0.62, 0.47, 0.30)
	path.material = _surface(path.color, Vector2(192, 64))
	path.z_index = 2
	path.polygon = PackedVector2Array([
		Vector2(0, 616), Vector2(300, 612), Vector2(470, 560), Vector2(496, 352), Vector2(546, 352),
		Vector2(530, 584), Vector2(320, 668), Vector2(0, 668)])
	floor_node.add_child(path)


func _solid(parent: Node2D, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	var body := StaticBody2D.new()
	body.name = "SolidBase"
	body.collision_layer = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = offset
	body.add_child(shape)
	parent.add_child(body)


func _prop(group: Node2D, texture: Texture2D, at: Vector2, scale_factor: float = 1.0) -> Node2D:
	var anchor := Node2D.new()
	anchor.position = at
	group.add_child(anchor)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2.ONE * scale_factor
	var used := texture.get_image().get_used_rect()
	sprite.position = -Vector2(used.position.x + used.size.x * 0.5, used.end.y) * scale_factor
	anchor.add_child(sprite)
	return anchor


## Duas fileiras de árvores na borda (posições fixas por hash), com tronco sólido;
## o portão oeste fica aberto.
func _build_border_trees() -> void:
	var group := Node2D.new()
	group.name = "VegetationHigh"
	group.y_sort_enabled = true
	add_child(group)
	var spots: Array[Vector2] = []
	for x in range(40, int(WORLD_SIZE.x), 110):
		spots.append(Vector2(x, 90)); spots.append(Vector2(x + 50, 180))
		spots.append(Vector2(x, WORLD_SIZE.y - 30)); spots.append(Vector2(x + 50, WORLD_SIZE.y - 110))
	for y in range(250, int(WORLD_SIZE.y) - 120, 110):
		spots.append(Vector2(40, y)); spots.append(Vector2(WORLD_SIZE.x - 40, y)); spots.append(Vector2(WORLD_SIZE.x - 130, y + 55))
	for at in spots:
		if at.distance_to(WEST_GATE) < 120 or Rect2(330, 120, 380, 300).has_point(at):
			continue  # portão e casa livres
		var h := hash(Vector2i(at))
		var tree := _prop(group, TREES[posmod(h, TREES.size())], at + Vector2(posmod(h >> 4, 21) - 10, posmod(h >> 8, 17) - 8), 2.0)
		tree.name = "Tree_%d_%d" % [int(at.x), int(at.y)]
		_solid(tree, Vector2(34, 18), Vector2(0, -8))


func _build_house() -> void:
	var group := Node2D.new()
	group.name = "MapArt"
	group.y_sort_enabled = true
	add_child(group)
	var house := _prop(group, COTTAGE, DOOR + Vector2(0, -4))
	house.name = "House"
	_solid(house, Vector2(170, 56), Vector2(0, -30))
	var lantern := _prop(group, LANTERN, DOOR + Vector2(60, 8))
	lantern.name = "Lantern"
	var sign_post := _prop(group, SIGN, WEST_GATE + Vector2(40, -40))
	sign_post.name = "GateSign"
	# Cerca na borda de cima do campo.
	for i in FIELD_SIZE.x / 2:
		var post := _prop(group, FENCE, Vector2(FIELD_ORIGIN * 32) + Vector2(32 + i * 64, -10))
		post.name = "Fence_%d" % i


func _build_decor() -> void:
	var group := Node2D.new()
	group.name = "Decorations"
	group.y_sort_enabled = true
	add_child(group)
	var field_rect := Rect2(Vector2(FIELD_ORIGIN * 32), Vector2(FIELD_SIZE * 32)).grow(48)
	for i in 40:
		var h := hash(Vector2i(i, 991))
		var at := Vector2(160 + posmod(h, 1280), 260 + posmod(h >> 11, 840))
		if field_rect.has_point(at) or at.distance_to(DOOR) < 160 or Rect2(0, 560, 560, 160).has_point(at):
			continue
		_prop(group, BUSH if i % 3 == 0 else FLOWERS, at)
