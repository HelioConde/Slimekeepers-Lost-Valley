extends Node2D
## Lago encantado da Clareira (referência V9): margem úmida, vegetação aquática
## mágica com partículas e reflexos, luz do lago no entorno e névoa rente à água.
## Criado em tempo de execução sobre NaturalSpring, sem editar a cena.
## - Plantas mágicas brilham sempre à noite; o reflexo da lua (shader) depende
##   do horário: as duas coisas são independentes.
## - Poucas partículas por planta, com três comportamentos (sobe, paira, cintila).

const LILY_GLOW := preload("res://assets/world/pond/lily_glow.png")
const LILY_PAD := preload("res://assets/world/pond/lily_pad.png")
const REEDS := preload("res://assets/world/pond/reeds_glow.png")
const LIGHTS := preload("res://scripts/world/ambient_lights.gd")
const GLOW_LILAC := Color(0.78, 0.6, 1.0)
const GLOW_CYAN := Color(0.45, 0.9, 1.0)
## Posições locais ao Pool (elipse da água ~86×46).
const PADS := [Vector2(-50, -12), Vector2(-28, 14), Vector2(36, 12), Vector2(58, -8), Vector2(-60, 6), Vector2(6, 18)]
const GLOWING_LILIES := [Vector2(-40, 0), Vector2(46, 0), Vector2(-8, 22)]
const REED_SPOTS := [Vector2(-88, -6), Vector2(-70, -34), Vector2(84, 22), Vector2(-60, 40)]

var water: Polygon2D
var pool: Node2D
var glows: Array[CanvasItem] = []      # halos e reflexos luminosos (só à noite)
var emitters: Array[CPUParticles2D] = []
var mists: Array[Sprite2D] = []
var light: PointLight2D
var moon: Sprite2D  # brilho do reflexo da lua (aditivo, não escurece com a noite)
var _time := 0.0


static func halo_texture(size: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = size
	texture.height = size
	return texture


func setup(spring: Node2D, decorations: Node2D) -> void:
	name = "PondMagic"
	pool = spring.get_node("Pool")
	water = pool.get_node("Water")
	water.light_mask = 2  # a luz do lago ilumina o entorno, não a própria água
	# Margem: sem o anel escuro grosso; só chão úmido estreito e translúcido.
	for ring in ["BankShadow", "StoneBank"]:
		var node := pool.get_node_or_null(ring) as CanvasItem
		if node: node.visible = false
	var wet := pool.get_node_or_null("WetBank") as Polygon2D
	if wet: wet.color = Color(0.2, 0.33, 0.27, 0.55)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for at in PADS:
		_sprite(pool, LILY_PAD, at, PADS.find(at) % 2 == 0)
	for i in GLOWING_LILIES.size():
		var at: Vector2 = GLOWING_LILIES[i]
		var flower := _sprite(pool, LILY_GLOW, at, i % 2 == 1)
		_reflection(pool, LILY_GLOW, at + Vector2(0, 10), GLOW_LILAC, additive)
		_halo(pool, at + Vector2(0, -2), 40, GLOW_LILAC, additive)
		_particles(flower, GLOW_LILAC, i)
	for i in REED_SPOTS.size():
		var at: Vector2 = pool.global_position + REED_SPOTS[i]
		var holder := Node2D.new()
		holder.name = "PondReeds_%d" % i
		holder.position = decorations.to_local(at)
		decorations.add_child(holder)
		var reeds := Sprite2D.new()
		reeds.name = "Sprite"
		reeds.texture = REEDS
		reeds.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		reeds.offset = Vector2(0, -21)
		reeds.flip_h = i % 2 == 0
		holder.add_child(reeds)
		_halo(holder, Vector2(0, -36), 28, GLOW_CYAN, additive)
		_particles(holder, GLOW_CYAN, i + 3, Vector2(0, -36))
	# Reflexo da lua: disco pixelado aditivo sobre o núcleo do shader, para o
	# branco-prateado vencer o escurecimento noturno. Linhas finas o cortam (ondas).
	moon = Sprite2D.new()
	moon.name = "MoonReflection"
	moon.texture = moon_texture()
	moon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	moon.material = additive
	moon.position = Vector2(85.0 * 0.18, -48.0 * 0.28).round()
	moon.modulate.a = 0.0
	pool.add_child(moon)
	# Luz fria do lago sobre pedras, arbustos e o personagem próximos.
	light = PointLight2D.new()
	light.name = "PondLight"
	light.texture = halo_texture(256)
	light.texture_scale = 1.8
	light.color = Color(0.7, 0.86, 1.0)
	light.energy = 0.0
	light.position = pool.position
	add_child(light)
	# Névoa rente à água: três véus lentos, translúcidos, sem cobrir o reflexo.
	var veil := halo_texture(64)
	for i in 3:
		var mist := Sprite2D.new()
		mist.texture = veil
		mist.scale = Vector2(2.6, 0.55)
		mist.modulate = Color(0.6, 0.78, 1.0, 0.0)
		mist.material = additive
		mist.position = pool.position + Vector2(-50 + i * 50, 30 - i * 22)
		mist.z_index = 1
		add_child(mist)
		mists.append(mist)


static func moon_texture() -> ImageTexture:
	var image := Image.create(28, 18, false, Image.FORMAT_RGBA8)
	for y in 18:
		for x in 28:
			var q := Vector2((x - 13.5) / 13.0, (y - 8.5) / 8.0)
			var r := q.length()
			if r > 1.0: continue
			var c := Color(0.95, 0.98, 1.0, 1.0) if r < 0.62 else Color(0.62, 0.78, 1.0, 0.75)
			if y in [5, 12] and (x + y) % 5 != 0: c.a *= 0.25  # linhas de onda cortando o disco
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


func _sprite(parent: Node2D, texture: Texture2D, at: Vector2, flip: bool) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = at
	sprite.flip_h = flip
	sprite.scale = Vector2(0.75, 0.75) if parent == pool else Vector2.ONE  # vitórias-régias em escala do lago
	parent.add_child(sprite)
	return sprite


## Reflexo da flor luminosa: cópia invertida abaixo dela, mesma cor, mais fraca.
func _reflection(parent: Node2D, texture: Texture2D, at: Vector2, color: Color, material: Material) -> void:
	var mirror := _sprite(parent, texture, at, false)
	mirror.flip_v = true
	mirror.scale = Vector2(1.0, 0.6)
	mirror.material = material
	mirror.modulate = Color(color.r, color.g, color.b, 0.0)
	mirror.set_meta("max_alpha", 0.3)
	glows.append(mirror)


func _halo(parent: Node2D, at: Vector2, size: int, color: Color, material: Material) -> void:
	var halo := Sprite2D.new()
	halo.texture = halo_texture(size)
	halo.position = at
	halo.material = material
	halo.modulate = Color(color.r, color.g, color.b, 0.0)
	halo.set_meta("max_alpha", 0.45)
	parent.add_child(halo)
	glows.append(halo)


## Três comportamentos alternados: sobe devagar, paira rente, cintila e some.
func _particles(parent: Node2D, color: Color, kind: int, at: Vector2 = Vector2.ZERO) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = 3
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 6.0
	p.color = color
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.emitting = false
	match kind % 3:
		0:  # sobe
			p.lifetime = 4.0
			p.gravity = Vector2(0, -6)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 5.0
		1:  # paira rente à água
			p.lifetime = 5.0
			p.gravity = Vector2.ZERO
			p.direction = Vector2(1, 0)
			p.spread = 180.0
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 4.0
		2:  # cintila e some
			p.lifetime = 1.2
			p.gravity = Vector2(0, -2)
			p.initial_velocity_min = 0.0
			p.initial_velocity_max = 2.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.25, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = glow
	parent.add_child(p)
	emitters.append(p)


func apply_time(minutes: float, delta: float) -> void:
	_time += delta
	var night := LIGHTS.night_factor(minutes)
	var material := water.material as ShaderMaterial
	if material:
		material.set_shader_parameter("moon_strength", smoothstep(0.4, 1.0, night))
	for i in glows.size():
		var item := glows[i]
		var pulse := 0.85 + 0.15 * sin(_time * 1.4 + i * 1.9)
		item.modulate.a = float(item.get_meta("max_alpha", 0.4)) * night * pulse
	for p in emitters:
		p.emitting = night > 0.5
	light.energy = 0.2 * night
	var moon_strength := smoothstep(0.4, 1.0, night)
	moon.modulate.a = 0.55 * moon_strength * (0.9 + 0.1 * sin(_time * 0.8))
	moon.position.x = round(85.0 * 0.18 + sin(_time * 0.3))
	for i in mists.size():
		var mist := mists[i]
		mist.modulate.a = 0.06 * night * (0.7 + 0.3 * sin(_time * 0.3 + i * 2.0))  # mínima: não borrar a água
		mist.position.x = pool.position.x + (-50 + i * 50) + sin(_time * 0.12 + i * 1.3) * 18.0


func _process(delta: float) -> void:
	apply_time(GameClock.get_hour() * 60.0 + GameClock.get_minute(), delta)
