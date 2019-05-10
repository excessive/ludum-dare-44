package systems;

import math.Ray;
import math.Quat;
import math.Vec2;
import math.Vec3;
import math.Utils;
import backend.Input;
import GameInput.Action;

class PawnCursor extends System {
	override function filter(e: Entity) {
		if (e.pawn == null || e.pawn != Cursor) {
			return false;
		}

		if (e.player != null && e.transform != null) {
			return true;
		}
		return false;
	}

	override function process(e: Entity, dt: Float) {
		if (GameInput.pressed(MenuToggle)) {
			GameInput.spin_lock();
		}

		if (GameInput.locked) {
			// make sure to eat mouse movements when paused so camera doesn't lurch
			Input.get_mouse_moved(true);
			return;
		}

		var move = Vec3.splat(0.0);
		update_controls(e, move, dt);
		update_physics(e, dt);

		// we need to move last so that blocking animations keep you frozen
		update_camera(e, move, dt);
	}

	function update_controls(e: Entity, move: Vec3, dt: Float) {
		// Move player
		var stick = GameInput.move_xy();
		move.set_xyz(stick.x, stick.y, 0);
		move.trim(1);
		var ml = move.length();

		// handle inputs only when captured
		if (!Input.get_relative() || GameInput.locked) {
			return;
		}

		// Zoom camera
		var trigger = GameInput.get_value(Action.LTrigger) - GameInput.get_value(Action.RTrigger);
		var orbit   = e.player.target_distance;
		orbit      -= trigger * 4 * dt;
		e.player.target_distance = Utils.clamp(orbit, e.player.orbit_min, e.player.orbit_max);

		var action_angle = new Vec2(move.x, move.y + 0.0001).angle_to() + Math.PI / 2;
		// adjust cursor up to be NW, not NE
		var action_orientation = Quat.from_angle_axis(action_angle, Vec3.up()) * Quat.from_angle_axis(Math.PI / 2, Vec3.up());
		action_orientation.x = 0;
		action_orientation.y = 0;
		action_orientation.normalize();
		var action_direction = action_orientation.apply_forward();

		if (ml > 0) {
			var limit: Float = 999;
			var new_velocity = e.transform.velocity + action_direction * e.player.speed * ml;
			var over_speed = new_velocity.length() > limit;

			if (over_speed && new_velocity.length() > e.transform.velocity.length()) {
				new_velocity.trim(e.player.last_vel);
			}
			e.transform.velocity = new_velocity;
			// e.player.reset_orientation = null;
		}
		// run to tile center after releasing input
		else if (e.player.current_tile != null) {
			var epos = e.transform.position;
			var tpos = e.player.current_tile.transform.position.copy();
			tpos.z = epos.z;

			var dist = Vec3.distance(epos, tpos);
			if (dist > 0.125) {
				var velocity = e.transform.velocity + (tpos - epos) * e.player.speed * dist;
				velocity.trim(e.player.speed_limit);
				e.transform.velocity = velocity;
			}
		}
	}

	static function update_camera(e: Entity, move: Vec3, dt: Float) {
		player.OrbitCamera.update_camera(e, move, dt, true);
	}

	function update_physics(e: Entity, dt: Float) {
		var next_position = e.transform.position + e.transform.velocity * dt;
		next_position.z += 1.0;
		var result = Main.scene.cast_ray(
			new Ray(next_position, -Vec3.up()),
			(e: SceneNode) -> e.item != null && switch (e.item) {
				case Ground(type, height): true;
				default: false;
			},
			2.0
		);
		if (result.exists()) {
			final hit = result.sure();
			var xform = hit.o.transform;
			var bound = hit.o.bounds;
			next_position.z = bound.size.z * 0.5 + xform.position.z;
			e.player.current_tile = hit.o;
		}
		else {
			next_position = e.transform.position;
			e.transform.velocity *= 0;
		}
		e.transform.position = next_position;

		// friction boiiiii
		var friction = e.player.friction;

		var limit = e.player.speed_limit;
		e.transform.velocity.trim(limit);

		// this is only used for UI, show lateral speed.
		var lateral_vel = e.transform.velocity.copy();
		lateral_vel.z = 0;
		e.player.last_vel = e.transform.velocity.length();
		e.player.last_speed = lateral_vel.length();

		e.transform.velocity *= Math.exp(-friction * dt);

		// respawn
		if (e.transform.position.z < World.kill_z) {
			e.transform.position.set_from(Main.spawn_transform.position);
			e.transform.velocity *= 0;
			e.last_tx.position = e.transform.position.copy();
			e.last_tx.velocity = e.transform.velocity.copy();
		}
	}
}
