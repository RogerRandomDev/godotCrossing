shader_type canvas_item;
render_mode unshaded;
uniform sampler2D edgeView;
uniform vec3 edgeColor=vec3(1.);
void fragment() {
	float borderAndDepth=texture(edgeView,UV).r;
	COLOR.rgb=mix(COLOR.rgb,edgeColor,borderAndDepth);
}
