shader_type canvas_item;
render_mode unshaded;
uniform float elapsed = 0.0;
varying vec2 pixel;
void vertex() { pixel = VERTEX; }
void fragment() {
	float step_time = floor(elapsed*8.0)/8.0;
	float stripe = mod(floor(pixel.y)-floor(step_time*12.0),11.0);
	vec3 water = vec3(0.22,0.71,0.73);
	if (stripe<1.0) { water = vec3(0.45,0.82,0.80); }
	COLOR=vec4(water,1.0);
}
