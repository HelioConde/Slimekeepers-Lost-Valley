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
uniform float moon_strength = 1.0;  // reflexo da lua (horário/céu); plantas brilham à parte
varying vec2 pixel;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() { pixel = VERTEX; }

void fragment() {
	vec2 p = floor(pixel / 2.0) * 2.0;
	float t = elapsed;
	float d = length(p / pool_radius);
	// Borda irregular do polígono: ruído leve para as faixas não serem elipses perfeitas.
	d += sin(atan(p.y, p.x) * 5.0) * 0.03;  // borda irregular suave, sem manchas
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
	water += vec3(0.07, 0.11, 0.09) * step(0.82, ribbon) * shallow_zone;
	// Ondulação curta (as linhas antigas), agora com movimento.
	float wave = sin(p.y * 0.23 + sin(p.x * 0.045) * 1.6 + t * 1.5);
	if (wave > 0.93 && hash(floor(vec2(p.x / 12.0, p.y / 4.0))) > 0.6) { water += vec3(0.12, 0.16, 0.13); }
	// Espuma na borda: anel recortado que pulsa.
	float foam = step(0.92, d) * step(0.5, hash(floor(p / 4.0) + floor(t * 0.4)));
	water = mix(water, vec3(0.62, 0.86, 0.8), foam * 0.75);
	// Brilhos de sol: poucos pontos de 2 px que piscam (somem à noite).
	float glint = step(0.994, hash(floor(p / 6.0) + vec2(floor(t * 0.8), 0.0)));
	water = mix(water, vec3(1.0, 0.98, 0.86), glint * (1.0 - night) * (1.0 - far_bank));
	// ---------------- Noite (refúgio iluminado pelo luar) ----------------
	// Profundidade: raso perto da margem deixa ver o fundo; centro azul-marinho.
	float dn = clamp(d, 0.0, 1.0);
	vec3 n_deep = vec3(0.03, 0.10, 0.22);
	vec3 n_mid = vec3(0.06, 0.19, 0.33);
	vec3 n_shallow = vec3(0.12, 0.33, 0.41);
	vec3 glow = dn < 0.5 ? n_deep : (dn < 0.78 ? n_mid : n_shallow);
	// Fundo entrevisto no raso: pedrinhas e musgo, pouco contraste.
	// Ondas: cada linha de 4 px com fase e velocidade próprias (nada sincronizado).
	float row = floor(p.y / 4.0);
	float row_phase = hash(vec2(row, 3.0)) * 6.28;
	float row_speed = 0.12 + hash(vec2(row, 7.0)) * 0.18;  // superfície calma
	float ripple = sin(p.x * 0.07 + t * row_speed + row_phase);
	float thin = step(mod(p.y, 4.0), 1.0);  // traços de 2 px de altura: linhas, não blocos
	float ripple_on = step(0.985, ripple) * step(0.75, hash(vec2(floor(p.x / 24.0), row))) * thin;
	glow = mix(glow, vec3(0.38, 0.6, 0.8), ripple_on * 0.4);
	// Reflexo da lua: núcleo estilizado quebrado em faixas + caminho de brilhos.
	vec2 m = vec2(pool_radius.x * 0.18, -pool_radius.y * 0.28);
	float shift = floor(sin(t * (0.25 + hash(vec2(row, 11.0)) * 0.2) + row * 1.7) * 1.5);
	vec2 q = (p + vec2(shift, 0.0) - m) / vec2(14.0, 9.0);
	float core = length(q);
	float gap = 1.0 - (1.0 - thin) * step(0.85, hash(vec2(row, floor(t * 0.4))));  // poucas linhas finas cortam o disco  // linhas que somem e voltam
	float disk = (1.0 - step(1.0, core)) * gap;
	vec3 silver = core < 0.6 ? vec3(0.96, 0.98, 1.0) : vec3(0.78, 0.88, 1.0);
	glow = mix(glow, silver, disk * moon_strength);
	// Caminho: traços que descem do núcleo até a margem próxima, de largura variável.
	float below = step(m.y + 8.0, p.y);
	float width = (3.0 + 4.0 * abs(sin(row * 0.8 + t * row_speed))) * (1.0 - smoothstep(0.8, 1.0, dn));
	float path = step(abs(p.x + shift * 1.5 - m.x), width) * below * thin * step(0.35, hash(vec2(row, 21.0)));
	float spark = step(0.45, hash(vec2(floor((p.x - m.x) / 6.0), row) + floor(t * 0.5 + row_phase)));
	glow = mix(glow, vec3(0.86, 0.94, 1.0), path * spark * moon_strength * (1.0 - smoothstep(0.0, 34.0, p.y - m.y) * 0.5));
	// Halo prateado em volta do núcleo, também quebrado pelas ondas.
	glow = mix(glow, vec3(0.32, 0.5, 0.78), (1.0 - step(1.7, core)) * step(1.0, core) * 0.6 * moon_strength);
	// Margem: reflexos ciano descontínuos que acompanham a borda + ondulações
	// que nascem nela e andam para dentro.
	float ang = atan(p.y / pool_radius.y, p.x / pool_radius.x);
	float seg = hash(vec2(floor(ang * 18.0), 5.0));
	float rim = step(0.9, d) * step(0.45, seg) * step(0.3, hash(vec2(floor(ang * 40.0), floor(t * 0.4))));
	glow = mix(glow, vec3(0.5, 0.86, 0.95), rim * 0.8);
	float shore_wave = step(0.95, sin(d * 60.0 + t * 0.8 + seg * 6.0)) * step(0.75, d) * step(d, 0.9) * step(0.7, seg) * thin;
	glow = mix(glow, vec3(0.36, 0.62, 0.86), shore_wave * 0.5);
	// Organismos luminosos submersos: três pontos lentos com halo de 2 px.
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		vec2 o = vec2(sin(t * 0.13 + fi * 2.1) * 0.55, cos(t * 0.11 + fi * 1.7) * 0.45) * pool_radius;
		float dist = length(p - floor(o / 2.0) * 2.0);
		glow = mix(glow, vec3(0.45, 0.95, 0.9), (1.0 - step(2.5, dist)) * 0.9);
		glow = mix(glow, vec3(0.2, 0.55, 0.65), (1.0 - step(6.5, dist)) * step(2.5, dist) * 0.35);
	}
	water = mix(water, glow, night);
	COLOR = vec4(water, 1.0);
}
