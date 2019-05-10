package editor.operators;

import exwidgets.Operator;

class Scene implements Operator {
	public inline function new() {}
	public function register() {
		return [
			"scene.new" => () -> {
				// Sys.exit(0);
				return false;
			},
			"scene.load" => () -> {
				// Sys.exit(0);
				return false;
			},
			"scene.save" => () -> {
				// Sys.exit(0);
				return false;
			},
			"scene.quit" => () -> {
				Sys.exit(0);
				return true;
			}
		];
	}
}
