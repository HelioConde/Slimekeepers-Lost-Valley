shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform float elapsed = 0.0;
uniform vec2 pool_radius = vec2(85.0,48.0);
varying vec2 pixel;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { pixel = VERTEX; }
void fragment() {
	vec2 p = floor(pixel / 2.0) * 2.0;
	float depth = clamp(length(p / pool_radius),0.0,1.0);
	vec3 water = mix(vec3(0.10,0.42,0.53),vec3(0.22,0.72,0.73),depth);
	float wave = sin(p.y*0.23 + sin(p.x*0.045)*1.6 + elapsed*1.5);
	if (wave>0.92 && hash(floor(vec2(p.x/12.0,p.y/4.0)))>0.58) { water += vec3(0.18,0.22,0.18); }
	COLOR=vec4(water,1.0);
}
