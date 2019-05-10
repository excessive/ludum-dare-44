package exwidgets;

// import math.Vec3;
// import math.Triangle;
// import exwidgets.Renderer.UiTriangle;
import exwidgets.ui.View;
import exwidgets.ui.Keybind;

@:nullSafety
class Context {
	var hit_views: Array<View> = [];
	public final root: View;
	var renderer(get, never): Renderer;
	inline function get_renderer() { return this.root.renderer; }
	var locked = false;

	public function new(renderer: Renderer, w: Int, h: Int) {
		this.root = new View(renderer, new exwidgets.Editor(), 0, 0, w, h);
		this.root.updateSplits();
		this.root.updateIndex(true);
	}

	public function input_locked(set: Bool) {
		this.locked = set;
		if (this.locked) {
			this.mouse_moved(-1, -1, 0, 0);
		}
	}

	public function key_pressed(key: String, is_repeat: Bool) {
		var name = key.toLowerCase();
		Keyboard.keystate.set(name, true);
		if (!is_repeat) {
			switch (Keyboard.focus) {
				case Some(widget): widget.keypressed(name);
				case None: Keybind.check();
			}
		}
	}

	public function key_released(key: String) {
		Keyboard.keystate.remove(key.toLowerCase());
	}

	public function text_input(str: String) {
		switch (Keyboard.focus) {
			case Some(widget): widget.textinput(str);
			case None:
		}
	}

	public function mouse_wheel(wx: Int, wy: Int) {
		var views = View.getViews();
		for (view in views) {
			if (view.active) {
				view.data.onMouseScroll(wx, wy);
			}
		}
	}

	public function mouse_pressed(mx: Int, my: Int, button: Int) {
		Keyboard.focus = None;
		var views = View.getViews();
		for (view in views) {
			var hit = view.hit(mx, my);
			if (hit != null) {
				hit_views.push(view);
				view.data.onMousePress(hit.x, hit.y, button);
			}
		}
	}

	public function mouse_released(mx: Int, my: Int, button: Int) {
		for (view in hit_views) {
			var hit = view.hit_free(mx, my);
			view.data.onMouseRelease(hit.x, hit.y, button);
		}
		hit_views.resize(0);
	}

	public function resize(w: Float, h: Float) {
		this.root.w = Std.int(w);
		this.root.h = Std.int(h);
		this.root.updateSplits();
	}

	function focus() {
		// case SDL_WINDOWEVENT_FOCUS_GAINED:
		// 	this.focused = true;
		// case SDL_WINDOWEVENT_FOCUS_LOST:
		// 	this.focused = false;
	}

	function hidden() {
		// case SDL_WINDOWEVENT_MINIMIZED:
		// 	this.hidden = true;
		// case SDL_WINDOWEVENT_RESTORED:
		// 	this.hidden = false;
	}

	public function mouse_moved(mx: Int, my: Int, dx: Int, dy: Int) {
		var views = View.getViews();
		var move_views = hit_views.copy();
		for (view in views) {
			if (view.active && move_views.indexOf(view) < 0) {
				move_views.push(view);
			}
		}
		for (view in move_views) {
			var hit = view.hit_free(mx, my);
			view.data.onMouseMove(hit.x, hit.y, dx, dy);
		}

		// update active flag if moving off a view
		var views = View.getViews();
		for (view in views) {
			var hit = view.hit(Std.int(mx), Std.int(my));
			if (view.active && hit == null) {
				view.dirty = true;
			}
			view.active = hit != null;
			if (view.active) {
				view.dirty = true;
			}
		}
	}

	public function draw() {
		var views = View.getViews();
		for (view in views) {
			if (!view.dirty) {
				// TODO: fix rendering problems when doing this.
				// continue;
			}
			view.dirty = false;

			// var _proj = MatrixUtils.fromOrtho(0, view.w, 0, view.h, -1, 1);
			// var _view = Matrix4x4.identity.clone();
			// var id = view.id + 1;
			// var bg = view.active ? Skin.BACKGROUND_ACTIVE_COLOR : Skin.BACKGROUND_COLOR;
			// setViewTransform(id, _view, _proj);
			// setViewClear(view.id, CLEAR_COLOR | CLEAR_DEPTH, bg, 1.0);
			// touch(view.id);

			view.data.draw();
			renderer.draw_lines(view.bounding_lines);
			renderer.draw_triangles(view.corner_tris);
		}
	}
}
