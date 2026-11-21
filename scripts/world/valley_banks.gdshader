shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform float elapsed = 0.0;
uniform sampler2D grass_atlas : filter_nearest;
// V9: grama do chão novo (atlas Wang, tile cheio em grass_origin) e escurecimento
// noturno igual ao do Ground, para a margem não destoar do resto.
uniform vec2 grass_origin = vec2(0.0);
uniform float grass_tile = 0.0;  // 1 = grass_atlas é o Wang 128x128
uniform float night_dim = 0.0;
uniform float night_value = 0.8;
uniform vec3 night_tint = vec3(.72,.82,1.0);
uniform sampler2D depth_map : filter_linear, repeat_disable;
varying vec2 p_world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { p_world=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec4 texel=texture(TEXTURE,UV);
	vec2 p=floor(p_world/2.0)*2.0;
	if(texel.g>texel.r*1.15 && texel.g>texel.b*1.35) {
		// Leave the existing meadow visible outside the irregular stone bank.
		vec2 ground_pixel=mod(floor(p_world),32.0);
        vec2 tile=floor(p_world/32.0);
        if(mod(tile.x+tile.y,2.0)==0.0)ground_pixel.x=31.0-ground_pixel.x;
        texel=texture(grass_atlas,(grass_origin+ground_pixel+vec2(.5))/vec2(textureSize(grass_atlas,0)));
        if(grass_tile<.5) texel.rgb*=vec3(.82,1.06,.94);
	} else if(texel.b>.38 && texel.g>.43 && texel.g>texel.r*1.15) {
		float depth=texture(depth_map,p_world/3200.0).r;
		vec3 shallows=mix(vec3(.49,.68,.58),vec3(.28,.57,.57),depth);
		texel.rgb=mix(shallows,texel.rgb,.12);
		// Inner water texels reveal the same bed and life as the open pool.
		texel.a*=.16;
	}
	float luma=dot(texel.rgb,vec3(.299,.587,.114));
	texel.rgb=mix(texel.rgb,mix(vec3(luma),texel.rgb,.6)*night_tint*night_value,night_dim);
	COLOR=texel;
}
