shader_type canvas_item;
render_mode unshaded;

#include "res://Shaders/raymarch.gdshaderinc"

void fragment()
{
	COLOR = vec4(fragment2(UV), 1.0);
	//ALBEDO = fragment2(UV);
	//ALPHA = 1.0f;
	//COLOR = vec4(UV,0.0,1.0);
}

void vertex()
{
	//VERTEX = vec3(VERTEX.x, VERTEX.y, 0.0f);
    UV = (VERTEX.xy - .5 * iResolution.xy) / iResolution.xy;
	UV.x *= iResolution.x/iResolution.y;
	UV.y = -UV.y;
}