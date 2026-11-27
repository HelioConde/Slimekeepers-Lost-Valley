extends Node
## Dormir no multijogador (relatório de playtest ID 35): o dia só vira quando todos os
## jogadores estão dormindo (na cama ou exaustos no lugar). Quem dorme fica parado e vê
## "Esperando os outros (1/2)". O anfitrião decide: com todos dormindo, avança até as
## 06:00 do dia seguinte e manda "wake"; cada lado acorda quando o dia muda (vale também
## para o desmaio da meia-noite do outro). Sem conexão, request() devolve false e a região
## dorme como no modo solo.

const MORNING := 360.0  ## 06:00 em minutos

var region: Node  ## região atual: wake_up(forced) e player
var sleeping := false
var forced := false  ## exausto: acorda com metade da energia e não pode se levantar
var remote_sleeping := false
var _slept_on_day := 0
var _session: Node
var _label: Label


static func everyone_asleep(asleep: int, players: int) -> bool:
	return players > 0 and asleep >= players


static func waiting_text(asleep: int, players: int, can_leave: bool) -> String:
	return "Esperando os outros (%d/%d)" % [asleep, players] + ("   •   [F] Levantar" if can_leave else "")


## Minutos de jogo até as 06:00 do dia seguinte (dorme sempre entre 06:00 e 23:59).
static func minutes_to_morning(minutes: float) -> float:
	return (1440.0 - minutes) + MORNING


func _ready() -> void:
	name = "NetSleep"
	_session = get_node_or_null("/root/NetSession")
	if _session == null: return
	_session.message.connect(_on_message)
	_session.peer_joined.connect(func(_who: String) -> void:
		remote_sleeping = false
		if sleeping: _session.send({"t": "sleep", "on": true}))
	_session.peer_left.connect(func() -> void:
		remote_sleeping = false
		if sleeping: _check_all_asleep(true))  # sozinho: dorme como no solo


func active() -> bool:
	return _session != null and bool(_session.get("connected"))


func players() -> int:
	return 2 if active() else 1


func asleep_count() -> int:
	return int(sleeping) + int(remote_sleeping and active())


## Pedido de dormir. true = o multijogador cuidou (esperando ou levantou); false = solo.
## Na cama, pedir de novo enquanto espera levanta; exausto (forced) não levanta.
func request(is_forced: bool) -> bool:
	if not active() and not sleeping: return false
	if sleeping:
		if not is_forced and not forced: _set_sleeping(false, false)
		return true
	_set_sleeping(true, is_forced)
	_check_all_asleep(false)
	return true


func _set_sleeping(on: bool, is_forced: bool) -> void:
	sleeping = on
	forced = is_forced and on
	_slept_on_day = int(GameClock.day_number)
	var player: Node = region.get("player") if is_instance_valid(region) else null
	if is_instance_valid(player):
		player.set_physics_process(not on)  # deitado: não anda
		if on and player is CharacterBody2D: (player as CharacterBody2D).velocity = Vector2.ZERO
	if active(): _session.send({"t": "sleep", "on": on})
	_refresh_label()


## Anfitrião (ou quem ficou sozinho) vira o dia quando todos dormem.
func _check_all_asleep(alone: bool) -> void:
	if not sleeping: return
	if not alone and (not active() or str(_session.get("mode")) != "host"): return
	if not alone and not everyone_asleep(asleep_count(), players()): return
	GameClock.advance_minutes(minutes_to_morning(GameClock.get_hour() * 60.0 + GameClock.get_minute()))
	if active(): _session.send({"t": "wake", "day": GameClock.day_number, "minutes": GameClock.get_hour() * 60 + GameClock.get_minute()})


func _on_message(data: Dictionary) -> void:
	match str(data.get("t", "")):
		"sleep":
			remote_sleeping = bool(data.get("on", false))
			_refresh_label()
			_check_all_asleep(false)
		"wake":
			preload("res://scripts/net/net_world.gd").follow_clock(GameClock, int(data.get("day", 1)), float(data.get("minutes", MORNING)))


func _process(_delta: float) -> void:
	if not sleeping: return
	if int(GameClock.day_number) > _slept_on_day:  # o dia virou: acorda
		var was_forced := forced
		remote_sleeping = false
		_set_sleeping(false, false)  # já avisa o outro
		if is_instance_valid(region) and region.has_method("wake_up"): region.call("wake_up", was_forced)


func _refresh_label() -> void:
	if not sleeping:
		if is_instance_valid(_label): _label.hide()
		return
	if not is_instance_valid(_label):
		var hud: Node = region.get_node_or_null("HUD/Interface") if is_instance_valid(region) else null
		if hud == null: return
		_label = Label.new()
		_label.name = "SleepWaiting"
		_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_label.offset_top = 60
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 18)
		_label.add_theme_constant_override("outline_size", 6)
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		hud.add_child(_label)
	_label.text = waiting_text(asleep_count(), players(), not forced)
	_label.show()
