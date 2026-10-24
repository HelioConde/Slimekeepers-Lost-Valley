extends Node2D
## Controle: 1-4 selecionam, F ou clique usa a ferramenta, E interage.
signal selected_tool_changed(index: int)
signal feedback(message: String)

const TOOL_IDS: Array[String] = ["machado", "picareta", "enxada", "regador"]
const TOOL_LABELS: Array[String] = ["MACHADO", "PICARETA", "ENXADA", "REGADOR"]
const COLORS: Array[Color] = [
	Color("#d5b080"), Color("#a8bec6"), Color("#c1a66e"), Color("#69b6cf")
]
const REACH: float = 74.0
const COOLDOWN: float = 0.36

@onready var character: CharacterBody2D = get_parent() as CharacterBody2D
@onready var inventory: Node = get_node("../../../Inventory")
var selected_index: int = 0
var _cooldown_left: float = 0.0

func _process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)

func _unhandled_input(event: InputEvent) -> void:
	# A ferramenta equipada nao deve agir enquanto o editor da casa usa o mouse.
	var house: Node = get_tree().get_first_node_in_group("slv_house_builder")
	if house != null and bool(house.call("is_building")):
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.physical_keycode >= KEY_1 and key.physical_keycode <= KEY_4:
			select_tool(key.physical_keycode - KEY_1)
			get_viewport().set_input_as_handled()
		elif key.physical_keycode == KEY_F:
			use_selected_tool()
			get_viewport().set_input_as_handled()
		elif key.physical_keycode == KEY_E:
			interact()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			use_selected_tool()
			get_viewport().set_input_as_handled()

func select_tool(index: int) -> void:
	if index < 0 or index >= TOOL_IDS.size():
		return
	selected_index = index
	selected_tool_changed.emit(index)
	feedback.emit("Ferramenta: " + TOOL_LABELS[index].capitalize())

func use_selected_tool() -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = COOLDOWN
	if character.has_method("play_tool_animation"):
		character.call("play_tool_animation", TOOL_IDS[selected_index])
	var target: Node = _nearest_target(TOOL_IDS[selected_index], false)
	if target == null:
		feedback.emit("Chegue mais perto e olhe para o alvo")
		return
	feedback.emit(String(target.call("tool_action", TOOL_IDS[selected_index], inventory)))

func interact() -> void:
	if _cooldown_left > 0.0:
		return
	var target: Node = _nearest_target("", true)
	if target == null:
		feedback.emit("Nada para interagir aqui")
		return
	_cooldown_left = COOLDOWN
	if character.has_method("play_tool_animation"):
		character.call("play_tool_animation", "interact")
	feedback.emit(String(target.call("interact_action", inventory)))

func _nearest_target(tool_id: String, for_interaction: bool) -> Node:
	var forward: Vector2 = _facing_vector()
	var closest_score: float = INF
	var closest: Node = null
	for entry in get_tree().get_nodes_in_group("clearing_interactables"):
		var target: Node = entry as Node
		if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
			continue
		if not target.has_method("target_world_position"):
			continue
		if for_interaction:
			if not bool(target.call("accepts_interact")):
				continue
		elif not bool(target.call("accepts_tool", tool_id)):
			continue
		var location: Vector2 = target.call("target_world_position")
		var offset: Vector2 = location - character.global_position
		var distance: float = offset.length()
		if distance > REACH:
			continue
		var alignment: float = offset.normalized().dot(forward) if distance > 1.0 else 1.0
		if distance > 29.0 and alignment < 0.10:
			continue
		var score: float = distance - alignment * 14.0
		if score < closest_score:
			closest_score = score
			closest = target
	return closest

func _facing_vector() -> Vector2:
	var direction: String = str(character.get("facing"))
	match direction:
		"north": return Vector2.UP
		"north-east": return Vector2(1, -1).normalized()
		"east": return Vector2.RIGHT
		"south-east": return Vector2(1, 1).normalized()
		"south": return Vector2.DOWN
		"south-west": return Vector2(-1, 1).normalized()
		"west": return Vector2.LEFT
		"north-west": return Vector2(-1, -1).normalized()
	return Vector2.DOWN

