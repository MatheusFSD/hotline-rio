// Full-screen pass behind the death and level-clear screens: the night behind is tinted, split
// into RGB, torn in horizontal bands when `glitch` spikes, wobbled, scanned and swept by
// diagonal stripes. `glitch` is kicked by the screen on every slam and every counted number.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec4 tint : source_color = vec4(0.85, 0.08, 0.12, 1.0);
uniform vec4 stripe : source_color = vec4(1.0, 0.2, 0.3, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform float stripe_speed = 0.6;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float frame = floor(TIME * 30.0);
	float band = floor(uv.y * 40.0);
	float torn = step(0.82 - glitch * 0.5, hash(vec2(band, floor(TIME * 14.0))));
	uv.x += (hash(vec2(band, frame)) - 0.5) * 0.08 * glitch * torn;
	uv.x += sin(uv.y * 18.0 + TIME * 5.0) * 0.0025 * amount;
	float split = 0.002 + 0.014 * glitch;
	vec3 col = vec3(texture(screen, uv + vec2(split, 0.0)).r, texture(screen, uv).g, texture(screen, uv - vec2(split, 0.0)).b);
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 graded = mix(col * 0.35, vec3(l) * tint.rgb * 1.9, 0.8);
	float diagonal = step(0.55, fract((UV.x * 1.6 + UV.y) * 7.0 - TIME * stripe_speed));
	graded = mix(graded, graded * 0.7 + stripe.rgb * 0.12, diagonal * 0.6);
	graded *= 0.82 + 0.18 * sin(FRAGCOORD.y * 3.14159);
	vec2 c = UV - 0.5;
	graded *= 1.15 - dot(c, c) * 1.4;
	graded += (hash(UV * 400.0 + frame) - 0.5) * 0.06 * glitch;
	COLOR = vec4(mix(col, graded, amount), 1.0);
}
