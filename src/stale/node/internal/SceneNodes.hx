package node.internal;

import node.Node.Socket;
import math.Vec3;
import math.Quat;
import components.Drawable;
import components.Transform;

class SceneNodes {
	public static function add(type) {
		return new Node({
			type: type,
			name:     "Add Node",
			inputs:   [
				new Socket("Event",       "event", 0),
				new Socket("Drawable",    "drawable",  1),
				new Socket("Transform",   "transform",  2)
			],
			defaults: [ false, [], new Transform() ],
			outputs:  [
				new Socket("Event", "event", 0),
			],
			output_node: true,
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				if (!connected[0]) {
					return [ false ];
				}
				var node = new SceneNode();
				if (connected[1]) {
					var drawable: Drawable = cast inputs[1];
					node.drawable = drawable;
				}
				if (connected[2]) {
					var xform: Transform = cast inputs[2];
					node.transform.set_from(xform);
				}
				Main.scene.add(node);
				return [ true ];
			}
		});
	}
}
