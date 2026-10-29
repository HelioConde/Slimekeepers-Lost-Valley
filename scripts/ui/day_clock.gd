extends PanelContainer
## HUD clock follows the singleton and never owns the game's time progression.

@onready var clock_label: Label = $ClockText


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f6e8c2")
	style.border_color = Color("694657")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	add_theme_stylebox_override("panel", style)
	clock_label.add_theme_font_override("font", preload("res://assets/fonts/PixelifySans.ttf"))
	clock_label.add_theme_color_override("font_color", Color("4c4350"))
	GameClock.time_changed.connect(_on_time_changed)
	GameClock.period_changed.connect(_on_period_changed)
	_update_display()


func _on_time_changed(_day: int, _hour: int, _minute: int) -> void:
	_update_display()


func _on_period_changed(_period: StringName) -> void:
	_update_display()


func _update_display() -> void:
	clock_label.text = "Dia %02d  •  %s\n%s" % [
		GameClock.day_number,
		GameClock.get_time_text(),
		GameClock.get_period_label()
	]
