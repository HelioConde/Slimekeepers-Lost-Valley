extends Node
## Global in-game time. Runs only while playing; persists between region scenes.
##
## The six periods are:
## 00:00-04:59 madrugada, 05:00-08:59 manha, 09:00-14:59 dia,
## 15:00-17:59 tarde, 18:00-19:59 anoitecendo, 20:00-23:59 noite.

signal time_changed(day: int, hour: int, minute: int)
signal period_changed(period: StringName)
signal day_changed(day: int)
## One bounded notification for sleep/fast-forward; days_passed can exceed one.
signal time_advanced(minutes: float, days_passed: int)

const MINUTES_PER_DAY: float = 1440.0
const START_MINUTE: float = 7.0 * 60.0

## Color keyframes, interpolated smoothly for pixel-art friendly ambient light.
## The last keyframe repeats the first, avoiding flashes at midnight.
const LIGHTING_STOPS = [
	[0, Color(0.46, 0.54, 0.75)],
	[180, Color(0.43, 0.50, 0.69)],
	[270, Color(0.51, 0.56, 0.73)],
	[300, Color(0.62, 0.58, 0.72)],
	[420, Color(1.0, 0.93, 0.83)],
	[540, Color(1.0, 1.0, 1.0)],
	[900, Color(1.0, 1.0, 1.0)],
	[1020, Color(0.99, 0.84, 0.70)],
	[1080, Color(0.88, 0.72, 0.75)],
	[1170, Color(0.65, 0.62, 0.73)],
	[1200, Color(0.57, 0.65, 0.87)],
	[1320, Color(0.53, 0.61, 0.84)],
	[1380, Color(0.49, 0.57, 0.79)],
	[1440, Color(0.46, 0.54, 0.75)]
]

## Editable: 24 real minutes = one in-game day; one real second = one in-game minute.
@export_range(60.0, 7200.0, 60.0) var seconds_per_game_day: float = 1440.0:
	set(value):
		seconds_per_game_day = value if is_finite(value) and value > 0.0 else 1440.0

var day_number: int = 1
var _minutes_of_day: float = START_MINUTE
var _running: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	seconds_per_game_day = float(ProjectSettings.get_setting("game/time/seconds_per_day", 1440.0))
	set_process(false)


func _process(delta: float) -> void:
	if not _running or get_tree().paused:
		return
	advance_minutes(delta * MINUTES_PER_DAY / seconds_per_game_day)


func start() -> void:
	if _running: return
	_running = true
	set_process(true)
	_emit_clock_state()


func stop() -> void:
	_running = false
	set_process(false)


func is_running() -> bool:
	return _running


func reset_new_game() -> void:
	stop()
	day_number = 1
	_minutes_of_day = START_MINUTE
	day_changed.emit(day_number)
	_emit_clock_state()


func advance_minutes(minutes: float) -> void:
	## Public helper for sleeping, later farming mechanics and automated tests.
	if not is_finite(minutes) or minutes <= 0.0 or minutes > 1440.0 * 1000000.0:
		return
	var old_minute: int = int(floor(_minutes_of_day))
	var old_period: StringName = get_period()
	var new_total: float = _minutes_of_day + minutes
	var days_passed: int = int(floor(new_total / MINUTES_PER_DAY))
	_minutes_of_day = fposmod(new_total, MINUTES_PER_DAY)
	if days_passed > 0:
		day_number += days_passed
		day_changed.emit(day_number)
	if old_minute != int(floor(_minutes_of_day)) or days_passed > 0:
		time_changed.emit(day_number, get_hour(), get_minute())
	var current_period: StringName = get_period()
	if current_period != old_period:
		period_changed.emit(current_period)
	time_advanced.emit(minutes, days_passed)


func set_time(hour: int, minute: int = 0) -> void:
	## Used for editor checks and future loading of saved game time.
	var old_period: StringName = get_period()
	_minutes_of_day = float(clampi(hour, 0, 23) * 60 + clampi(minute, 0, 59))
	time_changed.emit(day_number, get_hour(), get_minute())
	if get_period() != old_period:
		period_changed.emit(get_period())


func get_hour() -> int:
	return int(floor(_minutes_of_day / 60.0))


func get_minute() -> int:
	return int(floor(_minutes_of_day)) % 60


func get_time_text() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]


func get_period() -> StringName:
	return period_at(_minutes_of_day)


func period_at(minutes: float) -> StringName:
	var minute: float = fposmod(minutes, MINUTES_PER_DAY) if is_finite(minutes) else START_MINUTE
	if minute < 300.0:
		return &"madrugada"
	if minute < 540.0:
		return &"manha"
	if minute < 900.0:
		return &"dia"
	if minute < 1080.0:
		return &"tarde"
	if minute < 1200.0:
		return &"anoitecendo"
	return &"noite"


func get_period_label() -> String:
	match get_period():
		&"madrugada":
			return "Madrugada"
		&"manha":
			return "Manhã"
		&"dia":
			return "Dia"
		&"tarde":
			return "Tarde"
		&"anoitecendo":
			return "Anoitecendo"
		&"noite":
			return "Noite"
	return "Dia"


func get_lighting_color() -> Color:
	return lighting_at(_minutes_of_day)


func lighting_at(minutes: float) -> Color:
	var value: float = fposmod(minutes, MINUTES_PER_DAY) if is_finite(minutes) else START_MINUTE
	for i in range(LIGHTING_STOPS.size() - 1):
		var previous: Array = LIGHTING_STOPS[i]
		var following: Array = LIGHTING_STOPS[i + 1]
		var begin: float = float(previous[0])
		var end: float = float(following[0])
		if value <= end:
			var t: float = smoothstep(0.0, 1.0, clampf((value - begin) / (end - begin), 0.0, 1.0))
			var a: Color = previous[1]
			var b: Color = following[1]
			return a.lerp(b, t)
	return Color(0.48, 0.53, 0.70)


func get_save_data() -> Dictionary:
	return {"version": 1, "day": day_number, "minutes": _minutes_of_day}


func load_save_data(data: Dictionary) -> bool:
	# Validate transactionally: malformed saves leave the current clock untouched.
	var saved_day: Variant = data.get("day", 1)
	var saved_minutes: Variant = data.get("minutes", START_MINUTE)
	if not (saved_day is int or saved_day is float) or not (saved_minutes is int or saved_minutes is float): return false
	if not is_finite(float(saved_day)) or not is_finite(float(saved_minutes)): return false
	if float(saved_day) < 1 or float(saved_day) > 2000000000 or float(saved_day) != floorf(float(saved_day)): return false
	if float(saved_minutes) < 0 or float(saved_minutes) >= MINUTES_PER_DAY: return false
	if data.get("version", 1) != 1: return false
	day_number = int(saved_day)
	_minutes_of_day = float(saved_minutes)
	day_changed.emit(day_number)
	_emit_clock_state()
	return true


func _emit_clock_state() -> void:
	time_changed.emit(day_number, get_hour(), get_minute())
	period_changed.emit(get_period())
