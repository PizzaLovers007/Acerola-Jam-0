shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = SCREEN_UV;
	uv.x += 0.1 * sin((uv.y + TIME * 0.05) * 30.) * (1. - uv.y);
	COLOR = textureLod(screen_texture, uv, 0.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
