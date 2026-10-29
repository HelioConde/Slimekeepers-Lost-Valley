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
	COLOR = sprite_tint * sampled * inside;
}
