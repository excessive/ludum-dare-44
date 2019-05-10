package render;

import math.Vec3;

typedef Material = {
	color: Vec3,
	emission: Float,
	metalness: Float,
	roughness: Float,
	vampire: Bool,
	opacity: Float,
	double_sided: Bool,
	occlusion_mask: Bool,
	?alpha_multiply: Float,
	?triplanar: Bool,
	?shadow: Bool,
	?textures: {
		?albedo: String,
		?roughness: String,
		?metalness: String,
		?scale: Float
	}
}
