extends RefCounted
## Culturas da fazenda: estágios (sprites PixelLab já exportados, 48×48), semente e
## colheita. Cresce um estágio por dia em que a terra foi regada.

const ART := "res://assets/objects/pixellab_exports/crop_growth_stages_set_of_si_%s/crop_growth_stages_set_of_si.png"
const SEED_MOUND := "6db55afd"

const CROPS := {
	"cenoura": {"name": "Cenoura", "seed": "semente_cenoura", "harvest": "cenoura",
		"stages": [SEED_MOUND, "52a49051", "a1536cea", "da7b84bb", "b13c2714"]},
	"beterraba": {"name": "Beterraba", "seed": "semente_beterraba", "harvest": "beterraba",
		"stages": [SEED_MOUND, "66f68c6d", "72d86ab5", "36b6e132", "bf92d2a6"]},
	"repolho": {"name": "Repolho", "seed": "semente_repolho", "harvest": "repolho",
		"stages": [SEED_MOUND, "52a49051", "da7b84bb", "88c7e97f", "e88ba163"]},
	# Sementes silvestres coletadas com o Brotinho na Floresta: viram folhas frescas.
	"folhas_silvestres": {"name": "Folhas silvestres", "seed": "sementes_silvestres", "harvest": "folhas_frescas",
		"stages": [SEED_MOUND, "cb446daf", "66f68c6d", "36b6e132"]},
}

## Ordem em que as sementes aparecem ao trocar com [R].
const ORDER := ["cenoura", "beterraba", "repolho", "folhas_silvestres"]


static func ids() -> Array:
	return ORDER.duplicate()


static func get_crop(id: String) -> Dictionary:
	if not CROPS.has(id):
		return {}
	var crop: Dictionary = CROPS[id].duplicate(true)
	var paths: Array[String] = []
	for key in crop.stages:
		paths.append(ART % key)
	crop.stages = paths
	return crop


static func crop_for_seed(seed_item: String) -> String:
	for id in ORDER:
		if CROPS[id].seed == seed_item:
			return id
	return ""


static func last_stage(id: String) -> int:
	return (CROPS[id].stages as Array).size() - 1 if CROPS.has(id) else 0
