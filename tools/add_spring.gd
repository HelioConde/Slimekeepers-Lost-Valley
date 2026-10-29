extends SceneTree
func _initialize() -> void:
	var scene := (load("res://scenes/regions/ClareiraDoDespertar.tscn") as PackedScene).instantiate()
	preload("res://scripts/world/spring_builder.gd").new().apply(scene)
	var packed := PackedScene.new()
	var result := packed.pack(scene)
	if result == OK:
		result = ResourceSaver.save(packed,"res://scenes/regions/ClareiraDoDespertar.tscn")
	print("ADD_SPRING result=",result)
	scene.free()
	quit(result)
