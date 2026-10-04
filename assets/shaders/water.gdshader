shader_type spatial;
render_mode blend_mix, cull_disabled, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.05, 0.45, 0.75);
uniform vec3 shallow_color : source_color = vec3(0.35, 0.8, 0.95);
uniform float alpha = 0.82;

float wave(vec2 p, float t) {
	return sin(p.x * 3.1 + t * 1.3) * 0.5 + sin(p.y * 2.7 - t * 1.1) * 0.5
		+ sin((p.x + p.y) * 4.3 + t * 1.7) * 0.25;
}

void fragment() {
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME;
	float w = wave(world.xz, t);
	float caustic = smoothstep(0.55, 1.0, abs(sin(world.x * 5.0 + w * 2.0 + t) * sin(world.z * 5.0 - w * 2.0 - t * 0.8)));
	ALBEDO = mix(deep_color, shallow_color, 0.4 + 0.2 * w) + caustic * 0.25;
	ROUGHNESS = 0.08;
	METALLIC = 0.1;
	SPECULAR = 0.7;
	vec3 n = normalize(vec3(cos(world.x * 3.1 + t * 1.3) * 0.08, 1.0, cos(world.z * 2.7 - t * 1.1) * 0.08));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ALPHA = alpha;
}
