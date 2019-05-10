package node.internal;

import components.Transform;
import math.Vec3;
import math.Quat;
import node.Node.Socket;

class TxNodes {
	public static function new_transform(type) {
		return new Node({
			type: type,
			name:     "New Transform",
			inputs:   [
				new Socket("Transform",   "transform", 0),
				new Socket("Position",    "vec3",  1),
				new Socket("Velocity",    "vec3",  2),
				new Socket("Orientation", "quat",  3),
				new Socket("Scale",       "vec3",  4)
			],
			defaults: [ new Transform(), new Vec3(0, 0, 0), new Vec3(0, 0, 0), new Quat(0, 0, 0, 1), new Vec3(1, 1, 1) ],
			outputs:  [
				new Socket("Transform",   "transform", 0),
				new Socket("Position",    "vec3",  1),
				new Socket("Velocity",    "vec3",  2),
				new Socket("Orientation", "quat",  3),
				new Socket("Scale",       "vec3",  4)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var xform = new Transform();
				var base: Transform = cast inputs[0];

				if (connected[0]) {
					base = cast inputs[0];
				}
				xform.set_from(base);

				if (connected[1]) {
					var pos: Vec3 = cast inputs[1];
					xform.position.set_from(pos);
				}

				if (connected[2]) {
					var vel: Vec3 = cast inputs[2];
					xform.velocity.set_from(vel);
				}

				if (connected[3]) {
					var rot: Quat = cast inputs[3];
					xform.orientation.set_from(rot);
				}

				if (connected[4]) {
					var sca: Vec3 = cast inputs[4];
					xform.scale.set_from(sca);
				}

				return [
					xform,
					xform.position,
					xform.velocity,
					xform.orientation,
					xform.scale
				];
			}
		});
	}

	public static function get_transform(type) {
		return new Node({
			type: type,
			name:     "Get Transform",
			inputs:   [],
			defaults: [],
			outputs:  [
				new Socket("Transform",   "transform", 0),
				new Socket("Position",    "vec3",  1),
				new Socket("Velocity",    "vec3",  2),
				new Socket("Orientation", "quat",  3)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var e = Main.current_entity;

				return [
					e.transform,
					e.transform.position,
					e.transform.velocity,
					e.transform.orientation
				];
			}
		});
	}

	public static function set_transform(type) {
		return new Node({
			type: type,
			name:     "Set Transform",
			inputs:   [
				new Socket("Event",       "event", 0),
				new Socket("Transform",   "transform", 1),
				new Socket("Position",    "vec3",  2),
				new Socket("Velocity",    "vec3",  3),
				new Socket("Orientation", "quat",  4)
			],
			defaults: [ false, new Transform(), new Vec3(0, 0, 0), new Vec3(0, 0, 0), new Quat(0, 0, 0, 1) ],
			outputs:  [
				new Socket("Event", "event", 0),
			],
			output_node: true,
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var e = Main.current_entity;

				var event = false;
				if (connected[0]) {
					event = true;
				}

				if (connected[1]) {
					var xform: Transform = cast inputs[1];
					e.transform.set_from(xform);
				}

				if (connected[2]) {
					var pos: Vec3 = cast inputs[2];
					e.transform.position.set_from(pos);
				}

				if (connected[3]) {
					var vel: Vec3 = cast inputs[3];
					e.transform.velocity.set_from(vel);
				}

				if (connected[4]) {
					var rot: Quat = cast inputs[4];
					e.transform.orientation.set_from(rot);
				}

				return [
					event
				];
			}
		});
	}
}
