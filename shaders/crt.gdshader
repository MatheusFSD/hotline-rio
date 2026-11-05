// Old cathode-ray tube: curved glass, scanlines, an RGB mask, colour bleed, a slow rolling
// bar, snow and the classic power-on/off collapse to a line and a dot.
shader_type canvas_item;

uniform float open_x : hint_range(0.0, 1.0) = 1.0;
uniform float open_y : hint_range(0.0, 1.0) = 1.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float static_amount : hint_range(0.0, 1.0) = 0.0;
uniform float curvature = 4.0;
uniform float lines = 240.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 bend(vec2 uv) {
	vec2 c = uv * 2.0 - 1.0;
	vec2 offset = abs(c.yx) / vec2(curvature, curvature * 0.85);
	c += c * offset * offset;
	return c * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = bend(UV);
	float glass = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	vec2 p = (uv - 0.5) / vec2(max(open_x, 0.001), max(open_y, 0.001)) + 0.5;
	float lit = step(0.0, p.x) * step(p.x, 1.0) * step(0.0, p.y) * step(p.y, 1.0);
	float row = floor(p.y * lines);
	float tear = (hash(vec2(row, floor(TIME * 30.0))) - 0.5) * 0.02 * static_amount;
	vec2 q = p + vec2(tear + sin(p.y * 90.0 + TIME * 7.0) * 0.0007, 0.0);
	float bleed = 0.0018 + 0.004 * static_amount;
	vec3 col = vec3(texture(TEXTURE, q + vec2(bleed, 0.0)).r, texture(TEXTURE, q).g, texture(TEXTURE, q - vec2(bleed, 0.0)).b);
	col = (col + texture(TEXTURE, q - vec2(0.006, 0.0)).rgb * 0.14) / 1.14;
	col *= 0.76 + 0.24 * sin(q.y * lines * 3.14159);
	float m = mod(FRAGCOORD.x, 3.0);
	col *= vec3(m < 1.0 ? 1.1 : 0.93, (m >= 1.0 && m < 2.0) ? 1.1 : 0.93, m >= 2.0 ? 1.1 : 0.93);
	col *= 1.0 + 0.05 * sin((q.y - TIME * 0.12) * 6.2832);
	float snow = hash(floor(q * vec2(320.0, lines)) + fract(TIME * 7.13) * 91.0);
	col = mix(col, vec3(snow), static_amount);
	col += (snow - 0.5) * 0.05;
	col *= pow(max(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.0), 0.3) * 1.18;
	col = mix(col, vec3(1.0, 1.0, 0.97), flash) * lit;
	COLOR = vec4(mix(vec3(0.015, 0.018, 0.02), col, glass), 1.0);
}
