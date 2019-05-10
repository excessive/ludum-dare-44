package backend;

#if cpp
typedef NativeGame = backend.cpp.BaseGame;
#elseif lua
typedef NativeGame = backend.love.BaseGame;
#elseif hl
typedef NativeGame = backend.hl.BaseGame;
#end

typedef BaseGame = NativeGame;

enum GameEvent {
	MouseDown;
	MouseUp;
	MouseWheel;
	KeyDown;
	KeyUp;
	Resize;
	Load;
	Update;
	Draw;
}

class BaseGameX extends NativeGame {
	var on_load: Void->Void;
	var on_update: Void->Void;
	var on_draw: Void->Void;
	var on_resize: Void->Void;
	var on_keyup: Void->Void;
	var on_keydown: Void->Void;
	var on_mouseup: Void->Void;
	var on_mousedown: Void->Void;
	var on_mousewheel: Void->Void;
	public inline function hook(e: GameEvent, fn: Void->Void) {
		switch (e) {
			case Load: this.on_load = fn;
			case Update: this.on_update = fn;
			case Draw: this.on_draw = fn;
			case Resize: this.on_resize = fn;
			case KeyUp: this.on_keyup = fn;
			case KeyDown: this.on_keydown = fn;
			case MouseUp: this.on_mouseup = fn;
			case MouseDown: this.on_mousedown = fn;
			case MouseWheel: this.on_mousewheel = fn;
		}
	}
	override function quit(): Bool { return false; }
	override function load(window, args) { this.on_load(); }
	override function update(window, dt: Float) { this.on_update(); }
	override function mousepressed(x: Float, y: Float, button: Int) { this.on_mousedown(); }
	override function mousereleased(x: Float, y: Float, button: Int) { this.on_mouseup(); }
	override function wheelmoved(x: Float, y: Float) { this.on_mousewheel(); }
	override function keypressed(key: String, scan: String, isrepeat: Bool) { this.on_keydown(); }
	override function keyreleased(key: String, scan: String) { this.on_keyup(); }
	override function resize(w, h) { this.on_resize(); }
	override function draw(window) { this.on_draw(); }
}
