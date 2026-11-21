extends RefCounted
## Itens do jogo: nome, ícone e tipo (tool, seed, crop, food). Ícones PixelLab em
## assets/ui/items/; colheitas usam o último estágio da cultura (recortado).

const CROPS := preload("res://scripts/systems/crop_catalog.gd")
const ICONS := "res://assets/ui/items/%s.png"

const TOOLS := ["enxada", "regador"]
const ITEMS := {
	"enxada": {"name": "Enxada", "kind": "tool", "icon": "enxada"},
	"regador": {"name": "Regador", "kind": "tool", "icon": "regador"},
	"semente_cenoura": {"name": "Sementes de cenoura", "kind": "seed", "icon": "semente_cenoura", "crop": "cenoura"},
	"semente_beterraba": {"name": "Sementes de beterraba", "kind": "seed", "icon": "semente_beterraba", "crop": "beterraba"},
	"semente_repolho": {"name": "Sementes de repolho", "kind": "seed", "icon": "semente_repolho", "crop": "repolho"},
	"sementes_silvestres": {"name": "Sementes silvestres", "kind": "seed", "icon": "sementes_silvestres", "crop": "folhas_silvestres"},
	"cenoura": {"name": "Cenoura", "kind": "crop", "crop_art": "cenoura"},
	"beterraba": {"name": "Beterraba", "kind": "crop", "crop_art": "beterraba"},
	"repolho": {"name": "Repolho", "kind": "crop", "crop_art": "repolho"},
	"folhas_frescas": {"name": "Folhas frescas", "kind": "crop", "crop_art": "folhas_silvestres"},
	# Porção cozida na estação do Vale (valley_cooking.RECIPE_ID): alimenta melhor os slimes.
	"porcao_folhas_prototipo": {"name": "Porção de folhas", "kind": "food", "icon": "porcao_folhas"},
}
## Ordem dos itens na barra depois das ferramentas.
const ORDER := ["semente_cenoura", "semente_beterraba", "semente_repolho", "sementes_silvestres",
	"cenoura", "beterraba", "repolho", "folhas_frescas", "porcao_folhas_prototipo"]

static var _icon_cache: Dictionary = {}


static func info(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {"name": item_id.capitalize(), "kind": "other"})


static func kind(item_id: String) -> String:
	return str(info(item_id).get("kind", "other"))


static func icon(item_id: String) -> Texture2D:
	if _icon_cache.has(item_id):
		return _icon_cache[item_id]
	var data := info(item_id)
	var texture: Texture2D = null
	if data.has("icon") and ResourceLoader.exists(ICONS % data.icon):
		texture = load(ICONS % data.icon)
	elif data.has("crop_art"):
		var stages: Array = CROPS.get_crop(str(data.crop_art)).stages
		var art: Texture2D = load(stages[stages.size() - 1])
		var atlas := AtlasTexture.new()
		atlas.atlas = art
		atlas.region = Rect2(art.get_image().get_used_rect())
		texture = atlas
	_icon_cache[item_id] = texture
	return texture
