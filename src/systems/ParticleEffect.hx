package systems;

import render.Render;
import math.Mat4;
import love.graphics.GraphicsModule as Lg;
import love.graphics.SpriteBatchUsage;

import love.math.MathModule.random as rand;
import math.Vec3;
import math.Utils;
import components.Transform;
import components.Emitter;
import lua.Table;

class ParticleEffect extends System {
	override function filter(e: Entity) {
		return e.emitter.length > 0;
	}

	static var v3_zero = Vec3.zero();

	function spawn_particle(transform: Transform, emitter: Emitter) {
		if (!emitter.enabled) {
			return;
		}

		var pd = emitter.data;
		pd.last_spawn_time = pd.time;
		pd.index++;

		var mul = 10000.0;
		var offset = rand(emitter.emission_life_min*mul, emitter.emission_life_max*mul) / mul;
		var despawn_time = pd.time + offset;

		var velocity = v3_zero;
		if (emitter.velocity != null) {
			velocity = emitter.velocity;
		}

		var offset = v3_zero;
		if (emitter.offset != null) {
			offset = emitter.offset;
		}

		var instance = new InstanceData(
			transform.position,
			velocity, // ignore entity velocity!
			transform.offset + offset,
			pd.time,
			despawn_time,
			emitter.spawn_radius,
			emitter.spread
		);

		if (emitter.cull_behind != null && emitter.cull_behind) {
			var dir = instance.position - Render.camera.last_position;
			dir.normalize();

			var fwd = Render.camera.orientation.apply_forward();
			if (Vec3.dot(dir, fwd) < 0) {
				return;
			}
		}

		pd.particles.push(instance);
	}

	function update_emitter(transform: Transform, particle: Emitter, dt: Float) {
		var pd = particle.data;
		pd.time += dt;

		if (pd.buffer == null) {
			var fmt = Table.create();
			// x0 y0 z0 x3
			// x1 y1 z1 y3
			// x2 y2 z2 z3
			// instancing shader handles the rest
			fmt[1] = Table.create([ "InstanceMtx0", "float", cast 4 ]);
			fmt[2] = Table.create([ "InstanceMtx1", "float", cast 4 ]);
			fmt[3] = Table.create([ "InstanceMtx2", "float", cast 4 ]);

			pd.buffer = Lg.newMesh(fmt, particle.limit, Stream);
		}

		// It's been too long since our last particle spawn and we need more, time
		// to get to work.
		var spawn_delta = pd.time - pd.last_spawn_time;
		var count = pd.particles.length;
		if (particle.pulse > 0.0) {
			if (count + particle.emission_rate <= particle.limit && spawn_delta >= particle.pulse) {
				for (i in 0...particle.emission_rate) {
					this.spawn_particle(transform, particle);

					if (particle.update != null) {
						particle.update(particle, pd.index);
					}
				}
			}
		}
		else {
			var rate = 1/particle.emission_rate;
			if (count < particle.limit && spawn_delta >= rate) {
				var need = Std.int(Utils.min(17, Math.floor(spawn_delta / rate)));

				for (_ in 0...need) {
					this.spawn_particle(transform, particle);

					if (particle.update != null) {
						particle.update(particle, pd.index);
					}
				}
			}
		}

		// Because particles are added in order of time and removals maintain
		// order, we can simply count the number we need to get rid of and process
		// the rest.
		var remove_n = 0;
		for (i in 0...pd.particles.length) {
			var p = pd.particles[i];
			var idx = i+1;
			// sanity check: over particle limit for some reason (high rate?)
			if (idx > pd.buffer.getVertexCount()) {
				// trace("bailing", pd.buffer.getVertexCount(), pd.particles.length, particle.limit);
				continue;
			}
			if (pd.time >= p.despawn_time) {
				remove_n++;
				// pd.buffer.setVertexAttribute(idx, 1, 0, 0, 0, 0);
				// pd.buffer.setVertexAttribute(idx, 2, 0, 0, 0, 0);
				// pd.buffer.setVertexAttribute(idx, 3, 0, 0, 0, 0);
				continue;
			}
			p.position.x = p.position.x + p.velocity.x * dt;
			p.position.y = p.position.y + p.velocity.y * dt;
			p.position.z = p.position.z + p.velocity.z * dt;

			var life = p.despawn_time - p.spawn_time;
			var offset = pd.time - p.spawn_time;
			var scale = Utils.max(0.0, 1.0 - offset / life);

			var mtx = Mat4.from_srt(p.position, p.orientation, Vec3.splat(scale));
			pd.buffer.setVertexAttribute(idx, 1, mtx[0], mtx[1], mtx[2], mtx[12]);
			pd.buffer.setVertexAttribute(idx, 2, mtx[4], mtx[5], mtx[6], mtx[13]);
			pd.buffer.setVertexAttribute(idx, 3, mtx[8], mtx[9], mtx[10], mtx[14]);
		}

		// Particles be gone!
		if (remove_n > 0) {
			pd.particles.splice(0, remove_n);
		}
	}

	override function process(e: Entity, dt: Float) {
		if (GameInput.locked) {
			return;
		}

		var i = e.emitter.length;
		while (i-- > 0) {
			var emitter = e.emitter[i];
			if (emitter.lifetime != null) {
				emitter.lifetime -= dt;
				if (emitter.lifetime <= 0) {
					e.emitter.splice(i, 1);
					continue;
				}
			}
			update_emitter(e.transform, emitter, dt);
		}
	}
}
