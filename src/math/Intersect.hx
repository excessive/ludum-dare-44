package math;

import utils.Maybe;

typedef HitResult = { point: Vec3, distance: Float }
typedef CapsuleCapsuleResult = { p1: Vec3, p2: Vec3 }
typedef ClosestPointResult   = { p1: Vec3, p2: Vec3, dist2: Float, s: Float, t: Float }

class Intersect {
	public static inline function point_aabb(point: Vec3, aabb: Bounds) {
		return
			aabb.min.x <= point.x &&
			aabb.max.x >= point.x &&
			aabb.min.y <= point.y &&
			aabb.max.y >= point.y &&
			aabb.min.z <= point.z &&
			aabb.max.z >= point.z
		;
	}

	public static inline function encapsulate_aabb(outer: Bounds, inner: Bounds) {
		return
			outer.min.x <= inner.min.x &&
			outer.max.x >= inner.max.x &&
			outer.min.y <= inner.min.y &&
			outer.max.y >= inner.max.y &&
			outer.min.z <= inner.min.z &&
			outer.max.z >= inner.max.z
		;
	}

	public static inline function aabb_aabb_floats(
		a_min_x: Float, a_min_y: Float, a_min_z: Float,
		a_max_x: Float, a_max_y: Float, a_max_z:Float,
		b_min_x: Float, b_min_y: Float, b_min_z: Float,
		b_max_x: Float, b_max_y: Float, b_max_z: Float
	): Bool {
		return
			a_min_x <= b_max_x &&
			a_max_x >= b_min_x &&
			a_min_y <= b_max_y &&
			a_max_y >= b_min_y &&
			a_min_z <= b_max_z &&
			a_max_z >= b_min_z
		;
	}

	public static inline function aabb_aabb(a: Bounds, b: Bounds) {
		return
			a.min.x <= b.max.x &&
			a.max.x >= b.min.x &&
			a.min.y <= b.max.y &&
			a.max.y >= b.min.y &&
			a.min.z <= b.max.z &&
			a.max.z >= b.min.z
		;
	}

	public static function aabb_frustum(aabb: Bounds, frustum: Frustum) {
#if lua
		// This results in slightly faster code on haxe 3.4.4/luajit
		final box: lua.Table<Int, Vec3> = untyped __lua__(
			"{ {0}, {1} }",
			aabb.min,
			aabb.max
		);

		final n = 6;
		final planes: lua.Table<Int, Vec4> = untyped __lua__(
			"{ {0}, {1}, {2}, {3}, {4}, {5} }",
			frustum.left,
			frustum.right,
			frustum.bottom,
			frustum.top,
			frustum.near,
			frustum.far
		);

		for (i in 1...n) {
			// This is the current plane
			final p = planes[i];

			// p-vertex selection (with the index trick)
			// According to the plane normal we can know the
			// indices of the positive vertex

			// writing it this way fixes stupid lua codegen
			var bx: Float;
			var by: Float;
			var bz: Float;
			if (p.x > 0.0) bx = box[2].x; else bx = box[1].x;
			if (p.y > 0.0) by = box[2].y; else by = box[1].y;
			if (p.z > 0.0) bz = box[2].z; else bz = box[1].z;
			final dot = p.x * bx + p.y * by + p.z * bz;

			// Doesn't intersect if it is behind the plane
			if (dot < -p.w) {
				return false;
			}
		}

		return true;

#else
		// We have 6 planes defining the frustum, 5 if infinite.
		final box = [ aabb.min, aabb.max ];
		final n = 5;
		final planes = [
			frustum.left,
			frustum.left,
			frustum.right,
			frustum.bottom,
			frustum.top,
			frustum.near
		];

		// Skip the last test for infinite projections, it'll never fail.
		if (frustum.far != null) {
			planes.push(frustum.far);
			n += 1;
		}

		for (i in 0...n) {
			// This is the current plane
			final p = planes[i];

			// p-vertex selection (with the index trick)
			// According to the plane normal we can know the
			// indices of the positive vertex
			final px: Int = 0;
			final py: Int = 0;
			final pz: Int = 0;
			if (p.x > 0.0) px = 1;
			if (p.y > 0.0) py = 1;
			if (p.z > 0.0) pz = 1;

			// project p-vertex on plane normal
			// (How far is p-vertex from the origin)
			final dot = p.x * box[px].x + p.y * box[py].y + p.z * box[pz].z;

			// Doesn't intersect if it is behind the plane
			if (dot < -p.w) {
				return false;
			}
		}
		return true;
#end
	}

	// http://realtimecollisiondetection.net/blog/?p=103
	// sphere.position is a vec3
	// sphere.radius   is a number
	// triangle[1]     is a vec3
	// triangle[2]     is a vec3
	// triangle[3]     is a vec3
	public static function sphere_triangle(triangle: Triangle, center: Vec3, radius: Float) {
		// Sphere is centered at origin
		final A  = triangle.v0 - center;
		final B  = triangle.v1 - center;
		final C  = triangle.v2 - center;

		// Compute normal of triangle plane
		final V  = Vec3.cross(B - A, C - A);

		// Test if sphere lies outside triangle plane
		final rr = radius * radius;
		final d  = Vec3.dot(A, V);
		final e  = Vec3.dot(V, V);
		final s1 = d * d > rr * e;

		// Test if sphere lies outside triangle vertices
		final aa = Vec3.dot(A, A);
		final ab = Vec3.dot(A, B);
		final ac = Vec3.dot(A, C);
		final bb = Vec3.dot(B, B);
		final bc = Vec3.dot(B, C);
		final cc = Vec3.dot(C, C);

		final s2 = (aa > rr) && (ab > aa) && (ac > aa);
		final s3 = (bb > rr) && (ab > bb) && (bc > bb);
		final s4 = (cc > rr) && (ac > cc) && (bc > cc);

		// Test is sphere lies outside triangle edges
		final AB = B - A;
		final BC = C - B;
		final CA = A - C;

		final d1 = ab - aa;
		final d2 = bc - bb;
		final d3 = ac - cc;

		final e1 = Vec3.dot(AB, AB);
		final e2 = Vec3.dot(BC, BC);
		final e3 = Vec3.dot(CA, CA);

		final Q1 = A * e1 - AB * d1;
		final Q2 = B * e2 - BC * d2;
		final Q3 = C * e3 - CA * d3;

		final QC = C * e1 - Q1;
		final QA = A * e2 - Q2;
		final QB = B * e3 - Q3;

		final s5 = (Vec3.dot(Q1, Q1) > rr * e1 * e1) && (Vec3.dot(Q1, QC) > 0);
		final s6 = (Vec3.dot(Q2, Q2) > rr * e2 * e2) && (Vec3.dot(Q2, QA) > 0);
		final s7 = (Vec3.dot(Q3, Q3) > rr * e3 * e3) && (Vec3.dot(Q3, QB) > 0);

		// Return whether or not any of the tests passed
		return s1 || s2 || s3 || s4 || s5 || s6 || s7;
	}

	// https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code
	// ray.position    is a vec3
	// ray.direction   is a vec3
	// sphere.position is a vec3
	// sphere.radius   is a number
	public static function ray_sphere(ray: Ray, center: Vec3, radius: Float): Maybe<Vec3> {
		final offset = ray.position - center;
		final b = Vec3.dot(offset, ray.direction);
		final c = Vec3.dot(offset, offset) - radius * radius;

		// ray's position outside sphere (c > 0)
		// ray's direction pointing away from sphere (b > 0)
		if (c > 0 && b > 0) {
			return null;
		}

		final discr = b * b - c;

		// negative discriminant
		if (discr < 0) {
			return null;
		}

		// Clamp t to 0
		var t = Utils.max(0, -b - Math.sqrt(discr));

		// Return collision point and distance from ray origin
		return ray.position + ray.direction * t;//, t;
	}

	public static function ray_aabb(ray: Ray, aabb: Bounds): Maybe<HitResult> {
#if lua
		final min: (a:Float,b:Float)->Float = untyped __lua__("_G.math.min");
		final max: (a:Float,b:Float)->Float = untyped __lua__("_G.math.max");
#else
		final min = Utils.min;
		final max = Utils.max;
#end
		final rcp_len = 1.0 / ray.direction.length();
		final rcp_dx = 1 / (ray.direction.x * rcp_len);
		final rcp_dy = 1 / (ray.direction.y * rcp_len);
		final rcp_dz = 1 / (ray.direction.z * rcp_len);

		final t1 = (aabb.min.x - ray.position.x) * rcp_dx;
		final t2 = (aabb.max.x - ray.position.x) * rcp_dx;
		final t3 = (aabb.min.y - ray.position.y) * rcp_dy;
		final t4 = (aabb.max.y - ray.position.y) * rcp_dy;
		final t5 = (aabb.min.z - ray.position.z) * rcp_dz;
		final t6 = (aabb.max.z - ray.position.z) * rcp_dz;

		final tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
		final tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6));

		// ray is intersecting AABB, but whole AABB is behind us
		// or ray does not intersect AABB
		if (tmax < 0 || tmin > tmax) {
			return null;
		}

		// Return collision point and distance from ray origin
		return {
			point: ray.position + ray.direction * tmin,
			distance: tmin
		};
	}

	static final EPSILON = 1.19209290e-07;

	// http://stackoverflow.com/a/23976134/1190664
	public static function ray_plane(ray: Ray, plane: Plane): Maybe<Vec3> {
		final denom = Vec3.dot(plane.normal, ray.direction);

		// ray does not intersect plane
		if (Math.abs(denom) < EPSILON) {
			return null;
		}

		// distance of direction
		final d = plane.origin - ray.position;
		final t = Vec3.dot(d, plane.normal) / denom;

		if (t < EPSILON) {
			return null;
		}

		// Return collision point and distance from ray origin
		return ray.position + ray.direction * t;
	}

	public static function edge_plane(start: Vec3, end: Vec3, plane: Plane): Maybe<Vec3> {
		final direction = end - start;
		final length = direction.length();
		direction.normalize();

		final denom = Vec3.dot(plane.normal, direction);

		// parallel: ray cannot intersect plane
		if (Math.abs(denom) < EPSILON) {
			return null;
		}

		// distance of direction
		final d = plane.origin - start;
		final t = Vec3.dot(d, plane.normal) / denom;

		// ray does not hit plane within edge
		if (t < EPSILON || t > length) {
			return null;
		}

		// Return collision point and distance from ray origin
		return start + direction * t;
	}

	public static function ray_triangle(ray: Ray, triangle: Triangle, backface_cull: Bool = false): Maybe<HitResult> {
		final e1 = triangle.v1 - triangle.v0;
		final e2 = triangle.v2 - triangle.v0;
		final h  = Vec3.cross(ray.direction, e2);
		final a  = Vec3.dot(h, e1);

		// if a is too close to 0, ray does not intersect triangle
		if (Math.abs(a) <= EPSILON) {
			return null;
		}

		if (backface_cull && a < 0) {
			return null;
		}

		final f = 1 / a;
		final s = ray.position - triangle.v0;
		final u = Vec3.dot(s, h) * f;

		// ray does not intersect triangle
		if (u < 0 || u > 1) {
			return null;
		}

		final q = Vec3.cross(s, e1);
		final v = Vec3.dot(ray.direction, q) * f;

		// ray does not intersect triangle
		if (v < 0 || u + v > 1) {
			return null;
		}

		// at this stage we can compute t to find out where
		// the intersection point is on the line
		final t = Vec3.dot(q, e2) * f;

		// return position of intersection and distance from ray origin
		if (t >= EPSILON) {
			return {
				point: ray.position + ray.direction * t,
				distance: t
			};
		}

		// ray does not intersect triangle
		return null;
	}

	public static function capsule_capsule(c1: Capsule, c2: Capsule): Maybe<CapsuleCapsuleResult> {
		final ret    = closest_point_segment_segment(c1.a, c1.b, c2.a, c2.b);
		final radius = c1.radius + c2.radius;

		if (ret.dist2 <= radius * radius) {
			return {
				p1: ret.p1,
				p2: ret.p2
			};
		}

		return null;
	}

	public static function closest_point_segment_segment(p1: Vec3, p2: Vec3, p3: Vec3, p4: Vec3): ClosestPointResult {
		final epsilon = 1.19209290e-07;

		var c1: Vec3;  // Collision point on segment 1
		var c2: Vec3;  // Collision point on segment 2
		var s:  Float; // Distance of intersection along segment 1
		var t:  Float; // Distance of intersection along segment 2

		final d1: Vec3  = p2 - p1; // Direction of segment 1
		final d2: Vec3  = p4 - p3; // Direction of segment 2
		final r:  Vec3  = p1 - p3;
		final a:  Float = Vec3.dot(d1, d1);
		final e:  Float = Vec3.dot(d2, d2);
		final f:  Float = Vec3.dot(d2, r);

		// Check if both segments degenerate into points
		if (a <= epsilon && e <= epsilon) {
			c1 = p1;
			c2 = p3;
			s  = 0;
			t  = 0;

			return {
				p1:    c1,
				p2:    c2,
				dist2: Vec3.dot(c1 - c2, c1 - c2),
				s:     s,
				t:     t
			};
		}

		// Check if segment 1 degenerates into a point
		if (a <= epsilon) {
			s = 0;
			t = Utils.clamp(f / e, 0.0, 1.0);
		} else {
			final c = Vec3.dot(d1, r);

			// Check is segment 2 degenerates into a point
			if (e <= epsilon) {
				s = Utils.clamp(-c / a, 0.0, 1.0);
				t = 0;
			} else {
				final b     = Vec3.dot(d1, d2);
				final denom = a * e - b * b;

				if (Math.abs(denom) > 0) {
					s = Utils.clamp((b * f - c * e) / denom, 0.0, 1.0);
				} else {
					s = 0;
				}

				t = (b * s + f) / e;

				if (t < 0) {
					s = Utils.clamp(-c / a, 0.0, 1.0);
					t = 0;
				} else if (t > 1) {
					s = Utils.clamp((b - c) / a, 0.0, 1.0);
					t = 1;
				}
			}
		}

		c1 = p1 + d1 * s;
		c2 = p3 + d2 * t;

		return {
			p1:    c1,
			p2:    c2,
			dist2: Vec3.dot(c1 - c2, c1 - c2),
			s:     s,
			t:     t
		};
	}
}
