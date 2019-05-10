package patchy;

@:luaRequire("patchy")
extern class Patchy {
	@:native("load")
	function new(filename: String) {}
	function draw(x: Float, y: Float, w: Float, h: Float): Void {}
}
