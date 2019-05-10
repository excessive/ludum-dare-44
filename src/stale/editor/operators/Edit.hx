package editor.operators;

import exwidgets.Operator;

class Edit implements Operator {
	public inline function new() {}
	public function register() {
		return [
			"editor.toggle" => () -> {
				GameInput.spin_lock();
				return true;
			}
		];
	}
}
