package backend.love;

import love.math.MathModule as Lm;
import love.timer.TimerModule as Lt;
import love.graphics.GraphicsModule as Lg;
import love.audio.AudioModule as La;
import love.Love;
import love.event.EventModule as Event;
import love.keyboard.KeyboardModule as Keyboard;
import love.mouse.MouseModule as Mouse;

import backend.Window;
import backend.Profiler.SegmentColor;

import console.Console;

#if imgui
import imgui.Integration;
import imgui.ImGui;
#end

class GameLoop {
	static var window: Window;
	static var _game: BaseGame;
	static var _reload: BaseGame;
	public static var show_imgui: Bool = #if (debug && imgui) true #else false #end;

	static function load(args: Array<String>) {
		Anchor.update(window);
		_game.load(window, args);
	}

	static function update(dt: Float) {
		Anchor.update(window);
		Console.update(dt);
		_game.update(window, dt);
	}

	static function draw() {
		_game.draw(window);
		Console.draw(#if (debug && extra_debug) true #else false #end);
	}

	static function mousepressed(x: Float, y: Float, button: Float, istouch: Bool) {
#if imgui
		if (show_imgui && !Input.get_relative()) {
			Integration.mousepressed(button);
		}
#end

		_game.mousepressed(x, y, Std.int(button));
	}

	static function mousereleased(x: Float, y: Float, button: Float, istouch: Bool) {
#if imgui
		if (show_imgui && !Input.get_relative()) {
			Integration.mousereleased(button);
		}
#end

		_game.mousereleased(x, y, Std.int(button));
	}

	static function mousemoved(x: Float, y: Float, dx: Float, dy: Float, istouch: Bool) {
		if (!love.window.WindowModule.hasFocus()) {
			return;
		}

		Input.mx += dx;
		Input.my += dy;

#if imgui
		if (show_imgui && !Input.get_relative()) {
			Integration.mousemoved(x, y);
		}
#end

		_game.mousemoved(x, y, dx, dy);
	}

	static function wheelmoved(x: Float, y: Float) {
#if imgui
		if (show_imgui && !Input.get_relative()) {
			Integration.wheelmoved(y);
		}
#end

		_game.wheelmoved(x, y);
	}

	static function textinput(str: String) {
		if (!Console.textinput(str)) {
			_game.textinput(str);
		}
	}

	static function keypressed(key: String, scan: String, isrepeat: Bool) {
		if (Console.keypressed(key)) {
			return;
		}

		if (key == "escape" && Keyboard.isDown("lshift", "rshift")) {
			Event.quit();
		}

#if imgui
		if (show_imgui && !Input.get_relative() || key == "escape") {
			Integration.keypressed(key);
		}
#end

		_game.keypressed(key, scan, isrepeat);
	}

	static function keyreleased(key: String, scan: String) {
#if imgui
		if (show_imgui && !Input.get_relative()) {
			Integration.keyreleased(key);
		}
#end

		_game.keyreleased(key, scan);
	}

	static function resize(w: Float, h: Float) {
		Anchor.update(window);
		_game.resize(w, h);
		Console.resize(w, h);
	}

	public static var was_grabbed = false;
	static function focus(focused: Bool) {
		Console.focus(focused);
		Input.get_mouse_moved(true);
		Mouse.setRelativeMode(focused && was_grabbed);
	}

	static function quit(): Bool {
		if (!_game.quit()) {
#if imgui
			Integration.shutdown();
#end
			// haha fuck that segfault crash
			Sys.exit(0);
			return false;
		}
		return true;
	}

	static function real_run() {
		window = new Window();
		window.open(1024, 600);

#if imgui
		// var scale = love.window.WindowModule.getDPIScale();

		// ImGui.set_global_font("assets/fonts/Inconsolata-Regular.ttf", 16*scale, 0, 0, 2, 2);
		// Integration.set_global_font("assets/fonts/NotoSans-Regular.ttf", 16*scale, 0, 0, 2, 2);
		ImGui.push_color("Text", 1.00, 1.00, 1.00, 1.00);
		ImGui.push_color("WindowBg", 0.07, 0.07, 0.08, 0.98);
		ImGui.push_color("PopupBg", 0.07, 0.07, 0.08, 0.98);
		ImGui.push_color("CheckMark", 0.15, 1.0, 0.4, 0.91);
		ImGui.push_color("Border", 0.70, 0.70, 0.70, 0.20);
		ImGui.push_color("FrameBg", 0.80, 0.80, 0.80, 0.12);
		ImGui.push_color("FrameBgHovered", 0.04, 0.50, 0.78, 1.00);
		ImGui.push_color("FrameBgActive", 0.15, 0.52, 0.43, 1.00);
		ImGui.push_color("TitleBg", 0.15, 0.52, 0.43, 0.76);
		ImGui.push_color("TitleBgCollapsed", 0.11, 0.22, 0.23, 0.50);
		ImGui.push_color("TitleBgActive", 0.15, 0.52, 0.43, 1.00);
		ImGui.push_color("MenuBarBg", 0.07, 0.07, 0.11, 0.76);
		ImGui.push_color("ScrollbarBg", 0.26, 0.29, 0.33, 1.00);
		ImGui.push_color("ScrollbarGrab", 0.40, 0.43, 0.47, 0.76);
		ImGui.push_color("ScrollbarGrabHovered", 0.28, 0.81, 0.68, 0.76);
		ImGui.push_color("ScrollbarGrabActive", 0.96, 0.66, 0.06, 1.00);
		ImGui.push_color("SliderGrab", 0.28, 0.81, 0.68, 0.47);
		ImGui.push_color("SliderGrabActive", 0.96, 0.66, 0.06, 0.76);
		ImGui.push_color("Button", 0.22, 0.74, 0.61, 0.47);
		ImGui.push_color("ButtonHovered", 0.00, 0.48, 1.00, 1.00);
		ImGui.push_color("ButtonActive", 0.83, 0.57, 0.04, 0.76);
		ImGui.push_color("Header", 0.22, 0.74, 0.61, 0.47);
		ImGui.push_color("HeaderHovered", 0.07, 0.51, 0.92, 0.76);
		ImGui.push_color("HeaderActive", 0.96, 0.66, 0.06, 0.76);
		ImGui.push_color("Column", 0.22, 0.74, 0.61, 0.47);
		ImGui.push_color("ColumnHovered", 0.28, 0.81, 0.68, 0.76);
		ImGui.push_color("ColumnActive", 0.96, 0.66, 0.06, 1.00);
		ImGui.push_color("ResizeGrip", 0.22, 0.74, 0.61, 0.47);
		ImGui.push_color("ResizeGripHovered", 0.28, 0.81, 0.68, 0.76);
		ImGui.push_color("ResizeGripActive", 0.96, 0.66, 0.06, 0.76);
		ImGui.push_color("CloseButton", 0.00, 0.00, 0.00, 0.47);
		ImGui.push_color("CloseButtonHovered", 0.00, 0.00, 0.00, 0.76);
		ImGui.push_color("PlotLinesHovered", 0.22, 0.74, 0.61, 1.00);
		// ImGui.push_color("PlotHistogram", 0.78, 0.21, 0.21, 1.0);
		ImGui.push_color("PlotHistogram", 0.15, 0.52, 0.43, 1.00);
		ImGui.push_color("PlotHistogramHovered", 0.96, 0.66, 0.06, 1.00);
		ImGui.push_color("TextSelectedBg", 0.22, 0.74, 0.61, 0.47);
		ImGui.push_color("ModalWindowDarkening", 0.20, 0.20, 0.20, 0.69);

		Integration.new_frame();
		Profiler.load_zone();
#end

		Lm.setRandomSeed(lua.Os.time());
		var args = lua.Lib.tableToArray(untyped __lua__("arg"));
		args.splice(0, 1);

		var console_font = Lg.newFont("assets/fonts/Inconsolata-Regular.ttf", Console.fontSize);
		// console_font.setFallbacks(Lg.newFont("assets/fonts/unifont-7.0.06.ttf", Console.fontSize));
		Console.load(console_font);

		load(args);

		Love.mousepressed  = mousepressed;
		Love.mousereleased = mousereleased;
		Love.mousemoved    = mousemoved;
		Love.wheelmoved    = wheelmoved;
		Love.textinput     = textinput;
		Love.keypressed    = keypressed;
		Love.keyreleased   = keyreleased;
		Love.resize        = resize;
		Love.focus         = focus;

		// We don't want the first frame's dt to include time taken by love.load.
		Lt.step();

		var dt_samples = [ 0.0 ];

		// Main loop time.
		while (true) {
			Profiler.start_frame();

			// Process events.
			window.poll_events();
			untyped __lua__('
				for name, a,b,c,d,e,f in love.event.poll() do
					if name == "quit" then
						if not {0} or not {0}() then
							return a
						end
					end
					love.handlers[name](a,b,c,d,e,f)
				end
			', quit);

			// Update dt, as we'll be passing it to update
			Lt.step();
			// use average delta to try to compensate for frame timing issues
			var real_dt = Lt.getDelta();
			dt_samples.push(real_dt);

			var avg_dt = 0.0;
			for (dt in dt_samples) {
				avg_dt += dt;
			}
			avg_dt /= dt_samples.length;

			while (dt_samples.length > 5) {
				dt_samples.shift();
			}

			var dt = avg_dt;

			// use real dt if average is hosed
			// if (avg_dt > real_dt * 2) {
			// 	dt = real_dt;
			// }

			dt = Math.min(dt, 1/15);
			dt = Math.max(dt, 1/2000);

#if imgui
			if (Keyboard.isDown("tab")) {
				dt *= 4;
			}
#end

			// Call update and draw
			update(dt);

			if (_reload != null) {
				_game = _reload;
				_reload = null;
				La.stop();
				load(args);
				Lt.step();
				continue;
			}

			if (window.is_open()) {
				Lg.discard();
				// var bg = Lg.getBackgroundColor();
				// Lg.clear(bg.r, bg.g, bg.b, bg.a);
				Lg.origin();
				draw();

				Profiler.push_block("GC", new SegmentColor(0.5, 0.0, 0.0));
				Gc.run(false);
				Profiler.pop_block();

				Profiler.end_frame();
#if imgui
				Lg.setBlendMode(Alpha);
				if (show_imgui) {
					Integration.render();
				}
				Integration.new_frame();
#end
				window.present();
			}

			Lt.sleep(0.001);
		}
	}

	public static inline function change_game(game: BaseGame) {
		_reload = game;
	}

	public static inline function run(game: BaseGame) {
		Log.set_visibility(Debug, #if debug true #else false #end);
		_game = game;
		Love.run = real_run;
	}
}
