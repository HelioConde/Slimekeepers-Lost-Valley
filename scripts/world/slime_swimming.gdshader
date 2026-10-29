shader_type canvas_item;
uniform bool swimming = false;
void fragment() {
	vec4 art = texture(TEXTURE, UV) * COLOR;
	if (swimming && UV.y > 0.73) {
		art.rgb = mix(art.rgb, vec3(0.27, 0.60, 0.63), 0.48);
		art.a *= 0.52;
	}
	COLOR = art;
}
