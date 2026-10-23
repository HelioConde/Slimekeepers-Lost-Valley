extends TileMapLayer
## Uma clareira de demonstração editável: NÃO substitui o mapa principal.
## Tile 32x32; atlas em res://assets/tilesets/grass_dirt_v3_32x32.png
## São 16 padrões: canto superior esquerdo=1, superior direito=2,
## inferior esquerdo=4, inferior direito=8. Mapa de teste determinístico.

@export var world_width: int = 36
@export var world_height: int = 24
@export var build_on_ready: bool = true

func _ready() -> void:
    if build_on_ready and get_used_cells().is_empty():
        generate_demo()

func _corner_is_dirt(x: int, y: int) -> bool:
    var fx: float = float(x)
    var fy: float = float(y)
    # Estrada principal com ondulação suave e duas ramificações.
    var main_y: float = 13.2 + sin(fx * 0.22) * 1.45
    var main_path: bool = absf(fy - main_y) < 1.10
    var branch_x: float = 25.0 + sin(fy * 0.22) * 1.1
    var branch: bool = fy < 13.0 and absf(fx - branch_x) < 1.10
    var left_patch: bool = (Vector2(fx, fy) - Vector2(8.0, 6.0)).length() < 2.4
    var right_patch: bool = (Vector2(fx, fy) - Vector2(31.0, 19.0)).length() < 2.0
    return main_path or branch or left_patch or right_patch

func generate_demo() -> void:
    clear()
    for y in range(-int(world_height / 2), int(world_height / 2)):
        for x in range(-int(world_width / 2), int(world_width / 2)):
            var gx: int = x + int(world_width / 2)
            var gy: int = y + int(world_height / 2)
            var mask: int = 0
            if _corner_is_dirt(gx, gy): mask |= 1
            if _corner_is_dirt(gx + 1, gy): mask |= 2
            if _corner_is_dirt(gx, gy + 1): mask |= 4
            if _corner_is_dirt(gx + 1, gy + 1): mask |= 8
            set_cell(Vector2i(x, y), 0, Vector2i(mask % 8, int(mask / 8)))
