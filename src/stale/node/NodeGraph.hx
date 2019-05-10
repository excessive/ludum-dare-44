package node;

import node.Node.Socket;
import node.Node.Wire;
import math.Vec3;

typedef NodeProgram = Array<Array<Node>>;

class NodeGraph {
	public var name: String;
	public var nodes:      Array<Node> = [];
	public var connections = new Map<Socket, Wire>();
	public var output_cons = new Map<Socket, Array<Wire>>();

	// event name -> output nodes
	public var events   = new Map<String, Array<Node>>();
	public var programs = new Map<String, Array<NodeProgram>>();

	private function validate(basis: Node, node: Node, ?depth: Int): Bool {
		if (node == basis) {
			return false;
		}

		for (socket in node.inputs) {
			var next_wire = connections.get(socket);

			if (next_wire != null) {
				if (!validate(basis, next_wire.input.node, depth + 1)) {
					return false;
				}
			}
		}

		return true;
	}

	public inline function new(_name: String) {
		name = _name;
	}

	public function add(node: Node, ?position: Vec3): Node {
		node.position = position != null ? position : new Vec3(0, 0, 0);

		for (socket in node.inputs) {
			socket.node = node;
		}

		for (socket in node.outputs) {
			socket.node = node;
		}

		nodes.push(node);

		return node;
	}

	public function remove(node: Node) {
		for (socket in node.outputs) {
			disconnect(socket);
		}
		for (socket in node.inputs) {
			disconnect(socket);
		}
		nodes.remove(node);
		compile();
	}

	public function is_connected(socket: Socket) {
		return connections.exists(socket) || (output_cons.exists(socket) && output_cons[socket].length > 0);
	}

	/** returns true if a disconnection was made **/
	public function disconnect(socket: Socket) {
		var wire = connections[socket];
		if (wire != null) {
			if (output_cons.exists(wire.input)) {
				var out = output_cons[wire.input];
				out.remove(wire);
				if (out.length == 0) {
					output_cons.remove(wire.input);
				}
			}
			connections.remove(wire.output);
			return true;
		}
		return false;
	}

	public function connect(from: Socket, to: Socket): Wire {
		if (from.type != to.type) { return null; }

		if (validate(to.node, from.node, 0)) {
			var wire: Wire = {
				input:  from,
				output: to
			}

			connections[to] = wire;
			if (!output_cons.exists(from)) {
				output_cons[from] = [];
			}
			output_cons[from].push(wire);
			return wire;
		}

		return null;
	}

	function trace_path(program: NodeProgram, base: Node, node: Node, depth: Int) {
		if (program != null) {
			if (program[depth] == null) {
				program[depth] = [];
			}
			program[depth].push(node);
			node.active = true;
		}
		else if (node.events.length > 0) {
			for (event in node.events) {
				var ev = events[event];
				if (ev.indexOf(base) < 0) {
					ev.push(base);
				}
			}
		}

		for (socket in node.inputs) {
			var next_wire = connections.get(socket);

			if (next_wire != null) {
				trace_path(program, base, next_wire.input.node, depth + 1);
			}
		}
	}

	public function compile(): Bool {
		var outputs: Array<Node> = [];

		for (event in events.keys()) {
			events.remove(event);
		}

		for (node in nodes) {
			node.active = false;
			for (event in node.events) {
				if (!events.exists(event)) {
					events[event] = [];
				}
			}
			if (node.is_output) {
				outputs.push(node);
			}
		}

		if (outputs.length == 0) {
			return false;
		}

		for (node in outputs) {
			trace_path(null, node, node, 0);
		}

		for (event in events.keys()) {
			var nodes = events[event];
			var program = [];
			programs[event] = [];
			for (node in nodes) {
				trace_path(program, node, node, 0);
				programs[event].push(program);
			}
		}

		return true;
	}

	public inline function serialize(): String {
		return NodeGraphIO.serialize(this);
	}

	public static inline function deserialize(data: String): NodeGraph {
		return NodeGraphIO.deserialize(data);
	}

	public function execute(?event: String) {
		if (event == null) {
			for (e in events.keys()) {
				execute(e);
			}
			return;
		}

		if (!events.exists(event)) {
			return;
		}

		var event_programs = programs[event];
		if (event_programs == null) {
			return;
		}

		var bad_programs = [];

		for (program in event_programs) {
			var i = program.length;
			try {
				while (--i >= 0) {
					var level = program[i];
					for (node in level) {
						var connected = [];
						var skip = 0;
						var events = 0;
						var has_events = false;
						for (socket in node.inputs) {
							if (connections.exists(socket)) {
								connected.push(true);
								var wire = connections[socket];
								node.values[socket.index] = wire.input.node.computed[wire.input.index];
							}
							else {
								connected.push(false);
								node.values[socket.index] = node.defaults[socket.index];
							}
							if (socket.type == "event") {
								var val: Bool = cast node.values[socket.index];
								has_events = true;
								events++;
								if (!val) {
									skip++;
								}
							}
						}
						if (has_events && skip == events) {
							for (_ in node.inputs) {
								node.computed[i] = node.defaults[i];
							}
							continue;
						}
						if (node.evaluate != null) {
							#if lua
							node.computed = untyped __lua__("{0}:evaluate({0}, {1}, {2})", node, node.values, connected);
							#else
							node.computed = node.evaluate(node.values, connected);
							#end
							if (node.outputs.length != node.computed.length) {
								throw "sdkljfhsdkfjg";
							}
						}
					}
				}
			}
			catch (err: String) {
				trace("NODE ERROR: " + err);
				bad_programs.push(program);
			}
		}

		for (program in bad_programs) {
			event_programs.remove(program);
		}
	}
}
