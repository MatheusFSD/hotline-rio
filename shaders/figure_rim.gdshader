// Faint edge light drawn over a living fighter (additive next pass on the skin materials).
// Only the silhouette catches it, so heads, shoulders and arms separate from busy floors
// without an outline. Stepped in a few bands to stay in the PS1 register.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, fog_disabled;

uniform vec4 rim_color : source_color = vec4(1.0);
uniform float strength = 0.3;
uniform float power = 2.4;
uniform float bands = 4.0;

void fragment() {
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), power);
	edge = floor(edge * bands + 0.5) / bands;
	ALBEDO = rim_color.rgb * edge * strength;
}
