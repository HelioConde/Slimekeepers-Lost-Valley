shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform sampler2D depth_map : filter_linear, repeat_disable;
varying vec2 p_world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { p_world=VERTEX; }
void fragment() {
	vec2 p=floor(p_world/2.0)*2.0;
	float depth=texture(depth_map,p_world/3200.0).r;
	float patches=sin(p.x*.025+sin(p.y*.013)*2.0)*sin(p.y*.022);
	vec3 bed=mix(vec3(.53,.66,.55),vec3(.19,.42,.45),smoothstep(.0,1.0,depth));
	bed+=(hash(floor(p/4.0))-.5)*.027+patches*.022;
	vec2 cell=floor(p/30.0);
	vec2 center=vec2(7.0+hash(cell)*16.0,7.0+hash(cell+17.0)*16.0);
	vec2 pebble=(mod(p,30.0)-center)/vec2(4.0+hash(cell+4.0)*4.0,3.0+hash(cell+8.0)*2.0);
	float stone=dot(pebble,pebble);
	if(stone<1.0 && hash(cell+33.0)>.38) {
		bed+=vec3(.085,.09,.065)*(1.0-depth*.5);
		if(pebble.y>.3)bed-=vec3(.10,.10,.075);
	}
	COLOR=vec4(bed,1.0);
}
