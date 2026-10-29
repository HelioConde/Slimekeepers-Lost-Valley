extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := (load("res://scenes/regions/ClareiraDoDespertar.tscn") as PackedScene).instantiate()
	preload("res://scripts/world/composition_refinement.gd").new().apply(scene)
	var packed := PackedScene.new()
	var result := packed.pack(scene)
	if result==OK:
		result = ResourceSaver.save(packed,"res://scenes/regions/ClareiraDoDespertar.tscn")
	print("COMPOSITION_SAVE result=",result," trees=",scene.get_node("VegetationHigh").get_child_count())
	scene.free()
	await process_frame
	quit(result)
