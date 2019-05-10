package node.internal;

import math.Vec3;
import node.Node.Socket;

class Vec3Nodes {
	public static function add(type) {
		return new Node({
			type: type,
			name:     "Add",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [a + b];
			}
		});
	}

	public static function sub(type) {
		return new Node({
			type: type,
			name:     "Subtract",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [a - b];
			}
		});
	}

	public static function mul(type) {
		return new Node({
			type: type,
			name:     "Multiply",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [a * b];
			}
		});
	}

	public static function div(type) {
		return new Node({
			type: type,
			name:     "Divide",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [a / b];
			}
		});
	}

	public static function fdiv(type) {
		return new Node({
			type: type,
			name:     "Divide",
			inputs:   [
				new Socket("A", "vec3",  0),
				new Socket("B", "float", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3  = cast inputs[0];
				var b: Float = cast inputs[1];

				return [a / b];
			}
		});
	}

	public static function scale(type) {
		return new Node({
			type: type,
			name:     "Scale",
			inputs:   [
				new Socket("A", "vec3",  0),
				new Socket("B", "float", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3  = cast inputs[0];
				var b: Float = cast inputs[1];

				return [a * b];
			}
		});
	}

	public static function neg(type) {
		return new Node({
			type: type,
			name:     "Negate",
			inputs:   [
				new Socket("A", "vec3", 0)
			],
			defaults: [
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];

				return [-a];
			}
		});
	}

	public static function eq(type) {
		return new Node({
			type: type,
			name:     "Equal",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "bool", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [a == b];
			}
		});
	}

	public static function near(type) {
		return new Node({
			type: type,
			name:     "Near",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1),
				new Socket("Threshold", "float", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0),
				0
			],
			outputs:  [
				new Socket("Value", "bool", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3  = cast inputs[0];
				var b: Vec3  = cast inputs[1];
				var c: Float = cast inputs[2];

				return [Vec3.near(a, b, c)];
			}
		});
	}

	public static function length(type) {
		return new Node({
			type: type,
			name:     "Length",
			inputs:   [
				new Socket("A", "vec3", 0)
			],
			defaults: [
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "float", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];

				return [a.length()];
			}
		});
	}

	public static function lengthsq(type) {
		return new Node({
			type: type,
			name:     "Length Squared",
			inputs:   [
				new Socket("A", "vec3", 0)
			],
			defaults: [
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "float", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];

				return [a.lengthsq()];
			}
		});
	}

	public static function normalize(type) {
		return new Node({
			type: type,
			name:     "Normalize",
			inputs:   [
				new Socket("A", "vec3", 0)
			],
			defaults: [
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				a = a.copy();
				a.normalize();

				return [a];
			}
		});
	}

	public static function cross(type) {
		return new Node({
			type: type,
			name:     "Cross Product",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [Vec3.cross(a, b)];
			}
		});
	}

	public static function distance(type) {
		return new Node({
			type: type,
			name:     "Distance",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "float", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [Vec3.distance(a, b)];
			}
		});
	}

	public static function trim(type) {
		return new Node({
			type: type,
			name:     "Trim",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("Length", "float", 1),
			],
			defaults: [
				new Vec3(0, 0, 0),
				0
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3  = cast inputs[0];
				var b: Float = cast inputs[1];
				a = a.copy();
				a.trim(b);

				return [a];
			}
		});
	}

	public static function min(type) {
		return new Node({
			type: type,
			name:     "Minimum",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [Vec3.min(a, b)];
			}
		});
	}

	public static function max(type) {
		return new Node({
			type: type,
			name:     "Maximum",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [Vec3.max(a, b)];
			}
		});
	}

	public static function dot(type) {
		return new Node({
			type: type,
			name:     "Dot Product",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "float", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [Vec3.dot(a, b)];
			}
		});
	}

	public static function lerp(type) {
		return new Node({
			type: type,
			name:     "Linear Interpolation",
			inputs:   [
				new Socket("Start",    "vec3",  0),
				new Socket("Finish",   "vec3",  1),
				new Socket("Progress", "float", 2)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0),
				0
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3  = cast inputs[0];
				var b: Vec3  = cast inputs[1];
				var c: Float = cast inputs[2];

				return [Vec3.lerp(a, b, c)];
			}
		});
	}

	public static function project_on(type) {
		return new Node({
			type: type,
			name:     "Project On",
			inputs:   [
				new Socket("A", "vec3", 0),
				new Socket("B", "vec3", 1)
			],
			defaults: [
				new Vec3(0, 0, 0),
				new Vec3(0, 0, 0)
			],
			outputs:  [
				new Socket("Value", "vec3", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var a: Vec3 = cast inputs[0];
				var b: Vec3 = cast inputs[1];

				return [Vec3.project_on(a, b)];
			}
		});
	}
}
