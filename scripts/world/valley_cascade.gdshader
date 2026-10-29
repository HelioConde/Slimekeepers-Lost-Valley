shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform float elapsed=0.0;
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	vec2 pixel=floor(UV*vec2(textureSize(TEXTURE,0)));
	if(c.b>c.r+.12 && c.g>.48){
		// Match the local teal river while preserving value variation and rock pixels.
		float light=dot(c.rgb,vec3(.22,.60,.18));
		c.rgb=mix(vec3(.20,.46,.49),vec3(.48,.72,.68),smoothstep(.25,.92,light));
		float column=floor(pixel.x/3.0);
		float stream=step(.72,fract(pixel.y/23.0-elapsed*1.15+column*.173));
		float narrow=step(.5,fract(pixel.x/3.0));
		c.rgb=mix(c.rgb,vec3(.69,.85,.79),stream*narrow*.22);
	}
	if(c.r>.74 && c.g>.78 && c.b>.75){c.rgb=mix(c.rgb,vec3(.80,.91,.85),.72);}
	// Break the original static foam silhouette into small translucent pockets.
	if(UV.y>.87 && c.a>.0){c.a*=.48+.35*step(.35,fract(pixel.x*.173+floor(pixel.y/2.0)*.237));}
	COLOR=c;
}
