package math;

class Capsule {
	public final a: Vec3;
	public final b: Vec3;
	public final radius: FloatType;

	public function new(a: Vec3, b: Vec3, radius: Float) {
		this.a = a;
		this.b = b;
		this.radius = radius;
	}
}
