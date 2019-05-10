import math.Vec3;
import math.Quat;
import math.Frustum;
import math.Mat4;

class Camera {
	public var tilt:          Quat  = new Quat(0, 0, 0, 1);
	public var last_tilt:     Quat;

	public var fov:            Float = 70;
	public var target_offset:  Float = 0.825;
	public var orbit_distance: Float = 5;

	public var freeze_position: Bool = false;

	public var last_position: Vec3;
	public var target:        Vec3;
	public var last_target:   Vec3;
	public var orientation = new Quat(0, 0, 0, 1);
	public var last_orientation = new Quat(0, 0, 0, 1);
	public var view:          Mat4  = Mat4.from_identity();
	public var projection:    Mat4  = Mat4.from_identity();
	public var clip_distance: Float = 999;
	public var near:          Float = 1.0;
	public var far:           Float = 1000.0;

	var up    = Vec3.up();

	public function new(target: Vec3) {
		this.target    = target + new Vec3(0.0, 0.01, 0);
		this.last_target = this.target.copy();
		this.last_tilt   = this.tilt.copy();
		this.last_position = this.target.copy();
	}

	inline function real_orientation(mix: Float): Quat {
		var otn = this.orientation;
		if (mix < 1.0) {
			otn = Quat.slerp(this.last_orientation, this.orientation, mix);
		}
		return otn;
	}

	inline function real_target(mix: Float): Vec3 {
		var tgt = this.target;
		if (mix < 1.0) {
			tgt = Vec3.lerp(this.last_target, this.target, mix);
		}
		return tgt + new Vec3(0, 0, this.target_offset);
	}

	inline function real_tilt(mix: Float): Quat {
		var tlt = this.tilt;
		if (mix < 1.0) {
			tlt = Quat.slerp(this.last_tilt, this.tilt, mix);
		}
		return tlt;
	}
	public var frustum(default, null): Frustum;

	public function update(w: Float, h: Float, mix: Float = 1.0) {
		// var tilt = Quat.slerp(real_tilt(mix), new Quat(0, 0, 0, 1), 0.85);
		var tilt = Quat.slerp(real_tilt(mix), new Quat(0, 0, 0, 1), 0.925);
		var orientation = real_orientation(mix);
		var cam_tilt = tilt * orientation;
		var tilted = -tilt * orientation;
		var tilted_dir = tilted.apply_forward();

		// var bg = null;//Main.bg_transform;
		// if (bg != null && false) {
		// 	bg.is_static = true;
		// 	// we need the un-tilted normal matrix for shading
		// 	bg.update();

		// 	var orientation = bg.orientation;
		// 	bg.orientation = -tilt;

		// 	var normal_mtx = bg.normal_matrix;
		// 	bg.update();

		// 	// put everything back so we don't experience The Crazies
		// 	bg.orientation = orientation;
		// 	bg.normal_matrix = normal_mtx;
		// }
		// else {
		// 	bg.update();
		// }

		var target = real_target(mix);
		if (this.freeze_position) {
			this.view = Mat4.look_at(this.last_position, target + tilted_dir * 0.001, this.up);
		}
		else {
			var pos = tilted_dir * -this.orbit_distance;
			this.last_position = target + pos;

			var look = Mat4.look_at(target, target + tilted_dir * 0.001, cam_tilt * this.up);
			var offset = Mat4.translate(-pos);
			this.view = look * offset;
		}

		var aspect = Math.max(w / h, h / w);
		var aspect_inv = Math.min(w / h, h / w);

		var fovy = this.fov * aspect_inv;
		this.projection = Mat4.from_perspective(fovy, aspect, this.near, this.far);

		this.frustum = (this.projection * this.view).to_frustum();
	}
}
