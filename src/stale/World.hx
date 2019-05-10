import components.Trigger;
import iqm.Iqm;
import loaders.IqmLoader;
import math.Bounds;
import math.Intersect;
import math.Mat4;
import math.Octree;
import math.Ray;
import math.Triangle;
import math.Utils;
import math.Vec3;
import haxe.ds.Option;

class World {
	static var tri_octree: Octree<Triangle>;

	public static var kill_z: Float = -100;

	public static inline function convert(t: lua.Table<Int, Dynamic>) {
		var tris = [];
		// so it turns out: I know something about math.Triangle.
		// it's a liar. it doesn't use vec3's, it just decomposes them.
		// so reuse this and be nicer to the gc
		var v0 = new Vec3(0, 0, 0);
		var v1 = new Vec3(0, 0, 0);
		var v2 = new Vec3(0, 0, 0);
		lua.PairTools.ipairsEach(t, function(i, v) {
			v0.set_xyz(v[1].position[1], v[1].position[2], v[1].position[3]);
			v1.set_xyz(v[2].position[1], v[2].position[2], v[2].position[3]);
			v2.set_xyz(v[3].position[1], v[3].position[2], v[3].position[3]);
			tris.push(Triangle.without_normal(v0, v1, v2));
		});
		return tris;
	}

	public static function load(filename: String, set_bounds: Bool = false, reset: Bool = false) {
		var root = new SceneNode();
		root.name = "Map";
		root.hidden = true;

		if (backend.Fs.is_file(filename)) {
			console.Console.is('loading stage $filename');
		}
		else {
			throw "ARGH!";
		}

		var map_model = Iqm.load(filename, true);
		root.name = "MapExtras";
		root.transform.is_static = true;
		root.transform.update();

		var decoded = Iqm.decode_meta(map_model);
		var found_kill = false;

		switch (decoded) {
			case None: // pass
			case Some(meta):
			// var token = IqmLoader.load_file("assets/models/token.iqm");
			// var sphere = IqmLoader.load_file("assets/models/debug/unit-sphere.iqm");
			// for (p in meta.paths) {
			// 	var rail_root = new SceneNode();
			// 	// var name = get_prefix(p.name);
			// 	var capsules = [];

			// 	// move rails slightly up to make them easier to use
			// 	rail_root.transform.position.z += 0.125;
			// 	rail_root.transform.is_static = true;
			// 	rail_root.transform.update();

			// 	// inline function dump_point(point, pos: Vec3) {
			// 	// 	var node = new SceneNode();
			// 	// 	node.transform.position.set_xyz(pos.x, pos.y, pos.z);
			// 	// 	node.transform.scale *= 0.25;
			// 	// 	node.transform.is_static = true;
			// 	// 	node.transform.update();
			// 	// 	node.drawable = sphere;
			// 	// 	rail_root.children.push(node);
			// 	// }

			// 	inline function point2vec3(pos: Array<Float>) {
			// 		return new Vec3(pos[0], pos[1], pos[2]);
			// 	}

			// 	var min = new Vec3(0, 0, 0);
			// 	var max = new Vec3(0, 0, 0);
			// 	if (p.points.length > 0) {
			// 		var pos = p.points[0].position;
			// 		min.set_xyz(pos[0], pos[1], pos[2]);
			// 		max.set_xyz(min.x, min.y, min.z);
			// 	}

			// 	var radius = 0.5;
			// 	for (i in 1...Std.int(p.points.length)) {
			// 		var a = p.points[i-1];
			// 		var b = p.points[i];
			// 		var apos = rail_root.transform.matrix * point2vec3(a.position);
			// 		var bpos = rail_root.transform.matrix * point2vec3(b.position);
			// 		min = Vec3.min(min, apos);
			// 		min = Vec3.min(min, bpos);
			// 		max = Vec3.max(max, apos);
			// 		max = Vec3.max(max, bpos);
			// 		capsules.push(new Capsule(apos, bpos, radius));

			// 		// dump_point(a, apos);
			// 		// dump_point(b, bpos);
			// 	}

			// 	var pad = Vec3.splat(radius);
			// 	rail_root.bounds = Bounds.from_extents(min - pad, max + pad);

			// 	// rail_root.item = Rail(capsules);

			// 	root.children.push(rail_root);
			// }
			for (o in meta.trigger_areas) {
				var name = get_prefix(o.name);
				switch (name) {
					case "kill_z": {
						var node = new SceneNode();
						node.name = "KillPlane";
						node.transform.position.x = o.position[0];
						node.transform.position.y = o.position[1];
						node.transform.position.z = o.position[2];
						node.transform.orientation = new Mat4(o.transform_without_scale).to_quat();
						node.transform.orientation.normalize();

						node.transform.scale = new Vec3(
							o.size[0],
							o.size[1],
							o.size[2]
						) / 2;

						var avg_scale = node.transform.scale.length();
						node.transform.scale.set_xyz(avg_scale, avg_scale, avg_scale);

						node.transform.is_static = true;
						node.transform.update();

						// trace("register kill plane");
						// trace('${node.transform.position}, ${node.transform.scale}');

						kill_z = node.transform.position.z;
						found_kill = true;

						node.trigger = new Trigger(function(e: Entity, other: Entity, ts: TriggerState, _) {
							if (ts == Entered) {
								// trace('kill plane');
								// Signal.emit("respawn");
							}
						}, Circle, avg_scale / 2);

						root.children.push(node);
					}
					default:
				}
			}
			for (o in meta.objects) {
				var name = get_prefix(o.name);
				switch (name) {
					// case "theme": {
					// 	var node = new SceneNode();
					// 	node.transform.position.x = o.position[0];
					// 	node.transform.position.y = o.position[1];
					// 	node.transform.position.z = o.position[2];
					// 	node.item = Theme;
					// 	node.drawable = token;

					// 	// Main.collectibles += 1;

					// 	node.trigger = new Trigger(function(e: Entity, other: Entity, state, hit) {
					// 		Main.scene.remove(node);
					// 		Signal.emit("collected-item");
					// 	}, Radius, node.transform.scale.length() * 0.25);

					// 	root.children.push(node);
					// }
					default:
				}
			}
		}

		if (reset) {
			var base: Bounds = untyped __lua__("{0}.base", map_model.bounds);

			var world_size = base.max[0] - base.min[0];
			world_size = Utils.max(world_size, base.max[1] - base.min[1]);
			world_size = Utils.max(world_size, base.max[2] - base.min[2]);
			world_size *= 1.01;

			var center = new Vec3(
				(base.min[0] + base.max[0]) / 2,
				(base.min[1] + base.max[1]) / 2,
				(base.min[2] + base.max[2]) / 2
			);

			if (set_bounds) {
				kill_z = Utils.max(kill_z, base.min.z - 10);
			}

			// for the stages tested, 1.05 seemed to help perf & memory usage
			var octree_looseness = 1.05;
			var min_size = 5.0;
			tri_octree = new Octree(world_size, center, min_size, octree_looseness);
		}

		root.drawable = IqmLoader.get_views(map_model);

		var tris = convert(map_model.triangles);
		add_triangles(tris, root.transform.matrix);

		return root;
	}

	static function get_prefix(name: String): String {
		// if an object is for some reason just named ".", whatever
		var dot = name.indexOf(".");

		if (dot > 0) {
			return name.substr(0, dot);
		}

		return name;
	}

	// strip after last ., because the export always names things .001
	static function fix_name(name: String): String {
		var dot = name.lastIndexOf(".");

		if (dot > 0) {
			return name.substr(0, dot);
		}

		return name;
	}

	public static function cast_ray(r: Ray, ?max_distance: Float): Option<{ p: Vec3, d: Float }> {
		var nearest = max_distance;
		var closest_point = null;
		if (max_distance != null) {
			closest_point = r.direction * max_distance;
		}
		tri_octree.cast_ray(r, (ray, data) -> {
			for (o in data) {
				var tri = o.data;
				var hit_data = Intersect.ray_triangle(ray, tri);
				if (!hit_data.exists()) {
					continue;
				}
				var hit = hit_data.sure();
				var dist = Vec3.distance(hit.point, ray.position);
				if (nearest == null) {
					nearest = dist;
				}
				if (dist < nearest) {
					closest_point = hit.point;
					nearest = dist;
				}
			}
			return false;
		});
		if (closest_point == null) {
			return None;
		}
		return Some({ p: closest_point, d: nearest });
	}

	public static function get_triangles(min: Vec3, max: Vec3): Array<Triangle> {
		var tris = tri_octree.get_colliding(Bounds.from_extents(min, max));
		return tris;
	}

	public static function add_triangles(tris: Array<Triangle>, ?xform: Mat4) {
		for (t in tris) {
			var xt = t;
			if (xform != null) {
				xt = Triangle.transform(t, xform);
			}
			var min = xt.min();
			var max = xt.max();
			tri_octree.add(xt, Bounds.from_extents(min, max));
		}
	}
}
