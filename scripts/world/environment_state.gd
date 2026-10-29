extends RefCounted
## Explicit environmental inputs. No calendar or autonomous weather simulation.
signal changed
var _period := "morning"
var _rain := 0.0
var _wind := 1.0
var _fog := 0.0

func set_conditions(period: String = "morning", rain: float = 0.0, wind: float = 1.0, fog: float = 0.0) -> void:
	_period = period if period in ["morning", "afternoon", "night"] else "morning"
	_rain = clampf(rain, 0.0, 1.0) if is_finite(rain) else 0.0
	_wind = clampf(wind, 0.0, 1.5) if is_finite(wind) else 1.0
	_fog = clampf(fog, 0.0, 1.0) if is_finite(fog) else 0.0
	changed.emit()

func snapshot() -> Dictionary:
	return {"period": _period, "rain": _rain, "wind": _wind, "fog": _fog}
