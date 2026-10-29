extends Node2D
## Mapa provisório desenhado com tiles reais do pacote de assets.

const TILE_SIZE: int = 32
const TILE_COUNT = Vector2i(40, 30)
const ATLAS: Texture2D = preload("res://assets/tilesets/grass_dirt_v3_32x32.png")

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    queue_redraw()

func _draw() -> void:
    for y in range(TILE_COUNT.y):
        for x in range(TILE_COUNT.x):
            # Piso de grama com um caminho central de terra.
            var atlas_x: int = 0
            var atlas_y: int = 0
            if (x in range(18, 23) and y in range(1, 29)) or (y in range(13, 17) and x in range(3, 38)):
                atlas_x = 7
                atlas_y = 1
            var src := Rect2(float(atlas_x * TILE_SIZE), float(atlas_y * TILE_SIZE), TILE_SIZE, TILE_SIZE)
            var dest := Rect2(float(x * TILE_SIZE), float(y * TILE_SIZE), TILE_SIZE, TILE_SIZE)
            draw_texture_rect_region(ATLAS, dest, src)
    # Pequenas marcas de exploração com cores discretas.
    for i in range(12):
        var xx := float(96 + (i * 113) % 1080)
        var yy := float(104 + (i * 173) % 750)
        draw_circle(Vector2(xx, yy), 2.2, Color(0.89, 0.78, 0.43, 0.35))
