shader_type spatial;
render_mode unshaded;

#include "res://Shaders/raymarch.gdshaderinc"

void fragment()
{
	ALBEDO = fragment2(UV);
	ALPHA = 1.0f;
}

void vertex()
{
	VERTEX = vec3(VERTEX.x, VERTEX.y, 0.0f);
    UV = (VERTEX.xy + vec2(1.0f)) * .5f * iResolution.xy;
}