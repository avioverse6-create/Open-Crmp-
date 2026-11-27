shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back;

uniform sampler2D snow_albedo : source_color, repeat_enable;
uniform sampler2D snow_normal : hint_normal, repeat_enable;
uniform float snow_world_scale = 0.12;

varying vec3 world_normal;
varying vec3 world_position;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// World-space mapping avoids tiny stretched patches on large road/terrain meshes.
	vec2 snow_uv = world_position.xz * snow_world_scale;
	float upward = smoothstep(0.48, 0.82, world_normal.y);
	vec3 snow_color = texture(snow_albedo, snow_uv).rgb;
	vec3 snow_normal_sample = texture(snow_normal, snow_uv).rgb;
	ALBEDO = mix(vec3(0.78, 0.84, 0.90), snow_color, 0.78);
	NORMAL_MAP = snow_normal_sample;
	NORMAL_MAP_DEPTH = 0.12;
	ROUGHNESS = 0.98;
	METALLIC = 0.0;
	ALPHA = upward * 0.98;
}
