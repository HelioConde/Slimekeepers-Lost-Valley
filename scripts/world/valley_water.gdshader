shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
uniform float elapsed = 0.0;
uniform sampler2D depth_map : filter_linear, repeat_disable;
// 0 de dia, 1 à noite (valley_region): água azul profunda e luminosa, ondas
// claras, brilhos e coluna de reflexo da lua (fixa na tela, como no mundo real).
uniform float night = 0.0;
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
	vec3 deep = mix(vec3(.14,.52,.46),vec3(.04,.22,.26),depth);  // raso azul-ciano, fundo marinho (ref. V9 do rio)
	// Calma (igual ao lago): linhas finas de 2 px, lentas, fase própria por linha.
	float row = floor(p.y/4.0);
	float thin = step(mod(p.y,4.0),1.0);
	float row_phase = hash(vec2(row,3.0))*6.28;
	float row_speed = .12+hash(vec2(row,7.0))*.18;
	float wave = sin(p.x*.05+elapsed*row_speed+row_phase);
	float strokes = step(.988,wave)*step(.82,hash(vec2(floor(p.x/30.0),row)))*thin;
	deep = mix(deep,vec3(.40,.62,.86),strokes*.5);
	// Brilhos de estrela: poucos, piscando devagar.
	float star = step(.997,hash(floor(p/4.0)+vec2(floor(elapsed*.4),0.0)));
	deep = mix(deep,vec3(.85,.95,1.0),star);
	// Margem: reflexos ciano descontínuos na água rasa, devagar.
	float foam = (1.0-smoothstep(.06,.14,depth))*step(.6,hash(floor(p/4.0)+floor(elapsed*.4)))*thin;
	deep = mix(deep,vec3(.5,.84,.95),foam*.6);
	vec4 lit = vec4(deep,mix(.78,.9,depth));
	COLOR = mix(day,lit,night);
}
