@tool
extends Node2D
## Instancia reutilizavel com visualizacao no editor.
const ScaleDB = preload("res://scripts/world_object_scales.gd")
@export_dir var asset_folder: String = "":
	set(v):
		asset_folder = v
		if is_inside_tree():
			call_deferred("refresh_object")
@export var solid: bool = false:
	set(v):
		solid = v
		if is_inside_tree():
			call_deferred("refresh_object")
@export_range(0.5, 1.5, 0.05) var variation: float = 1.0:
	set(v):
		variation = v
		if is_inside_tree():
			call_deferred("refresh_object")
@onready var art: Sprite2D = $Artwork
@onready var shape_node: CollisionShape2D = $SolidBody/Footprint

func _ready() -> void:
	refresh_object()

func refresh_object() -> void:
	if not is_node_ready():
		return
	art.texture = null
	shape_node.disabled = true
	if asset_folder.is_empty():
		return
	var folder: String = ScaleDB.folder_path(asset_folder)
	var tex: Texture2D = ScaleDB.preview_texture(folder)
	if tex == null:
		push_warning("Objeto PixelLab ausente: %s" % folder)
		return
	var s: float = ScaleDB.scale_for(folder.get_file(), tex) * variation
	art.texture = tex
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.scale = Vector2.ONE * s
	art.offset = ScaleDB.anchor_offset(tex)
	if solid:
		var rect: Rect2i = ScaleDB.visible_rect(tex)
		var width: float = clampf(float(rect.size.x) * s * 0.40, 6.0, 46.0)
		var height: float = clampf(float(rect.size.y) * s * 0.18, 4.0, 16.0)
		var collision := RectangleShape2D.new()
		collision.size = Vector2(width, height)
		shape_node.shape = collision
		shape_node.position = Vector2(0, -height * 0.5)
		shape_node.disabled = false
