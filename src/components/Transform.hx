package components;

import math.Quat;
import math.Vec3;
import math.Mat4;

class Transform {
	public var position:      Vec3 = new Vec3(0, 0, 0);
	public var orientation:   Quat = new Quat(0, 0, 0, 1);
	public var velocity:      Vec3 = new Vec3(0, 0, 0);
	public var scale:         Vec3 = new Vec3(1, 1, 1);
	public var offset:        Vec3 = new Vec3(0, 0, 0);
	public var is_static:     Bool = false;
	public var matrix:        Mat4 = Mat4.from_identity();
	public var normal_matrix: Mat4 = Mat4.from_identity();

	public inline function new() {}

	public function update() {
		matrix = Mat4.from_srt(position + offset, orientation, scale);

		var inv = Mat4.inverse(matrix);
		inv.transpose();
		normal_matrix = inv;
	}

	public inline function set_from(other: Transform) {
		position.set_from(other.position);
		orientation.set_from(other.orientation);
		velocity.set_from(other.velocity);
		offset.set_from(other.offset);
		scale.set_from(other.scale);
	}

	public function copy() {
		var ret = new Transform();
		ret.set_from(this);
		return ret;
	}
}
