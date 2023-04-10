shader_type spatial;

uniform vec3 wrapAround=vec3(0.);

float distSquared(float a,float b){
	return a*a+b*b;
}
float dist(float a,float b){
	return sqrt(distSquared(a,b));
}

void vertex(){
	VERTEX=VERTEX+vec3(0.,4.,0.);
	VERTEX.y-=dist(VERTEX.x+wrapAround.z,VERTEX.z-wrapAround.x)/20.;
}