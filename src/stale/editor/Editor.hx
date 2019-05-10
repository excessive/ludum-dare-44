package editor;

import backend.Input;
import node.NodeList;
import utils.RecycleBuffer;
import backend.Window;

#if imgui
import node.NodeGraph;
import utils.Printf.format;
import imgui.ImGui as Ui;
import Main.scene;
import utils.Helpers;
import components.*;
import math.Vec3;
import math.Quat;
import Time.ClockTime;

import exwidgets.Context;
import exwidgets.Operator;
import exwidgets.OperatorList;
import exwidgets.ui.View;

class EditorOperators {
	public static function register_all() {
		var classes: Array<Operator> = [
			new editor.operators.Scene(),
			new editor.operators.Edit()
		];
		for (c in classes) {
			OperatorList.register(c.register());
		}
	}
}

class EditorKeybinds {
	public static function init() {
		var set = exwidgets.ui.Keybind.set;
		var Default = exwidgets.ui.Keybind.Default;
		set("scene.new", { type: Default, mapping: "Ctrl-N" });
		set("scene.load", { type: Default, mapping: "Ctrl-O" });
		set("scene.save", { type: Default, mapping: "Ctrl-S" });
		set("scene.close", { type: Default, mapping: "Ctrl-W" });
		set("scene.quit", { type: Default, mapping: "Ctrl-Q" });

		set("history.undo", { type: Default, mapping: "Ctrl-Z" });
		set("history.redo", { type: Default, mapping: "Ctrl-Shift-Z" });

		set("editor.toggle", { type: Default, mapping: "TAB" });
	}
}

class Editor {
	public static var context: Context;
	static var root(get, never): View;
	static inline function get_root() { return context.root; }

	public static function init() {
		NodeEditor.init();

		EditorOperators.register_all();
		EditorKeybinds.init();

		context = new Context(Render.ui_renderer, Std.int(1280), Std.int(720));
		root.split(0.25, false);
		root.updateIndex(true);

		var views = View.getViews();
		views[0].setEditor(new editor.OutlineEditor());
	}

	static var selected: Array<SceneNode> = [];

	static function dump_nodes(node: SceneNode, show_hidden: Bool) {
		if (node.hidden && !show_hidden) {
			return;
		}
		var flags = [
			"",
			"OpenOnDoubleClick"
		];
		var sel = selected.indexOf(node) >= 0;
		if (sel) {
			flags.push("Selected");
		}
		var vis_count = 0;
		if (show_hidden) {
			vis_count = node.children.length;
		}
		else {
			for (child in node.children) {
				if (!child.hidden) {
					vis_count++;
				}
			}
		}
		if (vis_count == 0) {
			flags.push("Leaf");
			flags.push("Bullet");
			// Ui.set_cursor_pos_x(0);//Ui.get_tree_node_to_label_spacing());
		}
		Ui.begin_group();
		if (node.hidden) {
			Ui.push_color("Text", 1.0, 1.0, 1.0, 0.35);
		}
		if (Ui.tree_node(node.name, false, cast flags)) {
			if (Ui.is_item_clicked(0)) {
				if (sel) {
					selected.remove(node);
				}
				else {
					selected.push(node);
				}
			}
			if (node.children.length > 0) {
				var size = Ui.get_content_region_max();
				Ui.same_line(size[0] - 50);
				Ui.text('(${node.children.length})');
				for (child in node.children) {
					dump_nodes(child, show_hidden);
				}
			}
			Ui.tree_pop();
		}
		else {
			if (Ui.is_item_clicked(0)) {
				if (sel) {
					selected.remove(node);
				}
				else {
					selected.push(node);
				}
			}
			var size = Ui.get_content_region_max();
			Ui.same_line(size[0] - 50);
			Ui.text('(${node.children.length})');
		}
		if (node.hidden) {
			Ui.pop_color();
		}
		Ui.end_group();
	}

	// do not put imgui stuff here
	public static inline function update(dt) {}

	static function edit_collidable(collidable: Collidable) {
		if (collidable == null) { return; }

		Ui.text("Collidable");
		Helpers.drag_vec3("Radius", collidable.radius);
		Ui.separator();
	}

	static function edit_drawable(drawable: Drawable) {
		if (drawable == null) { return; }

		Ui.text("Drawable");
		Ui.separator();
	}

	static function edit_physics(physics: Physics) {
		if (physics == null) { return; }

		Ui.text("Physics");
		// Ui.drag_float("Speed",    physics.speed, 0.1, 0, 1000);
		// Ui.drag_float("Mass",     physics.mass, 1, 0, 1000000);
		Ui.drag_float("Friction", physics.friction, 0.01, 0, 100);
		Ui.checkbox("Grounded",   physics.on_ground);
		Ui.separator();
	}

	static function edit_player(player: Player) {
		if (player == null) { return; }

		Ui.text("Player");
		// Ui.checkbox("Player", player);
		Ui.separator();
	}

	static function edit_transform(transform: Transform) {
		Debug.axis(transform.position, Vec3.right(), Vec3.forward(), Vec3.up(), 1.0);

		Ui.text("Transform");
		Helpers.drag_vec3("Position", transform.position);
		Helpers.drag_vec3("Velocity", transform.velocity);
		Helpers.input_quat("Rotation", transform.orientation);
		// Helpers.drag_vec3("Scale", transform.scale);

		if (Ui.button("Randomize##randrot")) {
			var q = new Quat(Math.random()*2-1, Math.random()*2-1, Math.random()*2-1, Math.random()*2-1+0.0001);
			q.normalize();
			transform.orientation = q;
		}

		transform.update();
		Ui.separator();
	}

	static function edit_scripts(entity: SceneNode, scripts: Array<NodeGraph>) {
		Ui.text("Scripts");
		if (Ui.button("Add New")) {
			var g = new NodeGraph("<unnamed>");
			g.add(NodeList.create(EventTick, new Vec3(0, 0, 0)));
			g.compile();
			entity.scripts.push(g);
		}
		for (graph in scripts) {
			if (Ui.tree_node(graph.name)) {
				Ui.text("Events:");
				Ui.spacing();
				for (key in graph.events.keys()) {
					Ui.text(key);
				}
				NodeEditor.draw(entity, graph);
				Ui.tree_pop();
			}
		}
		Ui.separator();
	}

	static function show_selected() {
		for (e in selected) {
			Ui.push_id('${e.id}');
			edit_collidable(e.collidable);
			edit_drawable(e.drawable);
			edit_physics(e.physics);
			edit_player(e.player);
			edit_transform(e.transform);
			edit_scripts(e, e.scripts);
			Ui.pop_id();
		}
	}

	static var show_hidden = false;

	static function begin_group_normal() {
		Ui.set_cursor_pos_x(Ui.get_tree_node_to_label_spacing() - 10);
		Ui.begin_group();
	}

	static function end_group_normal() {
		Ui.end_group();
		Ui.spacing();
	}

	static var cursor = new Vec3(0, 0, 0);

	public static function draw(window: Window, state: RecycleBuffer<Entity>) {
		MainMenu.draw();

		if (!GameInput.locked) {
			return;
		}

		if (Ui.begin("Scene")) {
			var flags: lua.Table<Int, String> = cast ["", "Framed"];
			if (Ui.tree_node("Time", true, flags)) {
				begin_group_normal();
				var day = Time.current_day;
				var time = Time.current_time;
				var ret = Ui.slider_float("Time", time.to_hour24f(), 0, 23.99);
				if (ret.status) {
					Time.current_time = ClockTime.from_hour(ret.f1);
				}
				Ui.text(format("Day: %d", [ day ]));
				Ui.text(format(
					"Time: %02d:%02d",
					[
						time.to_hour24(),
						time.to_minute()
					]
				));
				end_group_normal();
				Ui.tree_pop();
			}
			if (Ui.tree_node("Info", true, flags)) {
				begin_group_normal();
				Ui.spacing();
				Helpers.drag_vec3("Cursor", cursor);
				end_group_normal();
				Debug.aabb(cursor - new Vec3(1, 1, 1), cursor + new Vec3(1, 1, 1), 0, 0, 1);
				Debug.axis(cursor, Vec3.right(), Vec3.forward(), Vec3.up(), 1);
				Ui.tree_pop();
			}
			if (Ui.tree_node("Entities", true, flags)) {
				Ui.push_var("ItemSpacing", 0, 5);
				begin_group_normal();
				if (Ui.checkbox("Show Hidden", show_hidden)) {
					show_hidden = !show_hidden;
				}
				Ui.separator();
				for (node in scene.root.children) {
					dump_nodes(node, show_hidden);
				}
				end_group_normal();
				Ui.pop_var(1);
				Ui.tree_pop();
			}
			if (Ui.tree_node("Selection", true, flags)) {
				begin_group_normal();
				show_selected();
				end_group_normal();
				Ui.tree_pop();
			}
		}
		Ui.end();
	}
}
#else
class Editor {
	public static inline function init() {}
	public static inline function update(dt: Float) {}
	public static inline function draw(window: Window, state: RecycleBuffer<Entity>) {}
	public static inline function draw_ui() {}
}
#end
