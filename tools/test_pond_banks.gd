extends SceneTree
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures += 1
 print("PASS " if ok else "FAIL ", label)
func inventory(layer: TileMapLayer, center: Vector2) -> Dictionary:
 var counts := {}
 for cell in layer.get_used_cells():
  if layer.map_to_local(cell).distance_to(center)>220:continue
  var key := str([layer.get_cell_source_id(cell),layer.get_cell_atlas_coords(cell),layer.get_cell_alternative_tile(cell)])
  counts[key]=counts.get(key,0)+1
 return counts
func run():
 var region=load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
 var layer:TileMapLayer=region.get_node("VegetationLow")
 var water:Polygon2D=region.get_node("NaturalSpring/Pool/Water")
 var center:Vector2=region.get_node("NaturalSpring").position
 var original=inventory(layer,center)
 var polygon=water.polygon.duplicate()
 var rock:Node2D=region.get_node("Decorations/MossyRock_1317")
 var shape:CollisionPolygon2D=rock.get_node("SolidBase/BaseCollision")
 var original_rock=rock.position
 var original_shape=shape.position
 root.add_child(region)
 current_scene=region
 for i in 10:await physics_frame
 check(inventory(layer,center)==original,"All local painted plant tiles preserved after relocation")
 var wet:=0
 for cell in layer.get_used_cells():
  var data=layer.get_cell_tile_data(cell)
  var foot=layer.to_global(layer.map_to_local(cell)+Vector2(0,data.y_sort_origin))
  if Geometry2D.is_point_in_polygon(water.to_local(foot),water.polygon):wet+=1
 check(wet==0,"No terrestrial painted plant rooted inside pond")
 check(rock.position!=original_rock,"Floating rock moved to bank")
 check(not Geometry2D.is_point_in_polygon(water.to_local(rock.global_position),water.polygon),"Rock visible foot on dry ground")
 check(shape.position==original_shape and shape.get_parent().collision_layer==2,"Rock collider preserved with the prop")
 var dry:=true
 for offset in shape.polygon:
  if Geometry2D.is_point_in_polygon(water.to_local(shape.to_global(offset)),water.polygon):dry=false
 check(dry,"Rock collision footprint on dry bank")
 check(water.polygon==polygon,"Water contour preserved")
 check(region.get_node("NaturalSpring/WaterCollision").collision_layer==2,"Player still blocked by deep water")
 var stable=inventory(layer,center)
 var at=rock.position
 region._arrange_pond_banks()
 check(inventory(layer,center)==stable and rock.position==at,"Bank cleanup is idempotent")
 print("POND_BANKS: ",checks," checks; ",failures," failures")
 region.queue_free()
 await process_frame
 quit(1 if failures else 0)
