extends Node2D
## Presença do outro jogador na região (multijogador, scripts/net/net_session.gd):
## envia posição/direção/animação do jogador local ~15 vezes por segundo e mostra o
## outro protagonista (Aren ou Moni) quando ele está no mesmo mapa.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const SEND_EVERY := 1.0 / 15.0

var player: Node2D
var remote: Node2D
var _target := Vector2.ZERO
var _send_time := 0.0
var _session: Node


func _ready() -> void:
	name = "NetPresence"
	_session = get_node_or_null("/root/NetSession")
	if _session == null: return
	_session.message.connect(_on_message)
	# Avisos da sala (ID da sala, quem entrou/saiu) aparecem no jogo.
	var region := get_parent()
	if region.has_method("_notify"):
		_session.status_changed.connect(func(text: String) -> void: region.call("_notify", text))
		if _session.is_active() and not str(_session.status).is_empty(): region.call_deferred("_notify", str(_session.status))
	_session.peer_left.connect(func() -> void:
		if is_instance_valid(remote): remote.visible = false)


func _process(delta: float) -> void:
	if _session == null or not bool(_session.connected) or not is_instance_valid(player): return
	_send_time += delta
	if _send_time >= SEND_EVERY:
		_send_time = 0.0
		_session.send({"t": "state", "scene": get_tree().current_scene.scene_file_path if get_tree().current_scene else "",
			"x": player.global_position.x, "y": player.global_position.y,
			"facing": str(player.get("facing")), "anim": str(player.get("current_animation")),
			"frame": int((player.get("sprite") as AnimatedSprite2D).frame)})
	if is_instance_valid(remote) and remote.visible:
		remote.global_position = remote.global_position.lerp(_target, minf(1.0, delta * 12.0))


func _on_message(data: Dictionary) -> void:
	if str(data.get("t", "")) != "state": return
	var here: String = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	if str(data.get("scene", "")) != here:
		if is_instance_valid(remote): remote.visible = false
		return
	if not is_instance_valid(remote): _spawn_remote()
	_target = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	if not remote.visible:
		remote.global_position = _target
		remote.visible = true
	remote.set("facing", str(data.get("facing", "south")))
	var sprite: AnimatedSprite2D = remote.get("sprite")
	var anim := str(data.get("anim", ""))
	if sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim: sprite.play(anim)
		if not anim.begins_with("walk") and not anim.begins_with("run") and not anim.begins_with("idle_a") and not anim.begins_with("idle_b") and not anim.begins_with("idle_c"):
			sprite.frame = int(data.get("frame", 0))


func _spawn_remote() -> void:
	remote = PLAYER_SCENE.instantiate()
	remote.name = "RemotePlayer"
	remote.visible = false  # aparece já na posição recebida (sem deslizar de 0,0)
	remote.set("protagonist_override", str(_session.remote_protagonist))
	(remote as CollisionObject2D).collision_layer = 0
	(remote as CollisionObject2D).collision_mask = 0
	var cam := remote.get_node_or_null("Camera2D") as Camera2D
	if cam: cam.enabled = false  # a câmera continua no jogador local
	player.get_parent().add_child(remote)  # mesmo y-sort do jogador local
	remote.set_physics_process(false)
