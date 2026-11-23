extends RefCounted
## Shared personality and genuine artwork. No species-specific creature scripts.
const DEFINITIONS := {
	"brotinho": {"name": "Brotinho", "curiosity": 0.65, "shyness": 0.3, "energy": 0.65, "sociability": 0.55, "preference": "flowers", "scale": 0.86, "frames": "res://assets/slimes/bestiary/brotinho/brotinho_frames.tres"},
	"musguinho": {"name": "Musguinho", "curiosity": 0.35, "shyness": 0.85, "energy": 0.4, "sociability": 0.3, "preference": "shade", "scale": 0.86, "frames": "res://assets/slimes/living_v3/musguinho/frames.tres"},
	"bolhinha": {"name": "Bolhinha", "curiosity": 0.9, "shyness": 0.2, "energy": 0.85, "sociability": 0.85, "preference": "water", "scale": 0.86, "frames": "res://assets/slimes/living_v3/bolhinha/frames.tres"},
	# Colhita e Carreguim (2026-11-23): moram em outros mundos (bioma ainda não criado);
	# por enquanto só chegam pelo comando de admin. Arte provisória (quadro parado) até aprovar.
	"colhita": {"name": "Colhita", "curiosity": 0.6, "shyness": 0.4, "energy": 0.7, "sociability": 0.6, "preference": "flowers", "scale": 0.86, "frames": "res://assets/slimes/living_v3/colhita/frames.tres"},
	"carreguim": {"name": "Carreguim", "curiosity": 0.4, "shyness": 0.5, "energy": 0.8, "sociability": 0.5, "preference": "shade", "scale": 0.86, "frames": "res://assets/slimes/living_v3/carreguim/frames.tres"}
}

static func definition(species: String) -> Dictionary:
	return DEFINITIONS.get(species, DEFINITIONS.brotinho).duplicate(true)

static func available(species: String) -> bool:
	return DEFINITIONS.has(species) and ResourceLoader.exists(DEFINITIONS[species].frames)
