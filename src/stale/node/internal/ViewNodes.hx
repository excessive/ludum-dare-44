package node.internal;

import love.graphics.GraphicsModule as Lg;

import math.Quat;
import math.Vec2;
import math.Vec3;

import node.Node.Socket;
// import utils.Printf.format;

class ViewNodes {
	public static function number(type) {
		return new Node({
			type: type,
			name:     "View",
			inputs:   [
				new Socket("Number", "float", 0)
			],
			defaults: [0],
			outputs:  [],
			output_node: true,
			display_height: 20,
			// display: function(inputs: Array<Dynamic>, w: Float, h: Float) {
			// 	var v: String = cast inputs[0];

			// 	Lg.setColor(0, 0, 0, 1);
			// 	Lg.printf(v, 0, 0, w);
			// },
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [];
			}
		});
	}

	public static function string(type) {
		return new Node({
			type: type,
			name:     "View",
			inputs:   [
				new Socket("String", "string", 0)
			],
			defaults: [""],
			outputs:  [],
			output_node: true,
			display_height: 20,
			display: function(inputs: Array<Dynamic>, w: Float, h: Float) {
				var v: String = cast inputs[0];

				Lg.setColor(0, 0, 0, 1);
				Lg.printf(v, 0, 0, w);
			},
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [];
			}
		});
	}

	public static function vec2(type) {
		return new Node({
			type: type,
			name:     "View",
			inputs:   [
				new Socket("Vec2", "vec2", 0)
			],
			defaults: [new Vec2()],
			outputs:  [],
			output_node: true,
			display_height: 20,
			display: function(inputs: Array<Dynamic>, w: Float, h: Float) {
				var v: Vec2 = cast inputs[0];

				Lg.setColor(0, 0, 0, 1);
				// Lg.printf(format("[%0.3f,%0.3f]", [v.x, v.y]), 0, 0, w);
			},
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [];
			}
		});
	}

	public static function vec3(type) {
		return new Node({
			type: type,
			name:     "View",
			inputs:   [
				new Socket("Vec3", "vec3", 0)
			],
			defaults: [new Vec3(0, 0, 0)],
			outputs:  [],
			output_node: true,
			display_height: 20,
			display: function(inputs: Array<Dynamic>, w: Float, h: Float) {
				var v: Vec3 = cast inputs[0];

				Lg.setColor(0, 0, 0, 1);
				// Lg.printf(format("[%0.3f,%0.3f,%0.3f]", [v.x, v.y, v.z]), 0, 0, w);
			},
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [];
			}
		});
	}

	public static function quat(type) {
		return new Node({
			type: type,
			name:     "View",
			inputs:   [
				new Socket("Quat", "quat", 0)
			],
			defaults: [new Quat(0, 0, 0, 1)],
			outputs:  [],
			output_node: true,
			display_height: 20,
			display: function(inputs: Array<Dynamic>, w: Float, h: Float) {
				var v: Quat = cast inputs[0];

				Lg.setColor(0, 0, 0, 1);
				// Lg.printf(format("[%0.3f,%0.3f,%0.3f,%0.3f]", [v.x, v.y, v.z, v.w]), 0, 0, w);
			},
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [];
			}
		});
	}
}
