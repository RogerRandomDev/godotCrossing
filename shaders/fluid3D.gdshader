shader_type spatial;
render_mode cull_back;
uniform sampler2D SCREEN_TEXTURE:hint_screen_texture;
uniform sampler2D DEPTH_TEXTURE:hint_depth_texture,filter_linear;
//gradient texture for the fluid colors
uniform sampler2D colorMap;
//fluid bump maps
//use 2 noise textures
uniform sampler2D fluid0: repeat_enable;
uniform sampler2D fluid1: repeat_enable;
//scales the fluid up or down
uniform vec2 fluidScale=vec2(1.);
//# of colors/layers the fluid will sample
//4-6 appears more toon-y
uniform int layerCount=6;
//direction of fluid motion for the two fluid textures
uniform vec2 flowDirection0;
uniform vec2 flowDirection1;
//modifier for ripples
uniform float rippleStrength=1.;
//distortion of background through the fluid
uniform float distortion=1.;

uniform vec4 waterFallModifiers=vec4(1.,8.,8.,0.875);
//whether to ripple on the shore or not
uniform bool rippleShore=false;



global uniform vec3 wrapAround;
// player_pos updated in Ground.gd, used to calculate distance from player
// Set "active" to  false  to turn off the displacement shader.
global uniform bool active;
// Set "remap_normals" to true if you want lighting to take place after displacement
uniform bool remap_normals = true;
// Use RADIUS to determine how warped the world should be.
global uniform float RADIUS;
global uniform bool hang;


void vertex(){
	//rolling log
	// Vertex displacement math, as a function of dist_z, dist_y
	float dist_z = VERTEX.z - wrapAround.z;
	float dist_y = VERTEX.y;
	// Dz and theta is calculated from RADIUS for use in the transform. 
	float Dz = PI*RADIUS/2.0;
	float theta = dist_z / RADIUS;
	
	// Calculate which "side" we're on
	// 1 and -1 represent "hanging towel"
	// 0 represents the "rolling log" part
	int side;
	if (active) {
		if (dist_z > Dz) {
			side = 1;
		} else if (dist_z < -Dz) {
			side = -1;
		} else {
			side = 0;
		}
		
		// set side = 0 if you want a log without "hanging sides"
		if (!hang) { side = 0; }
		if (side == 1) {
			// positive vertical side
			VERTEX.y = -(dist_z - Dz) - RADIUS;
			VERTEX.z = dist_y + RADIUS;
		}
		if (side == -1) {
			// negative vertical side
			VERTEX.y = (dist_z + Dz) - RADIUS;
			VERTEX.z = - (dist_y + RADIUS);
		}
		if (side == 0) {
			// rolling log
			VERTEX.y = (dist_y + RADIUS)*cos(theta) - RADIUS;
			VERTEX.z = (dist_y + RADIUS)*sin(theta) ;
		}
		// reposition world vertices
		VERTEX.z += wrapAround.z;
	}
	// todo - recalculate normals
	if (remap_normals) {
		if (side == 1) {
			//vec3 normal = normalize(vec3(NORMAL.x, -NORMAL.z, NORMAL.y));
			vec3 normal = normalize(vec3(0.0, 1.0, 0.0));
			NORMAL = normal;
		} else if (side == -1) {
			//vec3 normal = normalize(vec3(NORMAL.x, NORMAL.z, -NORMAL.y));
			vec3 normal = normalize(vec3(0.0, 1.0, 0.0));
			NORMAL = normal;
		} else if (side == 0) {
			// todo - check this math!
			vec3 normal = normalize(vec3(
				NORMAL.x,
				NORMAL.y * cos(theta) - NORMAL.z * sin(theta),
				NORMAL.z * cos(theta) + NORMAL.z * sin(theta)
			));
			NORMAL = normal;
		}
	}
}








//gets depth of object inside of fluid
float getDepth(vec2 uv,vec3 vertex,mat4 projMatrix){

    float depthRaw = texture(DEPTH_TEXTURE, uv).x;
    vec3 ndc = vec3(uv * 2.0 - 1.0, depthRaw);
    vec4 view = projMatrix * vec4(ndc, 1.0);
    view.xyz /= view.w;	

    float waterDepth = -view.z + vertex.z;
	return waterDepth;
}

//x is fluid0 y is fluid1 and z is the layer that the fluid will be
vec3 getHeights(vec2 uv,vec4 waterFallMult){
	float height0=texture(fluid0,(uv*waterFallMult.xy+TIME*flowDirection0*waterFallMult.z)*fluidScale).r;
	float height1=texture(fluid1,(uv*waterFallMult.xy+TIME*flowDirection1*waterFallMult.z)*fluidScale).r;
	
	return vec3(
		height0,
		height1,
		floor(pow(height0,rippleStrength)*pow(height1,rippleStrength)*float(layerCount))/float(layerCount)
		);
}
uniform vec3 ripples[32];
float getDistSquared(vec2 pos){
	return pos.x*pos.x+pos.y*pos.y;
}

float drawRipples(vec2 uv){
	float rippleValue=0.;
	float rippleStack=0.;
	bool drawRipple=false;
	for(int i=0;i<32;i++){
		if(ripples[i].xyz==vec3(0.)){continue;}
		float dist=getDistSquared(uv-ripples[i].xy);
		bool insideRipple=dist<0.01*ripples[i].z;
		if(insideRipple){
			rippleValue=drawRipple?rippleValue-ripples[i].z*rippleStack:1.-ripples[i].z;
			rippleStack+=ripples[i].z;
		}
		drawRipple=drawRipple||(insideRipple&&dist>0.007*ripples[i].z);
	}
	return float(drawRipple)*max(rippleValue,0.);
}

float sample(in vec2 uv,in vec2 modBy,in mat4 inv_mat,in vec3 VERT){
	return min(min(min(min(min(min(min(min(
		getDepth(uv+vec2(modBy.x,0.),VERT,inv_mat),
		getDepth(uv-vec2(modBy.x,0.),VERT,inv_mat)),
		getDepth(uv+vec2(0.,modBy.y),VERT,inv_mat)),
		getDepth(uv-vec2(0.,modBy.y),VERT,inv_mat)),
		getDepth(uv+vec2(0.,modBy.y),VERT,inv_mat)),
		getDepth(uv+vec2(modBy.x,modBy.y),VERT,inv_mat)),
		getDepth(uv-vec2(modBy.x,modBy.y),VERT,inv_mat)),
		getDepth(uv+vec2(modBy.x,-modBy.y),VERT,inv_mat)),
		getDepth(uv+vec2(-modBy.x,modBy.y),VERT,inv_mat)
		);
}
float linear_position(in sampler2D depth_texture, in vec2 screen_uv, in mat4 inv_projection_matrix){
	float depth = texture(depth_texture, screen_uv).r;
    vec4 upos = inv_projection_matrix * vec4(screen_uv * 2.0 - 1.0, depth, 1.0);
    vec3 pixel_position = upos.xyz / upos.w;
	return pixel_position.y;
}
void fragment() {
	vec4 waterFall=vec4(1.);
	if(dot(NORMAL,VIEW_MATRIX[1].xyz)<=0.5){
		waterFall=waterFallModifiers;
	}
	vec3 heights=getHeights(UV,waterFall);
	
	vec4 mapColor=texture(colorMap,vec2(heights.z*waterFall.w,0.));
	vec2 uv=SCREEN_UV+(vec2(heights.x,heights.y)/VIEWPORT_SIZE-(0.5/VIEWPORT_SIZE))*distortion;
	//uv=SCREEN_UV;
	float transparency=max(mapColor.a,float(getDepth(SCREEN_UV,VERTEX,INV_PROJECTION_MATRIX)>4.));
	
	vec3 outCol=mix(texture(SCREEN_TEXTURE,uv).rgb,mapColor.rgb,transparency);
	float rippleStre=drawRipples(UV);
	outCol=mix(outCol,vec3(1.),rippleStre);
	if(rippleShore){
		float depth=getDepth(SCREEN_UV,VERTEX,INV_PROJECTION_MATRIX);
		outCol=(depth<0.5?mix(outCol,vec3(1.),clamp(abs(sin(-TIME*2.+depth*2.*PI))-depth*2.,0.,1.)):outCol);
	}
	ALBEDO.rgb=outCol;
}
