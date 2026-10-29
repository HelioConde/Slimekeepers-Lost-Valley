shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
varying vec2 ground_pixel;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float moss(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),f.x),f.y);
}
void vertex() { ground_pixel = VERTEX; }
void fragment() {
	vec2 p = floor(ground_pixel / 2.0) * 2.0;
	float patches = moss(p / 86.0) * 0.65 + moss(p / 27.0) * 0.35;
	COLOR.rgb *= mix(vec3(0.86,0.94,0.88),vec3(1.06,1.04,0.99),patches);
	float clearing = 1.0-smoothstep(260.0,600.0,length(p-vec2(1600.0)));
	COLOR.rgb *= mix(vec3(0.94,0.97,0.96),vec3(1.04,1.03,0.98),clearing);
}
