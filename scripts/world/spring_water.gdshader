shader_type canvas_item;
// Lago da Clareira. Participa do CanvasModulate (relógio global). Tudo decidido
// na grade de 2 px, em faixas: preserva a pixel art.
// - profundidade: fundo azul-petróleo, meio, raso turquesa (faixas, sem degradê);
// - margem de cima refletida (copa escura) no lado distante do lago;
// - cáusticas no raso, espuma recortada na borda, brilhos de sol de dia;
// - à noite a água fica azul luminosa, como na referência noturna.
uniform float elapsed = 0.0;
uniform vec2 pool_radius = vec2(85.0, 48.0);
uniform float night = 0.0;
varying vec2 pixel;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() { pixel = VERTEX; }

void fragment() {
	vec2 p = floor(pixel / 2.0) * 2.0;
	float t = elapsed;
	float d = length(p / pool_radius);
	// Borda irregular do polígono: ruído leve para as faixas não serem elipses perfeitas.
	d += (hash(floor(p / 8.0)) - 0.5) * 0.06;
	float band = floor(clamp(d, 0.0, 0.999) * 4.0) / 3.0;  // 0, 1/3, 2/3, 1
	vec3 deep = vec3(0.07, 0.31, 0.43);
	vec3 mid = vec3(0.12, 0.48, 0.56);
	vec3 shallow = vec3(0.27, 0.68, 0.66);
	vec3 water = band < 0.5 ? mix(deep, mid, band * 2.0) : mix(mid, shallow, (band - 0.5) * 2.0);
	// Reflexo da margem distante (topo do lago em 3/4): faixa escura e esverdeada.
	float far_bank = step(p.y, -pool_radius.y * 0.35) * step(0.62, d);
	water = mix(water, vec3(0.08, 0.27, 0.27), far_bank * 0.7);
	// Cáusticas: fitas de luz que andam devagar no raso.
	float ribbon = sin(p.x * 0.11 + sin(p.y * 0.17 + t * 0.9) * 1.6 + t * 0.6) * sin(p.y * 0.13 - t * 0.4);
	float shallow_zone = step(0.45, d) * (1.0 - far_bank);
	water += vec3(0.08, 0.13, 0.10) * step(0.72, ribbon) * shallow_zone;
	// Ondulação curta (as linhas antigas), agora com movimento.
	float wave = sin(p.y * 0.23 + sin(p.x * 0.045) * 1.6 + t * 1.5);
	if (wave > 0.93 && hash(floor(vec2(p.x / 12.0, p.y / 4.0))) > 0.6) { water += vec3(0.12, 0.16, 0.13); }
	// Espuma na borda: anel recortado que pulsa.
	float foam = step(0.9, d) * step(0.45, hash(floor(p / 4.0) + floor(t * 1.2)));
	water = mix(water, vec3(0.62, 0.86, 0.8), foam * 0.75);
	// Brilhos de sol: poucos pontos de 2 px que piscam (somem à noite).
	float glint = step(0.992, hash(floor(p / 6.0) + vec2(floor(t * 2.5), 0.0)));
	water = mix(water, vec3(1.0, 0.98, 0.86), glint * (1.0 - night) * (1.0 - far_bank));
	// Noite: água azul luminosa (compensa parte do escurecimento global) com
	// pontos ciano lentos no lugar dos brilhos de sol.
	vec3 glow = mix(vec3(0.08, 0.25, 0.50), vec3(0.03, 0.10, 0.30), 1.0 - d) + vec3(0.0, 0.03, 0.06) * band;
	float motes = step(0.994, hash(floor(p / 6.0) + vec2(0.0, floor(t * 0.7))));
	glow = mix(glow, vec3(0.55, 0.95, 1.0), motes);
	// Ondas claras e reflexo da lua (centro do lago, traços horizontais).
	float stroke = step(0.95, sin(p.y * 0.2 + sin(p.x * 0.05 + t * 0.3) * 2.0 + t * 0.8)) * step(0.4, hash(floor(p / vec2(24.0, 4.0))));
	glow = mix(glow, vec3(0.6, 0.85, 1.0), stroke * 0.5);
	float moon = 1.0 - smoothstep(0.12, 0.24, length((p - vec2(pool_radius.x * 0.15, -pool_radius.y * 0.2)) / pool_radius));
	glow = mix(glow, vec3(0.88, 0.96, 1.0), moon * step(0.4, hash(floor(p / vec2(8.0, 4.0)) + floor(t * 2.0))) * 0.9);
	water = mix(water, glow, night);
	COLOR = vec4(water, 1.0);
}
