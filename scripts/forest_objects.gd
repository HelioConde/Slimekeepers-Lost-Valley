extends Node2D

const Scales = preload("res://scripts/world_object_scales.gd")
## Objetos decorativos e solidos no mapa de teste Meadow & Forest.
## Usa sprites PixelLab ja exportados: nenhum PNG e alterado.
## Todos os objetos usam origem no ponto de contato com o solo para Y-sorting.

@export var populate_on_start: bool = true
@export var enable_collisions: bool = true
@export var contact_shadows: bool = true

const TILE_SIZE: int = 32
const SPRITES: Dictionary = {
    "oak_small": "res://sprites/objects/tree_oak_small_small_oak_tre/rotations/tree_oak_small_small_oak_tre.png",
    "oak_medium": "res://sprites/objects/tree_oak_medium_medium_oak_t/rotations/tree_oak_medium_medium_oak_t.png",
    "oak_large": "res://sprites/objects/tree_oak_large_large_mature/rotations/tree_oak_large_large_mature.png",
    "pine": "res://sprites/objects/tree_pine_tall_evergreen_pin/rotations/tree_pine_tall_evergreen_pin.png",
    "stump": "res://sprites/objects/tree_stump_small_cut_oak_stu/rotations/tree_stump_small_cut_oak_stu.png",
    "fallen_log": "res://sprites/objects/fallen_log_mossy_fallen_oak/rotations/fallen_log_mossy_fallen_oak.png",
    "bush_small": "res://sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png",
    "bush_large": "res://sprites/objects/bush_large_large_dense_fores/rotations/bush_large_large_dense_fores.png",
    "rock": "res://sprites/objects/rock_small_small_rounded_fie/rotations/rock_small_small_rounded_fie.png",
    "grass": "res://sprites/objects/tall_grass_small_clump_of_ta/rotations/tall_grass_small_clump_of_ta.png",
    "flowers": "res://sprites/objects/wildflowers_small_cluster_of/rotations/wildflowers_small_cluster_of.png"
}
const SOLID_RADIUS: Dictionary = {
    "oak_small": 9.0,
    "oak_medium": 11.0,
    "oak_large": 13.0,
    "pine": 10.0,
    "stump": 9.0,
    "bush_small": 11.0,
    "bush_large": 15.0,
    "rock": 9.0
}

# As coordenadas sao celulas no mapa 40x26, com o jogador em (0,0).
# Nao coloque objetos sobre o ponto inicial ou bloqueando completamente os caminhos.
# "size" escala a imagem visual e sua pequena area de colisao nos pes.
const PLACEMENTS: Array[Dictionary] = [
    {"id":"oak_large","x":-17,"y":-10,"size":1.55},
    {"id":"oak_large","x":-17,"y":5,"size":1.55,"flip":true},
    {"id":"oak_large","x":16,"y":-9,"size":1.60},
    {"id":"oak_large","x":15,"y":8,"size":1.55,"flip":true},
    {"id":"oak_medium","x":-14,"y":-3,"size":1.30},
    {"id":"oak_medium","x":-12,"y":8,"size":1.25,"flip":true},
    {"id":"oak_medium","x":13,"y":-3,"size":1.30},
    {"id":"oak_medium","x":7,"y":9,"size":1.25},
    {"id":"oak_small","x":-11,"y":-11,"size":1.00},
    {"id":"oak_small","x":-7,"y":-7,"size":1.05,"flip":true},
    {"id":"oak_small","x":11,"y":-10,"size":1.05},
    {"id":"oak_small","x":12,"y":4,"size":1.00,"flip":true},
    {"id":"oak_small","x":4,"y":4,"size":1.00},
    {"id":"pine","x":-18,"y":0,"size":1.40},
    {"id":"pine","x":-15,"y":10,"size":1.35},
    {"id":"pine","x":17,"y":-3,"size":1.40},
    {"id":"pine","x":17,"y":10,"size":1.30},
    {"id":"stump","x":-7,"y":5,"size":0.85},
    {"id":"stump","x":8,"y":-7,"size":0.90},
    {"id":"fallen_log","x":-9,"y":10,"size":1.05},
    {"id":"fallen_log","x":7,"y":7,"size":1.10,"flip":true},
    {"id":"bush_large","x":-12,"y":2,"size":1.00},
    {"id":"bush_large","x":11,"y":-5,"size":1.00},
    {"id":"bush_large","x":-14,"y":-8,"size":0.95},
    {"id":"bush_small","x":-6,"y":-5,"size":0.90},
    {"id":"bush_small","x":-10,"y":5,"size":0.95},
    {"id":"bush_small","x":9,"y":3,"size":0.90},
    {"id":"bush_small","x":14,"y":6,"size":0.90},
    {"id":"rock","x":-4,"y":7,"size":0.90},
    {"id":"rock","x":6,"y":-6,"size":0.95},
    {"id":"rock","x":-13,"y":-7,"size":0.85},
    {"id":"rock","x":11,"y":10,"size":0.95},
    {"id":"rock","x":-2,"y":-9,"size":0.80},
    {"id":"grass","x":-3,"y":2,"size":0.85},
    {"id":"grass","x":5,"y":-3,"size":0.80},
    {"id":"grass","x":-6,"y":10,"size":0.85},
    {"id":"grass","x":10,"y":1,"size":0.90},
    {"id":"grass","x":-11,"y":-5,"size":0.75},
    {"id":"flowers","x":-4,"y":-4,"size":0.80},
    {"id":"flowers","x":3,"y":6,"size":0.90},
    {"id":"flowers","x":-2,"y":9,"size":0.85},
    {"id":"flowers","x":7,"y":1,"size":0.85},
    {"id":"flowers","x":-9,"y":-6,"size":0.80},
    {"id":"flowers","x":10,"y":-9,"size":0.80}
]


func _ready() -> void:
    y_sort_enabled = true
    if populate_on_start:
        populate()


func populate() -> void:
    var created: int = 0
    for item in PLACEMENTS:
        var object_id: String = str(item.get("id", ""))
        var path: String = str(SPRITES.get(object_id, ""))
        if path.is_empty() or not ResourceLoader.exists(path):
            push_warning("Sprite de objeto nao encontrado: %s" % path)
            continue
        var texture: Texture2D = load(path) as Texture2D
        if texture == null:
            push_warning("Falha ao carregar sprite: %s" % path)
            continue

        var entity: Node2D = Node2D.new()
        entity.name = "%s_%02d" % [object_id, created]
        var cell_x: int = int(item.get("x", 0))
        var cell_y: int = int(item.get("y", 0))
        entity.position = Vector2(
            float(cell_x * TILE_SIZE) + float(TILE_SIZE) * 0.5,
            float(cell_y * TILE_SIZE) + float(TILE_SIZE) * 0.5
        )
        # Variacao original e preservada; so arvores em pe usam
        # a escala fixa escolhida manualmente para a floresta.
        var variation: float = float(item.get("size", 1.0))
        var scale_factor: float = variation if Scales.is_standing_tree(object_id) else Scales.scale_for(object_id, texture) * variation
        if object_id == "grass" or object_id == "flowers":
            # Decoracoes rasteiras ficam visualmente sob os pes do jogador.
            entity.z_index = -1
        add_child(entity)
        if contact_shadows:
            _add_contact_shadow(entity, object_id, scale_factor)

        var sprite: Sprite2D = Sprite2D.new()
        sprite.texture = texture
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.scale = Vector2.ONE * scale_factor
        sprite.flip_h = bool(item.get("flip", false))
        # Alinha a base visivel da arte ao ponto (0, 0) do objeto, mesmo
        # quando a PixelLab deixa margens transparentes no canvas.
        sprite.offset = Scales.anchor_offset(texture)
        entity.add_child(sprite)

        if enable_collisions:
            _add_footprint_collision(entity, object_id, scale_factor)
        created += 1
    print("Forest demo: %d objetos posicionados." % created)



func _add_contact_shadow(entity: Node2D, object_id: String, scale_factor: float) -> void:
    if object_id == "flowers" or object_id == "grass":
        return
    var width: float = 13.0
    if object_id == "bush_large" or object_id == "fallen_log":
        width = 21.0
    elif object_id == "rock" or object_id == "stump":
        width = 10.0
    var shadow: Polygon2D = Polygon2D.new()
    shadow.name = "ContactShadow"
    var points: PackedVector2Array = PackedVector2Array()
    for i in range(16):
        var angle: float = TAU * float(i) / 16.0
        points.append(Vector2(cos(angle) * width * scale_factor, sin(angle) * 4.5 * scale_factor))
    shadow.polygon = points
    shadow.position = Vector2(0.0, -1.0)
    shadow.color = Color(0.08, 0.17, 0.07, 0.20)
    entity.add_child(shadow)

func _add_footprint_collision(entity: Node2D, object_id: String, scale_factor: float) -> void:
    if object_id != "fallen_log" and not SOLID_RADIUS.has(object_id):
        return
    var body: StaticBody2D = StaticBody2D.new()
    body.name = "SolidFootprint"
    body.collision_layer = 1
    body.collision_mask = 0
    entity.add_child(body)

    var collider: CollisionShape2D = CollisionShape2D.new()
    collider.name = "Collider"
    collider.position = Vector2(0.0, -7.0 * scale_factor)
    if object_id == "fallen_log":
        var rectangle: RectangleShape2D = RectangleShape2D.new()
        rectangle.size = Vector2(47.0, 13.0) * scale_factor
        collider.shape = rectangle
    else:
        var circle: CircleShape2D = CircleShape2D.new()
        circle.radius = float(SOLID_RADIUS.get(object_id, 8.0)) * scale_factor
        collider.shape = circle
    body.add_child(collider)
