package node.internal;

import math.Vec3;
import node.Node.Socket;

class ValueNodes {
	public static function string(type) {
		return new Node({
			type: type,
			name:     "Value",
			inputs:   [
				new Socket("String", "string", 0, true)
			],
			defaults: [ "" ],
			outputs:  [
				new Socket("String", "string", 0)
			],
			output_node: true,
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [ inputs[0] ];
			}
		});
	}

	public static function time(type) {
		return new Node({
			type: type,
			name:     "Value",
			inputs:   [],
			defaults: [],
			outputs:  [
				new Socket("Day", "float", 0),
				new Socket("Time", "float", 1),
				new Socket("Normalized", "float", 2)
			],
			output_node: true,
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					Time.current_day,
					Time.current_time.to_hour24f(),
					Time.current_time.to_hour24f() / 24
				];
			}
		});
	}

	public static function number(type) {
		return new Node({
			type: type,
			name:     "Value",
			inputs:   [
				new Socket("X", "float", 0, true),
			],
			defaults: [ 0 ],
			outputs:  [
				new Socket("Value", "float", 0),
			],
			output_node: true,
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					inputs[0]
				];
			}
		});
	}

	public static function vec3(type) {
		return new Node({
			type: type,
			name:     "Value",
			inputs:   [
				new Socket("Vec3", "vec3", 0, true),
			],
			defaults: [ new Vec3(0, 0, 0) ],
			outputs:  [
				new Socket("Vec3", "vec3", 0),
			],
			output_node: true,
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var val: Vec3 = cast inputs[0];
				return [
					val
				];
			}
		});
	}
}
