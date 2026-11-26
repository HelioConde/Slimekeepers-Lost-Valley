extends SceneTree
## Auditoria dos recursos do começo (playtest IDs 01 e 06): quantos gravetos, pedrinhas e
## matos estão perto do início e à beira das trilhas, onde um iniciante procura.
## Uso: godot --path . --rendering-driver opengl3 --script res://tools/audit_early_resources.gd

const NEEDED := {"graveto": 2 + 6, "pedra_pequena": 2 + 4 + 5}  # machado + bancada (+ picareta)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var region: Node2D = load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
	root.add_child(region)
	for i in 30: await process_frame
	var forage: Node2D = region.get("gathering").forage
	var spawn := Vector2(3200, 3200)
	var trails: Dictionary = load("res://scripts/world/forest_layout.gd").trails()
	var near_route: Callable = func(at: Vector2) -> bool:
		return load("res://scripts/world/valley_layout.gd").route_distance(at, trails) < 90.0
	for item in ["graveto", "pedra_pequena", "fibra"]:
		var spots: Array = forage.spots.filter(func(s: Dictionary) -> bool: return s.item == item)
		var near := spots.filter(func(s: Dictionary) -> bool: return s.at.distance_to(spawn) < 700.0)
		var road := near.filter(func(s: Dictionary) -> bool: return near_route.call(s.at))
		print("%s: total %d · até 700 px do início %d · desses, à beira da trilha %d · precisa %s" % [item, spots.size(), near.size(), road.size(), str(NEEDED.get(item, "-"))])
	var rocks: Node2D = region.get("gathering").rocks
	var medium: Array = rocks.rocks.values().filter(func(r: Dictionary) -> bool: return r.kind == "medium" and r.at.distance_to(spawn) < 900.0)
	print("pedras médias até 900 px do início: %d" % medium.size())
	quit()
