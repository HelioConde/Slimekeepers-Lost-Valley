extends Node
## Despertar do protagonista (primeira cena jogável, Bíblia: "acordar perdido").
## Máquina de estados simples: cada estado toca uma animação do jogador e dura o
## tempo dela (ou um mínimo, se a arte faltar). Controle bloqueado até o fim; a
## interface volta aos poucos. Nunca prende o jogador: TIMEOUT força o fim, e
## Esc/Enter/E pulam a cena.

signal finished

const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")

enum State { SIT_IDLE, LOOK_LEFT, LOOK_RIGHT, CONFUSED, STAND_UP, LOOK_AROUND, DONE }
## estado -> [animação, segundos mínimos]
const STEPS := {
	State.SIT_IDLE: ["sit_idle", 2.4],
	State.LOOK_LEFT: ["sit_look_left", 1.4],
	State.LOOK_RIGHT: ["sit_look_right", 1.4],
	State.CONFUSED: ["sit_confused", 1.6],
	State.STAND_UP: ["stand_up", 1.0],
	State.LOOK_AROUND: ["idle_south", 1.4],
}
const TIMEOUT := 25.0
const CLOSE_ZOOM := 1.6  # aproximação suave durante o despertar

var state: State = State.SIT_IDLE
var player: CharacterBody2D
var camera: Camera2D
## Interface escondida durante a cena e mostrada no fim (CanvasItems/CanvasLayers).
var hud: Array = []
var _left := 0.0
var _elapsed := 0.0
var _normal_zoom := Vector2.ONE


func start(target: CharacterBody2D, hud_nodes: Array) -> void:
	name = "IntroWake"
	player = target
	camera = player.get_node_or_null("Camera2D")
	hud = hud_nodes
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.facing = "south"
	for node in hud:
		if node is CanvasItem: (node as CanvasItem).modulate.a = 0.0
		elif node is CanvasLayer: (node as CanvasLayer).visible = false
	if camera:
		_normal_zoom = camera.zoom
		camera.zoom = Vector2.ONE * CLOSE_ZOOM
	# Chega do escuro da tela de carregamento: a floresta clareia aos poucos.
	var veil := CanvasLayer.new()
	veil.layer = 50
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0.92)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.add_child(black)
	add_child(veil)
	var t := black.create_tween()
	t.tween_property(black, "color:a", 0.0, 1.6).set_trans(Tween.TRANS_SINE)
	t.tween_callback(veil.queue_free)
	_enter(State.SIT_IDLE)


func _enter(next: State) -> void:
	state = next
	if state == State.DONE:
		_finish()
		return
	var step: Array = STEPS[state]
	var length: float = player.play_wake(str(step[0]))
	if state == State.LOOK_AROUND:
		if camera:
			camera.create_tween().tween_property(camera, "zoom", _normal_zoom, 1.2).set_trans(Tween.TRANS_SINE)
	_left = maxf(length, float(step[1]))


func _process(delta: float) -> void:
	if state == State.DONE:
		return
	_elapsed += delta
	_left -= delta
	if _elapsed > TIMEOUT:
		_enter(State.DONE)
	elif _left <= 0.0:
		_enter(State.values()[state + 1])


func _unhandled_input(event: InputEvent) -> void:
	if state == State.DONE or _elapsed < 0.5:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_enter(State.DONE)


func _finish() -> void:
	if camera: camera.zoom = _normal_zoom
	player.set_physics_process(true)
	player.call("_play_animation", "idle_south")
	for node in hud:
		if node is CanvasLayer: (node as CanvasLayer).visible = true
		elif node is CanvasItem: (node as CanvasItem).create_tween().tween_property(node, "modulate:a", 1.0, 0.8)
	PROTAGONIST.finish_intro(get_tree())
	finished.emit()
	queue_free()

