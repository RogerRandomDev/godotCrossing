shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE:hint_screen_texture;
uniform sampler2D colorMap;
uniform sampler2D fluid0: repeat_enable;
uniform sampler2D fluid1: repeat_enable;

uniform vec2 fluidScale=vec2(1.);

uniform int layerCount=6;
uniform vec2 flowDirection0;
uniform vec2 flowDirection1;
uniform float rippleStrength=1.;
uniform float distortion=1.;

//x is fluid0 y is fluid1 and z is the layer that the fluid will be
vec3 getHeights(vec2 uv){
	float height0=texture(fluid0,(uv+TIME*flowDirection0)*fluidScale).r;
	float height1=texture(fluid1,(uv+TIME*flowDirection1)*fluidScale).r;
	
	return vec3(
		height0,
		height1,
		floor(pow(height0,rippleStrength)*pow(height1,rippleStrength)*float(layerCount))/float(layerCount)
		);
}
void fragment() {

	vec3 heights=getHeights(UV);
	
	vec4 mapColor=texture(colorMap,vec2(heights.z,0.));
	vec2 uv=SCREEN_UV+(pow(heights.x,rippleStrength)*pow(heights.y,rippleStrength))*SCREEN_PIXEL_SIZE*distortion;
	COLOR.rgb=mix(texture(SCREEN_TEXTURE,uv).rgb,mapColor.rgb,mapColor.a);
}
