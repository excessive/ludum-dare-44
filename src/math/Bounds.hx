package math;

@:publicFields
class Bounds {
	final center: Vec3;
	final size: Vec3;
	final min: Vec3;
	final max: Vec3;

	function new(center: Vec3, size: Vec3) {
		this.center = center;
		this.size   = size;
		this.min    = center - (size / 2);
		this.max    = center + (size / 2);
	}

	static function from_extents(min: Vec3, max: Vec3) {
		final size = max - min;
		final center = min + size / 2;
		return new Bounds(center, size);
	}
}
