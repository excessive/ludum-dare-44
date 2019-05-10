package render;

import love.graphics.Mesh as LgMesh;
import love.graphics.Image as LgImage;
// import math.Vec3;
import math.Mat4;
import render.Material;

import lua.Table;

typedef DrawCommand = {
	xform_mtx: Mat4,
	normal_mtx: Mat4,
	mesh: MeshView,
	material: Material,
	albedo_override: Null<LgImage>,
	bones: Table<Dynamic, Dynamic>,
	instance_count: Int,
	instance_buffer: Null<LgMesh>
}
