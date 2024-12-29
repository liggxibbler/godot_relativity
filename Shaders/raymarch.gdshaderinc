#include "res://Shaders/common.gdshaderinc"
#include "res://Shaders/signeddists.gdshaderinc"
#include "res://Shaders/rocket.gdshaderinc"

#define DEBUG true

//comment this if you do not want the delayed view.
//#define RETARD 0.0

#define MAX_ITER 1500
#define MAX_DIST 70.
#define SURF .0001

#define COLOR_RED vec3(2,0,.2)
#define COLOR_GREEN vec3(.2,1,0)
#define COLOR_MAGENTA vec3(1,0,1)
#define COLOR_BLUE vec3(0,.2,1)

uniform mat4 transformMatrix;
uniform vec4 fourvel;
uniform vec4 uposition;

uniform vec3 viewForward;
uniform vec3 viewUp;
uniform vec3 viewRight;

uniform vec3 resolution;
uniform vec4 enemyPosition;

uniform float projectionDistance;

//#define LIGHT_DIR viewForward;//vec3(-3,2,1)

const vec3 BOX_SIZE = vec3(.1);

vec3 GetColor(float s)
{
	return vec3(1.0) -
		vec3(1.,1.,0.) * smoothstep(0.,1., s) -
		vec3(0.,.6,.6) * smoothstep(0.,1., -s);
}

struct SceneDistances
{
	float cylinder1;
	float cylinder2;
	float cylinder3;
	float cylinder4;
	float marchDistance;
#if DEBUG
	int maxIteration;
	vec3 reason;
#endif
};

SceneDistances GetDistance(vec4 q)
{
	SceneDistances distances;

    //float dist=sdBox(q, BOX_SIZE);
	float dist=sdBoxFrame(q,vec4(0.5,0.5,0.5,0.0), 0.0005);

	dist = min(dist, sdSphere(q, enemyPosition, 1.0f));

	//the cylinders:
    float len= 3.;
    float d= 4.;
    float s=.5;

	q.x-=d;
    distances.cylinder1= sdCylinder(q.zxy, vec2(s,len*s));
    dist = min(dist,distances.cylinder1);
	if (true)
	{
    q.x+=2.*d;
    distances.cylinder2= sdCylinder(q.zxy, vec2(s,len*s));
    dist = min(dist,distances.cylinder2);

	q.x-=d;
    q.z-=d;
    distances.cylinder3= sdCylinder(q.xzy, vec2(s,len*s));
    dist = min(dist,distances.cylinder3);

	q.z+=2.*d;
    distances.cylinder4= sdCylinder(q.xzy, vec2(s,len*s));
    dist = min(dist,distances.cylinder4);
    }
	distances.marchDistance = dist;

    return distances;
}

vec4 GetRayDir(vec2 uv, float zoom, float t)
{
	vec4 ray = vec4(normalize(
		viewForward * zoom + uv.x * viewRight + uv.y * viewUp), t/c);

    vec4 rd = transformMatrix * ray;

	if (false)//resolution.z > 0.0)
	{
		rd.xyz=normalize(rd.xyz);
		rd.w=-resolution.z;
	}
	else
	{
		rd = normalize(rd);
	}
	
	return rd;
}

SceneDistances RayMarch(vec4 ro, vec4 rd, float direction)
{
	float dO = 0.;
	int i = 0;

	SceneDistances distances;

	bool isDone = false;

	while(true)
	{
		vec4 p = ro + dO * rd; //if rd.w =-c we look back in time as we march further away

		distances = GetDistance(p);
#if DEBUG
		distances.reason = vec3(0.0);
#endif

		float dS = direction * distances.marchDistance;

		dO += dS;
		distances.marchDistance = dO;

		if (dS < SURF)
		{
#if DEBUG
			distances.reason += COLOR_RED;
#endif
			isDone = true;
		}
		if(dO > MAX_DIST)
		{
#if DEBUG
			distances.reason += COLOR_GREEN;
#endif
			isDone = true;
		}

		i++;

		if (i >= MAX_ITER)
		{
			isDone = true;
#if DEBUG
			distances.reason += COLOR_BLUE;
#endif
		}

		if (isDone)
		{
			break;
		}
	}

#if DEBUG
	distances.maxIteration = i;
#endif

	return distances;
}

vec3 GetNormal(vec4 p)
{
	vec2 e = vec2(0.01,0);
	float d = GetDistance(p).marchDistance;
	vec3 n = vec3(d) - vec3(
		GetDistance(p- e.xyyy).marchDistance,
		GetDistance(p- e.yxyy).marchDistance,
		GetDistance(p- e.yyxy).marchDistance
	);

   return normalize(n);
}

struct MaterialQuery
{
	bool hasData;
	vec3 color;
};

MaterialQuery GetMaterial(vec4 p, SceneDistances distances)
{
	// Initialize hasData to true, and only set to false if there is no hit
	MaterialQuery result = MaterialQuery(true, vec3(0.0f));

	mat2 rotation = Rotate(p.w * .5);
	vec4 yz_rotated = p, xy_rotated = p;
	yz_rotated.yz *= rotation;
	float twisty_along_x = sin(atan(yz_rotated.y,yz_rotated.z)*10.);
	xy_rotated.xy *= rotation;
	float twisty_along_z = sin(atan(xy_rotated.y,xy_rotated.x)*10.);
    if(distances.cylinder1 < 5. * SURF)
    {
		p.yz *= rotation;
        result.color = COLOR_RED * twisty_along_x * twisty_along_x;
    }
    else if(distances.cylinder2 < 5. * SURF)
    {
		p.yz *= rotation;
		result.color = COLOR_GREEN * twisty_along_x * twisty_along_x;
    }
    else if(distances.cylinder3 < 5. * SURF)
    {
        p.xy *= rotation;
		result.color = COLOR_MAGENTA * twisty_along_z * twisty_along_z;
    }
    else if (distances.cylinder4 < 5. * SURF)
    {
        p.xy *= rotation;
		result.color = COLOR_BLUE * twisty_along_z * twisty_along_z;
    }
	else
	{
		result.hasData = false;
	}

	return result;
}

vec3 fragment2(vec2 texCoords)
{
	vec2 uv = texCoords;//(texCoords -.5*iResolution.xy)/iResolution.xy;

	vec3 albedo = vec3(texCoords, 0);
	//return albedo;

    //ray's spacetime origin represented in "stationary coordinates":
    vec4 RO = uposition;
    
    //ray in our moving coords:
    vec4 ray = GetRayDir(uv, projectionDistance, -c);

    SceneDistances distances = RayMarch(RO, ray, 1.);

	albedo = vec3(0., 0., 0.);

	if(distances.marchDistance < MAX_DIST)
	{ //if we hit an object:
		vec4 p = RO + distances.marchDistance * ray;

		float shift = dot(normalize(ray.xyz), fourvel.xyz);
		albedo=GetColor(shift);
		MaterialQuery query = GetMaterial(p, distances);
		if (query.hasData)
		{
			albedo += query.color;
			vec3 n = GetNormal(p);
			float costheta = dot(n, normalize(-viewForward)) * .5 + .5;
			albedo *= costheta * costheta;
		}
		float dist = length(distances.marchDistance * ray);
		albedo /= dist * dist * .2;
	}

	return vec3(albedo);
}