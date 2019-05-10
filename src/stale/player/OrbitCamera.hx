package player;

import math.Vec2;
import math.Vec3;
import math.Quat;
import math.Utils;

class OrbitCamera {
	public static function update_camera(e: Entity, move: Vec3, dt: Float, follow = false) {
		var cam = Render.camera;
		var xform = e.transform;
		var v = xform.velocity;
		var speed = v.length();

		if (speed == 0) {
			v = xform.position - e.last_tx.position;
			speed = v.length();
		}

		// only try to move the camera if the player is moving, or has
		// sufficient momentum that we can be sure it isn't margin of error
		var ml = Utils.max(move.length(), v.length() - 0.5);

		cam.orbit_distance = Utils.decay(cam.orbit_distance, e.player.target_distance, 8.0, dt);
		cam.target.x = xform.position.x;
		cam.target.y = xform.position.y;
		cam.target.z = Utils.decay(cam.target.z, xform.position.z, 5.0, dt);

		var desired_heading: Null<Float> = e.player.last_target_heading;
		if (ml > 0 || desired_heading == null) {
			desired_heading = new Vec2(v.x, v.y + 0.0001).angle_to() + Math.PI / 2;
			e.player.last_target_heading = desired_heading;
		}

		var current_heading = e.player.last_heading;
		if (current_heading == null) {
			current_heading = desired_heading;
		}

		var lateral_vel = new Vec2(v.x, v.y + 0.0001);
		var lateral_speed = lateral_vel.length();

		var heading_rate = 1.0 + 4.0 * Math.pow(Utils.min(lateral_speed / e.player.speed_limit, 1.0), 2.0);
		var heading_mix = Utils.decay(0, 1, heading_rate, dt);

		var dir = v.copy();
		dir.normalize();
		var pitch_limit = Utils.rad(50);
		var desired_pitch = Vec3.dot(dir, -Vec3.up()) * pitch_limit;
		desired_pitch += Utils.rad(10);
		desired_pitch = Utils.clamp(desired_pitch, -pitch_limit, pitch_limit);

		// don't autofollow in first person.
		if (e.player.target_distance <= 0.0 || follow) {
			e.player.last_heading = desired_heading;
			e.player.last_pitch = desired_pitch;
			return;
		}

		var current_pitch = e.player.last_pitch;
		if (current_pitch == null) {
			current_pitch = desired_pitch;
		}

		var old_heading = Quat.from_angle_axis(current_heading, Vec3.up());
		var new_heading = Quat.from_angle_axis(desired_heading, Vec3.up());

		var pitch_rate = 0.5 + 0.5 * Math.pow(Utils.min(speed / e.player.speed_limit, 1.0), 2.0);

		// if the pitch change is too small, ignore it
		var pitch = Utils.decay(current_pitch, desired_pitch, pitch_rate, dt);

		var spin_z = Quat.slerp(old_heading, new_heading, heading_mix);
		var spin_x = Quat.from_angle_axis(pitch, Vec3.right());

		cam.orientation = Quat.slerp(cam.orientation, spin_z * spin_x, Utils.decay(0, 1, 25, dt));
		cam.orientation.normalize();

		var new_dir = spin_z.apply_forward();
		e.player.last_heading = new Vec2(new_dir.x, new_dir.y).angle_to() + Math.PI / 2;
		e.player.last_pitch = pitch;
	}
}
