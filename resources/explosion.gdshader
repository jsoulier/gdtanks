shader_type spatial;
render_mode cull_back;

instance uniform vec3 color : source_color;
instance uniform float lifetime : hint_range(0.0f, 1.0f);

void fragment() {
	ALBEDO = mix(color, vec3(1.0f, 1.0f, 1.0f), pow(lifetime, 4.0f));
}