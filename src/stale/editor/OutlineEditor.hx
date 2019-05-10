package editor;

import exwidgets.ui.Layout;
import exwidgets.Editor;
import exwidgets.Geometry;

class OutlineEditor extends Editor {
	var ui: Layout;
	var hit_confirm: LayoutItemHitBox;

	override public function new() {
		super();
		this.ui = new Layout(this);
		this.ui.row();
		this.ui.category("Scene");
		this.ui.row();
		this.ui.button("New", "scene.new");
		// this.ui.button("Close", "scene.quit");
		this.ui.row();
		this.ui.button("Load", "scene.load");
		this.ui.button("Save", "scene.save");

		this.ui.row();
		this.ui.button("Edit", "editor.toggle");
		this.ui.canvas("spaaace", 16/9, (renderer, x, y, w, h) -> {
			var tris = [];
			Geometry.push_rectangle(tris, x, y, w, h, 0xCCCCCCFF, 0.05);
			renderer.draw_triangles(tris);
		});
		// this.ui.canvas("spaaace", 4/3, (renderer, x, y, w, h) -> {
		// 	var tris = [];
		// 	Geometry.push_rectangle(tris, x + 2, y + 2, w - 4, h - 4, 0x777777FF, 0);
		// 	Geometry.push_rectangle(tris, x + 4, y + 4, w - 8, h - 8, 0xCCCCCCFF, 0.1);
		// 	renderer.draw_triangles(tris);
		// });
	}

	override function onMousePress(x: Int, y: Int, button: Int) {
		this.ui.check_highlight(x, y);
		if (button == 1) {
			this.hit_confirm = this.ui.hit_scan(x, y);
		}
	}

	override function onMouseRelease(x: Int, y: Int, button: Int) {
		this.ui.check_highlight(x, y);
		if (button == 1) {
			this.ui.hit(x, y, this.hit_confirm);
			this.hit_confirm = null;
		}
	}

	override function onMouseMove(x: Int, y: Int, xrel: Int, yrel: Int) {
		if (hit_confirm == null) {
			this.ui.check_highlight(x, y);
		}
	}

	override function onMouseScroll(x: Int, y: Int) {
		var scroll_speed = 1;
		this.ui.scroll_offset -= y * scroll_speed;
		hit_confirm = null;
		this.ui.clear_highlight();
	}

	override function draw() {
		var v = this.view;
		var render = this.view.renderer;
		var buf = [];
		Geometry.push_rectangle(buf, v.x, v.y, v.w, v.h, 0x000000F0);
		render.draw_triangles(buf);
		this.ui.reflow(this.view.w, this.view.h);
		this.ui.draw(this.view.id);
	}
}
