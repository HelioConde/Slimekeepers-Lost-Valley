shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform sampler2D terrain_atlas : filter_nearest, repeat_disable;
uniform vec2 atlas_origin = vec2(0.0);
uniform float texture_strength = 0.5;
varying vec2 ground_pixel;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 cell=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),f.x),f.y);
}
void vertex() { ground_pixel = VERTEX; }
void fragment() {
	vec2 p=floor(ground_pixel);
	vec2 tile=floor(p/32.0); vec2 pixel=mod(p,32.0);
	if (mod(tile.x+tile.y*3.0,2.0)>0.5) { pixel.x=31.0-pixel.x; }
	vec3 texel=texture(terrain_atlas,(atlas_origin+pixel+vec2(0.5))/vec2(textureSize(terrain_atlas,0))).rgb;
	vec3 base=mix(COLOR.rgb,texel,texture_strength);
	float patches=noise(floor(p/2.0)*2.0/58.0);
	base*=mix(0.88,1.09,patches);
	// Single-pixel gravel and broken leaf litter preserve the original pixel scale.
	float fleck=hash(p);
	if (atlas_origin.x>0.0 && fleck>0.993) { base*=0.82; }
	if (atlas_origin.x>0.0 && fleck<0.004) { base=mix(base,vec3(0.84,0.76,0.48),0.25); }
	COLOR=vec4(base,COLOR.a);
}
