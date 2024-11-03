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

mat4 Lorentz(vec3 v)
{
     float beta= length(v)/c;
     float gamma = gamma(beta);
    
    float v2=dot(v,v);
    
	vec4 row1 = vec4(1.+(gamma-1.)*v.x*v.x/v2, (gamma-1.)*v.x*v.y/v2, (gamma-1.)*v.x*v.z/v2, -gamma*v.x/c);
	vec4 row2 = vec4((gamma-1.)*v.y*v.x/v2, 1.+(gamma-1.)*v.y*v.y/v2, (gamma-1.)*v.y*v.z/v2, -gamma*v.y/c);
	vec4 row3 = vec4((gamma-1.)*v.z*v.x/v2, (gamma-1.)*v.z*v.y/v2, 1.+(gamma-1.)*v.z*v.z/v2, -gamma*v.z/c);
	vec4 row4 = vec4(-gamma*v.x/c, -gamma*v.y/c, -gamma*v.z/c,   gamma);	
		
    return mat4(row1, row2, row3, row4);
}

mat2 rot(float a)
{ 
    return mat2(vec2(cos(a), -sin(a)), vec2(sin(a),cos(a)));
}