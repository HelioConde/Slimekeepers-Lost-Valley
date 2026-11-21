shader_type canvas_item;
// Grade de cor do mundo (abaixo do HUD): vibração seletiva, contraste suave,
// realce quente no que recebe luz e sombras levemente azuladas — a "pintura" da
// referência encantada. Opera pixel a pixel (sem desfoque): preserva a pixel art.
uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float vibrance = 0.35;      // satura mais as cores pouco saturadas
uniform float contrast = 0.10;
uniform vec3 highlight_tint = vec3(1.08, 1.02, 0.86);  // luz do sol nas partes claras
uniform vec3 shadow_tint = vec3(0.92, 0.98, 1.06);     // sombras frias/esverdeadas
uniform float tint_strength = 0.6;
uniform float vignette = 0.16;

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	// Vibração: puxa a saturação proporcionalmente ao que falta (não estoura o que já é forte).
	float sat = max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);
	c = mix(vec3(luma), c, 1.0 + vibrance * (1.0 - sat));
	// Contraste em torno do meio-tom.
	c = (c - 0.5) * (1.0 + contrast) + 0.5;
	// Divisão de tons: claros mais quentes, escuros mais frios.
	vec3 split = mix(shadow_tint, highlight_tint, smoothstep(0.25, 0.75, luma));
	c *= mix(vec3(1.0), split, tint_strength);
	// Vinheta leve: bordas da floresta mais fechadas, centro iluminado.
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * smoothstep(0.25, 0.75, dot(d, d) * 2.2);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
