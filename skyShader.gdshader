shader_type sky;
render_mode use_half_res_pass;


// Sky Gradients
uniform vec3 day_bottom_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 day_top_color : source_color = vec3(1.0, 1.0, 1.0);

uniform vec3 sunset_bottom_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 sunset_top_color : source_color = vec3(0.0, 0.0, 0.0);

uniform vec3 night_bottom_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 night_top_color : source_color = vec3(0.0, 0.0, 0.0);


// Horizon Stuff
uniform vec3 horizon_color_day : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 horizon_color_sunset : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 horizon_color_night : source_color = vec3(0.0, 0.8, 1.0);
uniform float horizon_falloff: hint_range(0.0, 1.0, 0.1);


// Sun Stuff
uniform vec3 sun_col: source_color = vec3(1.0);
uniform float sun_size: hint_range(0.01, 1.0) = 1.0;
uniform float sun_blur: hint_range(0.01, 1.0) = 0.01;


// Moon Stuff
uniform vec3 moon_col: source_color = vec3(1.0);
uniform float moon_size: hint_range(0.01, 1.0) = 1.0;
uniform float moon_crescent_offset: hint_range(-1.0, 1.0) = 0.5;



// Star Stuff
uniform sampler2D stars_texture: filter_linear_mipmap;
uniform float stars_cutoff;
uniform float stars_speed: hint_range(0.0, 0.1);





void sky() {
	vec2 sky_uv = EYEDIR.xz / EYEDIR.y;
	
	
	float day_amount = clamp(LIGHT0_DIRECTION.y, 0.0, 1.0);
	vec3 gradient_day = mix(day_bottom_color, day_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * day_amount;
	
	float night_amount = clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0);
	vec3 gradient_night = mix(night_bottom_color, night_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * night_amount;
	
	//float sunset_amount = clamp(1.0 - abs(LIGHT0_DIRECTION.y), 0.0, 1.0);
	vec3 gradient_sunset = mix(sunset_bottom_color, sunset_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * (1.-(day_amount+night_amount)*1.5);
	
	vec3 sky_gradients = gradient_day + gradient_sunset + gradient_night;
	
	
	
	
	float horizon = 1.0 - abs(EYEDIR.y + horizon_falloff);
	
	vec3 horizon_glow_amount_day = clamp(horizon * clamp(LIGHT0_DIRECTION.y, 0.0, 1.0), 0.0, 1.0) * horizon_color_day;
	vec3 horizon_glow_amount_sunset = clamp(horizon * clamp(1.0 - abs(LIGHT0_DIRECTION.y), 0.0, 1.0), 0.0, 1.0) * horizon_color_sunset;
	vec3 horizon_glow_night = clamp(horizon * clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0), 0.0, 1.0) * horizon_color_night;
	
	vec3 horizon_glow = horizon_glow_amount_day + horizon_glow_amount_sunset + horizon_glow_night;
	
	
	
	
	
	float sun_distance = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
	float sun_power = 1.0 - clamp(sun_distance / sun_size, 0.0, 1.0);
	float sun_disc = clamp(sun_power / sun_blur, sun_power, 1.0);
	vec3 sun = sun_col * sun_disc;
	
	
	
	float moon_distance = distance(EYEDIR.xyz, -LIGHT0_DIRECTION);
	float moon_power = 1.0 - clamp(moon_distance / moon_size, 0.0, 1.0);
	float moon_disc = clamp(moon_power / 0.01, moon_power, 1.0);
	
	float moon_crescent_distance = distance(vec3(EYEDIR.x + moon_crescent_offset, EYEDIR.yz), -LIGHT0_DIRECTION);
	float moon_crescent_power = 1.0 - clamp(moon_crescent_distance / moon_size, 0.0, 1.0);
	float moon_crescent_disc = clamp(moon_crescent_power / 0.01, moon_crescent_power, 1.0);
	
	vec3 moon_crescent = moon_col * moon_crescent_disc;
	
	vec3 moon = clamp( (moon_col * moon_disc) - moon_crescent, 0.0 , 1.0);
	
	
	
	
	
	
	
	vec3 stars = texture(stars_texture, EYEDIR.xy+ (stars_speed * TIME)).rgb;
	stars *= clamp(-(LIGHT0_DIRECTION.y)+0.1, 0.0, 1.0);
	stars = step(stars_cutoff, stars);
	
	
	
	vec3 sun_moon = sun + moon;
	sun_moon = clamp(sun_moon, 0.0, 1.0);
	
	sky_gradients = clamp(sky_gradients, 0.0, 1.0);
	
	
	
	vec3 sky = horizon_glow + sky_gradients + sun_moon + stars;
	
	
	
	COLOR = sky;
}