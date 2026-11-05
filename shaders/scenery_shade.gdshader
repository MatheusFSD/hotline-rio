// One multiply pass over the scenery that does the PS1 lighting work without adding polygons:
//  - faces: tops keep full light, faces toward the camera a little less, sides and backs less
//    again, so every box reads as a volume instead of one flat colour;
//  - contact: the baked floor map (scripts/contact_shadows.gd) darkens the ground under and
//    around furniture and walls, and the feet of whatever stands on it;
//  - grounding: upright faces darken in flat steps toward the floor;
//  - night: what lies outside the playable area sinks into cool, darker blue, and so does
//    anything above the bar's back wall, where street light never reaches.
// It only ever darkens: the lit materials underneath keep their colours and lamps.
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec4 stage = vec4(-15.1, -9.1, 15.1, 10.6);   // lit area: x0, z0, x1, z1 in metres
uniform float ramp = 3.0;                              // metres from the stage edge to full night
uniform vec3 night : source_color = vec3(0.32, 0.36, 0.48);
uniform float roof_from = 3.0;    // metres; the back wall tops out at 2.5
uniform float roof_night = 0.85;

uniform float face_up = 1.0;
uniform float face_front = 0.8;    // toward the camera (+z)
uniform float face_side = 0.68;
uniform float face_back = 0.62;
uniform float face_down = 0.55;

uniform sampler2D contact : hint_default_white, filter_nearest, repeat_disable;
uniform vec2 contact_origin = vec2(0.0);
uniform vec2 contact_size = vec2(1.0);
uniform float contact_reach = 0.35;   // metres above the floor the map still darkens

uniform float ground_height = 0.6;    // upright faces darken below this
uniform float ground_dark = 0.3;
uniform float ground_steps = 4.0;

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 a = abs(n);
	float face = (max(n.y, 0.0) * face_up + max(-n.y, 0.0) * face_down + max(n.z, 0.0) * face_front
		+ max(-n.z, 0.0) * face_back + a.x * face_side) / (a.x + a.y + a.z);
	float lift = clamp(world.y, 0.0, 10.0);
	float shade = texture(contact, (world.xz - contact_origin) / contact_size).r;
	float contact_k = mix(1.0, shade, 1.0 - smoothstep(0.08, contact_reach, lift));
	float steps = floor(clamp(lift / ground_height, 0.0, 1.0) * ground_steps) / ground_steps;
	float ground = 1.0 - ground_dark * (1.0 - a.y) * (1.0 - steps);
	vec2 outside = max(stage.xy - world.xz, world.xz - stage.zw);
	float k = smoothstep(0.0, ramp, length(max(outside, vec2(0.0))));
	// Street light never reaches the rooftops: anything above the bar's back wall sinks too.
	k = max(k, smoothstep(roof_from, roof_from + 2.0, world.y) * roof_night);
	ALBEDO = mix(vec3(1.0), night, k) * face * contact_k * ground;
}
