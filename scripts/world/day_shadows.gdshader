shader_type canvas_item;
render_mode unshaded;
varying float opacity;
void vertex() { opacity = COLOR.a; }
void fragment() {
	// Preserve the sprite's alpha silhouette, never its colored pixels.
	COLOR = vec4(.055,.075,.10,texture(TEXTURE,UV).a*opacity);
}
