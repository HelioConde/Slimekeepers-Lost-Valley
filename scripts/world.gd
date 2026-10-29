extends Node2D
## Primeiro "vertical slice": explorar, achar e fazer amizade com três slimes.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const SLIME_SCENE: PackedScene = preload("res://scenes/slime.tscn")
const TERRAIN_SCRIPT: Script = preload("res://scripts/terrain.gd")
const FONT: FontFile = preload("res://assets/fonts/PixelifySans.ttf")
const DAY_LIGHT_SCRIPT: Script = preload("res://scripts/world/day_night_lighting.gd")
const CLOCK_WIDGET: PackedScene = preload("res://scenes/ui/day_clock.tscn")

const BUSH_SMALL: Texture2D = preload("res://assets/sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png")
const BUSH_LARGE: Texture2D = preload("res://assets/sprites/objects/bush_large_large_dense_fores/rotations/bush_large_large_dense_fores.png")
const LOG: Texture2D = preload("res://assets/sprites/objects/fallen_log_mossy_fallen_oak/rotations/fallen_log_mossy_fallen_oak.png")

var player: CharacterBody2D
var slimes: Array[Node2D] = []
var friends_count: int = 0
var hud_title: Label
var hud_goal: Label
var hud_hint: Label
var popup: Label
var message_time: float = 0.0

func _ready() -> void:
    y_sort_enabled = true
    var terrain := Node2D.new()
    terrain.name = "Terrain"
    terrain.set_script(TERRAIN_SCRIPT)
    terrain.z_index = -10
    add_child(terrain)

    _populate_forest()
    player = PLAYER_SCENE.instantiate() as CharacterBody2D
    player.position = Vector2(640, 490)
    add_child(player)
    _spawn_slime("gelito", Vector2(475, 356))
    _spawn_slime("brotinho", Vector2(777, 352))
    _spawn_slime("brasinha", Vector2(672, 695))
    _create_hud()
    _update_hud()

func _process(delta: float) -> void:
    var closest := _closest_slime()
    if closest != null:
        var name_slime: String = str(closest.call("display_name"))
        hud_hint.text = "[E] %s: %s" % [("Conversar novamente" if bool(closest.get("befriended")) else "Fazer amizade"), name_slime]
        if Input.is_action_just_pressed("interact"):
            if bool(closest.call("make_friend")):
                friends_count += 1
                _notify("Novo amigo! %s entrou para sua jornada." % name_slime)
                _update_hud()
            else:
                _notify("%s já é seu amigo!" % name_slime)
    else:
        hud_hint.text = "WASD / Setas: andar   •   Shift: correr   •   E: interagir"
    if message_time > 0.0:
        message_time -= delta
        if message_time <= 0.0:
            popup.text = ""

func _closest_slime() -> Node2D:
    var closest: Node2D = null
    var distance := 90.0
    for slime in slimes:
        var new_distance := player.global_position.distance_to(slime.global_position)
        if new_distance < distance:
            distance = new_distance
            closest = slime
    return closest

func _spawn_slime(kind: String, pos: Vector2) -> void:
    var slime := SLIME_SCENE.instantiate() as Node2D
    slime.set("slime_type", kind)
    slime.position = pos
    add_child(slime)
    slimes.append(slime)

func _populate_forest() -> void:
    var small_locations := [Vector2(160,150),Vector2(325,265),Vector2(1025,300),Vector2(890,640),Vector2(330,755),Vector2(1080,825),Vector2(96,820),Vector2(1100,125),Vector2(230,545)]
    var large_locations := [Vector2(420,120),Vector2(865,170),Vector2(1080,525),Vector2(170,675),Vector2(980,885)]
    var log_locations := [Vector2(250,220),Vector2(980,460),Vector2(410,846)]
    for p in small_locations:
        _place_prop(BUSH_SMALL,p,0.55)
    for p in large_locations:
        _place_prop(BUSH_LARGE,p,0.68)
    for p in log_locations:
        _place_prop(LOG,p,0.67)

func _place_prop(tex: Texture2D, pos: Vector2, scale_factor: float) -> void:
    var prop := Sprite2D.new()
    prop.texture = tex
    prop.position = pos
    prop.scale = Vector2.ONE * scale_factor
    prop.offset = Vector2(0,-18)
    prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(prop)

func _create_hud() -> void:
    _install_day_night_lighting()
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)

    var interface := Control.new()
    interface.name = "Interface"
    interface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(interface)
    interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var panel := PanelContainer.new()
    panel.name = "MissionPanel"
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    interface.add_child(panel)
    panel.anchor_right = 0.5
    panel.offset_left = 18
    panel.offset_top = 16
    panel.offset_right = -12
    panel.offset_bottom = 116
    var style := StyleBoxFlat.new()
    style.bg_color = Color("f6e8c2")
    style.border_color = Color("694657")
    style.set_border_width_all(2)
    style.set_corner_radius_all(4)
    style.set_content_margin_all(14)
    style.shadow_color = Color(0.10, 0.08, 0.08, 0.35)
    style.shadow_size = 2
    style.shadow_offset = Vector2(2, 3)
    panel.add_theme_stylebox_override("panel", style)
    var contents := VBoxContainer.new()
    contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
    contents.add_theme_constant_override("separation", 6)
    panel.add_child(contents)
    hud_title = Label.new()
    hud_title.text = "SLIMEKEEPERS · LOST VALLEY"
    hud_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hud_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_title.add_theme_font_override("font", FONT)
    hud_title.add_theme_font_size_override("font_size", 20)
    hud_title.add_theme_color_override("font_color", Color("694657"))
    contents.add_child(hud_title)
    hud_goal = Label.new()
    hud_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hud_goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_goal.add_theme_font_override("font", FONT)
    hud_goal.add_theme_font_size_override("font_size", 18)
    hud_goal.add_theme_color_override("font_color", Color("3e5c43"))
    contents.add_child(hud_goal)

    var menu_button := Button.new()
    menu_button.name = "ReturnToMenu"
    menu_button.text = "Menu"
    menu_button.tooltip_text = "Voltar à tela inicial. O protótipo ainda não salva a partida."
    menu_button.add_theme_font_override("font", FONT)
    menu_button.add_theme_font_size_override("font_size", 20)
    menu_button.add_theme_color_override("font_color", Color("fff3d2"))
    menu_button.add_theme_color_override("font_hover_color", Color("fff3d2"))
    menu_button.add_theme_color_override("font_pressed_color", Color("fff3d2"))
    menu_button.add_theme_color_override("font_focus_color", Color("fff3d2"))
    interface.add_child(menu_button)
    menu_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    menu_button.offset_left = -116
    menu_button.offset_right = -18
    menu_button.offset_top = 16
    menu_button.offset_bottom = 58
    for state in ["normal", "hover", "pressed", "focus"]:
        var button_style := StyleBoxFlat.new()
        button_style.bg_color = Color("986841") if state == "normal" else Color("aa7747")
        if state == "pressed":
            button_style.bg_color = Color("765036")
        button_style.border_color = Color("694657") if state == "normal" else Color("a7cf87")
        button_style.set_border_width_all(2)
        button_style.set_corner_radius_all(4)
        button_style.set_content_margin_all(8)
        if state == "focus":
            button_style.draw_center = false
        menu_button.add_theme_stylebox_override(state, button_style)
    menu_button.pressed.connect(func() -> void:
        get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
    )

    var hint_panel := PanelContainer.new()
    hint_panel.name = "InteractionHint"
    hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    interface.add_child(hint_panel)
    hint_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    hint_panel.offset_left = 18
    hint_panel.offset_right = -18
    hint_panel.offset_top = -64
    hint_panel.offset_bottom = -16
    var hint_style := style.duplicate() as StyleBoxFlat
    hint_style.set_content_margin_all(10)
    hint_style.border_color = Color("608052")
    hint_panel.add_theme_stylebox_override("panel", hint_style)
    hud_hint = Label.new()
    hud_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hud_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hud_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_hint.add_theme_font_override("font", FONT)
    hud_hint.add_theme_font_size_override("font_size", 18)
    hud_hint.add_theme_color_override("font_color", Color("402f39"))
    hint_panel.add_child(hud_hint)

    popup = Label.new()
    popup.name = "FriendshipMessage"
    interface.add_child(popup)
    popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    popup.offset_left = 24
    popup.offset_right = -24
    popup.offset_top = 142
    popup.offset_bottom = 210
    popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    popup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
    popup.add_theme_font_override("font", FONT)
    popup.add_theme_font_size_override("font_size", 22)
    popup.add_theme_color_override("font_color", Color("fff0bc"))
    popup.add_theme_color_override("font_outline_color", Color("302a31"))
    popup.add_theme_constant_override("outline_size", 4)
    popup.add_theme_color_override("font_shadow_color", Color("132717"))
    popup.add_theme_constant_override("shadow_offset_x", 1)
    popup.add_theme_constant_override("shadow_offset_y", 2)

    var time_widget := CLOCK_WIDGET.instantiate() as Control
    interface.add_child(time_widget)
    GameClock.start()

func _install_day_night_lighting() -> void:
    # Canvas tint changes world brightness without modifying the HUD or sprites.
    if has_node("DayNightLighting"):
        return
    var ambient_light := CanvasModulate.new()
    ambient_light.name = "DayNightLighting"
    ambient_light.set_script(DAY_LIGHT_SCRIPT)
    add_child(ambient_light)

func _update_hud() -> void:
    if friends_count < 3:
        hud_goal.text = "Objetivo: faça amizade com 3 slimes (%d/3)" % friends_count
    else:
        hud_goal.text = "MISSÃO CONCLUÍDA! Os 3 slimes são seus amigos."
        _notify("O vale ganhou uma nova guardiã! Fim do protótipo 0.1.")

func _notify(message: String) -> void:
    popup.text = message
    message_time = 4.5
