#include "res://Shaders/common.gdshaderinc"

float mBox(vec3 p, vec3 b)
{
	return max(max(abs(p.x)-b.x,abs(p.y)-b.y),abs(p.z)-b.z);
}

float sdBox(vec4 p , vec3 s)
{
    float time=p.w;
    p.xyz=fract(p.xyz)-.5; //this creates the grid of reference cubes
    p.yz *= Rotate(time*.5);
    p.xyz = abs(p.xyz)-s;
    return length(max(p.xyz,0.))+ min(max(p.x,max(p.y,p.z)),0.);  
}

float sdSphere(vec4 p, vec4 center, float r)
{
	return length(p.xyz-center.xyz) - r;
}

float sdBoxFrame(vec4 p, vec4 b, float e )
{
	p.xyz=fract(p.xyz)-.5;
	p = abs(p)-b;
	vec4 q = abs(p+e)-e;
	return min(min(
	length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
	length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
	length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    float outer= min(max(d.x,d.y),0.0) + length(max(d,0.0));
    vec2 d2 = abs(vec2(length(p.xz),p.y)) - (h+vec2(-.05,.05));
    float inner= min(max(d2.x,d2.y),0.0) + length(max(d2,0.0));
    
    return max(outer,-inner);
}

void angularRepeatVec(const float a, inout vec2 v)
{
    float an = atan(v.y,v.x);
    float len = length(v);
    an = mod(an+a*.5,a)-a*.5;
    v = vec2(cos(an),sin(an))*len;
}

void angularRepeatFloat(const float a, const float offset, inout vec2 v)
{
    float an = atan(v.y,v.x);
    float len = length(v);
    an = mod(an+a*.5,a)-a*.5;
    an+=offset;
    v = vec2(cos(an),sin(an))*len;
}