shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D skew_texture : repeat_disable, filter_linear;

float hash21(vec2 v) {
	return fract(3627.1348 * sin(dot(v, vec2(912.1235, 579.1223))));
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 offset = texture(skew_texture, SCREEN_UV).rg;
	vec2 uv = SCREEN_UV + (offset - 0.5) * 0.15 * sin(TIME / 3.);
	COLOR = textureLod(screen_texture, uv, 0.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
