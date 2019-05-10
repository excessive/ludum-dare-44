package node.internal;

import node.Node.Socket;
import loaders.IqmLoader;

class DrawableNodes {
	public static function new_drawable(type) {
		return new Node({
			type: type,
			name:     "New Drawable",
			inputs:   [
				new Socket("Filename",  "string",  0),
			],
			defaults: [ "assets/models/debug/unit-sphere.iqm" ],
			outputs:  [
				new Socket("Drawable", "drawable", 0),
			],
			output_node: false,
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				var filename: String = cast inputs[0];
				return [
					IqmLoader.load_file(filename, false)
				];
			}
		});
	}
}
