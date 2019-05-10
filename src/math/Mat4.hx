package math;

#if lua
import lua.Table;
#end

#if 0
abstract Mat4(Table<Int, FloatType>) {
	@:nullSafety(false)
	public inline function new(?data: Array<Float>) {
		if (data == null) {
			this = untyped __lua__("{
				[0] = 1.0, 0.0, 0.0, 0.0,
				0.0, 1.0, 0.0, 0.0,
				0.0, 0.0, 1.0, 0.0,
				0.0, 0.0, 0.0, 1.0
			}");
		}
		else {
			this = untyped __lua__("{0}", data);
		}
	}
#else
abstract Mat4(Array<FloatType>) {
	public static inline function from_identity(): Mat4 {
		return new Mat4([
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		]);
	}

	public inline function new(data: Array<Float>) {
#if lua
		this = untyped __lua__("{0}", data);
#else
		this = [
			data[0], data[1], data[2], data[3],
			data[4], data[5], data[6], data[7],
			data[8], data[9], data[10], data[11],
			data[12], data[13], data[14], data[15],
		];
#end
	}
#end

	public inline function to_array(): Array<FloatType> {
		return this;
	}

	public function identity() {
		for (i in 0...16) {
			this[i] = 0;
		}
		for (i in 0...3) {
			this[i+i*4] = 1;
		}
	}

	public static function scale(s: Vec3) {
		return new Mat4([
			s.x, 0, 0, 0,
			0, s.y, 0, 0,
			0, 0, s.z, 0,
			0, 0, 0, 1
		]);
	}

	public static function translate(t: Vec3) {
		return new Mat4([
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			t.x, t.y, t.z, 1
		]);
	}

	public static inline function rotate(q: Quat) {
		var a = q.to_angle_axis();
		return from_angle_axis(a.angle, a.axis);
	}

	public static function project(obj: Vec3, mvp: Mat4, viewport: Vec4): Vec3 {
		var position = mvp.mul_vec3_w1(obj).w_div();
		position.x = position.x * 0.5 + 0.5;
		position.y = position.y * 0.5 + 0.5;
		position.z = position.z * 0.5 + 0.5;
		position.x = position.x * viewport.z + viewport.x;
		position.y = position.y * viewport.w + viewport.y;
		return position;
	}

	public static function from_st(translate: Vec3, scale: Vec3) {
		var sx = scale.x;
		var sy = scale.x;
		var sz = scale.x;

		return new Mat4([
			sx, 0, 0, 0,
			0, sy, 0, 0,
			0, 0, sz, 0,
			translate.x, translate.y, translate.z, 1
		]);
	}

	public static function from_srt(translate: Vec3, rotate: Quat, scale: Vec3) {
		var sx = scale.x;
		var sy = scale.y;
		var sz = scale.z;
		var unscaled = sx == 1 && sy == 1 && sz == 1;

		var _tx = translate.x;
		var _ty = translate.y;
		var _tz = translate.z;

		var aa = rotate.to_angle_axis();
		var axis = aa.axis;
		var l = axis.lengthsq();
		if (l > 0) {
			var angle = aa.angle;
			l = Math.sqrt(l);

			var x = axis.x / l;
			var y = axis.y / l;
			var z = axis.z / l;
			var c = Math.cos(angle);
			var s = Math.sin(angle);
			var c1 = 1.0-c;

			// no scaling, oriented
			if (unscaled) {
				return new Mat4([
					x*x*c1+c,   y*x*c1+z*s, x*z*c1-y*s, 0,
					x*y*c1-z*s, y*y*c1+c,   y*z*c1+x*s, 0,
					x*z*c1+y*s, y*z*c1-x*s, z*z*c1+c,   0,
					_tx, _ty, _tz, 1
				]);
			}
			// scaling, oriented (slowest case)
			else {
				return new Mat4([
					sx*(x*x*c1+c),   sy*(y*x*c1+z*s), sz*(x*z*c1-y*s), 0,
					sx*(x*y*c1-z*s), sy*(y*y*c1+c),   sz*(y*z*c1+x*s), 0,
					sx*(x*z*c1+y*s), sy*(y*z*c1-x*s), sz*(z*z*c1+c),   0,
					_tx, _ty, _tz, 1
				]);
			}
		}

		// scale+translate: fast case
		return new Mat4([
			sx, 0, 0, 0,
			0, sy, 0, 0,
			0, 0, sz, 0,
			_tx, _ty, _tz, 1
		]);
	}

	public static function look_at2(eye: Vec3, at: Vec3, up: Vec3) {
		var forward = (eye - at);
		forward.normalize();
		
		// Check if look direction is parallel to the up vector, if so, shuffle up vector elements
		if ((forward + up) == new Vec3(0, 0, 0)) {
			up *= 0;
		}
		
		var z_axis = forward;
		var x_axis = Vec3.cross(up , z_axis);
		x_axis.normalize();
		var y_axis = Vec3.cross(z_axis, x_axis);
		
		return new Mat4([
			x_axis.x, y_axis.x, z_axis.x, 0,
			x_axis.y, y_axis.y, z_axis.y, 0,
			x_axis.z, y_axis.z, z_axis.z, 0,
			eye.x, eye.y, eye.z, 1
		]);
	}

	public static function look_at(eye: Vec3, at: Vec3, up: Vec3, ?tilt: Quat) {
		var forward = at - eye;
		if (tilt != null) {
			forward = tilt * forward;
			up = tilt * up;
		}
		forward.normalize();
		var side = Vec3.cross(forward, up);
		side.normalize();
		var new_up = Vec3.cross(side, forward);

		return new Mat4([
			side.x, new_up.x, -forward.x, 0,
			side.y, new_up.y, -forward.y, 0,
			side.z, new_up.z, -forward.z, 0,
			-Vec3.dot(side, eye), -Vec3.dot(new_up, eye), Vec3.dot(forward, eye), 1
		]);
	}

	public static function inverse(a: Mat4): Mat4 {
		var out: Mat4 = a.copy();
		out.invert();
		return out;
	}

	public function invert() {
		var out = new Mat4([
			 this[5] * this[10] * this[15] - this[5] * this[11] * this[14] - this[9]  * this[6] * this[15] + this[9]  * this[7] * this[14] + this[13] * this[6] * this[11] - this[13] * this[7] * this[10],
			-this[1] * this[10] * this[15] + this[1] * this[11] * this[14] + this[9]  * this[2] * this[15] - this[9]  * this[3] * this[14] - this[13] * this[2] * this[11] + this[13] * this[3] * this[10],
			 this[1] * this[6]  * this[15] - this[1] * this[7]  * this[14] - this[5]  * this[2] * this[15] + this[5]  * this[3] * this[14] + this[13] * this[2] * this[7]  - this[13] * this[3] * this[6],
			-this[1] * this[6]  * this[11] + this[1] * this[7]  * this[10] + this[5]  * this[2] * this[11] - this[5]  * this[3] * this[10] - this[9]  * this[2] * this[7]  + this[9]  * this[3] * this[6],
			-this[4] * this[10] * this[15] + this[4] * this[11] * this[14] + this[8]  * this[6] * this[15] - this[8]  * this[7] * this[14] - this[12] * this[6] * this[11] + this[12] * this[7] * this[10],
			 this[0] * this[10] * this[15] - this[0] * this[11] * this[14] - this[8]  * this[2] * this[15] + this[8]  * this[3] * this[14] + this[12] * this[2] * this[11] - this[12] * this[3] * this[10],
			-this[0] * this[6]  * this[15] + this[0] * this[7]  * this[14] + this[4]  * this[2] * this[15] - this[4]  * this[3] * this[14] - this[12] * this[2] * this[7]  + this[12] * this[3] * this[6],
			 this[0] * this[6]  * this[11] - this[0] * this[7]  * this[10] - this[4]  * this[2] * this[11] + this[4]  * this[3] * this[10] + this[8]  * this[2] * this[7]  - this[8]  * this[3] * this[6],
			 this[4] * this[9]  * this[15] - this[4] * this[11] * this[13] - this[8]  * this[5] * this[15] + this[8]  * this[7] * this[13] + this[12] * this[5] * this[11] - this[12] * this[7] * this[9],
			-this[0] * this[9]  * this[15] + this[0] * this[11] * this[13] + this[8]  * this[1] * this[15] - this[8]  * this[3] * this[13] - this[12] * this[1] * this[11] + this[12] * this[3] * this[9],
			 this[0] * this[5]  * this[15] - this[0] * this[7]  * this[13] - this[4]  * this[1] * this[15] + this[4]  * this[3] * this[13] + this[12] * this[1] * this[7]  - this[12] * this[3] * this[5],
			-this[0] * this[5]  * this[11] + this[0] * this[7]  * this[9]  + this[4]  * this[1] * this[11] - this[4]  * this[3] * this[9]  - this[8]  * this[1] * this[7]  + this[8]  * this[3] * this[5],
			-this[4] * this[9]  * this[14] + this[4] * this[10] * this[13] + this[8]  * this[5] * this[14] - this[8]  * this[6] * this[13] - this[12] * this[5] * this[10] + this[12] * this[6] * this[9],
			 this[0] * this[9]  * this[14] - this[0] * this[10] * this[13] - this[8]  * this[1] * this[14] + this[8]  * this[2] * this[13] + this[12] * this[1] * this[10] - this[12] * this[2] * this[9],
			-this[0] * this[5]  * this[14] + this[0] * this[6]  * this[13] + this[4]  * this[1] * this[14] - this[4]  * this[2] * this[13] - this[12] * this[1] * this[6]  + this[12] * this[2] * this[5],
			 this[0] * this[5]  * this[10] - this[0] * this[6]  * this[9]  - this[4]  * this[1] * this[10] + this[4]  * this[2] * this[9]  + this[8]  * this[1] * this[6]  - this[8]  * this[2] * this[5]
		]);

		var det: FloatType = this[0] * out[0] + this[1] * out[4] + this[2] * out[8] + this[3] * out[12];

		if (det == 0) {
			return;
		}

		det = 1 / det;

		for (i in 0...16) {
			this[i] = out[i] * det;
		}
	}

	// TODO: remove allocation
	public inline function transpose() {
		this = [
			this[0], this[4], this[8], this[12],
			this[1], this[5], this[9], this[13],
			this[2], this[6], this[10], this[14],
			this[3], this[7], this[11], this[15],
		];
	}

	public static function from_angle_axis(angle: Float, axis: Vec3) {
		var l = axis.lengthsq();
		if (l == 0) {
			return Mat4.from_identity();
		}
		l = Math.sqrt(l);

		var x = axis.x / l;
		var y = axis.y / l;
		var z = axis.z / l;
		var c = Math.cos(angle);
		var s = Math.sin(angle);

		return new Mat4([
			x*x*(1-c)+c,   y*x*(1-c)+z*s, x*z*(1-c)-y*s, 0,
			x*y*(1-c)-z*s, y*y*(1-c)+c,   y*z*(1-c)+x*s, 0,
			x*z*(1-c)+y*s, y*z*(1-c)-x*s, z*z*(1-c)+c,   0,
			0, 0, 0, 1
		]);
	}

	public static function from_ortho(left: Float, right: Float, top: Float, bottom: Float, near: Float, far: Float) {
		return new Mat4([
			2 / (right - left), 0, 0, 0,
			0, 2 / (top - bottom), 0, 0,
			0, 0, -2 / (far - near), 0,
			-((right + left) / (right - left)), -((top + bottom) / (top - bottom)), -((far + near) / (far - near)), 1
		]);
	}

	public static function from_perspective(fovy: Float, aspect: Float, near: Float, far: Float) {
		var t = Math.tan(Utils.rad(fovy) / 2);
		return new Mat4([
			1 / (t * aspect), 0, 0, 0,
			0, 1 / t, 0, 0,
			0, 0, -(far + near) / (far - near), -1,
			0, 0,  -(2 * far * near) / (far - near), 0
		]);
	}

	public function set_clips(near: Float, far: Float) {
		this[10] = -(far + near) / (far - near);
		this[14] = -(2 * far * near) / (far - near);
	}

#if lua
	public static function from_cpml(t: lua.Table<Int, Float>) {
		return new Mat4([
			t[1], t[2], t[3], t[4],
			t[5], t[6], t[7], t[8],
			t[9], t[10], t[11], t[12],
			t[13], t[14], t[15], t[16]
		]);
	}
#end

	public static inline function bias(amount: Float = 0.0) {
		return new Mat4([
			0.5, 0.0, 0.0, 0.0,
			0.0, 0.5, 0.0, 0.0,
			0.0, 0.0, 0.5, 0.0,
			0.5, 0.5, 0.5, 1.0 + amount
		]);
	}

	public inline function copy() {
		return new Mat4([
			this[0], this[1], this[2], this[3],
			this[4], this[5], this[6], this[7],
			this[8], this[9], this[10], this[11],
			this[12], this[13], this[14], this[15],
		]);
	}

	public function to_quat(): Quat {
		// 00 01 02 03   0  1  2  3
		// 10 11 12 13   4  5  6  7
		// 20 21 22 23   8  9 10 11
		// 30 31 32 33  12 13 14 15
		// var m00 = this[0];
		// var m11 = this[5];
		// var m22 = this[10];
		// var m21 = this[9];
		// var m12 = this[6];
		// var m02 = this[2];
		// var m20 = this[8];
		// var m01 = this[1];
		// var m10 = this[4];
		// 00 10 20 30   0  1  2  3
		// 01 11 21 31   4  5  6  7
		// 02 12 22 32   8  9 10 11
		// 03 13 23 33  12 13 14 15
		var m00 = this[0];
		var m11 = this[5];
		var m22 = this[10];
		var m21 = this[6];
		var m12 = this[9];
		var m02 = this[8];
		var m20 = this[2];
		var m01 = this[4];
		var m10 = this[1];

		var q = new Quat(0, 0, 0, 1);
		var t: Float = m00 + m11 + m22;
		if( t > 0.0 ) {
			var s: Float = 0.5 / Math.sqrt(t + 1.0);
			q.w = 0.25 / s;
			q.x = ( m21 - m12 ) * s;
			q.y = ( m02 - m20 ) * s;
			q.z = ( m10 - m01 ) * s;
			return q;
		}
		if ( m00 > m11 && m00 > m22 ) {
			var s: Float = 2.0 * Math.sqrt( 1.0 + m00 - m11 - m22);
			q.w = (m21 - m12 ) / s;
			q.x = 0.25 * s;
			q.y = (m01 + m10 ) / s;
			q.z = (m02 + m20 ) / s;
		} else if (m11 > m22) {
			var s: Float = 2.0 * Math.sqrt( 1.0 + m11 - m00 - m22);
			q.w = (m02 - m20 ) / s;
			q.x = (m01 + m10 ) / s;
			q.y = 0.25 * s;
			q.z = (m12 + m21 ) / s;
		} else {
			var s: Float = 2.0 * Math.sqrt( 1.0 + m22 - m00 - m11 );
			q.w = (m10 - m01 ) / s;
			q.x = (m02 + m20 ) / s;
			q.y = (m12 + m21 ) / s;
			q.z = 0.25 * s;
		}
		return q;
	}

#if lua
	public function to_vec4s(): Table<Int, Table<Int, Float>> {
		return untyped __lua__("{
			{ {0}[0], {0}[4],  {0}[8], {0}[12]  },
			{ {0}[1], {0}[5],  {0}[9], {0}[13]  },
			{ {0}[2], {0}[6], {0}[10], {0}[14] },
			{ {0}[3], {0}[7], {0}[11], {0}[15] }
		}", this);
	}
#end

	public function to_frustum_corners() {
		var inv = Mat4.inverse(cast this);

		return [
			inv * new Vec3(-1,  1, -1),
			inv * new Vec3( 1,  1, -1),
			inv * new Vec3( 1, -1, -1),
			inv * new Vec3(-1, -1, -1),
			inv * new Vec3(-1,  1, 1),
			inv * new Vec3( 1,  1, 1),
			inv * new Vec3( 1, -1, 1),
			inv * new Vec3(-1, -1, 1)
		];
	}

	public function to_frustum(infinite: Bool = false) {
		// Extract the LEFT plane
		var left = new Vec4(
			this[3]  + this[0],
			this[7]  + this[4],
			this[11] + this[8],
			this[15] + this[12]
		);
		left.normalize();

		// Extract the RIGHT plane
		var right = new Vec4(
			this[3]  - this[0],
			this[7]  - this[4],
			this[11] - this[8],
			this[15] - this[12]
		);
		right.normalize();

		// Extract the BOTTOM plane
		var bottom = new Vec4(
			this[3]  + this[1],
			this[7]  + this[5],
			this[11] + this[9],
			this[15] + this[13]
		);
		bottom.normalize();

		// Extract the TOP plane
		var top = new Vec4(
			this[3]  - this[1],
			this[7]  - this[5],
			this[11] - this[9],
			this[15] - this[13]
		);
		top.normalize();

		// Extract the NEAR plane
		var near = new Vec4(
			this[3]  + this[2],
			this[7]  + this[6],
			this[11] + this[10],
			this[15] + this[14]
		);
		near.normalize();

		if (!infinite) {
			// Extract the FAR plane
			var far = new Vec4(
				this[3]  - this[2],
				this[7]  - this[6],
				this[11] - this[10],
				this[15] - this[14]
			);
			far.normalize();

			return new Frustum({
				left: left,
				right: right,
				bottom: bottom,
				top: top,
				near: near,
				far: far
			});
		}

		return new Frustum({
			left: left,
			right: right,
			bottom: bottom,
			top: top,
			near: near,
			far: null
		});
	}

	@:arrayAccess
	public inline function get(k: Int): Float {
		return this[k];
	}

	@:arrayAccess
	public inline function set(k: Int, v: Float) {
		this[k] = v;
		return v;
	}

#if MAT4_PREMUL
	@:op(A * B)
#end
	public function mul(b: Mat4) {
		var out = Mat4.from_identity();
		var a = this;
		// Sys.exit(1);
		out[0]  = a[0]  * b[0] + a[1]  * b[4] + a[2]  *  b[8] +  a[3] * b[12];
		out[1]  = a[0]  * b[1] + a[1]  * b[5] + a[2]  *  b[9] +  a[3] * b[13];
		out[2]  = a[0]  * b[2] + a[1]  * b[6] + a[2]  * b[10] +  a[3] * b[14];
		out[3]  = a[0]  * b[3] + a[1]  * b[7] + a[2]  * b[11] +  a[3] * b[15];
		out[4]  = a[4]  * b[0] + a[5]  * b[4] + a[6]  *  b[8] +  a[7] * b[12];
		out[5]  = a[4]  * b[1] + a[5]  * b[5] + a[6]  *  b[9] +  a[7] * b[13];
		out[6]  = a[4]  * b[2] + a[5]  * b[6] + a[6]  * b[10] +  a[7] * b[14];
		out[7]  = a[4]  * b[3] + a[5]  * b[7] + a[6]  * b[11] +  a[7] * b[15];
		out[8]  = a[8]  * b[0] + a[9]  * b[4] + a[10] *  b[8] + a[11] * b[12];
		out[9]  = a[8]  * b[1] + a[9]  * b[5] + a[10] *  b[9] + a[11] * b[13];
		out[10] = a[8]  * b[2] + a[9]  * b[6] + a[10] * b[10] + a[11] * b[14];
		out[11] = a[8]  * b[3] + a[9]  * b[7] + a[10] * b[11] + a[11] * b[15];
		out[12] = a[12] * b[0] + a[13] * b[4] + a[14] *  b[8] + a[15] * b[12];
		out[13] = a[12] * b[1] + a[13] * b[5] + a[14] *  b[9] + a[15] * b[13];
		out[14] = a[12] * b[2] + a[13] * b[6] + a[14] * b[10] + a[15] * b[14];
		out[15] = a[12] * b[3] + a[13] * b[7] + a[14] * b[11] + a[15] * b[15];
		return out;
	}

#if !MAT4_PREMUL
	@:op(A * B)
#end
	public function mul_post(b: Mat4) {
		var out = Mat4.from_identity();
		var a = this;
#if MAT4_REFERENCE
		Sys.exit(0);
		inline function A(row,col) return a[(col<<2)+row];
		inline function B(row,col) return b[(col<<2)+row];
		inline function P(row,col) return (col<<2)+row;

		for (i in 0...4) {
			var ai0 = A(i,0), ai1=A(i,1), ai2=A(i,2), ai3=A(i,3);
			out[P(i,0)] = ai0 * B(0,0) + ai1 * B(1,0) + ai2 * B(2,0) + ai3 * B(3,0);
			out[P(i,1)] = ai0 * B(0,1) + ai1 * B(1,1) + ai2 * B(2,1) + ai3 * B(3,1);
			out[P(i,2)] = ai0 * B(0,2) + ai1 * B(1,2) + ai2 * B(2,2) + ai3 * B(3,2);
			out[P(i,3)] = ai0 * B(0,3) + ai1 * B(1,3) + ai2 * B(2,3) + ai3 * B(3,3);
		}
#else
		out[0]  = b[0]  * a[0] + b[1]  * a[4] + b[2]  *  a[8] +  b[3] * a[12];
		out[1]  = b[0]  * a[1] + b[1]  * a[5] + b[2]  *  a[9] +  b[3] * a[13];
		out[2]  = b[0]  * a[2] + b[1]  * a[6] + b[2]  * a[10] +  b[3] * a[14];
		out[3]  = b[0]  * a[3] + b[1]  * a[7] + b[2]  * a[11] +  b[3] * a[15];
		out[4]  = b[4]  * a[0] + b[5]  * a[4] + b[6]  *  a[8] +  b[7] * a[12];
		out[5]  = b[4]  * a[1] + b[5]  * a[5] + b[6]  *  a[9] +  b[7] * a[13];
		out[6]  = b[4]  * a[2] + b[5]  * a[6] + b[6]  * a[10] +  b[7] * a[14];
		out[7]  = b[4]  * a[3] + b[5]  * a[7] + b[6]  * a[11] +  b[7] * a[15];
		out[8]  = b[8]  * a[0] + b[9]  * a[4] + b[10] *  a[8] + b[11] * a[12];
		out[9]  = b[8]  * a[1] + b[9]  * a[5] + b[10] *  a[9] + b[11] * a[13];
		out[10] = b[8]  * a[2] + b[9]  * a[6] + b[10] * a[10] + b[11] * a[14];
		out[11] = b[8]  * a[3] + b[9]  * a[7] + b[10] * a[11] + b[11] * a[15];
		out[12] = b[12] * a[0] + b[13] * a[4] + b[14] *  a[8] + b[15] * a[12];
		out[13] = b[12] * a[1] + b[13] * a[5] + b[14] *  a[9] + b[15] * a[13];
		out[14] = b[12] * a[2] + b[13] * a[6] + b[14] * a[10] + b[15] * a[14];
		out[15] = b[12] * a[3] + b[13] * a[7] + b[14] * a[11] + b[15] * a[15];
#end

		return out;
	}

	public static function flip_yz() {
		return new Mat4([
			1, 0, 0, 0,
			0, 0,-1, 0,
			0, 1, 0, 0,
			0, 0, 0, 1
		]);
	}

	@:op(A * B)
	public function mul_vec3(b: Vec3) {
		var a: Mat4 = cast this;
		return new Vec3(
			b.x * a[0] + b.y * a[4] + b.z * a[8]  + a[12],
			b.x * a[1] + b.y * a[5] + b.z * a[9]  + a[13],
			b.x * a[2] + b.y * a[6] + b.z * a[10] + a[14]
		);
	}

	public function mul_floats(x: Float, y: Float, z: Float) {
		var a: Mat4 = cast this;
		return new Vec3(
			x * a[0] + y * a[4] + z * a[8]  + a[12],
			x * a[1] + y * a[5] + z * a[9]  + a[13],
			x * a[2] + y * a[6] + z * a[10] + a[14]
		);
	}

	public function mul_vec3_w1(b: Vec3) {
		return new Vec4(
			b.x * this[0] + b.y * this[4] + b.z * this[8]  + this[12],
			b.x * this[1] + b.y * this[5] + b.z * this[9]  + this[13],
			b.x * this[2] + b.y * this[6] + b.z * this[10] + this[14],
			b.x * this[3] + b.y * this[7] + b.z * this[11] + this[15]
		);
	}

	public function mul_vec3_w0(b: Vec3) {
		return new Vec4(
			b.x * this[0] + b.y * this[4] + b.z * this[8],
			b.x * this[1] + b.y * this[5] + b.z * this[9],
			b.x * this[2] + b.y * this[6] + b.z * this[10],
			b.x * this[3] + b.y * this[7] + b.z * this[11]
		);
	}

	public function mul_vec3_perspective(b: Vec3) {
		var a: Mat4 = cast this;
		var b4 = a.mul_vec3_w1(b);
		// var inv_w = 1.0 / b4.w;
		var inv_w = Utils.sign(b4.w)/b4.w;
		return new Vec3(b4.x * inv_w, b4.y * inv_w, b4.z * inv_w);
	}

	@:op(A * B)
	public function mul_array(b: Array<Float>) {
		var a: Mat4 = cast this;
		return a * new Vec3(b[0], b[1], b[2]);
	}

	@:op(A * B)
	public function mul_vec4(b: Vec4) {
		return new Vec4(
			b.x * this[0] + b.y * this[4] + b.z * this[8]  + this[12] * b.w,
			b.x * this[1] + b.y * this[5] + b.z * this[9]  + this[13] * b.w,
			b.x * this[2] + b.y * this[6] + b.z * this[10] + this[14] * b.w,
			b.x * this[3] + b.y * this[7] + b.z * this[11] + this[15] * b.w
		);
	}

	public function equal(that: Mat4) {
		for (i in 0...16) {
			if (Math.abs(this[i] - that[i]) > 1.0e-5) {
				return false;
			}
		}
		return true;
	}

	public static function coalesce(matrices: Array<Mat4>): Array<FloatType> {
		var buffer: Array<FloatType> = [];
		buffer.resize(matrices.length*16);
		var i = 0;
		for (m in matrices) {
			var a = m.to_array();
			for (j in 0...16) {
				buffer[i++] = a[j];
			}
		}
		return buffer;
	}
}
