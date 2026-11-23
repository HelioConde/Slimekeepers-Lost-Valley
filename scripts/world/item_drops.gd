extends Node2D
## Itens que caem no chão (pedido do usuário, 2026-11-22): ao coletar, cortar ou
## colher, o produto salta do ponto, dá 3 quicadas cada vez menores e fica no chão;
## com o jogador dentro do alcance (MAGNET_RANGE) ele é puxado até o jogador e entra
## na bolsa. Bolsa cheia: o item espera no chão. Ao sair da região, o que sobrou vai
## para a bolsa (se couber).

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
## Alcance do ímã (px): a partir daqui o item voa para o jogador.
const MAGNET_RANGE := 72.0
const PICKUP_RANGE := 10.0
const FLY_SPEED := 260.0
## Alturas das 3 quicadas (px) e duração de cada uma (s).
const BOUNCES := [[18.0, 0.22], [9.0, 0.16], [4.0, 0.11]]

signal picked(item: String, amount: int)

var player: Node2D
var drops: Array[Dictionary] = []  # {item, amount, node, ready, speed}


func _init() -> void:
	name = "ItemDrops"
	y_sort_enabled = true


## Solta `amount` de `item` no chão a partir de `at` (pula para um lado).
func spawn(item: String, amount: int, at: Vector2) -> void:
	if amount <= 0: return
	var holder := Node2D.new()
	holder.name = "Drop_%s" % item
	holder.position = to_local(at)
	add_child(holder)
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.22)
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		pts.append(Vector2(cos(a) * 6.0, sin(a) * 2.5))
	shadow.polygon = pts
	holder.add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.name = "Icon"
	sprite.texture = ITEMS.icon(item)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 0.6
	sprite.offset = Vector2(0, -10)
	holder.add_child(sprite)
	var entry := {"item": item, "amount": amount, "node": holder, "ready": false, "speed": 0.0}
	drops.append(entry)
	# 3 quicadas: anda para um lado e sobe/desce cada vez menos.
	var side := Vector2(randf_range(-1.0, 1.0), randf_range(0.2, 1.0)).normalized() * randf_range(10.0, 18.0)
	var tween := holder.create_tween()
	var from := holder.position
	var step := side / BOUNCES.size()
	for b in BOUNCES:
		var height: float = b[0]
		var time: float = b[1]
		tween.tween_property(sprite, "position:y", -height, time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(holder, "position", from + step, time).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(sprite, "position:y", 0.0, time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		from += step
	tween.tween_callback(func() -> void: entry.ready = true)


func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	for entry in drops.duplicate():
		var node: Node2D = entry.node
		if not is_instance_valid(node) or not entry.ready: continue
		var target := player.global_position + Vector2(0, -14)
		var d := node.global_position.distance_to(target)
		if d > MAGNET_RANGE and float(entry.speed) <= 0.0: continue
		if BAG.count_item(get_tree(), str(entry.item)) >= ITEMS.max_stack(str(entry.item)):
			entry.speed = 0.0
			continue  # bolsa cheia: fica no chão
		entry.speed = minf(float(entry.speed) + FLY_SPEED * 3.0 * delta, FLY_SPEED * 2.0)
		node.global_position = node.global_position.move_toward(target, float(entry.speed) * delta)
		if node.global_position.distance_to(target) <= PICKUP_RANGE:
			_collect(entry)


func _collect(entry: Dictionary) -> void:
	var got := 0
	while got < int(entry.amount) and BAG.add_item(get_tree(), str(entry.item), 1): got += 1
	entry.amount = int(entry.amount) - got
	if got > 0: picked.emit(str(entry.item), got)
	if int(entry.amount) <= 0:
		(entry.node as Node).queue_free()
		drops.erase(entry)
	else:
		entry.speed = 0.0


## Itens ainda no chão (para testes e para recolher ao sair).
func pending() -> int:
	var total := 0
	for entry in drops: total += int(entry.amount)
	return total


## Põe na bolsa tudo o que estiver no chão e couber (sair da região, testes).
func collect_all() -> void:
	for entry in drops.duplicate():
		_collect(entry)


func _exit_tree() -> void:
	collect_all()
