extends Node2D
## Usa os sprites PixelLab existentes, sem pintura manual de canteiros.
const Scales = preload("res://scripts/world_object_scales.gd")
const SOIL_PREFIX: String = "farm_plot_ground_v2_seamless"
const BED_PREFIX: String = "farm_plot_detailed"
const CROP_PREFIX: String = "crop_growth_stages"
var soil_sprite: Sprite2D
var plant_sprite: Sprite2D
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
	_initialize_visuals()
	_sync_visuals()

func _process(delta: float) -> void:
	if state != State.REGADO:
		return
	growth_remaining -= delta
	if growth_remaining <= 0.0:
		state = State.PRONTO
		set_process(false)
		_sync_visuals()

func target_world_position() -> Vector2:
	return global_position

func accepts_tool(tool_id: String) -> bool:
	return (tool_id == "enxada" and state == State.GRAMA) or (tool_id == "regador" and state == State.PLANTADO)

func tool_action(tool_id: String, _bag: Node) -> String:
	if tool_id == "enxada":
		if state != State.GRAMA:
			return "Solo ja preparado"
		state = State.PREPARADO
		_sync_visuals()
		return "Solo preparado! Pressione E para plantar"
	if tool_id == "regador":
		if state != State.PLANTADO:
			return "Primeiro plante sementes"
		state = State.REGADO
		growth_remaining = growth_seconds
		set_process(true)
		_sync_visuals()
		return "Canteiro regado! Aguarde crescer"
	return "Ferramenta incorreta para este solo"

func accepts_interact() -> bool:
	return state == State.PREPARADO or state == State.PRONTO

func interact_action(bag: Node) -> String:
	if state == State.PREPARADO:
		if not bool(bag.call("take_item", "sementes", 1)):
			return "Sem sementes na mochila"
		state = State.PLANTADO
		_sync_visuals()
		return "-1 semente | Agora regue"
	if state == State.PRONTO:
		if int(bag.call("quantity", "colheita")) > 97:
			return "Mochila cheia de colheitas"
		bag.call("add_item", "colheita", 2)
		bag.call("add_item", "sementes", 1)
		state = State.PREPARADO
		_sync_visuals()
		return "+2 colheitas e +1 semente"
	return "Este canteiro ainda nao pode ser colhido"

func _find_variant(prefix: String, variant: int = 0) -> Texture2D:
	var folders: PackedStringArray = DirAccess.get_directories_at(Scales.ROOT)
	folders.sort()
	var matches: Array[String] = []
	for folder in folders:
		if folder.begins_with(prefix):
			matches.append(folder)
	if matches.is_empty():
		push_warning("Sprite PixelLab nao encontrado: " + prefix)
		return null
	return Scales.preview_texture(Scales.ROOT.path_join(matches[posmod(variant, matches.size())]))


func _initialize_visuals() -> void:
	soil_sprite = Sprite2D.new()
	soil_sprite.name = "CanteiroPixelLab"
	soil_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	soil_sprite.z_index = -2
	add_child(soil_sprite)
	plant_sprite = Sprite2D.new()
	plant_sprite.name = "PlantacaoPixelLab"
	plant_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plant_sprite.z_index = -1
	add_child(plant_sprite)


func _set_art(sprite: Sprite2D, texture: Texture2D, scale_id: String) -> void:
	sprite.texture = texture
	if texture == null:
		return
	sprite.scale = Vector2.ONE * Scales.scale_for(scale_id, texture)
	sprite.offset = Scales.anchor_offset(texture)


func _sync_visuals() -> void:
	if soil_sprite == null or plant_sprite == null:
		return
	soil_sprite.visible = state != State.GRAMA
	plant_sprite.visible = state == State.PLANTADO or state == State.REGADO or state == State.PRONTO
	if not soil_sprite.visible:
		soil_sprite.texture = null
		plant_sprite.texture = null
		return
	var soil: Texture2D = _find_variant(SOIL_PREFIX, 0) if state == State.PREPARADO else _find_variant(BED_PREFIX, 0)
	_set_art(soil_sprite, soil, "farm_plot_detailed" if state != State.PREPARADO else "farm_plot_ground")
	if plant_sprite.visible:
		var stage: int = 2
		if state == State.REGADO:
			stage = 8
		elif state == State.PRONTO:
			stage = 14
		_set_art(plant_sprite, _find_variant(CROP_PREFIX, stage), CROP_PREFIX)
	else:
		plant_sprite.texture = null


