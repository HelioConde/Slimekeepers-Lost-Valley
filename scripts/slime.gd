extends Node2D
## Criatura amigável. A primeira interação concede um vínculo ao jogador.

@export_enum("gelito", "brotinho", "brasinha") var slime_type: String = "gelito"
var befriended: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    var path := "res://assets/slimes/bestiary/%s/%s_frames.tres" % [slime_type, slime_type]
    sprite.sprite_frames = load(path) as SpriteFrames
    if sprite.sprite_frames != null:
        sprite.play("idle")

func display_name() -> String:
    match slime_type:
        "gelito": return "Gelito"
        "brotinho": return "Brotinho"
        "brasinha": return "Brasinha"
    return "Slime"

func make_friend() -> bool:
    if befriended:
        return false
    befriended = true
    sprite.play("happy")
    return true
