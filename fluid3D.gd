extends MeshInstance3D

var rippleSet=[]
@export var rippleSpeed:float=1.5

#add new ripple to the water
func addRipple(newRipple=Vector2(0,0)):
	rippleSet.push_back(newRipple)
	if(rippleSet.size()>32):rippleSet.pop_front()

#updates water ripples
func _process(delta):
	for ripple in rippleSet.size():
		rippleSet[ripple].z+=delta*rippleSpeed
		if(rippleSet[ripple].z>=1.05):rippleSet.remove_at(ripple);
	mesh.surface_get_material(0).set_shader_parameter("ripples",PackedVector3Array(rippleSet))
	
