package node.internal;

import math.Vec3;
import node.Node.Socket;

class ConvertNodes {
	public static function separate_vec3(type) {
		return new Node({
			type: type,
			name:     "Separate",
			inputs:   [
				new Socket("Vec3", "vec3", 0)
			],
			defaults: [ new Vec3(0, 0, 0) ],
			outputs:  [
				new Socket("X", "float", 0),
				new Socket("Y", "float", 1),
				new Socket("Z", "float", 2)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var v: Vec3 = cast inputs[0];

				return [
					v.x,
					v.y,
					v.z,
				];
			}
		});
	}

	public static function combine_vec3(type) {
		return new Node({
			type: type,
			name:     "Combine",
			inputs:   [
				new Socket("X", "float", 0),
				new Socket("Y", "float", 1),
				new Socket("Z", "float", 2)
			],
			defaults: [ 0, 0, 0 ],
			outputs:  [
				new Socket("Vec3", "vec3", 0),
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					new Vec3(inputs[0], inputs[1], inputs[2])
				];
			}
		});
	}

	public static function branch(type) {
		return new Node({
			type: type,
			name:     "Branch",
			inputs:   [
				new Socket("Event",     "event", 0),
				new Socket("Condition", "bool",  1)
			],
			defaults: [ false, false ],
			outputs:  [
				new Socket("True",  "event", 0),
				new Socket("False", "event", 1),
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var c: Bool = cast inputs[1];

				return [ c, !c ];
			}
		});
	}
}
