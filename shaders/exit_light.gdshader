// The exit once the bar is clear: a stepped glow traced on the floor around the exit rectangle
// (the same banded light as the hero's spectral fringe) and, with `curtain`, light rising out of
// the ground along its edges in bands that climb and fade.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 glow : source_color = vec3(0.35, 1.0, 0.82);
uniform float strength = 1.0;
uniform bool curtain = false;
uniform vec2 half_size = vec2(1.0, 1.15);   // floor: exit rectangle half extents, metres
uniform vec2 plane_size = vec2(3.2, 3.5);   // floor: size of the quad it is drawn on, metres

float steps(float v, float n) {
	return floor(v * n + 0.5) / n;
}

void fragment() {
	float a;
	if (curtain) {
		float h = UV.y;   // 0 at the floor, 1 at the top
		float rise = 0.55 + 0.45 * step(0.5, fract(h * 5.0 - TIME * 1.3));
		a = steps(pow(1.0 - h, 1.6), 6.0) * rise * 0.5;
	} else {
		vec2 p = (UV - 0.5) * plane_size;
		vec2 q = abs(p) - half_size;
		float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
		float edge = exp(-abs(d) * 5.0);
		float fill = d < 0.0 ? 0.2 + 0.08 * sin(TIME * 3.0) : 0.0;
		a = steps(clamp(edge + fill, 0.0, 1.0), 5.0);
	}
	ALBEDO = glow * a * strength;
}
