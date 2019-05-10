package math;

@:publicFields
class Utils {
	static inline function min(a: Float, b: Float): Float {
#if lua
		return lua.Math.min(a, b);
#else
		return Math.min(a, b);
#end
	}

	static function hsv_to_rgb(hsv: Vec3): Vec3 {
		final s = hsv[1];
		final v = hsv[2];

		if (s == 0) {
			return Vec3.splat(v);
		}

		final h = hsv[0] / 60;
		final i = Math.ffloor(h);

		final f = h - i;
		final p = v * (1-s);
		final q = v * (1-s*f);
		final t = v * (1-s*(1-f));

		return switch (i) {
			case 0: new Vec3(v, t, p);
			case 1: new Vec3(q, v, p);
			case 2: new Vec3(p, v, t);
			case 3: new Vec3(p, q, v);
			case 4: new Vec3(t, p, v);
			default: new Vec3(v, p, q);
		};
	}

	static inline function max(a: Float, b: Float): Float {
#if lua
		return lua.Math.max(a, b);
#else
		return Math.max(a, b);
#end
	}

	// Haxe doesn't always provide deg/rad, but Lua does.
	static inline function rad(deg: Float): Float {
#if lua
		return lua.Math.rad(deg);
#else
		return deg*(Math.PI/180);
#end
	}
	static inline function deg(rad: Float): Float {
#if lua
		return lua.Math.deg(rad);
#else
		return rad/(Math.PI/180);
#end
	}
	static function round(value: Float, ?precision: Float): Float {
		if (precision != null) {
			return round(value / precision) * precision;
		}
		return value >= 0 ? Math.floor(value+0.5) : Math.ceil(value-0.5);
	}
	static function wrap(v: Float, limit: Float) {
		if (v < 0) {
			v += round((-v/limit)+1)*limit;
		}
		return v % limit;
	}
	static inline function clamp(v: Float, low: Float, high: Float): Float {
		return max(min(v, high), low);
	}
	static inline function lerp(low: Float, high: Float, progress: Float): Float {
		// return low * (1 - progress) + high * progress;
		return low + (high - low) * progress;
	}
	static inline function sign(value: Float): Float {
		return (value < 0 ? -1 : (value > 0 ? 1 : 0));
	}

	static function smoothstep(low: Float, high: Float, progress: Float) {
		final t = clamp((progress - low) / (high - low), 0.0, 1.0);
		return t * t * (3.0 - 2.0 * t);
	}

	/** Returns `value` if it is equal or greater than |`size`|, or 0. **/
	static inline function deadzone(value: Float, size: Float): Float {
		return Math.abs(value) >= size? value : 0;
	}

	/** return if value is equal or greater than threshold. **/
	static inline function threshold(value: Float, threshold): Bool {
		// I know, it barely saves any typing at all.
		return Math.abs(value) >= threshold;
	}

	static function rotate_bounds(mtx: Mat4, min: Vec3, max: Vec3) {
		final verts = [
			mtx * new Vec3(min.x, min.y, max.z),
			mtx * new Vec3(max.x, min.y, max.z),
			mtx * new Vec3(min.x, max.y, max.z),
			mtx * new Vec3(max.x, min.y, min.z),
			mtx * new Vec3(max.x, max.y, min.z),
			mtx * new Vec3(min.x, max.y, min.z)
		];
		var new_min = mtx * min;
		var new_max = mtx * max;
		for (v in verts) {
			new_min = Vec3.min(new_min, v);
			new_max = Vec3.max(new_max, v);
		}
		return {
			min: new_min,
			max: new_max
		};
	}

	// Scales a value from one range to another
	static inline function map(value: Float, min_in: Float, max_in: Float, min_out: Float, max_out: Float) {
		return ((value) - (min_in)) * ((max_out) - (min_out)) / ((max_in) - (min_in)) + (min_out);
	}

	static inline function decay(low: Float, high: Float, rate: Float, dt: Float) {
		return lerp(low, high, 1.0 - Math.exp(-rate * dt));
	}

	/*
--- Check if value is equal or less than threshold.
-- @param value
-- @param threshold
-- @return boolean
function utils.tolerance(value, threshold)
	-- I know, it barely saves any typing at all.
	return abs(value) <= threshold
end
	*/

}
