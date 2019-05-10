import lua.PairTools;
import iqm.Iqm.IqmFile;
import math.TriangleBvh;
import math.Mat4;
import math.Ray;
import math.Triangle;
import math.Vec3;
import utils.Maybe;

enum Bucket {
	Solid;
	Ghost;
}

class CollisionWorld {
	static final bvhs: Array<{type:Bucket, tree:TriangleBvh}> = [];

	static function convert(t: lua.Table<Int, Dynamic>, xform: Mat4, _start: Int, _end: Int) {
		final tris = [];
		if (_end < _start) {
			_end = untyped __lua__("#{0}", t);
		}
		for (i in _start..._end+1) {
			final v = t[i];
			final tri = Triangle.without_normal(
				xform.mul_floats(v[1].position[1], v[1].position[2], v[1].position[3]),
				xform.mul_floats(v[2].position[1], v[2].position[2], v[2].position[3]),
				xform.mul_floats(v[3].position[1], v[3].position[2], v[3].position[3])
			);
			tris.push(tri);
		}
		return tris;
	}

	public static function get_triangles(bucket: Bucket, min: Vec3, max: Vec3): Array<Triangle> {
		var tris = [];
		for (bvh in bvhs) {
			if (bvh.type != bucket) {
				continue;
			}
			// concat does useless copies if you've got multiple trees
			for (tri in bvh.tree.get_colliding(min, max)) {
				tris.push(tri);
			}
		}
		return tris;
	}

	public static function cast_ray(bucket: Bucket, r: Ray, ?max_distance: Float): Maybe<{ p: Vec3, d: Float }> {
		var nearest = max_distance;
		var closest_point = null;
		var hit_node = null;
		if (max_distance != null) {
			closest_point = r.direction * max_distance;
		}
		for (bvh in bvhs) {
			if (bvh.type != bucket) {
				continue;
			}
			final hits = bvh.tree.ray_cast(r.position, r.direction, false);
			for (hit in hits) {
				final dist = hit.intersectionDistance;
				if (nearest == null) {
					nearest = dist;
				}
				if (dist <= nearest) {
					nearest = dist;
					hit_node = hit.triangle;
					closest_point = hit.intersectionPoint;
				}
			}
		}
		if (closest_point == null || hit_node == null) {
			return null;
		}
		return { p: closest_point, d: nearest };
	}

	public static inline function clear() {
		bvhs.resize(0);
	}

	public static function add(model: IqmFile, xform: Mat4, exclude_materials: Array<String>) {
		PairTools.ipairsEach(model.meshes, (i, mesh) -> {
			var bucket = Solid;
			if (exclude_materials.indexOf(mesh.material) >= 0) {
				bucket = Ghost;
			}
			final a = Math.ceil((mesh.first)/3);
			final b = Math.floor((mesh.last)/3);
			final tris = convert(model.triangles, xform, a, b);
			var bvh = new math.TriangleBvh(tris, 5);
			bvhs.push({ type: bucket, tree: bvh });
		});
	}
}
