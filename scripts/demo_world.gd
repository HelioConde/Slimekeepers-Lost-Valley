extends Node2D
## Cenario de teste sem tilesets externos. Pode ser substituido pelo mapa final.

const GRID_SIZE: int = 32
const GRID_LEFT: int = -20
const GRID_RIGHT: int = 20
const GRID_TOP: int = -13
const GRID_BOTTOM: int = 13
const GRASS_A: Color = Color("335c3d")
const GRASS_B: Color = Color("3a6543")
const DIRT: Color = Color("806f4b")
const ROCK: Color = Color("71837e")
const ROCK_SHADOW: Color = Color("465b58")
const OBSTACLES: Array[Vector2] = [
	Vector2(-192, -96), Vector2(-128, 96), Vector2(160, -80),
	Vector2(224, 112), Vector2(-288, 176), Vector2(96, 192)
]


func _ready() -> void:
	_create_obstacle_collisions()


func _draw() -> void:
	for ty in range(GRID_TOP, GRID_BOTTOM + 1):
		for tx in range(GRID_LEFT, GRID_RIGHT + 1):
			var cell := Vector2(tx * GRID_SIZE, ty * GRID_SIZE)
			var grass := GRASS_A if posmod(tx * 7 + ty * 11, 5) < 2 else GRASS_B
			draw_rect(Rect2(cell, Vector2(GRID_SIZE, GRID_SIZE)), grass)
			# Trilhas: um eixo horizontal e outro vertical.
			if absf(cell.y) < 28.0 or absf(cell.x) < 24.0:
				draw_rect(Rect2(cell, Vector2(GRID_SIZE, GRID_SIZE)), DIRT)
			draw_rect(Rect2(cell, Vector2(GRID_SIZE, GRID_SIZE)), Color(0, 0, 0, 0.05), false, 1.0)

	for position_2d in OBSTACLES:
		draw_circle(position_2d + Vector2(2, 5), 16.0, Color(0, 0, 0, 0.25))
		draw_circle(position_2d, 14.0, ROCK_SHADOW)
		draw_circle(position_2d + Vector2(-3, -4), 10.0, ROCK)

	# Limites aproximados do cenario de teste.
	var area := Rect2(
		Vector2(GRID_LEFT * GRID_SIZE, GRID_TOP * GRID_SIZE),
		Vector2((GRID_RIGHT - GRID_LEFT + 1) * GRID_SIZE, (GRID_BOTTOM - GRID_TOP + 1) * GRID_SIZE)
	)
	draw_rect(area, Color("c8b481"), false, 4.0)


func _create_obstacle_collisions() -> void:
	for point in OBSTACLES:
		var body := StaticBody2D.new()
		body.position = point
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)

		var collider := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		collider.shape = shape
		body.add_child(collider)

	# Colisores do contorno para evitar sair da area desenhada.
	var min_x := float(GRID_LEFT * GRID_SIZE)
	var max_x := float((GRID_RIGHT + 1) * GRID_SIZE)
	var min_y := float(GRID_TOP * GRID_SIZE)
	var max_y := float((GRID_BOTTOM + 1) * GRID_SIZE)
	_add_wall(Vector2((min_x + max_x) / 2.0, min_y), Vector2(max_x - min_x, 12))
	_add_wall(Vector2((min_x + max_x) / 2.0, max_y), Vector2(max_x - min_x, 12))
	_add_wall(Vector2(min_x, (min_y + max_y) / 2.0), Vector2(12, max_y - min_y))
	_add_wall(Vector2(max_x, (min_y + max_y) / 2.0), Vector2(12, max_y - min_y))


func _add_wall(where: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = where
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
