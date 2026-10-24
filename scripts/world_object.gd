@tool
extends Node2D
## Prefab reutilizavel: sempre consulta a escala global.
const Scales = preload("res://scripts/world_object_scales.gd")

@export_dir var asset_folder: String = "":
	set(value):
		asset_folder = value
		if is_inside_tree():
			call_deferred("refresh_object")

@export var solid: bool = false:
	set(value):
		solid = value
		if is_inside_tree():
			call_deferred("refresh_object")

@export_range(0.5, 1.5, 0.05) var variation: float = 1.0:
	set(value):
		variation = value
		if is_inside_tree():
			call_deferred("refresh_object")

@onready var artwork: Sprite2D = $Artwork
@onready var footprint: CollisionShape2D = $SolidBody/Footprint

func _ready() -> void:
	refresh_object()

func refresh_object() -> void:
	if not is_node_ready():
		return
	artwork.texture = null
	footprint.disabled = true
	if asset_folder.is_empty():
		return
	var folder: String = Scales.folder_path(asset_folder)
	var texture: Texture2D = Scales.preview_texture(folder)
	if texture == null:
		push_warning("Sprite PixelLab nao encontrado: %s" % folder)
		return
	var id: String = folder.get_file()
	var size: float = Scales.scale_for(id, texture) * variation
	artwork.texture = texture
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	artwork.scale = Vector2.ONE * size
	artwork.offset = Scales.anchor_offset(texture)
	if solid:
		var used: Rect2i = Scales.visible_rect(texture)
		var width: float = clampf(float(used.size.x) * size * 0.40, 6.0, 46.0)
		var height: float = clampf(float(used.size.y) * size * 0.18, 4.0, 16.0)
		var collision := RectangleShape2D.new()
		collision.size = Vector2(width, height)
		footprint.shape = collision
		footprint.position = Vector2(0.0, -height * 0.5)
		footprint.disabled = false
