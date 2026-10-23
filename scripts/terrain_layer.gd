@tool
extends TileMapLayer
## Terreno inicial: reconstrui no mapa os tiles 32x32 da exportacao PixelLab
## (atlas 1536x512 -> 48 colunas x 16 linhas). Nenhuma imagem e modificada.
## No editor a pintura inicial aparece automaticamente e pode ser salva (Ctrl+S).
## Depois de pintar pelo editor, o script NAO sobrescreve suas celulas.

const SOURCE_ID: int = 0
const GRID_SIZE: int = 32
const WALL_THICKNESS: float = 16.0
const ATLAS_COLUMNS: int = 48
const ATLAS_ROWS: int = 16
const MAP_TOP_LEFT: Vector2i = Vector2i(-24, -8)

@export var paint_when_empty: bool = true
@export var boundary_collisions: bool = true


func _ready() -> void:
    if Engine.is_editor_hint():
        # Evita alterar a cena durante a desserializacao do editor.
        call_deferred("_paint_initial_map")
    else:
        _paint_initial_map()
        if boundary_collisions:
            _add_play_area_boundaries()


func _paint_initial_map() -> void:
    if not paint_when_empty or not get_used_cells().is_empty():
        return
    if tile_set == null:
        push_error("Terrain: associe o TileSet resources/terrain_grass_dirt.tres")
        return

    var atlas: TileSetAtlasSource = tile_set.get_source(SOURCE_ID) as TileSetAtlasSource
    if atlas == null:
        push_error("Terrain: fonte 0 nao e TileSetAtlasSource")
        return
    var grid: Vector2i = atlas.get_atlas_grid_size()
    if grid.x < ATLAS_COLUMNS or grid.y < ATLAS_ROWS:
        push_error("Terrain: atlas menor que 48x16 tiles; confira tile_size=32")
        return

    # Importante: a exportacao PixelLab e uma composicao pronta. Copiar
    # cada tile para a mesma posicao reproduz o desenho sem emendas internas.
    for y in range(ATLAS_ROWS):
        for x in range(ATLAS_COLUMNS):
            set_cell(MAP_TOP_LEFT + Vector2i(x, y), SOURCE_ID, Vector2i(x, y), 0)


func _add_play_area_boundaries() -> void:
    # Asfalto/terra/grama nao bloqueiam o jogador; apenas o contorno do demo.
    var used: Rect2i = get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return
    var left: float = float(used.position.x * GRID_SIZE)
    var top: float = float(used.position.y * GRID_SIZE)
    var right: float = float(used.end.x * GRID_SIZE)
    var bottom: float = float(used.end.y * GRID_SIZE)
    var width: float = right - left
    var height: float = bottom - top
    _add_wall(Vector2((left + right) * 0.5, top - WALL_THICKNESS * 0.5), Vector2(width + WALL_THICKNESS * 2.0, WALL_THICKNESS))
    _add_wall(Vector2((left + right) * 0.5, bottom + WALL_THICKNESS * 0.5), Vector2(width + WALL_THICKNESS * 2.0, WALL_THICKNESS))
    _add_wall(Vector2(left - WALL_THICKNESS * 0.5, (top + bottom) * 0.5), Vector2(WALL_THICKNESS, height))
    _add_wall(Vector2(right + WALL_THICKNESS * 0.5, (top + bottom) * 0.5), Vector2(WALL_THICKNESS, height))


func _add_wall(center: Vector2, dimensions: Vector2) -> void:
    var wall: StaticBody2D = StaticBody2D.new()
    wall.name = "WorldBoundary"
    wall.collision_layer = 1
    wall.collision_mask = 0
    wall.position = center
    add_child(wall)

    var hitbox: CollisionShape2D = CollisionShape2D.new()
    var shape: RectangleShape2D = RectangleShape2D.new()
    shape.size = dimensions
    hitbox.shape = shape
    wall.add_child(hitbox)
