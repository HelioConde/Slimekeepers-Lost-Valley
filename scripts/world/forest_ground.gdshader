shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
varying vec2 ground_pixel;
// Chão V8 (ground_art.gd): tile Wang escolhido pelos 4 cantos da máscara
// (1 = grama, 0 = chão de mata). Desligado (use_wang = 0) mantém o tile antigo.
uniform sampler2D wang_atlas : filter_nearest, repeat_disable;
uniform sampler2D corner_mask : filter_nearest, repeat_disable;  // R grama, G terra gasta
uniform sampler2D dirt_wang_atlas : filter_nearest, repeat_disable;
uniform float use_wang = 0.0;
// 0 de dia, 1 à noite (AmbientLights): a grama pintada não pode brilhar sob a lua.
uniform float night_dim = 0.0;
uniform float night_value = 0.9;
uniform vec3 night_tint = vec3(0.72, 0.9, 1.25);  // brilho do chão à noite (Vale mais escuro: água em destaque)
// Sol e sombra no chão aberto: a copa da mata sombreia a grama vizinha (fria),
// com manchas de luz recortadas na faixa de transição; longe dela, sol quente.
uniform float canopy_shade = 0.0;
// Sombra longa da mata no sol baixo (AmbientLights): vetor do sol em px por px de
// altura e força. Faixas: troncos projetam listras longas sobre a grama aberta.
uniform vec2 sun_vector = vec2(0.0);
uniform float long_shadow = 0.0;
uniform float golden = 0.0;  // sol baixo: grama ao sol puxa para o dourado

uniform sampler2D corner_mask_soft : filter_linear, repeat_disable;  // a mesma máscara, filtrada

float forest_near(vec2 world) {
	vec2 size = vec2(textureSize(corner_mask_soft, 0));
	vec2 cell = world / 32.0;
	float forest = 0.0;
	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			vec2 at = cell + vec2(float(dx), float(dy)) * 3.0;
			forest += 1.0 - texture(corner_mask_soft, (at + vec2(0.5)) / size).r;
		}
	}
	return forest / 9.0;
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float moss(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),f.x),f.y);
}
varying vec2 world_pixel;
void vertex() {
	ground_pixel = VERTEX;
	// O TileMapLayer desenha por quadrantes: VERTEX é local a cada um.
	world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
vec3 wang_ground(vec2 world) {
	vec2 cell = floor(world / 32.0);
	ivec2 c = ivec2(cell);
	ivec2 size = textureSize(corner_mask, 0) - ivec2(1);
	c = clamp(c, ivec2(0), size - ivec2(1));
	vec3 m_nw = texelFetch(corner_mask, c, 0).rgb;
	vec3 m_ne = texelFetch(corner_mask, c + ivec2(1, 0), 0).rgb;
	vec3 m_sw = texelFetch(corner_mask, c + ivec2(0, 1), 0).rgb;
	vec3 m_se = texelFetch(corner_mask, c + ivec2(1, 1), 0).rgb;
	// Terra gasta tem prioridade: a borda dela é sempre grama (o tile terra↔grama).
	bool dirt = max(max(m_nw.g, m_ne.g), max(m_sw.g, m_se.g)) > 0.5;
	int index = dirt
		? int(m_nw.g < 0.5) * 8 + int(m_ne.g < 0.5) * 4 + int(m_sw.g < 0.5) * 2 + int(m_se.g < 0.5)
		: int(m_nw.r > 0.5) * 8 + int(m_ne.r > 0.5) * 4 + int(m_sw.r > 0.5) * 2 + int(m_se.r > 0.5);
	ivec2 local = ivec2(mod(floor(world), 32.0));
	// Tiles cheios (só grama ou só mata) espelhados por célula: quebra a grade.
	if (index == 0 || index == 15) {
		float h = hash(cell);
		if (h > 0.5) { local.x = 31 - local.x; }
		if (fract(h * 7.0) > 0.5) { local.y = 31 - local.y; }
	}
	ivec2 at = ivec2((index % 4) * 32, (index / 4) * 32) + local;
	return dirt ? texelFetch(dirt_wang_atlas, at, 0).rgb : texelFetch(wang_atlas, at, 0).rgb;
}

void fragment() {
	if (use_wang > 0.5) {
		vec3 g = wang_ground(floor(world_pixel));
		float luma = dot(g, vec3(0.299, 0.587, 0.114));
		// Noite: menos saturação e valor, puxando para o azul do luar.
		if (canopy_shade > 0.0) {
			vec2 px = floor(world_pixel / 2.0) * 2.0;  // manchas na grade de 2 px
			float near = smoothstep(0.0, 0.55, forest_near(world_pixel));
			float leaves = moss(px / 22.0) * 0.7 + moss(px / 9.0) * 0.3;
			float shade = step(leaves, near * 1.1);  // sombra recortada, sem degradê
			vec3 sun = g * mix(vec3(1.06, 1.04, 0.94), vec3(1.38, 1.08, 0.6), golden);
			vec3 cool = g * vec3(0.74, 0.82, 0.9);
			g = mix(g, mix(sun, cool, shade), canopy_shade * (1.0 - night_dim));
		}
		if (long_shadow > 0.0 && length(sun_vector) > 0.5) {
			vec2 dir = normalize(sun_vector);
			vec2 across = vec2(-dir.y, dir.x);
			vec2 sz = vec2(textureSize(corner_mask_soft, 0));
			// Mata "contra o sol": há árvores a 40–260 px na direção de onde vem a luz?
			// Listras: troncos separados por frestas de luz (ruído ao longo de 'across').
			float lane = floor(dot(world_pixel, across) / 14.0);
			float lane_rand = fract(sin(lane * 12.9898) * 43758.5453);
			float stripe = step(0.42, lane_rand);
			// Cada tronco tem um comprimento próprio (copas e alturas diferentes).
			float reach = 90.0 + fract(lane_rand * 7.31) * 190.0;
			// Ponta recortada em degraus de 2 px, sem aresta reta.
			reach += (hash(floor(world_pixel / 6.0)) - 0.5) * 24.0;
			float caster = 0.0;
			for (int k = 1; k <= 6; k++) {
				float dist = float(k) * 44.0;
				if (dist > reach) break;
				vec2 back = world_pixel - dir * dist;
				caster = max(caster, 1.0 - texture(corner_mask_soft, (back / 32.0 + vec2(0.5)) / sz).r);
			}
			float here_forest = 1.0 - texture(corner_mask_soft, (world_pixel / 32.0 + vec2(0.5)) / sz).r;
			float s = step(0.5, caster) * stripe * (1.0 - step(0.5, here_forest));
			g = mix(g, g * vec3(0.5, 0.55, 0.68), s * long_shadow * (1.0 - night_dim));
			// Feixes de luz pelas frestas das copas: faixas largas douradas na grama aberta,
			// paralelas às sombras, com borda em degraus de 2 px (referência das 18h).
			float beam_lane = floor((dot(world_pixel, across) + (hash(floor(world_pixel / 8.0)) - 0.5) * 6.0) / 34.0);
			float beam = step(0.62, fract(sin(beam_lane * 78.233) * 12345.678));
			float along = dot(world_pixel, dir);
			beam *= step(0.3, fract(sin(beam_lane * 3.7) * 999.1 + along / 520.0));  // feixes que começam e acabam
			g = mix(g, g * vec3(1.3, 1.2, 0.85) + vec3(0.04, 0.03, 0.0), beam * (1.0 - s) * (1.0 - here_forest) * long_shadow * golden * (1.0 - night_dim));
		}
		g = mix(g, mix(vec3(luma), g, 0.6) * night_tint * night_value, night_dim);
		COLOR.rgb = g;
	}
	vec2 p = floor(ground_pixel / 2.0) * 2.0;
	float patches = moss(p / 86.0) * 0.65 + moss(p / 27.0) * 0.35;
	// Variação de musgo sem virar "sombra sem dono": o tom muda, o valor quase não
	// (antes até -14% em manchas de ~86 px que pareciam sombras soltas no chão).
	COLOR.rgb *= mix(vec3(0.95,0.99,0.94),vec3(1.03,1.02,0.99),patches);
	float clearing = 1.0-smoothstep(260.0,600.0,length(p-vec2(1600.0)));
	COLOR.rgb *= mix(vec3(0.94,0.97,0.96),vec3(1.04,1.03,0.98),clearing);
}
