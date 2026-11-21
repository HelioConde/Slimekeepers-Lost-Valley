shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
// V9: a grama do topo dos platôs usa a grama pintada do chão (atlas Wang) e o
// mesmo escurecimento noturno do Ground (ground_art.gd / valley_region.gd).
uniform sampler2D grass_atlas : filter_nearest;
uniform vec2 grass_origin = vec2(96.0);
uniform float use_grass = 0.0;
uniform float night_dim = 0.0;
varying vec2 p_world;
void vertex() { p_world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	// Only the lower flat meadow is transparent; upper turf and rock stay intact.
	if(c.g>c.r*1.13 && c.g>c.b*1.5 && c.g<.35)c.a=0.0;
	else if(use_grass>.5 && c.a>.5 && c.g>c.r*1.13 && c.g>c.b*1.5){
		vec2 q=mod(floor(p_world),32.0);
		if(mod(floor(p_world.x/32.0)+floor(p_world.y/32.0),2.0)>.5)q.x=31.0-q.x;
		c.rgb=texture(grass_atlas,(grass_origin+q+vec2(.5))/vec2(textureSize(grass_atlas,0))).rgb;
	}
	float luma=dot(c.rgb,vec3(.299,.587,.114));
	c.rgb=mix(c.rgb,mix(vec3(luma),c.rgb,.6)*vec3(.72,.82,1.0)*.8,night_dim);
	COLOR=c;
}
