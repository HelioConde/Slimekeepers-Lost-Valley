shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform float elapsed = 0.0;
uniform sampler2D depth_map : filter_linear, repeat_disable;
// 0 de dia, 1 à noite (valley_region): água azul profunda e luminosa, ondas
// claras, brilhos e coluna de reflexo da lua (fixa na tela, como no mundo real).
uniform float night = 0.0;
uniform float moon_x = 0.72;  // posição da coluna da lua na tela (0..1)
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
	vec4 day = vec4(mix(water,vec3(.68,.89,.82),shine*.58),mix(.20,.36,depth)+shine*.20);
	// --- Noite ---
	vec3 deep = mix(vec3(.08,.25,.50),vec3(.03,.10,.30),depth);
	// Ondas: traços claros longos e curvos que derivam devagar.
	float wave = sin(p.y*.09+sin(p.x*.018+elapsed*.2)*2.4+elapsed*.5);
	float strokes = step(.965,wave)*step(.35,hash(floor(p/vec2(40,6))));
	deep = mix(deep,vec3(.42,.68,.98),strokes*.7);
	// Brilhos de estrela: pontos de 2 px que piscam.
	float star = step(.9955,hash(floor(p/4.0)+vec2(floor(elapsed*1.3),0.0)));
	deep = mix(deep,vec3(.85,.95,1.0),star);
	// Coluna da lua: faixa vertical na tela, feita de traços horizontais.
	float column = 1.0-smoothstep(.025,.075,abs(SCREEN_UV.x-moon_x+sin(p.y*.05+elapsed)*.004));
	float dash = step(.45,hash(floor(p/vec2(10,4))+floor(elapsed*2.0)));
	deep = mix(deep,vec3(.80,.92,1.0),column*dash*.85);
	// Espuma clara junto às margens (água rasa).
	float foam = (1.0-smoothstep(.06,.14,depth))*step(.5,hash(floor(p/4.0)+floor(elapsed*1.5)));
	deep = mix(deep,vec3(.62,.84,1.0),foam*.6);
	vec4 lit = vec4(deep,mix(.78,.9,depth));
	COLOR = mix(day,lit,night);
}
