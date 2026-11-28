shader_type canvas_item;
// Brisa nas folhas: desloca a amostra em degraus de 1 pixel (sem borrar a pixel art),
// mais forte na copa (no alto da camada) e nula no tronco/chão (abaixo de `rooted`).
uniform float speed = 1.0;
uniform float amount_px = 1.0;
uniform float rooted = 0.5;   // fração da altura (UV.y) a partir da qual nada se mexe

void fragment() {
	float reach = clamp((rooted - UV.y) / max(rooted, 0.001), 0.0, 1.0);
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	float gust = sin(TIME * speed * 1.3 + px.y * 0.06 + px.x * 0.015)
		+ 0.5 * sin(TIME * speed * 2.7 + px.x * 0.09);
	float shift = floor(gust * amount_px * reach + 0.5);
	COLOR = texture(TEXTURE, UV + vec2(shift * TEXTURE_PIXEL_SIZE.x, 0.0));
}
