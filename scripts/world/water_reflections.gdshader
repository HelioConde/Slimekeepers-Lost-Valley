shader_type canvas_item;
// Only reflected light bypasses ambient tint. The water below remains shaded.
render_mode unshaded;
uniform float elapsed = 0.0;
uniform vec4 light_color : source_color = vec4(1.0);
uniform float strength = 0.0;
uniform float axis = 0.65;
varying vec2 water_world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { water_world = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec2 p = floor(water_world / 2.0) * 2.0;
	// Broken horizontal glints, never a smooth bloom or a solid painted disc.
	float row = floor(p.y / 5.0);
	float drift = sin(row * .73 + elapsed * .7) * .025;
	float distance_to_axis = abs(SCREEN_UV.x - axis - (SCREEN_UV.y-.5)*.10 + drift);
	float band = 1.0-smoothstep(.025,.24,distance_to_axis);
	vec2 cell = floor(vec2((p.x + sin(row+elapsed*.8)*5.0)/14.0,p.y/5.0));
	float broken = step(.40,hash(cell));
	float wave = sin(p.y*.63 + sin(p.x*.031)*1.8 + elapsed*1.4);
	float streak = step(.64,wave) * broken;
	float core = step(.93,wave) * step(.79,hash(cell+7.0));
	float shimmer = .60+.40*sin(elapsed*1.8+hash(cell)*6.283);
	float alpha = strength * band * (streak*.68*shimmer + core*1.15);
	vec3 reflected_light = mix(light_color.rgb,vec3(1.0),core*.68);
	COLOR = vec4(reflected_light,clamp(alpha,0.0,.85));
}
