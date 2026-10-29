extends SceneTree
const TIMES := [[7,0,"manha"],[12,0,"dia"],[16,30,"tarde"],[18,30,"anoitecendo"],[22,0,"noite"],[3,0,"madrugada"]]
var report := {}
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(960,540)
 var clock=root.get_node("GameClock")
 for entry in [["FlorestaDoDespertarV2",Vector2(3210,5570)],["ValeDasNascentes",Vector2(1045,1900)]]:
  var region=load("res://scenes/regions/%s.tscn"%entry[0]).instantiate()
  root.add_child(region)
  current_scene=region
  for i in 10:await physics_frame
  region.player.position=entry[1]
  var camera=region.player.get_node("Camera2D")
  camera.position_smoothing_enabled=false
  camera.reset_smoothing()
  await create_timer(1).timeout
  var deltas:=[]
  for frame in 60:
   var start=Time.get_ticks_usec()
   await process_frame
   deltas.append((Time.get_ticks_usec()-start)/1000.0)
  deltas.sort()
  report[entry[0]]={"frame_p50_ms":deltas[30],"frame_p95_ms":deltas[57],"colors":{}}
  # Freeze world animation for comparable captures. HUD signals still update.
  region.process_mode=Node.PROCESS_MODE_DISABLED
  clock.stop()
  for moment in TIMES:
   clock.set_time(moment[0],moment[1])
   region.get_node("DayNightLighting")._process(0)
   await process_frame
   await RenderingServer.frame_post_draw
   var image=root.get_texture().get_image()
   var total:=0.0
   var count:=0
   for y in range(140,590,8):
    for x in range(30,1250,8):
     var c=image.get_pixel(x,y)
     total+=c.r*.2126+c.g*.7152+c.b*.0722
     count+=1
   report[entry[0]].colors[moment[2]]={"mean_world_luminance":total/count,"tint":str(clock.get_lighting_color()),"hud_pixel":str(image.get_pixel(50,60)),"trail_pixel":str(image.get_pixel(670,440)),"water_pixel":str(image.get_pixel(1000,400))}
   var path="res://docs/world/day_night/%s_%s.png"%[entry[0],moment[2]]
   image.save_png(path)
   print("CAPTURE ",path)
  # Same frozen scene: prove the light pass is visible and its glints animate.
  clock.set_time(22)
  var lighting=region.get_node("DayNightLighting")
  lighting._process(0)
  var reflections=lighting.get_node("WaterReflections")
  reflections.material.set_shader_parameter("strength",0.0)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/world/day_night/%s_reflection_off.png"%entry[0])
  reflections.reduce_motion=false
  lighting._process(1.0)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/world/day_night/%s_reflection_motion.png"%entry[0])
  region.queue_free()
  await process_frame
 FileAccess.open("res://docs/world/day_night/capture_metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 quit()
