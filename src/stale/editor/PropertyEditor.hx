package editor;

import exwidgets.ui.Layout;
import exwidgets.ui.InputContext;
import exwidgets.Editor;
import exwidgets.Geometry;

class PropertyEditor extends Editor {
	var ui: Layout;

	var input: InputContext;

	override public function new() {
		super();

		this.input = new InputContext();
		this.input.value = "test input";

		this.ui = new Layout(this);
		this.ui.row();
		this.ui.category("File");
		this.ui.row();
		this.ui.button("New", "file.new");
		this.ui.button("Open", "file.open");
		this.ui.row();
		this.ui.button("Save", "file.save");
		this.ui.button("Quit", "file.quit");
		this.ui.row();

		this.ui.row();
		this.ui.input("test", this.input);

		this.ui.row();
		this.ui.category("History");
		this.ui.row();
		this.ui.button("Undo", "history.undo");
		this.ui.button("Redo", "history.redo");

		this.ui.row();
		this.ui.category("Create");
		this.ui.row();
		this.ui.button("Cube", "mesh.new_cube");
		this.ui.button("Sphere", "mesh.new_sphere");
		this.ui.row();
		this.ui.button("Polygon", "mesh.poly_pen");

		this.ui.row();
		this.ui.category("Modify");
		this.ui.row();
		this.ui.button("Inset", "mesh.inset");
		this.ui.button("Extrude", "mesh.extrude");
		this.ui.row();
		this.ui.button("Bevel", "mesh.bevel");
		this.ui.row();
		this.ui.button("Loop Cut", "mesh.loop_cut");
		this.ui.button("Knife Cut", "mesh.knife_cut");
		this.ui.row();
		this.ui.button("Split", "mesh.split");
		this.ui.button("Merge", "mesh.merge");

		this.ui.row();
		this.ui.category("Delete");
		this.ui.row();
		this.ui.button("Selected", "mesh.delete_selected");
		this.ui.row();
		this.ui.button("Face", "mesh.delete_face");
		this.ui.button("Edge", "mesh.delete_edge");
		this.ui.button("Vertex", "mesh.delete_vertex");

		this.ui.row();
		this.ui.category("Select");
		this.ui.row();
		this.ui.button("None", "select.none");
		this.ui.button("All", "select.all");
		this.ui.row();
		this.ui.button("Less", "select.less");
		this.ui.button("More", "select.more");
		this.ui.row();
		this.ui.button("Linked", "select.linked");
		this.ui.button("Invert", "select.invert");
	}

	var hit_confirm: LayoutItemHitBox;

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
		var render = this.view.renderer;
		var buf = [];
		Geometry.push_rectangle(buf, this.view.x, this.view.y, this.view.w, this.view.h, 0x000000DD);
		render.draw_triangles(buf);
		this.ui.reflow(this.view.w, this.view.h);
		this.ui.draw(this.view.id);
	}
}
