import math.Vec3;
import math.Ray;
import math.Plane;
import math.Triangle;
import math.Capsule;
import utils.RecycleBuffer;

typedef CapsuleData = {
	capsule: Capsule,
	r: Float,
	g: Float,
	b: Float
}

class Debug {
	static var buffer: DumpBuffer;
	public static final capsules = new RecycleBuffer<CapsuleData>();

	static var vertices(get, never): RecycleBuffer<Array<Float>>;
	static inline function get_vertices() { return buffer.vertices; }

	static var cube_indices = [
		0, 4, 1, 5, 2, 6, 3, 7, // sides
		0, 1, 0, 3, 2, 3, 2, 1, // top
		4, 5, 4, 7, 6, 7, 6, 5  // bottom
	];

	public static function init() {
		buffer = new DumpBuffer();
	}

	public static function capsule(capsule: Capsule, r: Float = 1, g: Float = 1, b: Float = 1) {
		capsules.push({
			capsule: new Capsule(capsule.a, capsule.b, capsule.radius),
			r: r,
			g: g,
			b: b
		});
	}

	public static function line(v0: Vec3, v1: Vec3, r: Float = 1, g: Float = 1, b: Float = 1) {
		vertices.push([ v0[0], v0[1], v0[2], r*1, g*1, b*1, 1]);
		// love only gives us triangles, so dupe.
		vertices.push(vertices[vertices.length-1]);
		vertices.push([ v1[0], v1[1], v1[2], r*1, g*1, b*1, 1 ]);
	}

	public static function plane(plane: Plane, size: Float = 1, r: Float = 1, g: Float = 1, b: Float = 1) {
		var up = Vec3.up();
		if (plane.normal == up) {
			up.y = 1;
			up.z = 0;
		}
		var right = Vec3.cross(plane.normal, up);
		up = Vec3.cross(right, plane.normal);
		right.normalize();
		up.normalize();
		right *= size;
		up *= size;
		var tl = plane.origin + up - right;
		var tr = plane.origin + up + right;
		var bl = plane.origin - up - right;
		var br = plane.origin - up + right;
		line(tl, tr, r, g, b);
		line(tr, br, r, g, b);
		line(br, bl, r, g, b);
		line(bl, tl, r, g, b);
		line(plane.origin, plane.origin + plane.normal, r, g, b);
	}

	public static function ray(ray: Ray, length: Float = 10, r: Float = 1, g: Float = 1, b: Float = 1) {
		line(ray.position, ray.position + ray.direction * length, r, g, b);
	}

	public static function point(p: Vec3, size: Float = 1, r: Float = 1, g: Float = 1, b: Float = 1) {
		line(p, p + new Vec3(0, 0, size), r, g, b);
	}

	public static function point_axis(p: Vec3, size: Float = 1) {
		axis(p, Vec3.unit_x(), Vec3.unit_y(), Vec3.unit_z(), size);
	}

	public static function axis(origin: Vec3, x: Vec3, y: Vec3, z: Vec3, length: Float = 1) {
		line(origin, origin+x*length, 1.0, 0.0, 0.0);
		line(origin, origin+y*length, 0.0, 1.0, 0.0);
		line(origin, origin+z*length, 0.0, 0.0, 1.0);
	}

	public static function triangle(tri: Triangle, r: Float = 1, g: Float = 1, b: Float = 1) {
		line(tri.v0, tri.v1, r, g, b);
		line(tri.v1, tri.v2, r, g, b);
		line(tri.v2, tri.v0, r, g, b);
	}

	public static function aabb(min: Vec3, max: Vec3, r: Float = 1, g: Float = 1, b: Float = 1) {
		var cube_vertices = [
			new Vec3(min[0], min[1], max[2]),
			new Vec3(max[0], min[1], max[2]),
			new Vec3(max[0], max[1], max[2]),
			new Vec3(min[0], max[1], max[2]),
			new Vec3(min[0], min[1], min[2]),
			new Vec3(max[0], min[1], min[2]),
			new Vec3(max[0], max[1], min[2]),
			new Vec3(min[0], max[1], min[2])
		];

		var i = 1;
		for (j in 0...Std.int(cube_indices.length / 2)) {
			var i0 = cube_indices[i-1];
			var i1 = cube_indices[i];
			line(cube_vertices[i0], cube_vertices[i1], r, g, b);
			i += 2;
		}
	}

	public static function clear_capsules() {
		capsules.reset();
	}

	public static function draw(wipe_only: Bool) {
		buffer.draw(wipe_only);
	}
}
