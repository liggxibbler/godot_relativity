shader_type spatial;
render_mode unshaded;

#include "res://Shaders/common.gdshaderinc"
#include "res://Shaders/rocket.gdshaderinc"

//comment this if you do not want the delayed view.
#define RETARD 1.

#define MAX_ITER 1500.
#define MAX_DIST 70.
#define SURF .0001

uniform mat4 transformMatrix;
uniform vec4 fourvel;
uniform vec4 uposition;
uniform vec4 boost;
uniform vec3 orientation;
uniform vec3 iResolution;
uniform vec3 iMouse;
uniform float iTimeDelta;

const vec3 SIZE = vec3(.1); 

vec3 color(float s)
{
    return vec3(1) - 
		vec3(1.,1.,0) * smoothstep(.0,1., s) -
		vec3(0.,.6,.6) * smoothstep(0.,1., -s);
}

vec4 updatePos(vec2 m)
{
    // Fetch the fourposition from the Buffer B
    
    //position =texelFetch( iChannel0, ivec2(1,0), 0 );
    vec4 position = uposition;
    vec4 cam=vec4(-1,0,0,0);
    if(m!=vec2(0))
	{
        cam.xy*=rot((m.y-.5)*PI);
        cam.xz*=rot(-(m.x-.5)*2.*PI);    
    }
    position += transformMatrix*cam;
	return position;
}

struct SceneDistances
{
	float cylinder1;
	float cylinder2;
	float cylinder3;
	float cylinder4;
	float marchDistance;
};

SceneDistances getDist(vec4 q)
{
	SceneDistances distances;
	
    float dist= sdBox(q, SIZE);
    
    //the cylinders:
    float len= 3.;
    float d= 4.;
    float s=.5;
    q.x-=d;
    distances.cylinder1= sdCylinder(q.zxy, vec2(s,len*s));
    q.x+=2.*d;
    distances.cylinder2= sdCylinder(q.zxy, vec2(s,len*s));
    q.x-=d;
    q.z-=d;
    distances.cylinder3= sdCylinder(q.xzy, vec2(s,len*s));
    q.z+=2.*d;
    distances.cylinder4= sdCylinder(q.xzy, vec2(s,len*s));
    
    dist = min(dist,distances.cylinder1);
    dist = min(dist,distances.cylinder2);
    dist = min(dist,distances.cylinder3);
    dist = min(dist,distances.cylinder4);
    
	distances.marchDistance = dist;
	
    return distances;
}

vec4 getRayDir(vec2 uv, vec4 lookAt, float zoom)
{

    vec3 f= normalize(lookAt.xyz);
    vec3 r= normalize(cross(vec3(0,1,0),f));
    vec3 u= cross(f,r);
    
    return vec4(normalize(f*zoom+uv.x*r+uv.y*u),lookAt.w/c);

    //the w-component determines how we look into past/future/present.
}

SceneDistances RayMarch(vec4 ro, vec4 rd, float side)
{
	float dO=0.;
	float i=0.;
	
	SceneDistances distances;
	
	while(i<MAX_ITER)
	{
		vec4 p= ro+dO*rd; //if rd.w =-c we look back in time as we march further away
		distances = getDist(p);
		float dS=side*distances.marchDistance; 

		dO+=dS;
		if(dO>MAX_DIST||dS<SURF)
		{
			break;
		}
		i++;
	} 

	return distances;
}

vec3 getNormal(vec4 p)
{
	vec2 e= vec2(0.01,0);
	float d=getDist(p).marchDistance;
	vec3 n = d-vec3(
		getDist(p- e.xyyy).marchDistance,
		getDist(p- e.yxyy).marchDistance,
		getDist(p- e.yyxy).marchDistance
	);
   
   return normalize(n);
}

vec3 getMaterial(vec4 p, SceneDistances distances)
{
    if(distances.cylinder1<5.*SURF)
    {
        p.yz*=rot(p.w*.5);
        return vec3(2,0,.2)*sin(atan(p.y,p.z)*10.)*sin(atan(p.y,p.z)*10.);
    }
    else if(distances.cylinder2<5.*SURF)
    {
        p.yz*=rot(p.w*.5);
        return vec3(.2,1,0)*sin(atan(p.y,p.z)*10.)*sin(atan(p.y,p.z)*10.);
    }
    else if(distances.cylinder3<5.*SURF)
    {
        p.xy*=rot(p.w*.5);
        return vec3(1,0,1)*sin(atan(p.y,p.x)*10.)*sin(atan(p.y,p.x)*10.);
    }
    else if (distances.cylinder4<5.*SURF)
    {
        p.xy*=rot(p.w*.5);
        return vec3(0,.2,1)*sin(atan(p.y,p.x)*10.)*sin(atan(p.y,p.x)*10.);;
    }
}

vec3 fragment2(vec2 texCoords)
{
	vec3 albedo = vec3(0,0,0);
	vec2 uv = (texCoords -.5*iResolution.xy)/iResolution.y;
    vec2 m = iMouse.xy == vec2(0) ? vec2(.5) : (iMouse.xy-.5)/iResolution.xy;

    vec4 position = updatePos(m);
    
    //ray's spacetime origin represented in "stationary coordinates":
    vec4 RO = position;
    float zoom = 1.;
    
    //four-direction in our moving coords:
    vec4 lookAt;
    //what we actually see as light reaches our eyes:
    #ifdef RETARD 
        lookAt = vec4(c, 0, 0, -1);
    #else //the "instantaneous geometry" of spacetime/coordinates: 
        lookAt = vec4(c, 0, 0, 0);
	#endif
     
    if(m != vec2(0))
	{
        lookAt.xy*=rot((m.y-.5)*PI);
        lookAt.xz*=rot(-(m.x-.5)*2.*PI);
    }
      
    //ray in our moving coords:
    vec4 ray= getRayDir(uv, lookAt, zoom);
        
    //adding the rocket on top
    vec3 r_color = vec3 (0);
    vec3 cam=vec3(-7,1.5,0);
    
    if(m!=vec2(.5))
	{
        cam.xy *= rot((m.y-.5) * PI);
        cam.xz *= rot(-(m.x-.5) * 2. * PI);
    }           
	
	Fours fours = Fours(uposition, orientation, boost);
	
    float halo = rocket (r_color, cam, ray.xyz, fours, 0);
    
    if (length (r_color) > 0.0)
	{
        albedo.rgb = r_color.xyz;
    }
	else
	{
    //ray direction from moving coords to stationary coords:
    vec4 rd= transformMatrix*ray;
    //some rescaling for accuracy:
    
    #ifdef RETARD
        rd.xyz=normalize(rd.xyz);
        rd.w=-RETARD;
    #else
       rd=normalize(rd); 
    #endif    
    
   /* //just some helpfull scaling factors for raymarching:
    if(RETARD>0.){
         vv= max(0., -dot(fourvel.xyzw, rd.xyzw));
    }else{
         vv= abs(dot(fourvel.xyzw, rd.xyzw));
    }
    */
    
    
    //RAYMARCH IN SPACETIME calculated in stationary coordinates:
    vec4 p=RO;          
    
    SceneDistances distances = RayMarch(p, rd, 1.);
    
    vec3 col = vec3(0.0f, 0.0f, 0.0f);
	
	if(distances.marchDistance < MAX_DIST)
	{ //if we hit an object:
		p = p + distances.marchDistance * rd;
          
		vec3 col=color(dot(normalize(rd.xyz), fourvel.xyz));
		getMaterial(p, distances);

		vec3 n= getNormal(p);
      
		float dif= dot(n, normalize(vec3(-3,2,1)))*.5+.5;
		col /= length(distances.marchDistance * rd) * .2;
		col *= dif * dif;
	}

		albedo = col + halo * halo * vec3(.4,.2,1);    
	}
	
	return albedo;
}

void fragment()
{
	ALBEDO = fragment2(UV);
	//ALBEDO = vec3(UV,0);
	ALPHA = 1.0f;
}

void vertex()
{
	VERTEX = vec3(VERTEX.x, VERTEX.y, 0.0f);
	//POSITION = vec4(VERTEX.x, VERTEX.y, 0.0, 1.0);    
    UV = VERTEX.xy + vec2(1.0f) * .5f;// * iResolution.xy;
}