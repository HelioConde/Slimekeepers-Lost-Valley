extends Node2D
## HUD minimo: deixa claro qual animacao e direcao estao sendo utilizadas.

@onready var player = $Player
@onready var status_label: Label = $HUD/StatusLabel


func _process(_delta: float) -> void:
    status_label.text = "Estado: %s   |   Direcao: %s   |   Dash: %s" % [
        player.motion_state.to_upper(),
        player.facing.to_upper(),
        "PRONTO" if player.get_dash_ready() else "RECARREGANDO"
    ]
