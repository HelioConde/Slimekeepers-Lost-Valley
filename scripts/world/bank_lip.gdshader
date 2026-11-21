shader_type canvas_item;
// Borda de terra da margem (ref. V11 da ponte, Vale à noite): faixa marrom
// irregular de 6–8 px colada na margem, com uma linha de pedrinhas escuras do
// lado da água. Opaca (não aditiva), em coordenadas de mundo e grade de 2 px.
render_mode unshaded;

uniform float night = 1.0;
uniform sampler2D edge_map : filter_linear, repeat_disable;
uniform vec4 edge_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float edge_scale = 64.0;
varying vec2 world;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }

void fragment() {
	vec2 p = floor(world / 2.0) * 2.0;
	float e = texture(edge_map, (p - edge_rect.xy) / edge_rect.zw).r * edge_scale;
	float width = 6.0 + floor(hash(floor(p / 8.0)) * 2.0) * 2.0;  // 6–8 px, muda a cada 8 px
	float earth = step(e, width);
	float stones = step(width, e) * step(e, width + 3.0) * step(0.4, hash(floor(p / 6.0) + 7.0));
	vec3 soil = mix(vec3(0.2, 0.13, 0.1), vec3(0.26, 0.17, 0.12), step(0.6, hash(p + 3.0)));
	vec3 col = mix(vec3(0.07, 0.06, 0.08), soil, earth);
	COLOR = vec4(col, max(earth, stones) * night);
}
