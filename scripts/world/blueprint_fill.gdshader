shader_type canvas_item;
// Planta de construção (station_placer.gd): azul translúcida; ao construir, enche de
// amarelo de baixo para cima conforme o progresso (como no Palworld).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 plan_color : source_color = vec4(0.55, 0.85, 1.0, 0.55);
uniform vec4 fill_color : source_color = vec4(1.0, 0.85, 0.25, 0.85);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	bool filled = UV.y >= 1.0 - progress;
	vec4 tint = filled ? fill_color : plan_color;
	float shade = dot(tex.rgb, vec3(0.3, 0.55, 0.15));
	COLOR = vec4(tint.rgb * (0.55 + 0.6 * shade), tex.a * tint.a);
	// linha clara na borda do enchimento
	if (progress > 0.0 && progress < 1.0 && abs(UV.y - (1.0 - progress)) < 0.02) COLOR.rgb = vec3(1.0, 0.97, 0.75);
}
