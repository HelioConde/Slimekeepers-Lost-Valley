shader_type canvas_item;
// Participate in CanvasModulate so terrain and water follow the global clock.
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	// Only the lower flat meadow is transparent; upper turf and rock stay intact.
	if(c.g>c.r*1.13 && c.g>c.b*1.5 && c.g<.35)c.a=0.0;
	COLOR=c;
}
