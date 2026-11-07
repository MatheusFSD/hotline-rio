// The glass of the room's TV in the opening: the newscast while the set is on and, once it is
// off, the room reflected in the dark tube (scripts/intro.gd renders the reflection with a camera
// mirrored through the glass, so it is flipped left to right here, as a mirror is).
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D picture : source_color, filter_linear;
uniform sampler2D mirror : source_color, filter_linear;
uniform float reflection : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 on = texture(picture, UV).rgb;
	// Dark glass: the room comes back dim, a little blue, brighter toward the middle of the bulge.
	vec2 c = UV * 2.0 - 1.0;
	float bulge = 1.0 - 0.35 * dot(c, c);
	vec3 off = texture(mirror, vec2(1.0 - UV.x, UV.y)).rgb * vec3(0.34, 0.38, 0.44) * bulge + vec3(0.01, 0.012, 0.016);
	ALBEDO = mix(on, off, reflection);
}
