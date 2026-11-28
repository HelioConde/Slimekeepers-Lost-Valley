extends PanelContainer
## Lista contextual de receitas no Vale, sem criar receitas canonicas ou menus globais.
const COOKING := preload("res://scripts/systems/valley_cooking.gd")
const FONT := preload("res://assets/fonts/ui_font.tres")  # dígitos legíveis (playtest ID 33)
var details: Label

func _ready() -> void:
	name = "RecipePanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	offset_left = 18
	offset_right = 365
	offset_top = 143
	offset_bottom = 206
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("#e6d8bd")
	skin.border_color = Color("#68544e")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(4)
	skin.set_content_margin_all(6)
	add_theme_stylebox_override("panel", skin)
	details = Label.new()
	details.name = "RecipeList"
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_theme_font_override("font", FONT)
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", Color("#3f4f3a"))
	add_child(details)
	hide()

func refresh(tree: SceneTree) -> void:
	var entries: Array[Dictionary] = COOKING.recipe_options(tree)
	var lines: PackedStringArray = ["Receitas disponiveis (prototipo):"]
	for entry in entries:
		var label_text := str(entry.get("label", "Receita"))
		if bool(entry.get("available", false)):
			lines.append("  %s - pronta para preparar [F]" % label_text)
		else:
			var missing: Dictionary = entry.get("missing", {})
			if missing.is_empty():
				lines.append("  %s - indisponivel" % label_text)
			else:
				lines.append("  %s - falta %d folha(s)" % [label_text, int(missing.get("folhas_frescas", 0))])
	details.text = "\n".join(lines)
