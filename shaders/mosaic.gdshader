// Brazilian TV face blur: coarse pixel blocks over whatever is behind the rectangle.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float cell = 9.0;

void fragment() {
	vec2 block = vec2(cell) * SCREEN_PIXEL_SIZE;
	COLOR = texture(screen, (floor(SCREEN_UV / block) + 0.5) * block);
}
