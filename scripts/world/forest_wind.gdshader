shader_type canvas_item;
// Three shared species materials, updated centrally; collisions never move.
uniform float wind_time = 0.0;
uniform float wind_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform vec2 active_center = vec2(0.0);
uniform vec2 active_half_size = vec2(600.0, 360.0);
uniform float sway_rate = 1.35;
uniform float flexibility = 1.0;
uniform float plant_reaction = 0.0;
uniform int reactor_count = 0;
uniform vec4 reactors[8];
// Luz de folhagem (definida por AmbientLights conforme o GameClock). Direção em tela
// apontando PARA a fonte (sol/lua); 0 em foliage_light desliga o efeito.
uniform float foliage_light = 0.0;
uniform vec2 light_dir = vec2(-0.5, -0.85);
uniform vec3 light_color = vec3(1.0, 0.92, 0.62);
uniform float light_strength = 0.0;
uniform vec3 inner_shade = vec3(0.78, 0.9, 0.95);
uniform float shade_strength = 0.0;
varying float phase;
varying float active;
varying float interaction_bend;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
	vec2 world_origin = MODEL_MATRIX[3].xy;
	phase = dot(world_origin, vec2(0.017, 0.023));
	vec2 distance_from_view = abs(world_origin - active_center);
	active = step(distance_from_view.x, active_half_size.x + 160.0) * step(distance_from_view.y, active_half_size.y + 160.0);
	float bend = 0.0;
	if (plant_reaction > 0.0) {
		for (int i = 0; i < 8; i++) {
			if (i >= reactor_count) { break; }
			vec2 away = world_origin - reactors[i].xy;
			float near_actor = 1.0 - smoothstep(8.0, 48.0, length(away));
			bend += near_actor * reactors[i].z * (away.x >= 0.0 ? 1.0 : -1.0);
		}
	}
	// Same origin on all four vertices: avoid repeating proximity checks per texel.
	interaction_bend = clamp(bend, -1.0, 1.0) * plant_reaction;
}

void fragment() {
	float canopy = 1.0 - smoothstep(0.15, 0.70, UV.y);
	float wave = sin(wind_time * sway_rate + phase);
	vec2 offset = vec2(wind_direction.x, wind_direction.y * 0.3) * wave * wind_strength * flexibility;
	offset.x += interaction_bend * 2.0;
	vec2 pixels = round(offset * canopy * active);
	vec2 shifted_uv = UV - pixels * TEXTURE_PIXEL_SIZE;
	shifted_uv = (floor(shifted_uv / TEXTURE_PIXEL_SIZE) + vec2(0.5)) * TEXTURE_PIXEL_SIZE;
	vec4 sampled = texture(TEXTURE, shifted_uv);
	float inside = step(0.0, shifted_uv.x) * step(shifted_uv.x, 1.0) * step(0.0, shifted_uv.y) * step(shifted_uv.y, 1.0);
	vec4 lit = sampled;
	if (foliage_light > 0.0 && sampled.a > 0.5 && light_strength + shade_strength > 0.001) {
		// Só folhas (verde dominante): tronco, pedras e flores coloridas ficam como estão.
		float leaf = step(sampled.r, sampled.g) * step(sampled.b * 0.85, sampled.g);
		// Espelhamento (flip_h) inverte o UV: a luz precisa seguir a tela.
		vec2 flip = vec2(sign(dFdx(UV.x)), sign(dFdy(UV.y)));
		vec2 step_uv = round(light_dir * 1.4) * flip * TEXTURE_PIXEL_SIZE;
		vec4 toward1 = texture(TEXTURE, shifted_uv + step_uv);
		vec4 toward2 = texture(TEXTURE, shifted_uv + step_uv * 2.0);
		float l0 = dot(sampled.rgb, vec3(0.299, 0.587, 0.114));
		float l1 = dot(toward1.rgb, vec3(0.299, 0.587, 0.114)) * toward1.a;
		// Borda externa voltada para a luz e topo de cada tufo (vizinho mais escuro).
		float rim = 1.0 - toward2.a * toward1.a;
		float crest = clamp((l0 - l1) * 12.0, 0.0, 1.0);
		float glint = smoothstep(0.42, 0.62, l0);
		float light = clamp(max(rim, crest * 0.85) + glint * 0.35, 0.0, 1.0);
		// Parte de baixo do tufo (vizinho em direção à luz mais claro): sombra interna.
		float under = clamp((l1 - l0) * 12.0, 0.0, 1.0) * toward1.a;
		vec3 c = sampled.rgb;
		c = mix(c, c * light_color * 1.6 + light_color * 0.06, light * light_strength * leaf * foliage_light);
		c = mix(c, c * inner_shade, under * shade_strength * leaf * foliage_light);
		lit.rgb = c;
	}
	COLOR = sprite_tint * lit * inside;
}
