shader_type canvas_item;
// Água viva no menu: só os pixels azulados/brancos da arte (cachoeira, rio) ganham
// faixas de luz que correm na direção do fluxo. O resto da camada fica intocado.
uniform float speed = 1.0;
uniform vec2 flow = vec2(0.0, 1.0);   // direção do fluxo em UV (cachoeira desce)
uniform float bands = 46.0;           // quantas faixas cabem na camada
uniform float strength = 0.32;
// Mato ao vento: pixels verdes trocam pela amostra 1 px ao lado em onda (só entre verdes,
// então caminho, pedras e ruínas não se mexem).
uniform float grass_sway = 0.0;

bool is_green(vec4 c) {
	return c.a > 0.5 && c.g > c.r * 1.05 && c.g > c.b * 1.1;
}

float water_mask(vec4 c) {
	float blue = c.b - max(c.r, c.g * 0.92);
	float bright = dot(c.rgb, vec3(0.33));
	return c.a * clamp(blue * 5.0 + step(0.82, bright) * step(0.05, c.b - c.r) * 0.8, 0.0, 1.0);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (grass_sway > 0.0 && is_green(c)) {
		vec2 gp = UV / TEXTURE_PIXEL_SIZE;
		// Rajada que atravessa o gramado da esquerda para a direita.
		float gust = sin(TIME * speed * 1.6 - gp.x * 0.05 + gp.y * 0.12) + 0.4 * sin(TIME * speed * 3.1 + gp.x * 0.2);
		float shift = floor(gust * grass_sway * 0.7 + 0.5);
		vec4 moved = texture(TEXTURE, UV + vec2(shift * TEXTURE_PIXEL_SIZE.x, 0.0));
		if (is_green(moved)) c = moved;
	}
	float m = water_mask(c);
	if (m > 0.0) {
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
		float lane = fract(sin(px.x * 12.9898 + px.y * 0.1) * 43758.5453);
		float along = dot(UV / TEXTURE_PIXEL_SIZE, flow) / bands;
		float wave = fract(along * 0.5 - TIME * speed * (0.6 + lane * 0.5) + lane);
		float streak = step(0.86, wave);
		c.rgb = mix(c.rgb, vec3(0.92, 0.98, 1.0), streak * strength * m);
		c.rgb *= 1.0 + 0.05 * sin(TIME * speed * 2.0 + px.y * 0.35) * m;
	}
	COLOR = c;
}
