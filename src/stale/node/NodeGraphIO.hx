package node;

import math.Vec3;
import haxe.Json;
import backend.Log;

typedef SavedGraph = {
	name: String,
	nodes: Array<{
		id: String,
		type: String,
		position: Array<Float>,
		values: Array<{
			type: String,
			data: Dynamic
		}>
	}>,
	connections: Array<{
		in_node: String,
		in_socket: Int,
		out_node: String,
		out_socket: Int
	}>
}

class NodeGraphIO {
	public static function serialize(graph: NodeGraph): String {
		var data: SavedGraph = {
			name: graph.name,
			nodes: [],
			connections: []
		}

		for (conn in graph.connections) {
			data.connections.push({
				in_node: conn.input.node.uuid,
				in_socket: conn.input.index,
				out_node: conn.output.node.uuid,
				out_socket: conn.output.index
			});
		}

		for (node in graph.nodes) {
			var values = [];
			for (i in 0...node.defaults.length) {
				var v = node.defaults[i];
				var t = node.inputs[i].type;
				// if (t == "number") {
				// 	v = Std.string(v);
				// }
				values.push({
					type: t,
					data: v
				});
			}
			data.nodes.push({
				id: node.uuid,
				type: NodeList.get_name(node.type),
				position: [ node.position.x, node.position.y ],
				values: values
			});
		}

		return Json.stringify(data, null, "\t");
	}

	public static function deserialize(data: String): NodeGraph {
		var name = "<unnamed>";

		var parsed: SavedGraph = Json.parse(data);
		if (parsed.name != "") {
			name = parsed.name;
		}
		var g = new NodeGraph(name);

		var nodes = new Map<String, Node>();
		for (node in parsed.nodes) {
			var id = node.id;
			var key = NodeList.get_key(node.type);
			switch (key) {
				case None: Log.write(Custom("Graph"), 'invalid node type ${node.type}');
				case Some(v): {
					var add = NodeList.create(v, new Vec3(node.position[0], node.position[1], 0));
					for (i in 0...node.values.length) {
						var v = node.values[i];
						if (v.type == add.inputs[i].type) {
							add.defaults[i] = v.data;
						}
					}
					g.add(add);
					nodes[id] = add;
				}
			}
		}

		for (conn in parsed.connections) {
			var in_node = nodes[conn.in_node];
			if (in_node == null) {
				Log.write(Custom("Graph"), "missing input node; skipping");
				continue;
			}

			var out_node = nodes[conn.out_node];
			if (out_node == null) {
				Log.write(Custom("Graph"), "missing output node; skipping");
				continue;
			}

			// from
			var in_socket = in_node.outputs[conn.in_socket];
			if (in_socket == null) {
				Log.write(Custom("Graph"), "missing input socket; skipping");
				continue;
			}

			// to
			var out_socket = out_node.inputs[conn.out_socket];
			if (out_socket == null) {
				Log.write(Custom("Graph"), "missing output socket; skipping");
				continue;
			}

			Log.write(Custom("Graph"), 'connecting ${in_socket.node.name}@${in_socket.index} to ${out_socket.node.name}@${out_socket.index}');
			g.connect(in_socket, out_socket);
		}

		return g;
	}
}
