package exwidgets;

class Editor {
	public var view: exwidgets.ui.View;

	public function clone() {
		return new Editor();
	}
	public inline function new() {}

	public function onKeyDown(k: String) {}
	public function onTextInput(t: String) {}

	public function onMouseMove(x: Int, y: Int, xrel: Int, yrel: Int) {}
	public function onMousePress(x: Int, y: Int, button: Int) {}
	public function onMouseRelease(x: Int, y: Int, button: Int) {}

	public function onMouseScroll(x: Int, y: Int) {}

	public function draw() {}
}
