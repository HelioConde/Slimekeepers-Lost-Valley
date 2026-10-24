extends Node2D
## Canteiro da clareira: enxada > E plantar > regador > E colher.
enum State { GRAMA, PREPARADO, PLANTADO, REGADO, PRONTO }

@export var initial_state: State = State.GRAMA
@export_range(3.0, 60.0, 1.0) var growth_seconds: float = 9.0
var state: State = State.GRAMA
var growth_remaining: float = 0.0

func _ready() -> void:
	state = initial_state
	add_to_group("clearing_interactables")
	set_process(state == State.REGADO)
	if state == State.REGADO:
		growth_remaining = growth_seconds
	queue_redraw()

func _process(delta: float) -> void:
	if state != State.REGADO:
		return
	growth_remaining -= delta
	if growth_remaining <= 0.0:
		state = State.PRONTO
		set_process(false)
		queue_redraw()

func target_world_position() -> Vector2:
	return global_position

func accepts_tool(tool_id: String) -> bool:
	return (tool_id == "enxada" and state == State.GRAMA) or (tool_id == "regador" and state == State.PLANTADO)

func tool_action(tool_id: String, _bag: Node) -> String:
	if tool_id == "enxada":
		if state != State.GRAMA:
			return "Solo ja preparado"
		state = State.PREPARADO
		queue_redraw()
		return "Solo preparado! Pressione E para plantar"
	if tool_id == "regador":
		if state != State.PLANTADO:
			return "Primeiro plante sementes"
		state = State.REGADO
		growth_remaining = growth_seconds
		set_process(true)
		queue_redraw()
		return "Canteiro regado! Aguarde crescer"
	return "Ferramenta incorreta para este solo"

func accepts_interact() -> bool:
	return state == State.PREPARADO or state == State.PRONTO

func interact_action(bag: Node) -> String:
	if state == State.PREPARADO:
		if not bool(bag.call("take_item", "sementes", 1)):
			return "Sem sementes na mochila"
		state = State.PLANTADO
		queue_redraw()
		return "-1 semente | Agora regue"
	if state == State.PRONTO:
		if int(bag.call("quantity", "colheita")) > 97:
			return "Mochila cheia de colheitas"
		bag.call("add_item", "colheita", 2)
		bag.call("add_item", "sementes", 1)
		state = State.PREPARADO
		queue_redraw()
		return "+2 colheitas e +1 semente"
	return "Este canteiro ainda nao pode ser colhido"

func _draw() -> void:
	var rect := Rect2(Vector2(-27.0, -21.0), Vector2(54.0, 42.0))
	draw_rect(rect.grow(3.0), Color("#79914c"))
	if state == State.GRAMA:
		draw_rect(rect, Color("#648a40"))
		for i in range(8):
			var gx: float = -20.0 + float((i * 11) % 40)
			var gy: float = -15.0 + float((i * 7) % 28)
			draw_line(Vector2(gx, gy), Vector2(gx + 3.0, gy - 6.0), Color("#9ab45a"), 2.0)
		return
	draw_rect(rect, Color("#67432d"))
	draw_rect(rect.grow(-3.0), Color("#916541"), false, 2.0)
	for i in range(4):
		var y: float = -13.0 + float(i) * 9.0
		draw_line(Vector2(-21.0, y), Vector2(21.0, y), Color("#503421"), 2.0)
	if state == State.PREPARADO:
		return
	if state == State.REGADO:
		draw_rect(rect.grow(-4.0), Color(0.2, 0.3, 0.5, 0.18))
	var leaf_scale: float = 0.7 if state == State.PLANTADO else (1.35 if state == State.PRONTO else 1.0)
	for point in [Vector2(-12.0, -7.0), Vector2(12.0, -7.0), Vector2(-12.0, 10.0), Vector2(12.0, 10.0)]:
		_draw_crop(point, leaf_scale)

func _draw_crop(center: Vector2, size: float) -> void:
	var leaf_color := Color("#67a94e") if state != State.PRONTO else Color("#91ca53")
	var offset: float = 6.0 * size
	draw_line(center + Vector2(0.0, 3.0), center + Vector2(0.0, -offset), Color("#345c2d"), 2.0)
	draw_circle(center + Vector2(-offset * 0.60, -offset * 0.55), 3.4 * size, leaf_color)
	draw_circle(center + Vector2(offset * 0.60, -offset * 0.65), 3.4 * size, leaf_color)
	if state == State.PRONTO:
		draw_circle(center + Vector2(0.0, -5.0), 3.2, Color("#e6a44d"))
