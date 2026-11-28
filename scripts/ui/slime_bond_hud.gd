extends PanelContainer
## Slime por perto (exemplo do usuário, 2026-11-23): retrato, nome e os corações do
## laço (slime_feeding). Aparece sob a energia só com um slime perto do jogador.

const SKIN := preload("res://scripts/ui/hud_skin.gd")
const FEEDING := preload("res://scripts/systems/slime_feeding.gd")
const SHOWN_HEARTS := 5  # corações visíveis (de MAX_HEARTS); cada um = MAX/5 do laço

## Devolve o slime mais próximo (ou null); a região liga isto ao seu _closest_slime.
var source: Callable
var _portrait: TextureRect
var _name: Label
var _role: Label  ## função e comida favorita
const ROLES := preload("res://scripts/world/farm_helpers.gd").ROLES
const ROLE_NAMES := {"plantar": "Planta", "regar": "Rega", "adubar": "Aduba", "colher": "Colhe", "carregar": "Carrega ao baú"}
const FOOD_NAMES := {"vegetal": "vegetais", "fruta": "frutas", "marinha": "comida do mar", "cozido": "pratos cozidos"}
var _hearts: HBoxContainer
var _full: Texture2D
var _empty: Texture2D


func _ready() -> void:
	name = "SlimeBond"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -232
	offset_right = -18
	offset_top = 202
	offset_bottom = 266
	add_theme_stylebox_override("panel", SKIN.panel(14, 8))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_portrait = SKIN.icon("", 30)
	row.add_child(_portrait)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	_name = SKIN.label("", 14)
	column.add_child(_name)
	_role = SKIN.label("", 10)
	column.add_child(_role)
	_hearts = HBoxContainer.new()
	_hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hearts.add_theme_constant_override("separation", 2)
	column.add_child(_hearts)
	_full = SKIN.heart(true)
	_empty = SKIN.heart(false)
	for i in SHOWN_HEARTS:
		var h := TextureRect.new()
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.custom_minimum_size = Vector2(14, 12)
		_hearts.add_child(h)


func _process(_delta: float) -> void:
	var slime: Node2D = source.call() if source.is_valid() else null
	visible = is_instance_valid(slime)
	if not visible: return
	_name.text = str(slime.call("display_name"))
	var species := str(slime.get("slime_type"))
	var parts: PackedStringArray = []
	if ROLES.has(species): parts.append(ROLE_NAMES.get(ROLES[species], ""))
	var liked: String = FEEDING.LIKES.get(species, "")
	if not liked.is_empty(): parts.append("gosta de " + str(FOOD_NAMES.get(liked, liked)))
	_role.text = " · ".join(parts)
	var sprite := slime.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null and sprite.sprite_frames != null:
		_portrait.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var hearts: int = FEEDING.hearts(get_tree(), str(slime.get("persistent_id")))
	var lit := ceili(float(hearts) * SHOWN_HEARTS / FEEDING.MAX_HEARTS)
	for i in SHOWN_HEARTS:
		(_hearts.get_child(i) as TextureRect).texture = _full if i < lit else _empty
