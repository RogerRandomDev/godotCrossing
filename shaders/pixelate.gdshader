shader_type spatial;
render_mode unshaded;
uniform sampler2D SCREEN_TEXTURE:hint_screen_texture;
uniform sampler2D DEPTH_TEXTURE:hint_depth_texture;

float linear_position(in sampler2D depth_texture, in vec2 screen_uv, in mat4 inv_projection_matrix){
	float depth = texture(depth_texture, screen_uv).r;
    vec4 upos = inv_projection_matrix * vec4(screen_uv * 2.0 - 1.0, depth, 1.0);
    vec3 pixel_position = upos.xyz / upos.w;
	return pixel_position.y;
}
float linear_depth(in sampler2D depth_texture, in vec2 screen_uv, in mat4 inv_projection_matrix){
	// get raw depth, this is not a linear value in godot 4.0 vulkan rendering
	float raw_depth = texture(depth_texture, screen_uv)[0];
    
	vec3 normalized_device_coordinates = vec3(screen_uv * 2.0 - 1.0, raw_depth);
	
	//convert NDC to view space via the inverse projection matrix
    vec4 view_space = inv_projection_matrix * vec4(normalized_device_coordinates, 1.0);	
    
	//linearize the depth
	view_space.xyz /= view_space.w;
	
	// camera view points in the negative Z direction, so all depths are negative
	// we invert the sign here to get positive depth values
	return -view_space.z;
}
float linear_sample(in vec2 uv,in vec2 modBy,in sampler2D tex,in mat4 inv_mat){
	return (
		linear_position(tex,uv+vec2(modBy.x,0.),inv_mat)+
		linear_position(tex,uv-vec2(modBy.x,0.),inv_mat)+
		linear_position(tex,uv+vec2(0.,modBy.y),inv_mat)+
		linear_position(tex,uv-vec2(0.,modBy.y),inv_mat)
		)-linear_position(tex,uv,inv_mat)*4.;
}
float sample(in vec2 uv,in vec2 modBy,in sampler2D tex,in mat4 inv_mat){
	return (
		linear_depth(tex,uv+vec2(modBy.x,0.),inv_mat)+
		linear_depth(tex,uv-vec2(modBy.x,0.),inv_mat)+
		linear_depth(tex,uv+vec2(0.,modBy.y),inv_mat)+
		linear_depth(tex,uv-vec2(0.,modBy.y),inv_mat)
		)-linear_depth(tex,uv,inv_mat)*4.;
}


void fragment() {
	//bool outline=sample(SCREEN_UV,0.5/VIEWPORT_SIZE,SCREEN_TEXTURE)>0.75;
	float depth=sample(SCREEN_UV,1./VIEWPORT_SIZE,DEPTH_TEXTURE,INV_PROJECTION_MATRIX);
	float belowWater=linear_depth(DEPTH_TEXTURE,SCREEN_UV,INV_PROJECTION_MATRIX);
	//ALBEDO.r=float(texture(DEPTH_TEXTURE,SCREEN_UV).r>=1.||belowWater<-2.);
	ALBEDO.rg=vec2(float((belowWater<40.)&&depth>0.5),depth);
}
