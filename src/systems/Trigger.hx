package systems;

#if imgui
import imgui.ImGui;
#end
import components.Transform;
import math.Vec3;
import math.Bounds;
import math.Ray;
import math.Plane;
import math.Intersect;
import math.Capsule;
import Debug.line;

@:publicFields
class Trigger extends System {
	var player: Null<Entity>;

	override function filter(e: Entity) {
		if (e.player != null && e.collidable != null) {
			this.player = e;
		}
		return e.trigger != null && e.transform != null;
	}

	static function in_front_of(p: Transform, e: Transform, max_distance: Float, min_angle: Float) {
		var dir = p.orientation * -Vec3.unit_y();

		var ppos = p.position;
		var epos = e.position;
		var p2e = epos - ppos;
		p2e.normalize();

		if (Vec3.dot(p2e, dir) > min_angle) {
			var in_range = Vec3.distance(ppos, epos) <= max_distance;
			var offset = new Vec3(0, 0, 0.001);
			if (in_range) {
				line(ppos + offset, ppos + p2e + offset, 0, 1, 0.5);
			}
			else {
				line(ppos + offset, ppos + p2e + offset, 1, 0, 0.5);
			}
			return in_range;
		}

		return false;
	}

	function crossed_plane(plane: Plane, size: Float, line: Capsule, double_sided: Bool = true): Bool {
		var ppos = line.a;
		var pend = line.b;

		// for line tracing
		var pdir = pend - ppos;
		pdir.normalize();
		var ray = new Ray(ppos, pdir);

		var hit_data = Intersect.ray_plane(ray, plane);
		if (!hit_data.exists()) {
			return false;
		}
		var hit = hit_data.sure();

		// don't care if we're hitting the plane outside of range.
		if (Vec3.distance(plane.origin, hit) > size) {
			return false;
		}

		var origin = hit - ppos;
		origin.normalize();

		var target = hit - pend;
		target.normalize();

		// if first and last are not on the same side, then this line
		// will cross the target plane.
		if (double_sided) {
			return plane.is_front_facing(origin) != plane.is_front_facing(target);
		}
		// this one will only work if you cross front-to-back
		return !plane.is_front_facing(origin) && plane.is_front_facing(target);
	}

	override function update(entities: Array<Entity>, dt: Float) {
		// do NOT update triggers when the game is paused
		if (GameInput.locked) {
			return;
		}

#if imgui
		if (ImGui.get_want_capture_keyboard()) {
			return;
		}
#end

		if (this.player == null) {
			return;
		}

		var p = this.player;
		var ppos = p.transform.position;
		var pend = p.last_tx.position;
		var pcap = new Capsule(pend, ppos, p.collidable.radius.length());
		// var dir = p.transform.orientation.apply_forward();
		// line(ppos, ppos + dir, 1, 1, 0);

		var up = Vec3.up();
		var range = new Vec3(0, 0, 0);
		for (e in entities) {
			var trigger = e.trigger;
			var tpos = e.transform.position;
			var tcap = new Capsule(tpos, tpos, trigger.range);
			var hit = false;
			var cap_hit = null;
			switch (trigger.type) {
				case Radius:
					hit = Intersect.capsule_capsule(pcap, tcap) != null;
				case Capsule:
					var height = e.transform.orientation * up * trigger.max_angle_height;
					tcap = new Capsule(tpos, tpos + height, trigger.range);
					final result = Intersect.capsule_capsule(pcap, tcap);
					if (result.exists()) {
						cap_hit = result.sure();
					}
					hit = cap_hit != null;
				case Volume:
					for (i in 0...3) {
						range[i] = trigger.range;
					}
					// TODO: change to line-aabb
					hit = Intersect.point_aabb(ppos, Bounds.from_extents(tpos - range, tpos + range));
				case RadiusInFront:
					hit = in_front_of(p.transform, e.transform, trigger.range, 1-trigger.max_angle_height);
				case Circle:
					var plane = new Plane(e.transform.position, e.transform.orientation.apply_forward());
					hit = crossed_plane(plane, trigger.range, pcap, trigger.max_angle_height > 0);
			}
			if (hit) {
				trigger.cb(e, p, trigger.inside ? Inside : Entered, {a: pcap, b: tcap, hit: cap_hit});
				trigger.inside = true;
			}
			else if (trigger.inside) {
				trigger.cb(e, p, Left, null);
				trigger.inside = false;
			}
		}
	}
}
