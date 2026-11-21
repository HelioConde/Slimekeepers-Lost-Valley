shader_type canvas_item;
// Água encantada (V11): camada ADITIVA por cima de cada corpo d'água, só luz.
// Tudo em coordenadas de mundo (MODEL_MATRIX): nada segue câmera ou tela.
// Camadas (cada uma ligável para o protótipo A/B/C/D):
//  1. fios luminosos que acompanham a correnteza (duas escalas);
//  2. bordas molhadas: faixa estreita pela máscara de distância à margem;
//  3. cintilações tipo estrela (algumas de 4 pontas), determinísticas;
//  4. reflexos coloridos das plantas/slimes luminosos próximos.
render_mode blend_add, unshaded;

uniform float elapsed = 0.0;
uniform float night = 1.0;        // 0 dia, 1 noite
uniform vec2 flow_dir = vec2(0.08, 1.0);
uniform float flow_speed = 5.0;
// Máscara de distância à margem: R = distância/escala (0 na margem).
uniform sampler2D edge_map : filter_linear, repeat_disable;
uniform vec4 edge_rect = vec4(0.0, 0.0, 1.0, 1.0);  // posição e tamanho (mundo)
uniform float edge_scale = 64.0;                     // px de mundo para R = 1
// Fontes de luz próximas (mundo + cor), para reflexos e mais cintilações.
const int MAX_LIGHTS = 24;
uniform vec4 lights[24];          // xy = posição, z = raio, w = intensidade
uniform vec4 light_colors[24];
uniform int light_count = 0;
uniform float layer_threads = 1.0;
uniform float layer_edges = 1.0;
uniform float layer_stars = 1.0;
uniform float layer_plants = 1.0;
uniform float layer_mist = 1.0;
varying vec2 world;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }

// Coordenadas no referencial do fluxo: "along" desce com a água, "across" atravessa.
vec2 flow_space(vec2 p) {
	vec2 d = normalize(flow_dir);
	return vec2(dot(p, vec2(-d.y, d.x)), dot(p, d));
}

void fragment() {
	vec2 p = floor(world / 2.0) * 2.0;  // grade de 2 px: pixel art
	float t = elapsed;
	vec2 fs = flow_space(p);
	vec3 col = vec3(0.0);
	float lum_scale = mix(0.35, 1.0, night);

	// ---------- 1. Fios luminosos ----------
	if (layer_threads > 0.0) {
		// Escala ampla: correntes longas, lentas.
		vec2 q = vec2(fs.x * 0.0045, (fs.y - t * flow_speed) * 0.011);  // fios deitados, atravessando o fluxo
		vec2 warp = vec2(vnoise(q * 1.6 + 4.0), vnoise(q * 1.6 + 9.0)) - 0.5;
		float f = vnoise(q + warp * 1.3);
		float c = abs(fract(f * 7.0) - 0.5);           // 0 no centro do fio
		float thick = step(c, 0.018) + step(c, 0.04) * step(0.7, vnoise(q * 3.0));  // 2 espessuras
		// Segmentos que acendem e apagam: janela que corre pelo fio.
		float seg = vnoise(vec2(fs.x * 0.02, fs.y * 0.008) + vec2(0.0, t * 0.15));
		float fade = smoothstep(0.42, 0.7, seg);
		col += vec3(0.25, 0.75, 1.0) * min(thick, 1.0) * fade * 0.38;
		// Escala fina: reflexos rápidos e curtos.
		vec2 q2 = vec2(fs.x * 0.012, (fs.y - t * flow_speed * 2.5) * 0.03);
		float g = vnoise(q2 + warp * 2.0);
		float c2 = abs(fract(g * 5.0) - 0.5);
		float quick = step(c2, 0.02) * step(0.6, hash(floor(p / vec2(10.0, 4.0)) + floor(t * 1.5)));
		col += vec3(0.45, 0.85, 1.0) * quick * 0.35;
		col *= layer_threads;
	}

	// ---------- 2. Bordas molhadas ----------
	vec2 euv = (world - edge_rect.xy) / edge_rect.zw;
	float e = texture(edge_map, euv).r * edge_scale;  // px até a margem
	if (layer_edges > 0.0) {
		float lap = 0.5 + 0.5 * sin(e * 0.45 - t * 1.8 + vnoise(p * 0.02) * 6.0);  // ondinhas contra a borda
		float along = vnoise(p * 0.025 + vec2(t * 0.08, 0.0));                         // trechos fortes e fracos
		float band = (1.0 - smoothstep(1.0, 7.0, e)) * step(0.5, e);                    // faixa estreita colada na margem
		float ripple = (1.0 - smoothstep(6.0, 16.0, e)) * step(7.0, e) * step(0.82, lap); // ondinha a poucos px
		float strength = smoothstep(0.35, 0.75, along);
		col += vec3(0.45, 0.88, 1.0) * (band * (0.35 + 0.65 * lap) + ripple * 0.6) * strength * 0.8 * layer_edges;
	}

	// ---------- 4. Reflexos das fontes de luz (calculados antes: aumentam estrelas) ----------
	float near_light = 0.0;
	vec3 plant = vec3(0.0);
	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= light_count) break;
		vec4 L = lights[i];
		vec2 d = p - L.xy;
		near_light = max(near_light, (1.0 - smoothstep(0.0, L.z * 2.5, length(d))) * L.w);
		// Reflexo: mancha vertical quebrada logo abaixo da fonte, em traços de 2 px.
		vec2 r = (d - vec2(0.0, L.z * 0.5)) / vec2(L.z * 0.45, L.z * 1.1);
		float blob = 1.0 - smoothstep(0.55, 1.0, length(r));
		float dash = step(mod(p.y, 4.0), 1.0) * step(0.35, hash(vec2(floor(p.x / 4.0), floor(p.y / 4.0) + floor(t * 0.8))));
		plant += light_colors[i].rgb * blob * dash * L.w;
	}
	col += plant * 0.7 * layer_plants * step(1.5, e) * night;

	// ---------- 3. Cintilações ----------
	if (layer_stars > 0.0) {
		vec2 cell = floor(p / 22.0);
		float h = hash(cell);
		float chance = 0.035 + near_light * 0.25;
		if (h < chance) {
			vec2 c0 = cell * 22.0 + floor(vec2(hash(cell + 3.0), hash(cell + 7.0)) * 9.0) * 2.0 + 4.0;
			float period = 2.0 + hash(cell + 11.0) * 4.0;
			float ph = fract(t / period + hash(cell + 13.0));
			float life = smoothstep(0.0, 0.12, ph) * (1.0 - smoothstep(0.18, 0.5, ph));  // sobe, pico, some
			vec2 d = abs(p - c0);
			float core = step(d.x + d.y, 0.5);
			float big = step(0.7, hash(cell + 17.0));                                   // ~30% com 4 pontas
			float arms = big * (step(d.x, 0.5) * step(d.y, 4.5) + step(d.y, 0.5) * step(d.x, 4.5)) * step(0.4, life);
			vec3 tint = mix(vec3(0.85, 0.95, 1.0), vec3(1.0), hash(cell + 19.0));
			col += tint * (core + arms * 0.7) * life * 1.2;
		}
	}

	// ---------- 5. Névoa rente à água (ref. da ponte) ----------
	// Véus largos que derivam devagar, em degraus de 1/6 (sem degradê liso).
	if (layer_mist > 0.0) {
		vec2 m = world * vec2(0.0035, 0.007) + vec2(t * 0.012, t * 0.004);
		float veil = vnoise(m) * 0.7 + vnoise(m * 2.3 + 5.0) * 0.3;
		veil = floor(smoothstep(0.5, 0.85, veil) * 6.0) / 6.0;
		col += vec3(0.10, 0.13, 0.19) * veil * night * layer_mist * smoothstep(4.0, 20.0, e);
	}
	// Nada fora da água nem na própria linha da margem.
	col *= step(0.5, e) * lum_scale;
	COLOR = vec4(col, 1.0);
}
