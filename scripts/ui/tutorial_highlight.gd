extends Node2D
## Destaque do tutorial (pedido do usuário, 2026-11-23): anel branco piscando em volta
## do que a dica pede (gravetos, pedrinhas, mato, árvores pequenas, a bancada). Fica no
## mundo, acima do chão e dos objetos; tutorial_hud.gd preenche `targets` a cada quadro.

## [posição no mundo (pé do alvo), raio] de cada alvo.
var targets: Array = []
var _time := 0.0


func _ready() -> void:
	name = "TutorialHighlight"
	z_index = 20
	z_as_relative = false


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if targets.is_empty(): return
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)  # pisca ~1 vez por segundo
	var white := Color(1, 1, 1, 0.35 + 0.55 * pulse)
	for t: Array in targets:
		var at: Vector2 = t[0]
		var r: float = float(t[1]) * (1.0 + 0.08 * pulse)
		draw_set_transform(at, 0.0, Vector2(1.0, 0.5))  # anel achatado no chão
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, white, 2.0)
		draw_arc(Vector2.ZERO, r + 3.0, 0.0, TAU, 32, Color(1, 1, 1, white.a * 0.35), 1.0)
		draw_set_transform(Vector2.ZERO)
		# setinha piscando acima do alvo
		var tip := at + Vector2(0, -r * 0.5 - 22.0 - 4.0 * pulse)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-5, -6), tip + Vector2(5, -6), tip]), white)
