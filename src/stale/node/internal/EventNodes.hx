package node.internal;

import node.Node.Socket;

class EventNodes {
	public static function load(type) {
		return new Node({
			type: type,
			name:     "Load",
			inputs:   [],
			defaults: [],
			outputs:  [
				new Socket("On Load", "event", 0, true, "load"),
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					true,
				];
			}
		});
	}

	public static function tick(type) {
		return new Node({
			type: type,
			name:     "Tick",
			inputs:   [],
			defaults: [],
			outputs:  [
				new Socket("Each Tick", "event", 0, true, "tick"),
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					true,
				];
			}
		});
	}

	public static function day(type) {
		return new Node({
			type: type,
			name:     "Day",
			inputs:   [],
			defaults: [],
			outputs:  [
				new Socket("Each Day", "event", 0, true, "day"),
				new Socket("Day", "float", 1),
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					true,
					Time.current_day
				];
			}
		});
	}
}
