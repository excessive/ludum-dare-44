package systems;

class ChainJoint {
	public var x: Float;
	public var y: Float;
	public var w: Float;
	public var x1: Float;
	public var y1: Float;
	public var l: Float = 0;
	public var s: Float = 0.1;
	public var vx: Float = 0;
	public var vy: Float = 0;
	public var bx: Float = 0;
	public var by: Float = 0;
	public inline function new(_x: Float, _y: Float, _w: Float = 0) {
		this.x = _x;
		this.y = _y;
		this.w = _w;
		this.x1 = this.x;
		this.y1 = this.y;
	}
}

class ChainPhysics {
	var joints: Array<ChainJoint>;

	inline function length(x: Float, y: Float) {
		return Math.sqrt((x*x) + (y*y));
	}

	inline function distance(x1: Float, y1: Float, x2: Float, y2: Float) {
		return length(x2 - x1, y2 - y1);
	}

	inline function new() {
		joints = [
			new ChainJoint(10, 40),
			new ChainJoint(10, 50,  0.1),
			new ChainJoint(10, 60,  0.2),
			new ChainJoint(10, 70,  0.4),
			new ChainJoint(10, 80,  0.8),
			new ChainJoint(10, 90,  0.8),
			new ChainJoint(10, 100, 0.8),
			new ChainJoint(10, 110, 0.8),
			new ChainJoint(10, 120, 0.8),
			new ChainJoint(10, 130, 0.8),
			new ChainJoint(10, 140, 0.8),
			new ChainJoint(10, 150, 0.8),
			new ChainJoint(10, 160, 0.8),
			new ChainJoint(10, 170, 0.8)
		];

		// joint init
		for (i in 0...joints.length) {
			var j = joints[i];
			j.x1 = j.x;
			j.y1 = j.y;
			j.vx = 0;
			j.vy = 0;
			if (i > 0) {
				var j1 = joints[i - 1];
				j.l = distance(j.x, j.y, j1.x, j1.y);
			}
		}
	}

	var mx: Float = 0;
	var my: Float = 0;

	public function update(dt: Float = 0.016667) {
		var gravity = 0.0;
		var drag    = 0.8;
		var stretch = 0.9;
		var bend    = 0.0;

		// target position
		var j0 = joints[0];
		j0.x = mx;
		j0.y = my;

		// base angle
		var angle = 0.0;
		var ux = Math.cos(angle);
		var uy = Math.sin(angle);
		for (i in 1...joints.length) {
			var j1 = joints[i - 1];
			var j = joints[i];
			var l = j.l;

			var cx = 0.0;
			var cy = 0.0;
			var ax = 0.0;
			var ay = gravity;

			// Estimate new positions
			j.x = j.x1 + drag * dt * j.vx + (dt*dt) * ax;
			j.y = j.y1 + drag * dt * j.vy + (dt*dt) * ay;
			j.bx = j.x;
			j.by = j.y;

			// Constant distance constraint
			var d = distance(j1.x, j1.y, j.x, j.y);
			if (d != 0 && d != l) {
				var a = stretch * (d - l) / d;
				var dx = a * (j1.x - j.x);
				var dy = a * (j1.y - j.y);

				j.x += dx;
				j.y += dy;

				// Velocity correction
				cx += j1.w * dx;
				cy += j1.w * dy;
			}

			// Shape constraint
			var tx = j1.x + ux * l;
			var ty = j1.y + uy * l;

			var a = bend * j.s;
			var dx = a * (tx - j.x);
			var dy = a * (ty - j.y);

			j.x += dx;
			j.y += dy;

			// Velocity correction
			cx += j1.w * dx;
			cy += j1.w * dy;

			ux = (j.x - j1.x) / l;
			uy = (j.y - j1.y) / l;

			// Update state
			j1.vx = (j1.x - j1.x1 - cx) / dt;
			j1.vy = (j1.y - j1.y1 - cy) / dt;

			j1.x1 = j1.x;
			j1.y1 = j1.y;
		}

		// Update root state
		var j = joints[joints.length - 1];
		j.vx = (j.x - j.x1) / dt;
		j.vy = (j.y - j.y1) / dt;

		j.x1 = j.x;
		j.y1 = j.y;
	}
}
