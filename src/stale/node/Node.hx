package node;

import math.Vec3;
import backend.Timer;
import node.NodeList;

private class UUID {
	public static function uuid() {
		// Based on https://gist.github.com/LeverOne/1308368
		var uid = new StringBuf(), a = 8;
		uid.add(StringTools.hex(Std.int(Timer.get_time()), 8));
		while((a++) < 36) {
			uid.add(a*51 & 52 != 0
				? StringTools.hex(a^15 != 0 ? 8^Std.int(Math.random() * (a^20 != 0 ? 16 : 4)) : 4)
				: "-"
			);
		}
		return uid.toString().toLowerCase();
	}
}

typedef Wire = {
	var input:  Socket;
	var output: Socket;
}

@:publicFields
class Socket {
	var label: String;
	var type:  String;
	var index: Int;
	var hidden: Bool;
	var uuid:  String;
	var node:  Node;
	var event: String;
	function new(_label: String, _type: String, _index: Int, _hidden: Bool = false, ?_event: String, ?_uuid: String) {
		label = _label;
		type = _type;
		index = _index;
		hidden = _hidden;
		event = _event;
		if (_uuid != null) {
			uuid = _uuid;
		}
		else {
			uuid = UUID.uuid();
		}
		node = null;
	}
}

typedef EvaluateCb = Array<Dynamic>->Array<Bool>->Array<Dynamic>;
typedef DisplayCb = Array<Dynamic>->Float->Float->Void;

typedef NodeParams = {
	var type:     NodeType;
	var name:     String;
	var inputs:   Array<Socket>;
	var outputs:  Array<Socket>;
	var evaluate: EvaluateCb;
	var defaults: Array<Dynamic>;
	@:optional var output_node: Bool;
	@:optional var display_height: Float;
	@:optional var display: DisplayCb;
	@:optional var uuid:   String;
}

class Node {
	// UI stuff
	public var position: Vec3 = new Vec3(0, 0, 0);
	public var drag_start: Vec3;
	public var active: Bool;
	public var display: Null<DisplayCb>;
	public var display_height: Null<Float>;

	public var type: NodeType;

	// actual node data
	public var name:     String;
	public var inputs:   Array<Socket>;
	public var outputs:  Array<Socket>;
	public var defaults: Array<Dynamic>;
	public var evaluate: Null<EvaluateCb>;

	public var events: Array<String> = [];

	var output_node: Bool = false;
	public var is_output(get, never): Bool;
	inline function get_is_output() return output_node;

	public var is_event(get, never): Bool;
	inline function get_is_event() return events.length > 0 && !output_node;

	public var uuid:     String;
	public var values:   Array<Dynamic> = [];
	public var computed: Array<Dynamic> = [];

	public function new(params: NodeParams) {
		if (params.uuid == null) {
			this.uuid = UUID.uuid();
		} else {
			this.uuid = params.uuid;
		}

		this.type     = params.type;
		this.name     = params.name;
		this.inputs   = params.inputs;
		this.outputs  = params.outputs;
		this.evaluate = params.evaluate;
		this.defaults = params.defaults;
		this.display  = params.display;
		this.output_node = params.output_node;
		this.display_height = params.display_height;
		for (v in values) {
			values.push(v);
		}
		for (socket in outputs) {
			if (socket.event != null) {
				events.push(socket.event);
			}
		}
		// assert(defaults.length == inputs.length, "All inputs must have a default value");
	}

	function input(uuid: String): Socket {
		for (socket in inputs) {
			if (socket.uuid == uuid) {
				return socket;
			}
		}

		return null;
	}

	function output(uuid: String): Socket {
		for (socket in outputs) {
			if (socket.uuid == uuid) {
				return socket;
			}
		}

		return null;
	}
}
