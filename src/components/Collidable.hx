package components;

import math.Vec3;

class Collidable {
	// public var radius: Vec3 = new Vec3(0.25, 0.25, 0.75);
	public var radius = new Vec3(1, 1, 1);
	public inline function new(?radius: Vec3) {
		if (radius != null) {
			this.radius = radius;
		}
	}
}
