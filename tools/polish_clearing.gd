extends SceneTree
func _initialize() -> void:
	var scene := (load("res://scenes/regions/ClareiraDoDespertar.tscn") as PackedScene).instantiate()
	preload("res://scripts/world/clearing_polish.gd").new().apply(scene)
	var packed := PackedScene.new()
	var result := packed.pack(scene)
	if result == OK:
		result = ResourceSaver.save(packed,"res://scenes/regions/ClareiraDoDespertar.tscn")
	print("WOODLAND_POLISH result=",result," accents=",scene.get_node("WoodlandDetails").get_child_count()," low_tiles=",scene.get_node("VegetationLow").get_used_cells().size())
	scene.free()
	quit(result)
