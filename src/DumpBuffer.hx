import math.ColorUtils;
import lua.Table;
import love.graphics.Mesh;
import love.graphics.MeshDrawMode;
import love.graphics.SpriteBatchUsage;
import love.graphics.GraphicsModule as Lg;

import math.Vec3;
import math.Triangle;
import math.Utils;

import utils.RecycleBuffer;

class DumpBuffer {
	var mesh: Mesh;
	public var vertices(default, never) = new RecycleBuffer<Array<Float>>();

	public function new() {
		var fmt = Table.create();
		fmt[1] = Table.create([ "VertexPosition", "float", cast 3 ]);
		fmt[2] = Table.create([ "VertexColor", "float", cast 4 ]);
		mesh = Lg.newMesh(fmt, 65535, MeshDrawMode.Triangles, SpriteBatchUsage.Stream);
	}

	public function add_triangle(tri: Triangle, c0: Array<Float>, c1: Array<Float>, c2: Array<Float>) {
		vertices.push([tri.v0_x, tri.v0_y, tri.v0_z, c0[0], c0[1], c0[2], c0[3]]);
		vertices.push([tri.v1_x, tri.v1_y, tri.v1_z, c1[0], c1[1], c1[2], c1[3]]);
		vertices.push([tri.v2_x, tri.v2_y, tri.v2_z, c2[0], c2[1], c2[2], c2[3]]);
	}

	public function draw(wipe_only: Bool) {
		if (wipe_only || vertices.length == 0) {
			vertices.reset();
			return;
		}

		var t = Table.create();
		var verts = Std.int(Utils.min(vertices.length, 65535));
		for (i in 0...verts) {
			t[i+1] = Table.create();
			for (j in 0...7) { // XYZRGBA
				t[i+1][j+1] = vertices[i][j];
			}
		}

		mesh.setVertices(t);
		mesh.setDrawRange(1, verts);
		Lg.draw(mesh);

		vertices.reset();
	}
}
