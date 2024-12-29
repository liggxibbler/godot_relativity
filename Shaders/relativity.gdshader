shader_type canvas_item;
render_mode unshaded;

#include "res://Shaders/raymarch.gdshaderinc"

void fragment()
{
	COLOR = vec4(fragment2(UV), 1.0);
}

void vertex()
{
	UV = (VERTEX.xy - .5 * resolution.xy) / resolution.xy;
	UV.x *= resolution.x / resolution.y;
	UV.y = -UV.y;
}