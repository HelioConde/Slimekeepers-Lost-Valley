extends CanvasModulate
## Ambient color on the gameplay canvas only; HUD remains in its own CanvasLayer.
## Ambient tint plus lightweight surface reflections and ground silhouette shadows.
var water_reflections: Node
var day_shadows: Node2D

func _ready() -> void:
	color = GameClock.get_lighting_color()
	GameClock.period_changed.connect(_sync_environment, CONNECT_DEFERRED)
	call_deferred("_sync_environment", GameClock.get_period())
	call_deferred("_install_reflections")
	call_deferred("_install_shadows")


func _process(delta: float) -> void:
	color = GameClock.get_lighting_color()
	if is_instance_valid(water_reflections): water_reflections.update_for_time(delta)
	if is_instance_valid(day_shadows): day_shadows.update_for_time(delta)

func _install_shadows() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or day_shadows: return
	day_shadows = preload("res://scripts/world/day_shadows.gd").new()
	day_shadows.name = "DayShadows"
	add_child(day_shadows)

func _install_reflections() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or water_reflections: return
	water_reflections = preload("res://scripts/world/water_reflections.gd").new()
	water_reflections.name = "WaterReflections"
	add_child(water_reflections)

func _exit_tree() -> void:
	GameClock.stop()

func _sync_environment(period: StringName) -> void:
	# Deferred signals may outlive a scene's removal during travel.
	if not is_inside_tree() or is_queued_for_deletion(): return
	# Adapt the six clock periods to the existing three ambience profiles.
	var region := get_parent()
	if not region.has_method("set_environment_conditions"): return
	var profile := "night" if period in [&"noite", &"madrugada"] else ("afternoon" if period in [&"tarde", &"anoitecendo"] else "morning")
	var weather: Dictionary = get_tree().get_meta("environment_conditions", {})
	region.set_environment_conditions(profile, weather.get("rain", 0.0), weather.get("wind", 1.0), weather.get("fog", 0.0))
