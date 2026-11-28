extends Node2D
## Desenho no chão dentro de uma região com y-sort (avisos do boss, anel da arena):
## em y = 1 fica logo depois das camadas de chão (y 0) e antes de tudo o que tem altura
## (jogador, boss, árvores), então nunca cobre o jogador. Quem usa passa um `painter`
## que desenha em coordenadas do mundo com to_local().

var painter: Callable


func _ready() -> void:
	position = Vector2(0, 1)
	z_index = 0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if painter.is_valid(): painter.call(self)
