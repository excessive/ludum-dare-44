package node.internal;

import node.Node.Socket;

class MathNodes {
	public static function eq() {
		return new Node({
			type: type,
			name:     "Equal",
			inputs:   [
				new Socket("A", "float", 0),
				new Socket("B", "float", 1)
			],
			defaults: [ 0, 0 ],
			outputs:  [
				new Socket("Equal", "bool", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					Math.abs(inputs[0] - inputs[1]) < 1e-9
				];
			}
		});
	}

	public static function add() {
		return new Node({
			type: type,
			name:     "Add",
			inputs:   [
				new Socket("A", "float", 0),
				new Socket("B", "float", 1)
			],
			defaults: [ 0, 0 ],
			outputs:  [
				new Socket("Value", "float", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					inputs[0] + inputs[1]
				];
			}
		});
	}

	public static function sub() {
		return new Node({
			type: type,
			name:     "Subtract",
			inputs:   [
				new Socket("A", "float", 0),
				new Socket("B", "float", 1)
			],
			defaults: [ 0, 0 ],
			outputs:  [
				new Socket("Value", "float", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					inputs[0] - inputs[1]
				];
			}
		});
	}

	public static function mul() {
		return new Node({
			type: type,
			name:     "Multiply",
			inputs:   [
				new Socket("A", "float", 0),
				new Socket("B", "float", 1)
			],
			defaults: [ 0, 0 ],
			outputs:  [
				new Socket("Value", "float", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					inputs[0] * inputs[1]
				];
			}
		});
	}

	public static function div() {
		return new Node({
			type: type,
			name:     "Divide",
			inputs:   [
				new Socket("A", "float", 0),
				new Socket("B", "float", 1)
			],
			defaults: [ 0, 0 ],
			outputs:  [
				new Socket("Value", "float", 0)
			],
			evaluate: function(inputs: Array<Dynamic>, connected: Array<Bool>): Array<Dynamic> {
				return [
					inputs[0] / inputs[1]
				];
			}
		});
	}
}
