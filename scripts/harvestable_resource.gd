extends Node
## Componente que transforma um sprite em um recurso coletavel.
@export var required_tool: String = "machado"
@export var reward_item: String = "madeira"
@export var reward_quantity: int = 1
@export var remaining_hits: int = 2
var display_name: String = "Recurso"

func configure(tool_id: String, item_id: String, amount: int, hits: int, label: String) -> void:
	required_tool = tool_id
	reward_item = item_id
	reward_quantity = maxi(1, amount)
	remaining_hits = maxi(1, hits)
	display_name = label

func _ready() -> void:
	add_to_group("clearing_interactables")

func target_world_position() -> Vector2:
	var parent_2d: Node2D = get_parent() as Node2D
	return parent_2d.global_position if parent_2d != null else Vector2.ZERO

func accepts_tool(tool_id: String) -> bool:
	return tool_id == required_tool

func tool_action(tool_id: String, bag: Node) -> String:
	if tool_id != required_tool:
		return "Ferramenta incorreta para " + display_name
	remaining_hits -= 1
	if remaining_hits > 0:
		var sprite: Sprite2D = get_parent().get_node_or_null("Artwork") as Sprite2D
		if sprite != null:
			sprite.modulate = Color(1.0, 0.83, 0.75)
		return "%s: faltam %d golpes" % [display_name, remaining_hits]
	var added: int = int(bag.call("add_item", reward_item, reward_quantity))
	get_parent().queue_free()
	return "+%d %s" % [added, reward_item] if added > 0 else "Mochila cheia"

func accepts_interact() -> bool:
	return required_tool == "mao"

func interact_action(bag: Node) -> String:
	if not accepts_interact():
		return "Use a ferramenta adequada"
	return tool_action("mao", bag)
