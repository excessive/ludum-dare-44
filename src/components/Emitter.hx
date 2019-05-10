package components;

import math.Quat;
import love.math.MathModule as Lm;
import math.Vec3;

// instance buffer
import love.graphics.Mesh;

@:publicFields
class InstanceData {
	var spawn_time: Float;
	var despawn_time: Float;
	var position:     Vec3;
	var orientation:  Quat;
	var velocity:     Vec3;

	inline function new(pos: Vec3, vel: Vec3, offset: Vec3, spawn: Float, despawn: Float, radius: Float, spread: Float) {
		this.spawn_time = spawn;
		this.despawn_time = despawn;
		this.position     = pos + new Vec3(
			(2*Lm.random()-1)*radius + offset.x,
			(2*Lm.random()-1)*radius + offset.y,
			offset.z
		);

		this.velocity = new Vec3(
			vel.x + (2 * Lm.random()-1) * spread,
			vel.y + (2 * Lm.random()-1) * spread,
			vel.z + (2 * Lm.random()-1) * spread
		);

		// go wild
		this.orientation = Quat.from_angle_axis(Lm.random(5000)/5000*Math.PI*2, this.velocity);
		this.orientation.normalize();
	}
}

@:publicFields
class ParticleData {
	var index:           Int   = 0;
	var last_spawn_time: Float = 0.0;
	var particles:       Array<InstanceData> = [];
	var time:            Float = 0.0;
	var buffer:          Null<Mesh> = null;
	inline function new() {}
}

typedef Emitter = {
	enabled: Bool,
	limit: Int,
	pulse: Float,
	spawn_radius: Float,
	spread: Float,
	emission_rate: Int,
	emission_life_min: Float,
	emission_life_max: Float,
	data: ParticleData,
	drawable: Drawable,
	?offset: Vec3,
	?velocity: Vec3,
	?lifetime: Float,
	?update: Emitter->Int->Void,
	?cull_behind: Bool,
}
