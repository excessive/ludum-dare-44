#ifdef VERTEX
// attribute vec3 VertexNormal;
attribute vec4 VertexWeight;
attribute vec4 VertexBone; // used as ints!

uniform mat4 u_model, u_viewproj;
uniform int u_rigged;
uniform mat4 u_pose[110];

mat4 getDeformMatrix() {
	if (u_rigged == 1) {
		// *255 because byte data is normalized against our will.
		return
			u_pose[int(VertexBone.x*255.0)] * VertexWeight.x +
			u_pose[int(VertexBone.y*255.0)] * VertexWeight.y +
			u_pose[int(VertexBone.z*255.0)] * VertexWeight.z +
			u_pose[int(VertexBone.w*255.0)] * VertexWeight.w
		;
	}
	return mat4(1.0);
}

vec4 position(mat4 mvp, vec4 vertex) {
	mat4 transform = u_model;
	transform *= getDeformMatrix();

	vec4 wpos = transform * vertex;
	return u_viewproj * wpos;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
	return vec4(1.0);
}
#endif
