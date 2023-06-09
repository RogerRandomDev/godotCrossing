shader_type spatial;
render_mode unshaded,shadows_disabled,cull_front,world_vertex_coords;
global uniform float outlineSize;
global uniform vec4 outlineColor;
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

void fragment() {
	ALBEDO.rgb=outlineColor.rgb;
}
