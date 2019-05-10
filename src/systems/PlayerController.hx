package systems;

import math.Ray;
import components.Transform;
import components.Player;
import collision.Response;
import math.Vec2;
import math.Vec3;
import math.Quat;
import math.Utils;
import render.Render;
import anim9.Anim9;

enum QueueAnim {
	Idle;
	Hop;
	Land;
	Alert;
}

class PlayerController extends System {
	override function filter(e: Entity) {
		return e.player != null && e.physics != null && e.collidable != null;
	}

	// MAGIC NUMBERS THEY JUST WORK
	static final gravity_strength = 0.70;
	// static final friction         = 0.00825;
	static final up               = Vec3.up();
	static final right            = Vec3.right();

	static final anim_state: Map<Entity, {
		state: QueueAnim,
		tracks: Map<QueueAnim, Anim9Track>,
		was_blocked: Bool
	}> = [];

	static function get_thingy(move: Vec3, tetsumusu: Quat) {
		// TRICKY: map the input onto square gate.
		// rolled out and super monkey ball do this, and bites is adamant
		// that it makes the game feel much better. i'm gonna trust him.
		final ml = move.length();

		// figure out movement relative to camera, nudged to handle no inputs
		final angle: Float = new Vec2(move.x, move.y + 0.0001).angle_to() + Math.PI / 2;
		final move_orientation: Quat = tetsumusu * Quat.from_angle_axis(angle, up);
		move_orientation.x = 0;
		move_orientation.y = 0;
		move_orientation.normalize();

		// accelerate
		final move_right = move_orientation * right;
		final thingy = Quat.from_angle_axis(Utils.min(Math.pow(ml, 3), Math.sqrt(2.0)) * -gravity_strength, move_right);
		thingy.normalize();
		return thingy;
	}

	// welcome to da camera z0ne
	// TODO: attempt to simplify this shit, it's really dense
	public static function adjust_camera(e: Entity, move: Vec3, cam: Camera, dt: Float) {
		final xform = e.transform;
		final v = xform.velocity;
		final speed = v.length();

		// only try to move the camera if the player is moving, or the ball
		// has sufficient momentum that we can be sure it isn't margin of error
		final ml = Utils.max(move.length(), v.length() - 0.5);

		final camera_tilt = get_thingy(move, cam.orientation);
		// used on stage end
		if (cam.freeze_position) {
			camera_tilt.x = 0;
			camera_tilt.y = 0;
			camera_tilt.z = 0;
			camera_tilt.w = 1;
		}

		// decay this so that the game isn't jittery when receiving input.
		// doesn't affect physics!
		final tilt_mix = Utils.decay(0, 1, 10.0, dt);
		e.player.lag_tilt = Quat.slerp(e.player.lag_tilt, camera_tilt, tilt_mix);
		cam.tilt = e.player.lag_tilt;

		var target_distance = 4.5 + speed / 100;

		final back = new Ray(cam.target, -cam.orientation.apply_forward());
		var result = CollisionWorld.cast_ray(Solid, back, cam.orbit_distance);
		if (result.exists()) {
			var hit = result.sure();
			target_distance = Utils.min(hit.d, target_distance);
		}

		cam.orbit_distance = Utils.decay(cam.orbit_distance, target_distance, 0.8, dt);
		cam.target.set_from(xform.position + xform.offset);

		var desired_heading: Float = e.player.last_target_heading;
		if (ml > 0 || desired_heading == null) {
			desired_heading = new Vec2(v.x, v.y + 0.0001).angle_to() + Math.PI / 2;
			e.player.last_target_heading = desired_heading;
		}

		var current_heading = e.player.last_heading;
		if (current_heading == null) {
			current_heading = desired_heading;
		}

		final lateral_vel = new Vec2(v.x, v.y + 0.0001);
		final lateral_speed = lateral_vel.length();

		final heading_rate = 0.5 + 4.0 * Math.pow(Utils.min(lateral_speed / 15, 1.0), 2.0);
		final heading_mix = Utils.decay(0, 1, heading_rate, dt);

		// prevent camera jiggle from small errors in collision resolution
		final dir = v.copy();
		dir.z *= Utils.min(lateral_speed * 0.5, 1.0);
		if (Math.abs(dir.z) < 0.25) {
			dir.z = 0;
		}
		if (dir.length() < 0.05) {
			dir.set_xyz(0, 0, 0);
		}
		dir.normalize();
		final pitch_limit = Utils.rad(75);
		var desired_pitch = Vec3.dot(dir, -up) * pitch_limit;
		desired_pitch += Utils.rad(10);
		desired_pitch = Utils.clamp(desired_pitch, -pitch_limit, pitch_limit);

		var current_pitch = e.player.last_pitch;
		if (current_pitch == null) {
			current_pitch = desired_pitch;
		}

		final old_heading = Quat.from_angle_axis(current_heading, up);
		final new_heading = Quat.from_angle_axis(desired_heading, up);

		final pitch_rate = 0.5 + 1.5 * Math.pow(Utils.min(speed / 15, 1.0), 2.0);

		// if the pitch change is too small, ignore it
		final pitch = Utils.decay(current_pitch, desired_pitch, pitch_rate, dt);

		final spin_z = Quat.slerp(old_heading, new_heading, heading_mix);
		final spin_x = Quat.from_angle_axis(pitch, right);
		cam.orientation.set_from(Quat.slerp(cam.orientation, spin_z * spin_x, Utils.decay(0, 1, 25, dt)));
		cam.orientation.normalize();

		final new_dir = spin_z.apply_forward();
		e.player.last_heading = new Vec2(new_dir.x, new_dir.y).angle_to() + Math.PI / 2;
		e.player.last_pitch = pitch;
	}

	static final substeps = 1;

	// function update_animation(e: Entity, queue: QueueAnim) {
	// 	final anim = anim_state[e];
	// 	if (anim.state == queue) {
	// 		return;
	// 	}
	// 	if (anim.tracks[anim.state].)
	// 	if (e.animation)
	// 	anim.state = queue;
	// 	e.animation.transition(anim.tracks[anim.state], 0.1);
	// }

	function update_animation(e: Entity, queue_anim: QueueAnim) {
		final anim = anim_state[e];
		final tracks = anim.tracks;

		function play(track: Anim9Track, ?target: Anim9Track, immediate: Bool = false) {
			if (e.animation == null || track == null) { return; }

			if (!e.animation.find_track(track)) {
				e.animation.transition(track, 0.1);
				// wtf why
				anim.was_blocked = !e.animation.animations[cast track.name].loop;

				if (anim.was_blocked) {
					track.callback = () -> {
						var into = tracks[Idle];
						var len = 0.2;
						if (target != null) {
							into = target;
						}
						if (immediate) {
							len = 0.0;
						}
						e.animation.transition(into, len);
						anim.was_blocked = false;
					}
				}
			}
		}

		if (!anim.was_blocked) {
			switch (queue_anim) {
				case Hop: play(tracks[Hop]);
				case Idle: play(tracks[Idle]);
				case Land: play(tracks[Land]);
				case Alert: play(tracks[Alert]);
			}
		}
	}
	override function process(e: Entity, dt: Float) {
		if (GameInput.pressed(MenuToggle)) {
			// Sfx.bloop.stop();
			// Sfx.bloop.play();
			GameInput.spin_lock();
			Sfx.menu_pause(GameInput.locked);
			return;
		}

		if (GameInput.locked || console.Console.visible) {
			return;
		}

		if (!anim_state.exists(e)) {
			final tracks = [
				Hop => e.animation.new_track("hop", 1, 1, () -> { Sfx.plop.stop(); Sfx.plop.play(); }, false, true),
				Idle => e.animation.new_track("idle"),
				Land => e.animation.new_track("land"),
				Alert => e.animation.new_track("alert")
			];
			anim_state[e] = {
				state: Idle,
				tracks: tracks,
				was_blocked: false
			}
		}
		var queue = Idle;

		//if (GameInput.pressed(Respawn) && !Stage.stop_time) {
		//	Sfx.stop_all();
		//	// Signal.emit("respawn");
		//	return;
		//}

		final gravity_orientation = new Quat(0, 0, 0, 1);

		final xform = e.transform;
		final cam   = Render.camera;
		final stick = GameInput.move_xy() * e.player.speed; // slower
		final move  = new Vec3(stick.x, stick.y, 0);

		// HACK: Adjust -y input in the air if lateral movement is too low
		// this prevents camera jitters when falling.
		if (!e.physics.on_ground && move.y < 0) {
			final v = xform.velocity;
			final lateral_vel = new Vec2(v.x, v.y + 0.0001);
			final lateral_speed = lateral_vel.length();
			final limit = 5;
			// velocity is camera backward
			if (lateral_speed < limit && Vec3.dot(move, new Vec3(0, -1, 0)) > 0.5) {
				var m2 = move.copy();
				final mix = lateral_speed / limit;
				move.y *= move.x;
				m2 = Vec3.lerp(move, m2, mix);
				move.x = m2.x;
				move.y = m2.y;
				move.trim(1.0);
			}
		}

		final ml = move.length();

		final bonk_max: Float = 2.0;
		final bonk_min = bonk_max / 2.0;
		var bonk_threshold = bonk_min;

		if (ml > 0) {
			queue = Hop;
			// final move_norm = move.copy();
			// fun fact: monkey ball doesn't do this, diagonals are >1 strength
			// move.trim(1.0);
			// if (move.trim(1.0)) {
			// 	ml = 1;
			// }
			move.fmul_inplace(-1);

			final d = xform.velocity.copy();
			d.normalize();

			// bonk at a lower threshold if you are trying to avoid a surface.
			final actual_dir = new Vec2(d.x, d.y + 0.0001);
			actual_dir.normalize();

			final angle = actual_dir.angle_to() + Math.PI / 2;
			final fast = get_thingy(move, Quat.from_angle_axis(angle, up)*cam.tilt);
			final slow = get_thingy(move, cam.orientation*cam.tilt);

			// figure out movement relative to camera, nudged to handle no inputs
			final angle: Float = new Vec2(move.x, move.y + 0.0001).angle_to() + Math.PI / 2;
			final move_orientation: Quat = cam.orientation * Quat.from_angle_axis(angle, up);
			move_orientation.x = 0;
			move_orientation.y = 0;
			move_orientation.normalize();

			final move_cam = move_orientation.apply_forward();
			final desired_dir = new Vec2(move_cam.x, move_cam.y + 0.0001);
			desired_dir.normalize();

			var bonk_scale = Utils.max(0.0, Vec2.dot(actual_dir, desired_dir));
			bonk_scale = Math.pow(bonk_scale, 2.0);
			bonk_scale = Math.max(0.5, bonk_scale);
			bonk_threshold = Utils.lerp(bonk_min, bonk_max, bonk_scale);
			// trace(bonk_scale);

			// sel=0 feels pretty close to the same now, might be removable
			final sel = Utils.map(xform.velocity.length(), 0, 20, 0, 1);
			gravity_orientation.set_from(Quat.slerp(slow, fast, Utils.min(sel, 1)));
		}

		dt /= substeps;

		var touched_ground = false;

		final bonk_data = {
			bonked: false,
			impulse: new Vec3(0, 0, 0)
		};

		var search = Main.scene.get_child("kill_z");
		var kill_z = -10.0;
		if (search.exists()) {
			kill_z = search.sure().transform.position.z;
		}

		search = Main.scene.get_child("spawn");
		var spawn = new Transform();
		if (search.exists()) {
			spawn = search.sure().transform;
		}

		for (i in 0...substeps) {
			// slow down
			// final friction = 0.00825;
			var apply_friction = 0.0;
			if (e.physics.on_ground) {
				apply_friction = e.player.friction;
				// if pushing into a wall/hill, add more friction.
				// this makes pushing up ramps/etc feel better
				apply_friction += e.player.slope * apply_friction;

				// stop fast if you aren't pushing
				if (ml == 0) {
					apply_friction *= 4;
				}

				e.player.last_valid_positions.unshift({
					position: e.transform.position.copy(),
					orientation: cam.orientation.copy()
				});

				// store 5 seconds worth of positions, maximum
				final max_positions = Std.int(1/Main.timestep*5*substeps);
				e.player.last_valid_positions.resize(max_positions);
			}
			// if (/*Stage.stop_time && */e.physics.on_ground) {
			// 	apply_friction = friction * 2;
			// }
			xform.velocity *= (1.0 - apply_friction);

			// handle collisions
			final gravity       = gravity_orientation * up * -gravity_strength / substeps;
			final radius        = e.collidable.radius;
			final visual_offset = new Vec3(0, 0, radius.z);
			final packet = Response.update(
				xform.position + visual_offset,
				xform.velocity * dt,
				radius,
				gravity * dt,
				(min, max) -> CollisionWorld.get_triangles(Solid, min, max),
				1
			);

			var water_hits = Response.check(packet.position, radius, (min, max) -> CollisionWorld.get_triangles(Ghost, min, max));
			if (water_hits > 0 && !e.player.invulnerable) {
				// RIP
				Signal.emit('reset', { ded:true, fall:false });
				return;
			}

			final sky_ray = CollisionWorld.cast_ray(Solid, new Ray(packet.position, Vec3.up()));
			if (!sky_ray.exists()) {
				// trace("can see the sky o shit");
				water_hits += 1;

				if (!e.player.invulnerable) {
					e.collidable.radius.fadd_inplace(-Player.death_size * 0.1 * dt);
					e.collidable.radius.x = Utils.max(Player.death_size, e.collidable.radius.x);
					e.collidable.radius.y = Utils.max(Player.death_size, e.collidable.radius.y);
					e.collidable.radius.z = Utils.max(Player.death_size, e.collidable.radius.z);
					e.transform.scale.set_from(e.collidable.radius);
					e.transform.offset.z = 0.557712 * e.transform.scale.z;
				}

				if (e.player.state == Safe) {
					Signal.emit("hud-danger");
					queue = Alert;
				}
				e.player.state = Danger;
				Bgm.set_ducking(0.25);
				Bgm.effect_vol = 1.0;

				if (e.collidable.radius.z <= Player.death_size && !e.player.invulnerable) {
					Signal.emit('reset', { ded:true, fall:false });
					return;
				}
			}
			else {
				Bgm.set_ducking(0.5);
				Bgm.effect_vol = 0.0;
				if (e.player.state == Danger) {
					Signal.emit("hud-safe");
				}
				e.player.state = Safe;
			}
			e.emitter[1].enabled = e.player.state == Danger;

			// if (water_hits > 0) {
			// }

			final old_position = xform.position;

			// BUG: velocity is doubled, apparently, so we have to be careful
			// to cut it in half before messing with anything... I don't know
			// why this happens, but fixing it will quite probably change how
			// the game feels, so don't even try w/o a good reason.
			final old_speed     = xform.velocity.length() * 0.5;
			final old_direction = xform.velocity.copy();
			old_direction.normalize();

			final new_position = packet.position - visual_offset;

			// ignore less than 10cm/s to avoid jittering
			final min_move = 0.1;
			if (Vec3.distance(old_position, new_position) < min_move*dt && ml < 0.001) {
				new_position.set_from(old_position);
				packet.velocity *= 0;
			}

			xform.position = new_position;
			final new_direction = packet.velocity / dt;
			xform.velocity = new_direction;

			var new_speed = new_direction.length();
			new_direction.normalize();
			// enforce maintaining speed through collision redirections
			xform.velocity = new_direction * Utils.max(old_speed, new_speed);
			new_speed = xform.velocity.length();

			// for each contact you hit harder than the bonk threshold,
			// accumulate weighted hit normals. if any hits are hard enough,
			// we'll use that to redirect the player
			final bonk         = new Vec3(0, 0, 0);
			var bonk_power     = 0.0;
			var bonked         = false;
			final slope        = new Vec3(0, 0, 0);
			var grounded       = false;
			final orient_slope = new Vec3(0, 0, 0);

			for (c in packet.contacts) {
				slope.add_inplace(c.normal);

				final dz = Vec3.dot(c.normal, up);
				if (dz >= 0.25) {
					grounded = true;
					orient_slope.add_inplace(c.normal);
				}

				// invert so parallel is 0, direct is 1.
				final facing = -Vec3.dot(old_direction, c.normal);

				// never bonk a surface you're traveling perfectly parallel to,
				// but easily bonk any you travel directly into.
				final hit_power = old_speed * facing;
				final this_bonked = hit_power > bonk_threshold;
				if (this_bonked) {
					bonk_power += hit_power;
					bonk.add_inplace(c.normal * facing);
					bonked = true;
				}
			}

			if (bonked) {
				bonk.normalize();
				final bounce = Vec3.reflect(old_direction, bonk);

				// if the redirection was minor, we want to stay close to the
				// original speed. if it was significant, cut speed a lot. This
				// works around ridiculous reverse bounces.
				var max_power = Utils.max(0.0, Vec3.dot(old_direction, bounce));
				max_power = Utils.lerp(0.5, 1.0, max_power);

				final max_bonk = 18; // around 40mph
				var power = 0.25 + 0.25 * Utils.min(1.0, bonk_power / max_bonk);
				power = 1.0 - power;
				power *= max_power;

				final impulse = old_speed * power * 2;
				bonk_data.bonked = true;
				xform.velocity = bounce * impulse;
				// bonk_data.impulse += bounce * impulse;
			}

			e.physics.on_ground = grounded;
			if (e.physics.on_ground) {
				touched_ground = true;
				final forward = xform.velocity.copy();
				forward.normalize();

				final right     = Vec3.cross(forward, gravity_orientation * up);
				e.player.spin = Quat.from_angle_axis(xform.velocity.length() * -dt, right);

				slope.normalize();

				if (xform.velocity.length() > 0) {
					// final ground_ray = CollisionWorld.cast_ray(Solid, new Ray(packet.position, -Vec3.up()));
					// if (ground_ray.exists()) {
					// 	final hit = ground_ray.sure();
					// 	e.transform.orientation = Quat.from_direction(hit.p);
					// }
					orient_slope.normalize();
					final t = Utils.decay(0, 1, 5, dt);


					final velocity = xform.velocity;
					final vel_angle = new Vec2(velocity.x, velocity.y + 0.0001).angle_to() + Math.PI / 2;
					final vel_orientation = Quat.from_angle_axis(vel_angle, Vec3.up());
					vel_orientation.x = 0;
					vel_orientation.y = 0;
					vel_orientation.normalize();

					final spin = Quat.from_direction(orient_slope) * vel_orientation;

					e.transform.orientation.set_from(Quat.slerp(e.transform.orientation, spin, t));
				}

				// old slope value: in an older build, we reduced friction w/this
				// final steepness = Utils.max(0.0, 1.0 - Vec3.dot(slope, up));
				final slope_forward = Vec3.cross(slope, right);
				e.player.slope = Utils.max(0.0, 1.0 - Vec3.dot(slope_forward, forward));
			}
			else {
				e.player.slope = 0.0;
			}

			//xform.orientation = e.player.spin * xform.orientation;
			xform.orientation.normalize();

			// reset/kill-z
			if (xform.position.z < kill_z && !e.player.invulnerable) {// && !Stage.stop_time) {
				Signal.emit('reset', { ded:true, fall:true });
				//xform.velocity.fmul_inplace(0);
				//final offset = xform.offset.copy();
				//final scale = xform.scale.copy();
				//xform.set_from(spawn);
				//xform.offset.set_from(offset);
				//xform.scale.set_from(scale);
			}
		}

		dt *= substeps;

		if (bonk_data.bonked) {
			Signal.emit("vibrate", {
				power: 0.75,
				duration: 1/6
			});

			queue = Land;
			//Sfx.bonk.stop();
			//Sfx.bonk.play();
		}

		final speed = xform.velocity.length();
		//cam.freeze_position = Stage.stop_time;
		adjust_camera(e, move, cam, dt);
		update_animation(e, queue);

		if (touched_ground) {
			//Sfx.wub_for_speed(speed);
		}
	}
}
