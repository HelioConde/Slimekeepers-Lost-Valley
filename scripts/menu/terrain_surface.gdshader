shader_type canvas_item;
// Shared with gameplay trails: respect the world CanvasModulate.
uniform sampler2D terrain_atlas : filter_nearest, repeat_disable;
uniform vec2 atlas_origin = vec2(0.0, 0.0);
uniform float texture_strength = 0.72;
varying vec2 ground_pixel;
void vertex() {
	ground_pixel = VERTEX;
}
void fragment() {
	vec2 tile = floor(ground_pixel / 32.0);
	vec2 pixel = mod(floor(ground_pixel), 32.0);
	// Mirror small patches to break the repeated pattern without resampling pixels.
	if (mod(tile.x + tile.y * 3.0, 2.0) > 0.5) { pixel.x = 31.0 - pixel.x; }
	if (mod(tile.x * 3.0 + tile.y, 3.0) > 1.0) { pixel.y = 31.0 - pixel.y; }
	vec2 uv = (atlas_origin + pixel + vec2(0.5)) / vec2(textureSize(terrain_atlas, 0));
	vec4 texel = texture(terrain_atlas, uv);
	COLOR = vec4(mix(COLOR.rgb, texel.rgb, texture_strength), COLOR.a);
}
