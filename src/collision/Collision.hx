package collision;

import math.Vec3;
import math.Plane;
import math.Utils;
import collision.Response.Packet;

class Collision {
	private static function triangle_intersects_point(point: Vec3, v0: Vec3, v1: Vec3, v2: Vec3): Bool {
		var u = v1    - v0;
		var v = v2    - v0;
		var w = point - v0;

		var vw = Vec3.cross(v, w);
		var vu = Vec3.cross(v, u);

		if (Vec3.dot(vw, vu) < 0.0) {
			return false;
		}

		var uw = Vec3.cross(u, w);
		var uv = Vec3.cross(u, v);

		if (Vec3.dot(uw, uv) < 0.0) {
			return false;
		}

		var d: Float = uv.length();
		var r: Float = vw.length() / d;
		var t: Float = uw.length() / d;

		return (r + t) <= 1;
	}

	private static function get_lowest_root(root: {v: Float}, a: Float, b: Float, c: Float, max: Float): Bool {
		// check if solution exists
		var determinant: Float = b*b - 4.0*a*c;

		// if negative there is no solution
		if (determinant < 0.0) {
			return false;
		}

		// calculate two roots
		var sqrtD: Float = Math.sqrt(determinant);
		var r1: Float = (-b - sqrtD) / (2*a);
		var r2: Float = (-b + sqrtD) / (2*a);

		// set x1 <= x2
		if (r1 > r2) {
			var temp: Float = r2;
			r2 = r1;
			r1 = temp;
		}

		// get lowest root
		if (r1 > 0 && r1 < max) {
			root.v = r1;
			return true;
		}

		if (r2 > 0 && r2 < max) {
			root.v = r2;
			return true;
		}

		// no solutions
		return false;
	}

	public static function check_triangle(packet: Packet, p1: Vec3, p2: Vec3, p3: Vec3) {
		var plane = Plane.from_triangle(p1, p2, p3);

		// only check front facing triangles
		if (!plane.is_front_facing(packet.e_norm_velocity)) {
			return packet;
		}

		// get interval of plane intersection
		var t0: Float = 0.0;
		var embedded_in_plane: Bool = false;

		// signed distance from sphere to point on plane
		var signed_dist_to_plane: Float = plane.signed_distance(packet.e_base_point);

		// cache this as we will reuse
		var normal_dot_vel = Vec3.dot(plane.normal, packet.e_velocity);

		// if sphere is moving parallel to plane
		if (normal_dot_vel == 0.0) {
			if (Math.abs(signed_dist_to_plane) >= 1.0) {
				// no collision possible 
				return packet;
			} else {
				// sphere is in plane in whole range [0..1]
				embedded_in_plane = true;
				t0 = 0.0;
			}
		} else {
			// N dot D is not 0, calc intersect interval
			var nvi = 1.0 / normal_dot_vel;
			t0 = (-1.0 - signed_dist_to_plane) * nvi;
			var t1 = ( 1.0 - signed_dist_to_plane) * nvi;

			// swap so t0 < t1
			if (t0 > t1) {
				var temp = t1;
				t1 = t0;
				t0 = temp;
			}

			// check that at least one result is within range
			if (t0 > 1.0 || t1 < 0.0) {
				// both values outside range [0,1] so no collision
				return packet;
			}

			t0 = Utils.clamp(t0, 0.0, 1.0);
		}

		// time to check for a collision
		var collision_point: Vec3 = new Vec3(0.0, 0.0, 0.0);
		var found_collision: Bool = false;
		var t: Float = 1.0;

		// first check collision with the inside of the triangle
		if (!embedded_in_plane) {
			var plane_intersect: Vec3 = packet.e_base_point - plane.normal;
			var temp: Vec3 = packet.e_velocity * t0;
			plane_intersect += temp;

			if (triangle_intersects_point(plane_intersect, p1, p2, p3)) {
				found_collision = true;
				t = t0;
				collision_point = plane_intersect;
			}
		}

		// no collision yet, check against points and edges
		if (!found_collision) {
			var velocity = packet.e_velocity.copy();
			var base = packet.e_base_point.copy();
		
			var velocity_sq_length = velocity.lengthsq();
			var a: Float = velocity_sq_length;
			var new_t = { v: 0.0 };
			
			// equation is a*t^2 + b*t + c = 0
			// check against points
			inline function check_point(collision_point: Vec3, p: Vec3) {
				var temp = base - p;
				var b = 2.0 * Vec3.dot(velocity, temp);
				var temp = p - base;
				var c = temp.lengthsq() - 1.0;
				if (get_lowest_root(new_t, a, b, c, t)) {
					t = new_t.v;
					found_collision = true;
					collision_point = p;
				}
				return collision_point;
			}

			// p1
			collision_point = check_point(collision_point, p1);

			// p2
			if (!found_collision) {
				collision_point = check_point(collision_point, p2);
			}

			// p3
			if (!found_collision) {
				collision_point = check_point(collision_point, p3);
			}

			// check against edges
			inline function check_edge(collision_point: Vec3, pa: Vec3, pb: Vec3) {
				var edge = pb - pa;
				var base_to_vertex = pa - base;
				var edge_sq_length = edge.lengthsq();
				var edge_dot_velocity = Vec3.dot(edge, velocity);
				var edge_dot_base_to_vertex = Vec3.dot(edge, base_to_vertex);

				// calculate params for equation
				var a = edge_sq_length * -velocity_sq_length + edge_dot_velocity * edge_dot_velocity;
				var b = edge_sq_length * (2.0 * Vec3.dot(velocity, base_to_vertex)) - 2.0 * edge_dot_velocity * edge_dot_base_to_vertex;
				var c = edge_sq_length * (1.0 - base_to_vertex.lengthsq()) + edge_dot_base_to_vertex * edge_dot_base_to_vertex;

				// do we collide against infinite edge
				if (get_lowest_root(new_t, a, b, c, t)) {
					// check if intersect is within line segment
					var f = (edge_dot_velocity * new_t.v - edge_dot_base_to_vertex) / edge_sq_length;
					if (f >= 0.0 && f <= 1.0) {
						t = new_t.v;
						found_collision = true;
						collision_point = pa + (edge * f);
					}
				}

				return collision_point;
			}
			collision_point = check_edge(collision_point, p1, p2); // p1 -> p2
			collision_point = check_edge(collision_point, p2, p3); // p2 -> p3
			collision_point = check_edge(collision_point, p3, p1); // p3 -> p1
		}

		// set results
		if (found_collision) {
			// distance to collision, t is time of collision
			var dist_to_coll = t * packet.e_velocity.length();

			// are we the closest hit?
			if (!packet.found_collision || dist_to_coll < packet.nearest_distance) {
				packet.nearest_distance = dist_to_coll;
				packet.intersect_point  = collision_point;
				packet.intersect_time   = t;
				packet.found_collision  = true;
			}
		}

		return packet;
	}
}
