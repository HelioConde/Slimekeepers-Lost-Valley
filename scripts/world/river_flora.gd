extends Node2D
## Vegetação aquática mágica ao longo dos rios (V11, ref. da ponte à noite):
## juncos com pontas ciano na beira da água e vitórias-régias com flor lilás
## luminosa na água rasa. Posições determinísticas (malha do mundo + hash), só
## onde há água de verdade; nada sobre pontes. O brilho noturno vem do
## MushroomGlows (meta magic_flower), igual às flores do lago.

const REEDS := preload("res://assets/world/pond/reeds_glow.png")
const LILY := preload("res://assets/world/pond/lily_glow.png")
const PAD := preload("res://assets/world/pond/lily_pad.png")
const CELL := 72.0
const SHORE := 30.0

var placed: Array[Dictionary] = []


static func _rand(key: Vector2i, salt: int) -> float:
	return float(posmod(hash(Vector3i(key.x, key.y, salt)), 10000)) / 10000.0


static func _in_water(at: Vector2, waters: Array) -> bool:
	for w: Polygon2D in waters:
		if Geometry2D.is_point_in_polygon(w.global_transform.affine_inverse() * at - w.offset, w.polygon): return true
	return false


static func _on_bridge(at: Vector2, bridges: Array) -> bool:
	for r: Rect2 in bridges:
		if r.grow(36.0).has_point(at): return true
	return false


## shore: água com terra a SHORE px; open: água sem terra a 2·SHORE px.
func setup(waters: Array, bridges: Array, decorations: Node2D, water_layer: Node2D) -> void:
	name = "RiverFlora"
	var bounds := Rect2()
	for w: Polygon2D in waters:
		for point in w.polygon:
			var g: Vector2 = w.global_transform * (point + w.offset)
			bounds = Rect2(g, Vector2.ZERO) if bounds.size == Vector2.ZERO and bounds.position == Vector2.ZERO else bounds.expand(g)
	for gy in range(int(bounds.position.y / CELL), int(bounds.end.y / CELL) + 1):
		for gx in range(int(bounds.position.x / CELL), int(bounds.end.x / CELL) + 1):
			var key := Vector2i(gx, gy)
			var at := (Vector2(key) + Vector2(_rand(key, 1), _rand(key, 2))) * CELL
			if not _in_water(at, waters) or _on_bridge(at, bridges): continue
			var land := 0
			for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				if not _in_water(at + dir * SHORE, waters): land += 1
			var r := _rand(key, 3)
			if land > 0 and r < 0.28:
				_add(decorations, REEDS, at, Vector2(0, -21), "reeds", key)
			elif land == 0 and r < 0.24:
				var near_shore := false
				for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
					if not _in_water(at + dir * SHORE * 5.0, waters): near_shore = true
				if near_shore:
					_add(water_layer, LILY if _rand(key, 4) < 0.5 else PAD, at, Vector2.ZERO, "lily", key)


func _add(parent: Node2D, texture: Texture2D, at: Vector2, offset: Vector2, kind: String, key: Vector2i) -> void:
	var holder := Node2D.new()
	holder.name = "RiverFlora_%s_%d_%d" % [kind, key.x, key.y]
	holder.position = parent.to_local(at.round())
	parent.add_child(holder)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = offset
	sprite.flip_h = _rand(key, 5) < 0.5
	if kind == "lily":
		sprite.scale = Vector2(0.75, 0.75)
		sprite.set_meta("no_shadow", true)
	if texture == PAD:
		holder.add_to_group("water_light_sources")
		holder.set_meta("light_color", Color(0.2, 0.35, 0.45))
		holder.set_meta("light_radius", 10.0)
		holder.set_meta("light_strength", 0.25)
	if texture != PAD:
		sprite.set_meta("magic_flower", true)
		holder.add_to_group("water_light_sources")
		holder.set_meta("light_color", Color(0.4, 0.85, 1.0) if kind == "reeds" else Color(0.75, 0.5, 1.0))
		holder.set_meta("light_radius", 12.0)
	holder.add_child(sprite)
	placed.append({"kind": kind, "at": at})
