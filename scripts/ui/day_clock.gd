extends PanelContainer
## HUD clock follows the singleton and never owns the game's time progression.
## Visual do exemplo do usuário (2026-11-23): sol/lua, "Dia 03 · 07:18" e a plaqueta
## do período em painel de madeira com folhas (scripts/ui/hud_skin.gd).

const SKIN := preload("res://scripts/ui/hud_skin.gd")

@onready var clock_label: Label = $ClockText
var period_label: Label
var _icon: TextureRect


func _ready() -> void:
	add_theme_stylebox_override("panel", SKIN.panel(16, 8))
	offset_left = -232
	offset_bottom = offset_top + 64
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_icon = SKIN.icon("res://assets/ui/hud/icon_sun.png", 26)
	row.add_child(_icon)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 1)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	clock_label.reparent(column)
	clock_label.add_theme_font_override("font", SKIN.FONT)
	clock_label.add_theme_font_size_override("font_size", 17)
	clock_label.add_theme_color_override("font_color", SKIN.INK)
	var plaque := PanelContainer.new()
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.add_theme_stylebox_override("panel", SKIN.plaque())
	plaque.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(plaque)
	period_label = SKIN.label("", 12)
	period_label.name = "PeriodText"
	period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.add_child(period_label)
	GameClock.time_changed.connect(_on_time_changed)
	GameClock.period_changed.connect(_on_period_changed)
	_update_display()


func _on_time_changed(_day: int, _hour: int, _minute: int) -> void:
	_update_display()


func _on_period_changed(_period: StringName) -> void:
	_update_display()


func _update_display() -> void:
	clock_label.text = "Dia %02d  •  %s" % [GameClock.day_number, GameClock.get_time_text()]
	# Estação do ano (seasons.gd) junto do período: "Manhã · Primavera".
	period_label.text = "%s · %s" % [GameClock.get_period_label(), preload("res://scripts/systems/seasons.gd").display(GameClock.day_number)]
	var hour: int = GameClock.get_hour()
	var night := hour < 6 or hour >= 19
	_icon.texture = load("res://assets/ui/hud/icon_%s.png" % ("moon" if night else "sun"))
