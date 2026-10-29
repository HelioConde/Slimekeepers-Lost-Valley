extends SceneTree
const PACK := "res://docs/asset_review/provided_pack_20261025/Slimekeepers_Sprites_Tela_Inicial/"

func _initialize() -> void:
	call_deferred("_preview")

func _preview() -> void:
	root.size = Vector2i(1400,850)
	root.content_scale_size = Vector2i.ZERO
	var canvas := Control.new()
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	var samples := ["02_Casa/casa_principal.png","03_Arvores/arvore_verde_grande.png","04_Agua_Cachoeiras/cachoeira_grande_com_lago.png","06_Plantacoes_Objetos/canteiro_hortalicas.png","03_Arvores/cerejeira_rosa.png","06_Plantacoes_Objetos/cerca_longa.png","02_Casa/floreira_01.png","09_Decoracoes/ponte_madeira.png"]
	for index in range(samples.size()):
		var cell := Control.new()
		cell.position = Vector2((index%4)*350,(index/4)*425)
		canvas.add_child(cell)
		for side in range(2):
			var backdrop := ColorRect.new()
			backdrop.position = Vector2(side*175,0)
			backdrop.size = Vector2(175,425)
			backdrop.color = Color("#729453") if side==0 else Color("#49303b")
			cell.add_child(backdrop)
		var caption := Label.new()
		caption.text = str(samples[index]).get_file()
		caption.add_theme_font_size_override("font_size",18)
		caption.position = Vector2(8,8)
		cell.add_child(caption)
		var source := Image.load_from_file(PACK+str(samples[index]))
		var sprite := Sprite2D.new()
		sprite.texture = ImageTexture.create_from_image(source)
		sprite.position = Vector2(175,230)
		if source.get_width() < 150: sprite.scale = Vector2(2,2)
		cell.add_child(sprite)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/asset_review/pack_on_backdrops.png")
	quit()
