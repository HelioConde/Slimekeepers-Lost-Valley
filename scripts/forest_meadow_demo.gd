extends Node2D
## Cena de teste nao destrutiva do Meadow & Forest V2.
## Usa mascara de 4 cantos com as 16 transicoes do atlas 32x32.

@export var regenerate_on_start: bool = true
@export var map_width: int = 40
@export var map_height: int = 26

@onready var ground: TileMapLayer = $Ground
@onready var player_camera: Camera2D = $WorldObjects/Player/Camera2D


func _ready() -> void:
    _configure_camera_limits()
    if regenerate_on_start:
        _generate_demo()


func _configure_camera_limits() -> void:
    # O mapa tem 40x26 tiles de 32 px e esta centrado na origem.
    # Limites ajustados evitam as faixas cinzas vistas ao caminhar nas bordas.
    var origin_x: int = -int(map_width / 2)
    var origin_y: int = -int(map_height / 2)
    var bounds := Rect2(
        Vector2(float(origin_x * 32), float(origin_y * 32)),
        Vector2(float(map_width * 32), float(map_height * 32))
    )
    player_camera.call("configure_world_bounds", bounds)


func _generate_demo() -> void:
    ground.clear()
    var first_x: int = -int(map_width / 2)
    var first_y: int = -int(map_height / 2)
    for y in range(first_y, first_y + map_height):
        for x in range(first_x, first_x + map_width):
            # NW=1, NE=2, SE=4, SW=8; cantos calculados
            # nas mesmas coordenadas para garantir continuidade.
            var mask: int = 0
            if _forest_corner(x, y):
                mask |= 1
            if _forest_corner(x + 1, y):
                mask |= 2
            if _forest_corner(x + 1, y + 1):
                mask |= 4
            if _forest_corner(x, y + 1):
                mask |= 8
            ground.set_cell(Vector2i(x, y), 0, Vector2i(mask % 8, mask >> 3))


func _forest_corner(x: int, y: int) -> bool:
    var fx: float = float(x)
    var fy: float = float(y)
    var edge_left: float = -13.0 + sin(fy * 0.21) * 2.2
    var edge_right: float = 11.0 + sin(fy * 0.28 + 1.2) * 2.5
    var in_left_forest: bool = fx < edge_left
    var in_right_forest: bool = fx > edge_right and fy < 3.0
    var island_x: float = (fx + 0.5) / 6.0
    var island_y: float = (fy - 7.0) / 3.8
    var island: bool = island_x * island_x + island_y * island_y < 1.0
    return in_left_forest or in_right_forest or island
