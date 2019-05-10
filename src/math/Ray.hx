package math;

class Ray {
	public final position: Vec3;
	public final direction: Vec3;

	public inline function new(p: Vec3, d: Vec3) {
		this.position  = p;
		this.direction = d;
	}
}
