extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := (load("res://scenes/regions/ClareiraDoDespertar.tscn") as PackedScene).instantiate()
	var count: int = preload("res://scripts/world/rock_clarity.gd").new().apply(scene)
	var packed := PackedScene.new()
	var result := packed.pack(scene)
	if result==OK:
		result = ResourceSaver.save(packed,"res://scenes/regions/ClareiraDoDespertar.tscn")
	print("ROCK_CLARITY replaced=",count," result=",result)
	scene.free()
	await process_frame
	quit(result)
