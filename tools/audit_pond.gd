extends SceneTree
func _initialize():call_deferred("run")
func run():
 var region=load("res://scenes/regions/FlorestaDoDespertarV2.tscn").instantiate()
 root.add_child(region)
 current_scene=region
 for i in 10:await physics_frame
 var water:Polygon2D=region.get_node("NaturalSpring/Pool/Water")
 for sprite in region.find_children("*","Sprite2D",true,false):
  if not sprite.is_visible_in_tree() or not sprite.texture:continue
  var used=sprite.texture.get_image().get_used_rect()
  var foot=Vector2(used.position.x+used.size.x*.5,used.end.y)+sprite.offset
  if sprite.centered:foot-=sprite.texture.get_size()*.5
  foot=sprite.to_global(foot)
  if foot.distance_to(water.global_position)<190:
   print("PROP ",sprite.get_path()," foot=",foot," wet=",Geometry2D.is_point_in_polygon(water.to_local(foot),water.polygon)," tex=",sprite.texture.resource_path)
 for label in ["VegetationLow","GroundDetails"]:
  var layer:TileMapLayer=region.get_node(label)
  for cell in layer.get_used_cells():
   var data=layer.get_cell_tile_data(cell)
   var foot=layer.to_global(layer.map_to_local(cell)+Vector2(0,data.y_sort_origin))
   if foot.distance_to(water.global_position)<130:
    var atlas=layer.tile_set.get_source(layer.get_cell_source_id(cell))
    print("TILE ",label," ",cell," foot=",foot," wet=",Geometry2D.is_point_in_polygon(water.to_local(foot),water.polygon)," tex=",atlas.texture.resource_path)
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(960,540)
 region.player.position=water.global_position+Vector2(-140,80)
 var camera=region.player.get_node("Camera2D")
 camera.position_smoothing_enabled=false
 camera.position=Vector2(140,-80)
 camera.reset_smoothing()
 await create_timer(.5).timeout
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/world/pond_cleanup/after.png")
 quit()
