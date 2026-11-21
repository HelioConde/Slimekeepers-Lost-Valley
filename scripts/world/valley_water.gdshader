shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform float elapsed = 0.0;
uniform sampler2D depth_map : filter_linear, repeat_disable;
// 0 de dia, 1 à noite (valley_region): água azul profunda e luminosa, ondas
// claras, brilhos e coluna de reflexo da lua (fixa na tela, como no mundo real).
uniform float night = 0.0;
varying vec2 p_world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
// Correnteza (V11): campo de ruído arrastado rio abaixo e torcido por outro
// ruído; as curvas de nível viram fios de corrente curvos e longos.
float flow_field(vec2 p, float t) {
	vec2 drift = vec2(0.08, 1.0) * t * 5.0;
	vec2 q = p * vec2(0.0045, 0.013) - drift * vec2(0.0045, 0.013);  // ondas largas, deitadas
	vec2 warp = vec2(vnoise(q * 1.7 + 3.1), vnoise(q * 1.7 + 8.4)) - 0.5;
	return vnoise(q + warp * 1.4) * 0.65 + vnoise(q * 2.3 - warp) * 0.35;
}
void vertex() { p_world = VERTEX; }
void fragment() {
	vec2 p = floor(p_world/2.0)*2.0;
	float depth = texture(depth_map,p_world/3200.0).r;
	vec3 water = mix(vec3(.31,.75,.72),vec3(.10,.51,.62),depth);
	float ripple = sin(p.y*.12+sin(p.x*.027)*1.8+elapsed*.75);
	float shine = step(.987,ripple)*step(.82,hash(floor(p/vec2(26,12))));
	// A transparent film above the real mineral bed, submerged plants and fish.
	vec4 day = vec4(mix(water,vec3(.68,.89,.82),shine*.58),mix(.20,.36,depth)+shine*.20);
	// --- Noite (V11, ref. da ponte): fundo marinho, raso turquesa, correntes ---
	float t = elapsed;
	float f = flow_field(p, t);
	// Profundidade em faixas (raso → turquesa; fundo → azul-marinho), com o campo
	// de corrente tingindo manchas mais claras e mais escuras.
	float band = floor(clamp(depth * 0.8 + (f - 0.5) * 0.35, 0.0, 0.999) * 5.0) / 4.0;
	vec3 deep = mix(vec3(.04,.42,.42), vec3(.01,.15,.17), band);
	// Faixas de luz (ref.): cristas curvas e diagonais que correm rio abaixo,
	// estreitas (4–6 px) e suaves nas pontas — nada de blocos chapados.
	vec2 sw = vec2(p.x * 0.8 + p.y * 0.5, p.y - t * 9.0);
	float swell = sin(sw.y * 0.03 + f * 6.0 + sin(sw.x * 0.01 + t * 0.15) * 2.4);
	float ridge = smoothstep(0.82, 0.97, swell) * smoothstep(0.25, 0.65, vnoise(p * 0.008 + t * 0.02));
	deep = mix(deep, vec3(.16,.48,.72), floor(ridge * 3.0) / 3.0 * 0.6);
	// Vegetação submersa no raso: tufos escuros-esverdeados sob a superfície.
	// Plantas submersas: tufos de folhas verticais (2 px) em células de 40 px.
	vec2 wc = floor(p / 40.0);
	float tuft = 0.0;
	if (hash(wc + 31.0) < 0.3) {
		vec2 base = wc * 40.0 + vec2(8.0 + floor(hash(wc + 2.0) * 12.0) * 2.0, 30.0);
		vec2 d = p - base;
		for (int k = 0; k < 4; k++) {
			float fk = float(k);
			float x = fk * 4.0 - 6.0 + floor(sin(t * 0.8 + fk + d.y * 0.3) * 1.0) * 2.0;
			float h = 10.0 + hash(wc + fk) * 10.0;
			tuft = max(tuft, step(abs(d.x - x), 1.0) * step(-h, d.y) * step(d.y, 0.0));
		}
	}
	deep = mix(deep, vec3(.07,.34,.32), tuft * 0.7);
	// Margem: ondinhas ciano descontínuas que vêm e vão contra a borda.
	float thin = step(mod(p.y,4.0),1.0);
	float edge = 1.0 - smoothstep(.08, .3, depth);
	float lap = step(0.6, sin(depth * 90.0 - t * 1.6 + hash(floor(p / 16.0)) * 6.0)) * step(0.45, hash(floor(p / vec2(10.0, 4.0))));
	deep = mix(deep, vec3(.55,.86,.98), edge * lap * thin * 0.7);
	// Espuma clara bem na borda (correnteza raspando na margem).
	float foam = (1.0 - smoothstep(.05, .12, depth)) * step(.55, hash(floor(p/4.0) + floor(t * 1.2)));
	deep = mix(deep, vec3(.85,.95,1.0), foam * 0.7);
	vec4 lit = vec4(deep,mix(.72,.95,depth));  // raso deixa ver o leito e as plantas
	COLOR = mix(day,lit,night);
}
