extends Camera3D


func _process(delta):
	if Input.is_key_pressed(KEY_W):
		position.z-=delta*16.
	if Input.is_key_pressed(KEY_S):
		position.z+=delta*16.
	position.z=clamp(position.z,-80,100)
	RenderingServer.global_shader_parameter_set("wrapAround",global_transform.origin)

