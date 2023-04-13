shader_type sky;
render_mode use_quarter_res_pass;

uniform vec3 shortFrequency:source_color;
uniform vec3 midFrequency:source_color;
uniform vec3 longFrequency:source_color;

uniform float midFrequencyStrength:hint_range(0.,1.);

uniform float horizonDuration:hint_range(-1.,1.);

uniform float sunSize:hint_range(0.,0.25);

uniform sampler2D starNoise:repeat_enable;

uniform float starCutoff:hint_range(0.,1.);


vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void sky() {
	
	vec3 sky_color;
	float distToSun=distance(LIGHT0_DIRECTION,-EYEDIR);
	//calculate strength for each frequency based on sun angle
	float shortFrequencyStrength=(
		distance(-abs(LIGHT0_DIRECTION.y),EYEDIR.y)
	);
	float longFrequencyStrength=(1.-shortFrequencyStrength);
	
	vec3 shortCol=shortFrequency*shortFrequencyStrength+midFrequencyStrength;
	vec3 midCol=midFrequency*midFrequencyStrength;
	vec3 longCol=longFrequency*(longFrequencyStrength-midFrequencyStrength);
	float light_blockage=clamp(
		(
			LIGHT0_DIRECTION.y+horizonDuration
		),0.,1.
	);
	sky_color=(
		(shortCol+midCol+longCol)/3.+
		vec3(float(distToSun<sunSize))
		)*(1.-light_blockage);
	float starStrength=texture(starNoise,EYEDIR.xy-LIGHT0_DIRECTION.xz).r;
	vec3 starColor=vec3(1.)*(
		float(
			starStrength<(light_blockage)*starCutoff
			)
	);
	
	vec3 outputColor=sky_color+starColor;
	
	COLOR=outputColor;
	
	
	
}
