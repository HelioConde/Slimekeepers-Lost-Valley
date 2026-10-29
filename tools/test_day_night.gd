extends SceneTree
## Clock contract and real scene lifecycle. No visual claims from headless checks.
const ClockScript = preload("res://scripts/systems/game_clock.gd")
const Travel = preload("res://scripts/world/region_travel.gd")
var checks := 0
var failures := 0
var events := []
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures += 1
 print("PASS " if ok else "FAIL ", label)
func distance(a: Color, b: Color) -> float:
 return Vector3(a.r,a.g,a.b).distance_to(Vector3(b.r,b.g,b.b))
func settle():
 for i in 5: await process_frame
func switch_to(path: String) -> Node:
 var error := change_scene_to_file(path)
 check(error==OK,"Scene transition accepted: "+path)
 for i in 120:
  await process_frame
  if is_instance_valid(current_scene) and current_scene.scene_file_path==path and current_scene.is_node_ready():
   await settle()
   return current_scene
 check(false,"Scene transition completed: "+path)
 return null
func run():
 var model := ClockScript.new()
 root.add_child(model)
 check(model.day_number==1 and model.get_time_text()=="07:00" and model.get_period_label()=="Manhã","Initial day 1 at 07:00")
 check(is_equal_approx(model.seconds_per_game_day,1440.0),"Default day lasts 24 real minutes")
 var boundaries := [[4,59,"madrugada","manha"],[8,59,"manha","dia"],[14,59,"dia","tarde"],[17,59,"tarde","anoitecendo"],[19,59,"anoitecendo","noite"],[23,59,"noite","madrugada"]]
 model.time_changed.connect(func(d,h,m):events.append(["time",d,h,m]))
 model.period_changed.connect(func(period):events.append(["period",period]))
 model.day_changed.connect(func(d):events.append(["day",d]))
 for boundary in boundaries:
  model.set_time(boundary[0],boundary[1])
  check(model.get_period()==StringName(boundary[2]),"Before boundary %02d:%02d"%[boundary[0],boundary[1]])
  var previous_day := model.day_number
  events.clear()
  model.advance_minutes(1)
  check(model.get_period()==StringName(boundary[3]),"Period crosses to "+boundary[3])
  check(events.filter(func(e):return e[0]=="period").size()==1 and events.filter(func(e):return e[0]=="time").size()==1,"One time/period notification per boundary")
  check(model.day_number==previous_day+(1 if boundary[0]==23 else 0),"Day rolls only at midnight")
 check(model.has_signal("time_advanced"),"Batch advance hook for future systems")
 if model.has_signal("time_advanced"): model.time_advanced.connect(func(m,d):events.append(["advance",m,d]))
 model.reset_new_game()
 events.clear()
 model.advance_minutes(2880.5)
 check(model.day_number==3 and model.get_save_data().minutes==420.5,"Multi-day sleep preserves fractional minutes")
 check(events.filter(func(e):return e[0]=="advance").size()==1 and events.filter(func(e):return e[0]=="day").size()==1,"Multi-day skip has bounded aggregate notifications")
 var saved := model.get_save_data()
 model.reset_new_game()
 model.load_save_data(saved)
 check(model.get_save_data()==saved,"Save/load round-trip including fraction and day")
 for invalid in [{"minutes":NAN},{"minutes":INF},{"minutes":-1},{"minutes":1440},{"day":"bad"},{"day":0},{"day":1.5},{"version":99}]:
  model.load_save_data(invalid)
  check(model.get_save_data()==saved,"Invalid save leaves clock intact: "+str(invalid))
 for invalid in [NAN,INF,-INF,-1.0]:
  model.advance_minutes(invalid)
  check(model.get_save_data()==saved,"Invalid elapsed time rejected: "+str(invalid))
 for invalid in [NAN,INF,0.0,-1.0]:
  model.seconds_per_game_day=invalid
  check(is_finite(model.seconds_per_game_day) and model.seconds_per_game_day>0,"Invalid duration falls back safely")
 model.seconds_per_game_day=720
 model.reset_new_game()
 model.start()
 model._process(1.0)
 check(model.get_time_text()=="07:02","Configurable clock speed")
 model.stop()
 saved=model.get_save_data()
 model._process(100)
 check(model.get_save_data()==saved,"Stopped clock consumes no delta")
 var continuous:=true
 var readable:=true
 for minute in 1440:
  var tint:Color=model.lighting_at(minute)
  if distance(tint,model.lighting_at(minute+1))>.015:continuous=false
  if tint.r*.2126+tint.g*.7152+tint.b*.0722<.48:readable=false
 check(continuous,"All lighting minutes interpolate continuously, including midnight")
 check(readable,"Night palette retains minimum ambient luminance")
 check(model.lighting_at(720)==Color.WHITE,"Midday preserves original sprite palette")
 check(distance(model.lighting_at(180),model.lighting_at(1320))>.03,"Predawn differs visibly from night")
 model.free()
 var clock=root.get_node("GameClock")
 clock.reset_new_game()
 # Legacy and current playable scenes all share the same installation.
 for path in ["res://scenes/world.tscn","res://scenes/regions/ClareiraDoDespertar.tscn",Travel.CLEARING,Travel.VALLEY]:
  var region=await switch_to(path)
  if not region:quit(1);return
  check(region.find_children("*","CanvasModulate",true,false).size()==1,"Exactly one ambient controller: "+path)
  var widget:Control=region.get_node("HUD/Interface/DayClock")
  check(widget.get_canvas()!=region.get_canvas(),"Clock uses independent HUD canvas")
  check(widget.get_node("ClockText").get_theme_font("font").resource_path.ends_with("PixelifySans.ttf"),"HUD theme available")
  clock.set_time(22)
  await settle()
  check(distance(region.get_node("DayNightLighting").color,clock.get_lighting_color())<.001,"Region applies current time without entry flash")
  check(widget.get_node("ClockText").text.contains("22:00") and widget.get_node("ClockText").text.contains("Noite"),"HUD updates from global clock")
  for resolution in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
   root.size=resolution
   root.content_scale_size=Vector2i(960,540)
   await settle()
   check(not widget.get_global_rect().intersects(region.get_node("HUD/Interface/ReturnToMenu").get_global_rect()),"Clock does not cover Menu at "+str(resolution))
 clock.set_time(18,35)
 var before:Dictionary=clock.get_save_data()
 var valley=await switch_to(Travel.VALLEY)
 check(clock.day_number==before.day and clock.get_time_text()=="18:35","Global time preserved entering valley")
 var forest=await switch_to(Travel.CLEARING)
 check(clock.day_number==before.day and clock.get_time_text()=="18:35","Global time preserved returning to forest")
 paused=true
 before=clock.get_save_data()
 await create_timer(.2,true).timeout
 check(clock.get_save_data()==before,"SceneTree pause stops real clock processing")
 paused=false
 await create_timer(.15,true).timeout
 check(clock.get_save_data().minutes>before.minutes,"Clock resumes after pause")
 # Menu actually installed, not a direct stop() mock.
 await switch_to("res://scenes/start_menu.tscn")
 before=clock.get_save_data()
 await create_timer(.2,true).timeout
 check(not clock.is_running() and clock.get_save_data()==before,"Main menu consumes no game time")
 current_scene._start_game()
 for i in 120:
  await process_frame
  if is_instance_valid(current_scene) and current_scene.scene_file_path==Travel.CLEARING:break
 await settle()
 check(clock.day_number==1 and clock.get_time_text()=="07:00" and clock.is_running(),"Actual New Game starts day 1 at 07:00")
 clock.set_time(22)
 await settle()
 check(get_meta("environment_conditions",{}).get("period")=="night","Existing ambience follows the global nighttime profile")
 print("DAY_NIGHT_TEST ",checks," checks; ",failures," failures")
 current_scene.queue_free()
 await process_frame
 quit(1 if failures else 0)
