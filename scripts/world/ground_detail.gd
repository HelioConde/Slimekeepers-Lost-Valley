extends Node2D
## Detalhe de chão por tipo de terreno (V6): quebra a grama lisa sem espalhar os
## mesmos objetos por igual.
## - Clareira aberta: grupos de flores silvestres de uma espécie, com vazios entre
##   eles. Um ruído de baixa frequência decide onde há grupo; o resto fica livre.
## - Borda de árvore: folhas caídas, brotos e pedrinhas junto às raízes.
## - Beira de trilha: só pedrinhas e capim, sem nada no leito do caminho.
## Determinístico (hash por célula): o mesmo mapa sempre recebe o mesmo arranjo.
## Coordenadas locais do layout da Clareira (o nó fica em (1600, 1600), como
## WoodlandDetails e VegetationHigh).

const Layout := preload("res://scripts/world/clearing_layout.gd")
const ART := "res://assets/world/ground/%s.png"
const CELL := 36.0
const SPAWN_FREE := 80.0  # área livre em volta do ponto de início
const SLIME_FREE := 56.0
const TRAIL_FREE := 30.0  # leito do caminho
const TRAIL_EDGE := 58.0
const TREE_EDGE := 78.0
const RIM_DEPTH := 60.0  # faixa junto à borda da clareira: arbustos e folhas
## Tipos fora de assets/world/ground.
const PATHS := {
	"grass": "res://assets/menu/environment/grass.png",
	"bush": "res://assets/world/forest/bush_lush_round.png",
}

var area := Rect2()  # vazio = clareira inteira
var tree_feet: Array[Vector2] = []
var wind_material: Material
var bush_parent: Node2D  # arbustos são de pé: vão para um grupo com ordenação por Y
## Áreas reservadas (água etc.): [{center: Vector2, radius: Vector2}] em coordenadas
## locais; nada é posto dentro da elipse ampliada pela margem do objeto.
var avoid: Array[Dictionary] = []
var placed: Array[Dictionary] = []  # {kind, at} para testes e depuração

var _noise := FastNoiseLite.new()
var _species := FastNoiseLite.new()
var _textures: Dictionary = {}


func _init() -> void:
	name = "GroundDetail"
	position = Vector2(1600, 1600)
	z_index = -4  # cobertura de chão, sempre abaixo de personagens
	_noise.seed = 60621
	_noise.frequency = 0.012
	_species.seed = 7717
	_species.frequency = 0.006


## Zona de um ponto: "trail_bed", "trail_edge", "root", "rim", "open" ou "" (fora).
func zone_at(at: Vector2, paths: Dictionary) -> String:
	if at.distance_to(Layout.SPAWN) < SPAWN_FREE: return ""
	for area in avoid:
		var margin := Vector2(70, 60)  # cobre a copa de um arbusto em pé
		if ((at - area.center) / (area.radius + margin)).length() < 1.0: return ""
	for slime in Layout.SLIME_POSITIONS:
		if at.distance_to(slime) < SLIME_FREE: return ""
	var trail := Layout.trail_distance(at, paths)
	if trail < TRAIL_FREE: return "trail_bed"
	var near_tree := INF
	for foot in tree_feet:
		near_tree = minf(near_tree, at.distance_to(foot))
	if near_tree < 26.0: return ""  # o tronco e a colisão ficam limpos
	if near_tree < TREE_EDGE: return "root"
	if trail < TRAIL_EDGE: return "trail_edge"
	if Layout.inside_clearing(at, 40.0):
		return "open" if Layout.inside_clearing(at, 40.0 - RIM_DEPTH) else "rim"
	return ""


func build() -> void:
	var paths := Layout.trails()
	var bounds := area if area.has_area() else Rect2(Layout.SPAWN - Vector2(360, 360), Vector2(720, 720))
	var cells := Vector2i((bounds.size / CELL).ceil())
	for cy in cells.y:
		for cx in cells.x:
			var key := Vector2i(int(bounds.position.x / CELL) + cx, int(bounds.position.y / CELL) + cy)
			var at := (Vector2(key) + Vector2(_rand(key, 1), _rand(key, 2))) * CELL
			match zone_at(at, paths):
				"open": _open(at, key)
				"root": _root(at, key)
				"rim": _rim(at, key, paths)
				"trail_edge": if _rand(key, 3) < 0.2: _put("pebbles" if _rand(key, 4) < 0.15 else "grass_tuft_sunlit", at, key)


func _open(at: Vector2, key: Vector2i) -> void:
	var density := _noise.get_noise_2dv(at)
	if density > 0.3:
		# Poucos grupos, de uma espécie só (2–4 flores); amarelas mais raras que lilás.
		var kind := "wildflower_yellow" if _species.get_noise_2dv(at) > 0.25 else "wildflower_lilac"
		for i in 2 + int(_rand(key, 5) * 3.0):
			var offset := Vector2(_rand(key, 10 + i) - 0.5, _rand(key, 20 + i) - 0.5) * Vector2(28, 16)
			_put(kind, at + offset, key, i)
		if _rand(key, 6) < 0.5: _put("grass", at + Vector2(18, 8), key, 9)
	elif density > -0.05 and _rand(key, 7) < 0.3:
		# Variações de grama em volta dos grupos; o resto da clareira fica aberto.
		var r := _rand(key, 8)
		_put("grass" if r < 0.45 else "grass_tuft_sunlit" if r < 0.8 else "clover_sprig", at, key)


func _rim(at: Vector2, key: Vector2i, paths: Dictionary) -> void:
	var r := _rand(key, 12)
	# Arbustos só na moldura da clareira, longe dos caminhos e um a cada poucos metros.
	if r < 0.2 and bush_parent and Layout.trail_distance(at, paths) > 80.0 and (key.x + key.y) % 2 == 0 and _free_of_props(at):
		_bush(at, key)
	elif r < 0.45: _put("fallen_leaves", at, key)
	elif r < 0.65: _put("grass", at, key)


func _root(at: Vector2, key: Vector2i) -> void:
	var r := _rand(key, 11)
	# Refs. V9: flores sob a borda das copas (o centro aberto continua livre).
	if r < 0.3: _put("fallen_leaves", at, key)
	elif r < 0.55:
		var kind := "wildflower_lilac" if _rand(key, 13) < 0.6 else "wildflower_yellow"
		_put(kind, at, key)
		_put(kind, at + Vector2(10, 4), key, 1)
	elif r < 0.72: _put("clover_sprig", at, key)
	elif r < 0.8: _put("pebbles", at, key)


## Arbusto novo não cobre pedra, toco ou arbusto que já estão na cena.
func _free_of_props(at: Vector2) -> bool:
	for prop in bush_parent.get_children():
		if prop is Node2D and (prop as Node2D).position.distance_to(at) < 70.0:
			return false
	return true


func _texture(kind: String) -> Texture2D:
	if not _textures.has(kind):
		_textures[kind] = load(PATHS.get(kind, ART % kind))
	return _textures[kind]


func _bush(at: Vector2, key: Vector2i) -> void:
	var holder := Node2D.new()
	holder.name = "GroundBush_%d_%d" % [key.x, key.y]
	holder.position = at.round()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = _texture("bush")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.position = Vector2(-48, -81)  # mesma montagem dos Underbrush da cena
	sprite.flip_h = _rand(key, 40) < 0.5
	if wind_material: sprite.material = wind_material
	holder.add_child(sprite)
	bush_parent.add_child(holder)
	placed.append({"kind": "bush", "at": at})


func _put(kind: String, at: Vector2, key: Vector2i, index: int = 0) -> void:
	_texture(kind)
	var sprite := Sprite2D.new()
	sprite.texture = _textures[kind]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = at.round()
	sprite.offset = Vector2(0, -12)  # base do sprite no ponto
	sprite.flip_h = _rand(key, 30 + index) < 0.5
	if wind_material and kind in ["wildflower_yellow", "wildflower_lilac", "grass_tuft_sunlit", "clover_sprig", "grass"]:
		sprite.material = wind_material
	add_child(sprite)
	placed.append({"kind": kind, "at": at})


static func _rand(key: Vector2i, salt: int) -> float:
	return float(posmod(hash(Vector3i(key.x, key.y, salt)), 10000)) / 10000.0
