shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform float elapsed=0.0;
// Brilho refletido do céu (Astronomy, via waterfall_life): dourado de manhã,
// âmbar no fim da tarde, azulado à noite.
uniform vec4 glint_color : source_color = vec4(1.0,0.97,0.8,1.0);
uniform float glint_strength = 0.5;
// Noite (valley_region): a queda vira um véu branco-azulado luminoso (referência V9).
uniform float night = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	vec2 size=vec2(textureSize(TEXTURE,0));
	vec2 pixel=floor(UV*size);
	if(c.b>c.r+.12 && c.g>.48){
		// Match the local teal river while preserving value variation and rock pixels.
		float light=dot(c.rgb,vec3(.22,.60,.18));
		c.rgb=mix(vec3(.20,.46,.49),vec3(.48,.72,.68),smoothstep(.25,.92,light));
		// Colunas de 3 px com velocidade e fase próprias: o fluxo nunca se repete em bloco
		// e acelera para baixo (a água ganha velocidade na queda).
		float column=floor(pixel.x/3.0);
		float speed=1.0+hash(vec2(column,3.0))*.7;
		float fall=UV.y*UV.y*9.0;
		float stream=step(.70,fract(pixel.y/23.0-elapsed*speed-fall*.15+column*.173));
		float narrow=step(.5,fract(pixel.x/3.0));
		c.rgb=mix(c.rgb,vec3(.69,.85,.79),stream*narrow*.26);
		// Fios escuros mais lentos dão profundidade entre as faixas claras.
		float under=step(.86,fract(pixel.y/31.0-elapsed*speed*.55+column*.41));
		c.rgb=mix(c.rgb,vec3(.13,.35,.40),under*(1.0-narrow)*.25);
		// Gotas cintilantes descendo, na cor da luz do horário.
		float drop=step(.965,hash(vec2(column,floor(pixel.y/2.0-elapsed*speed*9.0))));
		c.rgb=mix(c.rgb,glint_color.rgb,drop*narrow*glint_strength*.85);
		// Bordas laterais mais claras: leitura do volume da queda contra a rocha.
		float edge=1.0-smoothstep(.0,.16,min(UV.x,1.0-UV.x));
		c.rgb=mix(c.rgb,vec3(.62,.82,.78),edge*.22);
		// Crista no alto: a água vira a borda com um brilho que pisca de leve.
		float lip=1.0-smoothstep(.0,.07,UV.y);
		c.rgb=mix(c.rgb,glint_color.rgb,lip*glint_strength*(.35+.25*step(.5,hash(vec2(column,floor(elapsed*4.0))))));
		// Noite: compensa o escurecimento global com azul-prateado claro, mantendo
		// as faixas de fluxo (claras ainda mais claras).
		float lum=dot(c.rgb,vec3(.3,.59,.11));
		vec3 moonlit=mix(vec3(.34,.62,.74),vec3(.88,.97,1.0),smoothstep(.3,.7,lum));
		c.rgb=mix(c.rgb,moonlit,night*.85);
	}
	if(c.r>.74 && c.g>.78 && c.b>.75){c.rgb=mix(c.rgb,mix(vec3(.80,.91,.85),vec3(.92,.97,1.0),night),.72);}
	// Espuma da base: bolsões translúcidos que trocam de lugar (não repetem o mesmo contorno).
	if(UV.y>.87 && c.a>.0){c.a*=.48+.35*step(.35,fract(pixel.x*.173+floor(pixel.y/2.0)*.237+floor(elapsed*3.0)*.311));}
	COLOR=c;
}
