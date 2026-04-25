shader_type spatial;
render_mode cull_back;

instance uniform float lifetime : hint_range(0.0f, 1.0f);

void fragment() {
	ALBEDO = mix(vec3(1.0f, 0.0f, 0.0f), vec3(1.0f, 1.0f, 1.0f), pow(lifetime, 4.0f));
}