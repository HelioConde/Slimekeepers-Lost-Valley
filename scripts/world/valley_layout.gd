extends RefCounted
## All units are world pixels. Six connected basins; elevations are visual terraces
## with solid fronts and walkable routes around their sides, not a 3D height system.
const SIZE := Vector2(3200,3200)
const SPAWN := Vector2(1600,180)
const SEED := 271026
const BRIDGES := [Rect2(470,1198,280,84), Rect2(2400,1198,280,84), Rect2(784,1510,88,340), Rect2(2266,1500,88,340), Rect2(1410,2180,320,88)]
const FALLS := [Vector2(640,650),Vector2(2470,650),Vector2(1600,1360)]
const HABITATS := [Vector2(1070,1400),Vector2(2130,1370),Vector2(1000,1980),Vector2(2220,2040),Vector2(1910,2770),Vector2(2750,2850)]

static func curve(points: Array) -> Curve2D:
	var c := Curve2D.new()
	c.bake_interval = 10
	for i in points.size():
		var tangent := Vector2.ZERO
		if i>0 and i<points.size()-1:
			tangent = (points[i+1]-points[i-1]).normalized()*minf(points[i].distance_to(points[i-1]),points[i].distance_to(points[i+1]))*.15
		c.add_point(points[i],-tangent,tangent)
	return c

static func routes() -> Dictionary:
	return {
		"EscadaOeste":curve([Vector2(260,1240),Vector2(260,850),Vector2(300,770),Vector2(360,730),Vector2(360,540),Vector2(440,530)]),
	"EscadaCentral":curve([Vector2(1100,1330),Vector2(1300,1440),Vector2(1380,1410),Vector2(1380,1220),Vector2(1440,1150)]),
	"RampaLeste":curve([Vector2(2910,1240),Vector2(2940,900),Vector2(2820,780),Vector2(2710,700),Vector2(2710,510)]),
	"Entrada":curve([Vector2(1600,70),SPAWN,Vector2(1460,500),Vector2(1350,800),Vector2(1180,1040),Vector2(980,1240)]),
		"MargemNorteOeste":curve([Vector2(260,1240),Vector2(610,1240),Vector2(980,1240),Vector2(1100,1330),HABITATS[0]]),
		"MiranteLeste":curve([Vector2(1350,800),Vector2(1720,760),Vector2(2070,1060),Vector2(2240,1240),Vector2(2540,1240),Vector2(2910,1240)]),
		"PonteOeste":curve([Vector2(980,1240),Vector2(830,1420),Vector2(828,1680),Vector2(830,1950),Vector2(1040,2170)]),
		"PonteLeste":curve([Vector2(2240,1240),Vector2(2310,1440),Vector2(2310,1670),Vector2(2310,1950),Vector2(2180,2170)]),
		"MargemSul":curve([Vector2(1040,2170),Vector2(1270,2240),Vector2(1380,2224),Vector2(1570,2224),Vector2(1780,2224),Vector2(1850,2180),Vector2(2180,2170)]),
		"JardimUmido":curve([Vector2(260,1240),Vector2(190,1670),Vector2(260,2050),Vector2(540,2180),Vector2(1040,2170)]),
		"Brejo":curve([Vector2(1040,2170),Vector2(1120,2510),Vector2(1080,2880),Vector2(1400,2970),Vector2(1780,3090)]),
		"SaidaSul":curve([Vector2(2180,2170),Vector2(2960,2200),Vector2(2980,2690),Vector2(2850,3020),Vector2(2300,3050),Vector2(1780,3090),Vector2(1780,3160)]),
		"HabitatNascenteLeste":curve([Vector2(2240,1240),HABITATS[1]]),
		"HabitatOeste":curve([Vector2(830,1950),HABITATS[2]]),
		"HabitatLeste":curve([Vector2(2310,1950),HABITATS[3]]),
		"HabitatSul":curve([Vector2(1780,3090),Vector2(1810,2900),HABITATS[4]]),
		"HabitatIlhota":curve([Vector2(2850,3020),HABITATS[5]])
	}

static func basins() -> Array:
	return [[Vector2(640,850),Vector2(310,195)], [Vector2(2470,850),Vector2(320,210)], [Vector2(1600,1730),Vector2(590,300)], [Vector2(500,1710),Vector2(245,300)], [Vector2(2700,1700),Vector2(240,340)], [Vector2(2370,2590),Vector2(410,300)]]

static func streams() -> Array:
	return [
		[curve([Vector2(640,420),Vector2(620,480),Vector2(655,550),Vector2(640,650),Vector2(640,850)]),42.0],
		[curve([Vector2(2470,410),Vector2(2440,490),Vector2(2490,570),Vector2(2470,650),Vector2(2470,850)]),42.0],
		[curve([Vector2(1600,1010),Vector2(1640,1110),Vector2(1580,1200),Vector2(1600,1360),Vector2(1600,1540)]),40.0],
		[curve([Vector2(660,970),Vector2(610,1240),Vector2(500,1550)]),55.0],
		[curve([Vector2(2470,1010),Vector2(2540,1240),Vector2(2700,1550)]),55.0],
		[curve([Vector2(650,1700),Vector2(828,1680),Vector2(1110,1680)]),55.0],
		[curve([Vector2(2100,1670),Vector2(2310,1670),Vector2(2600,1670)]),55.0],
		[curve([Vector2(1600,1910),Vector2(1570,2224),Vector2(1810,2460),Vector2(2110,2590)]),65.0]
	]

static func blob(at: Vector2, radius: Vector2, seed_: float = 0, count: int = 48) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in count:
		var a := TAU*i/count
		var r := 1.0 + sin(a*3+seed_)*.075 + cos(a*7-seed_)*.035
		result.append((at+Vector2(cos(a),sin(a))*radius*r).snapped(Vector2(2,2)))
	return result

static func ribbon(c: Curve2D, half_width: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var length := c.get_baked_length()
	for i in range(int(ceil(length/12))+1):
		var t := minf(i*12,length)
		var at := c.sample_baked(t)
		var tangent := (c.sample_baked(minf(t+2,length))-c.sample_baked(maxf(t-2,0))).normalized()
		var n := Vector2(-tangent.y,tangent.x)*half_width
		left.append((at+n).snapped(Vector2(2,2)))
		right.append((at-n).snapped(Vector2(2,2)))
	right.reverse()
	left.append_array(right)
	return left

static func route_distance(at: Vector2, paths: Dictionary) -> float:
	var d := INF
	for c: Curve2D in paths.values():
		d = minf(d,at.distance_to(c.get_closest_point(at)))
	return d
