const float frames = 70.;

//t is the proper time in rockets moving frame (counted in frames so
//fps would not affect the physics)
#define dt iTimeDelta

#define PI 3.14159265359

const float c=1.;//Not sure if everything works if you change c.

float gamma(float b)
{

    return pow(1.-b*b,-.5);
}

//for infinitesimal lorentz transforms it is faster to use this generator:
mat4 LorentzGenerator(vec3 e)
{
     float cc=c*c;

     return mat4(vec4(0 ,0  , 0 , -e.x/cc),
				vec4(0,   0,  0 ,  -e.y/cc),
				vec4(0, 0,   0,   -e.z/cc) ,
				vec4(-e.x, -e.y  , -e.z ,0));
}

mat2 Rotate(float angle)
{
    return mat2(
		vec2(cos(angle), -sin(angle)),
		vec2(sin(angle),cos(angle)));
}