shader_type spatial;

instance uniform vec3 color : source_color;

void fragment() {
	ALBEDO = color;
}
