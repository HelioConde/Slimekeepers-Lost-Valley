shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform float elapsed = 0.0;
uniform sampler2D depth_map : filter_linear, repeat_disable;
varying vec2 p_world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { p_world = VERTEX; }
void fragment() {
	vec2 p = floor(p_world/2.0)*2.0;
	float depth = texture(depth_map,p_world/3200.0).r;
	vec3 water = mix(vec3(.31,.75,.72),vec3(.10,.51,.62),depth);
	float ripple = sin(p.y*.12+sin(p.x*.027)*1.8+elapsed*.75);
	float shine = step(.987,ripple)*step(.82,hash(floor(p/vec2(26,12))));
	// A transparent film above the real mineral bed, submerged plants and fish.
	COLOR = vec4(mix(water,vec3(.68,.89,.82),shine*.58),mix(.20,.36,depth)+shine*.20);
}
