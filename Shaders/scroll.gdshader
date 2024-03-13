shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv = UV;
	uv += TIME * 0.5;
	vec3 color = vec3(0.5);
	// Called for every pixel the material is visible on.
	COLOR = texture(TEXTURE, uv) * vec4(color, 1.);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
