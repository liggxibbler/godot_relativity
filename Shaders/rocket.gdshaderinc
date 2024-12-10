#include "res://Shaders/common.gdshaderinc"
#include "res://Shaders/signeddists.gdshaderinc"

struct Df_ret
{
	float ret;
	float halo;
};

struct Fours
{
	vec4 position;
	vec3 orientation;
	vec4 boost;
};

float dfRocketBody(vec3 p)
{

    vec3 p2 = p;

    angularRepeatVec(PI*.25,p2.zy);
    float d = p2.z;
    d = max(d, (Rotate(PI*-.125)*( p2.xz+vec2(-.7,0))).y);
    d = max(d, (Rotate(PI*-.25*.75)*(p2.xz+vec2(-0.95,0))).y);
    d = max(d, (Rotate(PI*-.125*.5)*( p2.xz+vec2(-0.4,0))).y);
    d = max(d, (Rotate(PI*.125*.25)*( p2.xz+vec2(+0.2,0))).y);
    d = max(d, (Rotate(PI*.125*.8)*( p2.xz+vec2(.5,0))).y);

    d = max(d,-.8-p.x);

    d -= .5;

  	return d;
}

float dfRocketFins(vec3 p, Fours fours)
{

    p.yz *= Rotate(fours.position.w * (1. + 10. * fours.boost.w));
    vec3 pFins = p;
    angularRepeatVec(PI * .5, pFins.zy);
    pFins -= vec3(-1.0 + cos(p.x + .2) * .5, .0, .0);
    pFins.xz *= Rotate(-PI * .25);
    float scale = 1.0 - pFins.z * .6;
    float d = mBox(pFins, vec3(.17, .03, 3.0) * scale) * .5;
    return d;
}

float Jet(vec3 p)
{
    float d = length(p.yz);
    if(p.x > 0.2)
	{
		d = 20.;
	}

    return d - p.x * .05;
}

Df_ret df(vec3 p, Fours fours, float halo)
{
    if(fours.boost.xz!=vec2(0))
	{
        p.xz*=Rotate(-atan(fours.orientation.z,fours.orientation.x));
    }

    float proxy = mBox(p,vec3(4.5,.8,.8));
    if (proxy>1.)
    	return Df_ret(proxy, halo);
    float dRocketBody = dfRocketBody(p);
    float dRocketFins = dfRocketFins(p, fours);
    float dJet=  Jet(p);
    if(fours.boost.w == 1. && dJet < dRocketFins * 5. && dJet < .4)
	{
    	halo+=.7;
    }

    return Df_ret(min(dRocketBody,dRocketFins), halo);
}

vec3 nf(vec3 p, Fours fours, float halo)
{
    vec2 e = vec2(0,0.005);
	float x = df(p+e.yxx, fours, halo).ret;
	float y = df(p+e.xyx, fours, halo).ret;
	float z = df(p+e.xxy, fours, halo).ret;
    return normalize(vec3(x,y,z));
}

struct RocketOutput
{
	vec3 color;
	float halo;
};

RocketOutput rocket (in vec3 pos, in vec3 dir, Fours fours, float halo)
{
	float dist, tdist = .0;

    for (int i=0; i<100; i++)
    {
		Df_ret ret = df(pos, fours, halo);
		dist = ret.ret;
		halo = ret.halo;
		pos  += dist*dir;
        tdist += dist;
        if (dist<0.00001||dist>7.0)break;
    }

    vec3 normal = nf(pos, fours, halo);

    float ao = df(pos + normal * .125, fours, halo).ret * 8.0 +
        df(pos+normal*.5, fours, halo).ret * 2.0 +
    	df(pos+normal*.25, fours, halo).ret * 4.0 +
    	df(pos+normal*.06125, fours, halo).ret * 16.0;

    ao=ao*.125+.5;

    if(fours.boost.xz!=vec2(0))
	{
        pos.xz*=Rotate(-atan(fours.orientation.z,fours.orientation.x));
    }

    vec3 materialColor = vec3(0);
    vec3 blueColor = vec3(.1,.4,.9);

    float dRocketBody = dfRocketBody(pos);
    float dRocketFins = dfRocketFins(pos, fours);
    float dRocket = min(dRocketBody, dRocketFins);

    float r = dot(pos.yz,pos.yz);

    if (dRocketBody<dRocketFins)
    {
        if (pos.x<-.85)
		{
            if (pos.x<-1.2)
			{
                materialColor = blueColor + vec3(0.03 / r);
			}
            else
			{
                materialColor = vec3(.7,.1,.7);
			}
		}
		else
		{
			if (pos.x>1.0)
			{
				materialColor = vec3 (.7,.1,.7);
			}
			else
			{
				materialColor = vec3(.6);
			}
		}
    }
    else
    {
        materialColor = vec3(.7,.1,.7);
        if (length (pos - 0.1 * vec3(0.0, normal.yz)) > length (pos))
		{
            materialColor -= vec3(.9,.3,1.5) * min(0.2, pos.x + 1.3) / r;
        }
    }

	vec3 color = vec3(0.0f);
    if (dist<.1)
	{
		color =  ao * materialColor;
	}
	return RocketOutput(color, halo);
}