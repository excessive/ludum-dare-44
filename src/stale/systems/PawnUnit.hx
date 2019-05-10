package systems;

import math.Ray;
import components.Emitter.ParticleData;
import iqm.Iqm;
import math.Quat;
import math.Vec2;
import math.Vec3;
import math.Utils;
import anim9.Anim9.Anim9Track;
import backend.Input;
import GameInput.Action;
import loaders.IqmLoader;

enum QueueAnim {
	Idle;
	Run;
}

class PawnUnit extends System {
	public static var tracks: {
		idle:   Anim9Track,
		run:    Anim9Track,
	} = {
		idle:   null,
		run:   null,
	};

	static var queue_anim:  QueueAnim = Idle;
	static var was_blocked: Bool      = false;

	static var cube: IqmFile;

	static var num_grinds: Int = 2;
	static var grind_idx:  Int = 0;

	override function filter(e: Entity) {
		if (e.pawn == null || e.pawn != Unit) {
			return false;
		}

		if (e.player != null && e.transform != null) {
			// Load animations tracks
			if(e.animation != null && tracks.idle == null) {
				tracks.idle   = e.animation.new_track("idle");
				tracks.run    = e.animation.new_track("run");
			}

			if (cube == null) {
				cube = Iqm.load("assets/models/debug/unit-cube.iqm");
			}

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
		update_unit(e, move, dt);
		update_physics(e, dt);

		// we need to move last so that blocking animations keep you frozen
		update_animation(e, dt);
		update_camera(e, move, dt);
	}

	function update_controls(e: Entity, move: Vec3, ml: Float, dt: Float) {
		// Zoom camera
		var trigger = GameInput.get_value(Action.LTrigger) - GameInput.get_value(Action.RTrigger);
		var orbit   = e.player.target_distance;
		orbit      -= trigger * 4 * dt;
		e.player.target_distance = Utils.clamp(orbit, e.player.orbit_min, e.player.orbit_max);

		var action_angle = new Vec2(move.x, move.y + 0.0001).angle_to() + Math.PI / 2;
		// adjust unit up to align with display for direct control
		var action_orientation = Quat.from_angle_axis(action_angle, Vec3.up()) * Quat.from_angle_axis(Math.PI / 4, Vec3.up());
		action_orientation.x = 0;
		action_orientation.y = 0;
		action_orientation.normalize();
		var action_direction = action_orientation.apply_forward();

		if (ml > 0) {
			queue_anim = Run;

			var limit: Float = 999;
			var new_velocity = e.transform.velocity + action_direction * e.player.speed * ml;
			var over_speed = new_velocity.length() > limit;

			if (over_speed && new_velocity.length() > e.transform.velocity.length()) {
				new_velocity.trim(e.player.last_vel);
			}
			e.transform.velocity = new_velocity;
			e.transform.orientation = action_orientation.copy();
			e.player.reset_orientation = null;
		}
	}

	function update_unit(e: Entity, move: Vec3, dt: Float) {
		// Move player
		var stick = GameInput.move_xy();
		move.set_xyz(stick.x, stick.y, 0);
		move.trim(1);
		var ml = move.length();

		queue_anim = Idle;

		// handle inputs only when captured
		// var have_input = Input.get_relative() && !GameInput.locked;
		var have_input = !GameInput.locked;
		if (have_input && ml > 0) {
			update_controls(e, move, ml, dt);
		}
		// run to tile center after releasing input
		else if (e.player.current_tile != null) {
			var epos = e.transform.position;
			var tpos = e.player.current_tile.transform.position.copy();
			tpos.z = epos.z;

			var dist = Vec3.distance(epos, tpos);
			if (dist > 0.125) {
				queue_anim = Run;
				var velocity = e.transform.velocity + (tpos - epos) * e.player.speed * dist;
				velocity.trim(e.player.speed_limit);
				e.transform.velocity = velocity;

				if (e.player.reset_orientation == null) {
					e.player.reset_orientation = e.transform.orientation.copy();
				}

				var vel_angle = new Vec2(velocity.x, velocity.y + 0.0001).angle_to() + Math.PI / 2;
				var vel_orientation = Quat.from_angle_axis(vel_angle, Vec3.up());
				vel_orientation.x = 0;
				vel_orientation.y = 0;
				vel_orientation.normalize();
				e.transform.orientation = vel_orientation;
			}
			else if (e.player.reset_orientation != null) {
				e.transform.orientation = Quat.slerp(
					e.transform.orientation,
					e.player.reset_orientation,
					Utils.decay(0, 1, 8, dt)
				);
			}
		}
	}

	function update_animation(e: Entity, dt: Float) {
		function play(track: Anim9Track, ?target: Anim9Track, immediate: Bool = false) {
			if (e.animation == null || track == null) { return; }

			if (!e.animation.find_track(track)) {
				e.animation.transition(track, 0.2);
				was_blocked = !e.animation.animations[cast track.name].loop;

				if (was_blocked) {
					track.callback = () -> {
						var into = tracks.idle;
						var len = 0.2;
						if (target != null) {
							into = target;
						}
						if (immediate) {
							len = 0.0;
						}
						e.animation.transition(into, len);
						was_blocked = false;
					}
				}
			}
		}

		if (!was_blocked) {
			switch (queue_anim) {
				case Idle:   play(tracks.idle);
				case Run:    play(tracks.run);
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

		// if we're just grounding on this frame and hit normal is
		// approximately up: fx!
		if (e.transform.velocity.length() > 2) {
			var node = new SceneNode();
			var lifetime = 0.75;
			var particles = 15;
			node.emitter.push({
				data: new ParticleData(),
				enabled: true,
				limit: particles,
				pulse: lifetime,
				spawn_radius: 0.0,
				spread: 2.0,
				lifetime: lifetime,
				emission_rate: particles,
				emission_life_min: lifetime/5,
				emission_life_max: lifetime,
				drawable: IqmLoader.get_views(cube)
			});
			node.emitter[0].data.time = lifetime;
			node.transform.position.set_from(e.transform.position);

			// Signal.emit("vibrate", {
			// 	power: 1.0,
			// 	duration: 0.1,
			// });

			Main.scene.add(node);
			Signal.after(node.emitter[0].lifetime, function() {
				Main.scene.remove(node);
			});
		}

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
			e.transform.orientation.set_from(Main.spawn_transform.orientation);
			e.transform.velocity *= 0;
			e.last_tx.position = e.transform.position.copy();
			e.last_tx.velocity = e.transform.velocity.copy();
		}
	}
}
