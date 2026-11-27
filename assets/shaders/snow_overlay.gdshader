shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back;

uniform sampler2D snow_albedo : source_color, repeat_enable;
uniform sampler2D snow_normal : hint_normal, repeat_enable;
uniform float snow_uv_scale = 8.0;

varying vec3 world_normal;
varying vec2 snow_uv;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	snow_uv = UV * snow_uv_scale;
}

void fragment() {
	float upward = smoothstep(0.58, 0.86, world_normal.y);
	vec3 snow_color = texture(snow_albedo, snow_uv).rgb;
	vec3 snow_normal_sample = texture(snow_normal, snow_uv).rgb;
	ALBEDO = mix(vec3(0.78, 0.84, 0.90), snow_color, 0.78);
	NORMAL_MAP = snow_normal_sample;
	NORMAL_MAP_DEPTH = 0.16;
	ROUGHNESS = 0.97;
	METALLIC = 0.0;
	ALPHA = upward * 0.98;
}
