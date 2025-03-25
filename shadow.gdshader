shader_type canvas_item;

uniform vec4 shadow_color: source_color = vec4(.0, .0, .0, .5);
uniform float mix_amount = 0.5;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	COLOR = mix(tex_color, shadow_color, mix_amount);
}