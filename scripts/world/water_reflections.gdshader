shader_type canvas_item;
// Reflexos de Sol e Lua (V10). Só a luz refletida ignora o tom ambiente; a água
// por baixo continua sombreada. TUDO em coordenadas de mundo: a âncora de cada
// reflexo vem da geometria do corpo d'água + posição do astro (Astronomy), nunca
// da tela, da câmera ou do jogador.
render_mode unshaded;
uniform float elapsed = 0.0;
// Âncoras do reflexo (mundo), uma por célula do corpo d'água, sempre dentro da
// água (WaterReflections.pick_anchors). Cada pixel usa a âncora mais próxima.
const int MAX_ANCHORS = 16;
uniform vec2 moon_anchors[16];
uniform vec2 sun_anchors[16];
uniform int anchor_count = 0;
// Céu (Astronomy.sky).
uniform float moon_strength = 0.0;
uniform float moon_phase = 0.5;
uniform float sun_strength = 0.0;
uniform vec4 sun_color : source_color = vec4(1.0);
varying vec2 world;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }

vec2 nearest(vec2 p, bool moon) {
	vec2 best = vec2(1e9);
	float best_d = 1e18;
	for (int i = 0; i < MAX_ANCHORS; i++) {
		if (i >= anchor_count) break;
		vec2 a = moon ? moon_anchors[i] : sun_anchors[i];
		vec2 d = p - a;
		float dd = dot(d, d);
		if (dd < best_d) { best_d = dd; best = a; }
	}
	return best;
}

// Coluna de reflexo fragmentada: linhas de 2 px a cada 4 px, cada linha com
// largura, deslocamento e velocidade próprios; traços quebrados que derivam.
float column(vec2 p, vec2 a, float half_width, float up, float down, float speed_scale) {
	float dy = p.y - a.y;
	if (dy < -up || dy > down) return 0.0;
	float row = floor(p.y / 4.0);
	float thin = step(mod(p.y, 4.0), 1.0);
	float rs = (0.15 + hash(vec2(row, 7.0)) * 0.2) * speed_scale;
	float sway = floor(sin(elapsed * rs + row * 1.7) * 2.0);
	float taper = 1.0 - smoothstep(0.0, 1.0, dy > 0.0 ? dy / down : -dy / up);
	float w = half_width * (0.35 + 0.65 * abs(sin(row * 0.9 + elapsed * rs))) * taper;
	float inside = step(abs(p.x - a.x - sway), w);
	float dash = step(0.42, hash(vec2(floor((p.x + elapsed * rs * 6.0) / 6.0), row)));
	return inside * dash * thin;
}

void fragment() {
	vec2 p = floor(world / 2.0) * 2.0;
	vec4 outc = vec4(0.0);
	// ---- Lua ----
	if (moon_strength > 0.003) {
		vec2 a = floor(nearest(p, true) / 2.0) * 2.0;
		float c = column(p, a, 50.0, 24.0, 260.0, 1.0);  // coluna larga e longa (ref. da ponte)
		// Disco estilizado e discreto, com a fase (lado iluminado pela fase).
		vec2 q = (p - a) / vec2(13.0, 9.0);
		float disk = 0.0;
		if (dot(q, q) <= 1.0) {
			float term = cos(TAU * moon_phase) * sqrt(max(0.0, 1.0 - q.y * q.y));
			float lit = moon_phase < 0.5 ? step(term, q.x) : step(q.x, -term);
			float cut = 1.0 - step(mod(p.y, 6.0), 1.0) * step(0.6, hash(vec2(floor(p.y / 6.0), floor(elapsed * 0.4))));
			disk = lit * cut;
		}
		// Pontos prateados ao redor (ondulação fina).
		float spark = step(0.993, hash(floor(p / 4.0) + vec2(floor(elapsed * 0.6), 3.0))) * (1.0 - smoothstep(10.0, 60.0, length(p - a)));
		float lum = clamp(disk * 0.95 + c * 0.75 + spark * 0.8, 0.0, 1.0) * moon_strength;
		vec3 col = mix(vec3(0.62, 0.8, 1.0), vec3(0.94, 0.97, 1.0), clamp(disk + spark, 0.0, 1.0));
		outc = vec4(col, lum);
	}
	// ---- Sol ----
	if (sun_strength > 0.003) {
		vec2 a = floor(nearest(p, false) / 2.0) * 2.0;
		float c = column(p, a, 26.0, 20.0, 120.0, 1.3);
		float glint = step(0.988, hash(floor(p / 4.0) + vec2(floor(elapsed * 1.2), 9.0))) * (1.0 - smoothstep(20.0, 90.0, length(p - a)));
		float lum = clamp(c * 0.9 + glint, 0.0, 1.0) * sun_strength;
		if (lum > outc.a) outc = vec4(mix(sun_color.rgb * 1.15, vec3(1.0), 0.35 + glint * 0.5), lum);
	}
	COLOR = vec4(outc.rgb, clamp(outc.a, 0.0, 0.9));
}
