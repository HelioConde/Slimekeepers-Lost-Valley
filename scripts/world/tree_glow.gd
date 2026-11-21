extends Node
## Árvores encantadas do Vale (ref. V11): uma em cada RATIO árvores (escolha
## estável pela posição) ganha um brilho quente junto ao tronco e alguns
## vagalumes girando na copa. Só à noite; tudo aditivo e preso à árvore.

const RATIO := 5
const WARM := Color(1.0, 0.65, 0.3)
## Carvalho grande (PixelLab, 128×128) para as árvores junto às pontes (ref. V11).
const GRAND_OAK := preload("res://assets/world/forest/oak_grand.png")
const GRAND_OFFSET := Vector2(-128, -220)  # base do tronco (coluna 64, linha 110) na origem, escala 2

var glows: Array[Sprite2D] = []
var flies: Array[CPUParticles2D] = []


static func chosen(at: Vector2) -> bool:
	return posmod(hash(Vector2i(at.round())), RATIO) == 0


func setup(tree_groups: Array, landmarks: Array = []) -> void:
	name = "TreeGlow"
	var tex := preload("res://scripts/world/mushroom_glows.gd").radial(40, 28, PackedFloat32Array([0.0, 0.35, 0.7]), PackedFloat32Array([0.8, 0.4, 0.0]))
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for group: Node in tree_groups:
		for tree in group.get_children():
			if not (tree is Node2D) or not tree.has_node("Sprite"): continue
			var at := (tree as Node2D).global_position
			var near_landmark := false
			for r: Rect2 in landmarks:
				if r.grow(260.0).has_point(at): near_landmark = true  # árvores junto às pontes
			if not (near_landmark or chosen(at)): continue
			if near_landmark:
				var sprite := tree.get_node("Sprite") as Sprite2D
				sprite.texture = GRAND_OAK
				sprite.position = GRAND_OFFSET
			var glow := Sprite2D.new()
			glow.texture = tex
			glow.material = additive
			glow.position = Vector2(0, -18)
			glow.modulate = Color(WARM, 0.0)
			glow.set_meta("no_shadow", true)
			tree.add_child(glow)
			glows.append(glow)
			var p := CPUParticles2D.new()
			p.amount = 5
			p.lifetime = 4.0
			p.preprocess = 2.0
			p.local_coords = false
			p.position = Vector2(0, -90)
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 46.0
			p.gravity = Vector2.ZERO
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 6.0
			p.spread = 180.0
			p.orbit_velocity_min = -0.05
			p.orbit_velocity_max = 0.05
			p.scale_amount_min = 2.0
			p.scale_amount_max = 2.5
			var ramp := Gradient.new()
			ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
			ramp.colors = PackedColorArray([Color(1, 0.9, 0.5, 0), Color(1, 0.9, 0.5, 1), Color(1, 0.8, 0.4, 0.6), Color(1, 0.8, 0.4, 0)])
			p.color_ramp = ramp
			p.material = additive
			p.z_as_relative = false
			p.z_index = 30
			p.emitting = false
			p.set_meta("no_shadow", true)
			tree.add_child(p)
			flies.append(p)


func apply_time(night: float, t: float) -> void:
	for i in glows.size():
		glows[i].modulate.a = 0.55 * night * (0.85 + 0.15 * sin(t * 1.3 + i))
	for p in flies:
		p.emitting = night > 0.5
