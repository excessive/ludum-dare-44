package math;

@:publicFields
class ColorUtils {
	static inline function decodeA8(color: Int) {
		return ((color >>  0) & 0xff) / 255.0;
	}

	static inline function encodeRGBA(color: Array<Float>): Int {
		return ((Std.int(color[0] * 255) & 0xff) << 24)
			| ((Std.int(color[1] * 255) & 0xff) << 16)
			| ((Std.int(color[2] * 255) & 0xff) <<  8)
			| ((Std.int(color[3] * 255) & 0xff) <<  0);
	}

	static inline function decodeRGBA8(color: Int) {
		return [
			((color >> 24) & 0xff) / 255.0,
			((color >> 16) & 0xff) / 255.0,
			((color >>  8) & 0xff) / 255.0,
			((color >>  0) & 0xff) / 255.0
		];
	}
	static inline function adjust(color: Array<Float>, amount: Float) {
		return [
			color[0] + amount,
			color[1] + amount,
			color[2] + amount,
			color[3]
		];
	}

	// usage: var rainbow = [ for (i in 0...360) hsv_to_color(i, 1.0, 1.0) ];
	public static function hsv_to_color(h: Float, s: Float, v: Float): Array<Float> {
		var f, q, p, t;
		if (s == 0) return [ v, v, v ];
		h /= 60.0;
		var i = Math.ffloor(h);
		f = h - i;
		p = v * (1-s);
		q = v * (1-s*f);
		t = v * (1-s*(1-f));
		if      (i == 0) return [ v, t, p ];
		else if (i == 1) return [ q, v, p ];
		else if (i == 2) return [ p, v, t ];
		else if (i == 3) return [ p, q, v ];
		else if (i == 4) return [ t, p, v ];
		else             return [ v, p, q ];
	}
}
