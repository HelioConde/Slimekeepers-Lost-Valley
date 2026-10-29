extends RefCounted
## Versioned expansion. Original clearing_layout remains available for the legacy scene.
const Legacy = preload("res://scripts/world/clearing_layout.gd")
const TILE_SIZE := 32
const MAP_TILES := Vector2i(200,200)
const WORLD_SIZE := Vector2(6400,6400)
const OFFSET := Vector2(1600,1600)
const SPAWN := Vector2(3200,3200)
const EXCLUSION := 960.0
const SOUTH_EXIT := Vector2(3220,6280)
const SOUTH_ARRIVAL := Vector2(3220,6140)
const SEED := 271027
const CORE := Rect2(1600,1600,3200,3200)

static func habitats() -> Array[Dictionary]:
	return [
		{"id":"H01", "name":"Jardim das Folhas", "center":Vector2(4920,3170), "radius":150.0,"population":2},
		{"id":"H02", "name":"Círculo Musgoso", "center":Vector2(1980,2120), "radius":150.0,"population":2},
		{"id":"H03", "name":"Campo dos Brotos", "center":Vector2(3240,4870), "radius":140.0,"population":2},
		{"id":"H04", "name":"Bosque Silencioso", "center":Vector2(4880,1700), "radius":150.0,"population":2}
	]

static func points_of_interest() -> Array[Dictionary]:
	return [
		{"id":"leaves", "name":"Jardim das Folhas", "at":Vector2(4480,3270), "description":"Folhas novas e flores indicam o refúgio dos Brotinhos, mais adiante pela trilha."},
		{"id":"mushrooms", "name":"Bosque dos Cogumelos", "at":Vector2(2100,2860), "description":"Cogumelos crescem à sombra das raízes antigas."},
		{"id":"old_tree", "name":"Árvore Centenária", "at":Vector2(2860,1880), "description":"As raízes guardam a memória silenciosa desta floresta."},
		{"id":"moss_circle", "name":"Círculo Musgoso", "at":Vector2(1980,2120), "description":"O musgo cobre pedras dispostas muito antes da sua chegada."},
		{"id":"time_log", "name":"Tronco do Tempo", "at":Vector2(2800,3660), "description":"Uma árvore caída se tornou abrigo para outra vida."},
		{"id":"lookout", "name":"Mirante Rochoso", "at":Vector2(5110,1260), "description":"Do pequeno platô, as copas formam um mar verde."},
		{"id":"secret_garden", "name":"Jardim Escondido", "at":Vector2(5100,4250), "description":"Flores azuis e rosadas iluminam este jardim protegido."},
		{"id":"wet_passage", "name":"Passagem Úmida", "at":Vector2(3220,5680), "description":"A umidade e o som da água anunciam o Vale das Nascentes."}
	]

static func trails() -> Dictionary:
	var paths := {}
	for label in Legacy.trails():
		var original: Curve2D = Legacy.trails()[label]
		var moved := Curve2D.new()
		moved.bake_interval = original.bake_interval
		for i in original.point_count:
			moved.add_point(original.get_point_position(i)+OFFSET,original.get_point_in(i),original.get_point_out(i))
		paths[label] = moved
	paths["NorthExtension"] = Legacy._curve([Vector2(3270,1540),Vector2(3300,1280),Vector2(3020,860),Vector2(3270,120)])
	paths["EastExtension"] = Legacy._curve([Vector2(4860,3150),Vector2(5360,3280),Vector2(5900,3040),Vector2(6280,3150)])
	paths["SouthExtension"] = Legacy._curve([Vector2(3220,4860),Vector2(3300,5260),Vector2(3200,5700),SOUTH_EXIT])
	paths["MushroomLoop"] = Legacy._curve([Vector2(2560,2790),Vector2(2320,2870),Vector2(2100,2860),Vector2(1900,2630),Vector2(1980,2120),Vector2(2510,2140),Vector2(3190,2110)])
	paths["AncientTree"] = Legacy._curve([Vector2(3190,2110),Vector2(3050,1960),Vector2(2860,1880)])
	paths["EastHabitat"] = Legacy._curve([Vector2(4290,3270),Vector2(4480,3270)])
	paths["SouthHabitat"] = Legacy._curve([Vector2(3130,4330),Vector2(3260,4460),Vector2(3350,4580),Vector2(3220,4860)])
	paths["NorthernHills"] = Legacy._curve([Vector2(3270,1540),Vector2(3790,1500),Vector2(4270,1900),Vector2(4880,1700),Vector2(5110,1480),Vector2(5370,2200),Vector2(5360,3280)])
	paths["LookoutSteps"] = Legacy._curve([Vector2(5110,1480),Vector2(5110,1260)])
	paths["HiddenGardenLoop"] = Legacy._curve([Vector2(5360,3280),Vector2(5480,3780),Vector2(5100,4250),Vector2(4660,4520),Vector2(3350,4580)])
	paths["WesternForestLoop"] = Legacy._curve([Vector2(3300,5260),Vector2(2500,5380),Vector2(1880,4980),Vector2(1310,4100),Vector2(1420,3000),Vector2(1980,2120)])
	return paths

static func open_area(at: Vector2, margin: float=0.0) -> bool:
	if at.distance_to(SPAWN) < 300+margin: return true
	for h in habitats():
		if at.distance_to(h.center) < h.radius+margin: return true
	for p in points_of_interest():
		if at.distance_to(p.at) < 120+margin: return true
	return false

static func zone(at: Vector2) -> String:
	if at.distance_to(SPAWN) < 520: return "Clareira do Despertar"
	if at.y > 5000: return "Caminho das Nascentes"
	if at.x < 2500 and at.y < 3400: return "Bosque dos Cogumelos"
	if at.x > 4500 and at.y < 2400: return "Colinas Verdes"
	if at.y < 2500: return "Mata Antiga"
	if at.x > 4200: return "Refúgio Verde"
	return "Floresta Profunda"
