package editor;

import imgui.ImGui as Ui;
import math.Vec2;
import math.Vec3;
import math.Utils;
import node.*;
import node.Node.Wire;

import love.graphics.Canvas;
import love.graphics.GraphicsModule as Lg;

import love.math.MathModule as Lm;
import love.math.BezierCurve;
import backend.Input;

class BunchaNodes {
	public static function fuck_it(): NodeGraph {
		var graph = new NodeGraph("test");
		var e = graph.add(NodeList.create(EventTick, new Vec3(50, 50, 0)));
		var a = graph.add(NodeList.create(TransformGet, new Vec3( 50, 250, 0)));
		var b = graph.add(NodeList.create(TransformSet, new Vec3(400,  50, 0)));
		graph.connect(e.outputs[0], b.inputs[0]);
		graph.connect(a.outputs[0], b.inputs[1]);
		graph.compile();
		return graph;
	}
}

class NodeEditor {
	static var canvases = new Map<NodeGraph, Canvas>();
	static var tmp_wire: Wire = null;

	public static function init() {}

	static function draw_node(graph: NodeGraph, node: Node) {
		var f = Lg.getFont();
		var row_height = f.getHeight();
		var rows = Utils.max(node.inputs.length, node.outputs.length);
		var padding = 10;
		var width = 200.0;
		var title_height = row_height + padding*2;

		row_height *= 1.5;
		var height = rows*row_height + padding*2;

		if (node.display_height != null) {
			height += node.display_height;
		}

		var x = node.position.x;
		var y = node.position.y;

		// title bar
		Lg.setColor(color_for_node(node));
		Lg.rectangle(Fill, x, y, width, title_height);

		Ui.set_cursor_pos_x(x);
		Ui.set_cursor_pos_y(y);
		Ui.invisible_button("titlebar", width-title_height, title_height);
		if (Ui.is_item_active(0)) {
			var mouse = Input.get_mouse_pos();
			var pos = Ui.get_window_pos();
			mouse.x -= pos.f1;
			mouse.y -= pos.f2;
			if (node.drag_start == null) {
				node.drag_start = node.position.copy();
				node.drag_start.x -= mouse.x;
				node.drag_start.y -= mouse.y;
			}
			node.position.x = node.drag_start.x + mouse.x;
			node.position.y = node.drag_start.y + mouse.y;
		}
		else {
			node.drag_start = null;
		}
		Lg.setColor(1, 0, 0, 0.25);
		Lg.rectangle(Fill, x+width-title_height, y, title_height, title_height);
		Ui.set_cursor_pos_x(x+width-title_height);
		Ui.set_cursor_pos_y(y);
		if (node.active) {
			Ui.push_color("Button", 0.6, 0.25, 0.1, 1);
			Ui.push_color("ButtonHovered", 0.8, 0.2, 0.1, 1);
			Ui.push_color("ButtonActive", 0.95, 0.3, 0.15, 1);
		}
		else {
			Ui.push_color("Button", 0.45, 0.2, 0.1, 1);
			Ui.push_color("ButtonHovered", 0.7, 0.2, 0.1, 1);
			Ui.push_color("ButtonActive", 0.9, 0.3, 0.15, 1);
		}
		Ui.button("X", title_height, title_height);
		if (Ui.is_item_clicked(0)) {
			graph.remove(node);
		}
		Ui.pop_color(3);

		// background
		if (node.active) {
			Lg.setColor(0.95, 0.95, 0.95, 1);
		}
		else {
			Lg.setColor(0.75, 0.75, 0.75, 1);
		}
		Lg.rectangle(Fill, x, y+title_height, width, height);

		// title
		Lg.setColor(1, 1, 1, 1);
		Lg.print(node.name, x + padding, y + padding);

		x += padding;
		y += title_height + padding;
		width -= padding;

		inline function draw_socket(type: String, x: Float, y: Float, connected: Bool) {
			var socket_size = 5;
			Lg.setColor(color_for(type, 0.75));
			Lg.circle(Fill, x, y, socket_size);

			Lg.setLineWidth(1);
			Lg.setColor(color_for(type, 0.5));
			Lg.circle(Line, x, y, socket_size);

			if (connected) {
				Lg.setColor(1, 1, 1, 1);
				Lg.setLineWidth(1);
				Lg.circle(Line, x, y, 3);
				Lg.circle(Line, x, y, 3);
			}

			Ui.set_cursor_pos_x(x-socket_size);
			Ui.set_cursor_pos_y(y-socket_size);
			Ui.invisible_button("socket", socket_size*2, socket_size*2);
			if (Ui.is_item_clicked(0)) {
				return true;
			}
			return false;
		}

		// inputs/outputs
		var max: Float = 0;
		for (sock in node.inputs) {
			max = Utils.max(max, f.getWidth(sock.label));
		}
		var rmax: Float = 0;
		for (sock in node.outputs) {
			rmax = Utils.max(rmax, f.getWidth(sock.label));
		}
		for (i in 0...node.inputs.length) {
			var socket = node.inputs[i];
			var ix = x;
			var iy = y + i * row_height;
			Lg.setColor(0, 0, 0, 1);
			Lg.print(socket.label, ix, iy);
			if (!graph.is_connected(socket) && !node.is_output) {
				Ui.set_cursor_pos_x(ix + max + padding);
				Ui.set_cursor_pos_y(iy);
				Ui.push_item_width(width - max - padding * 3 - rmax);
				switch (socket.type) {
					case "float": {
						var ret = Ui.drag_float('##${socket.label}_$i', node.defaults[i], 0.1, 0, 0);
						node.defaults[i] = ret.f1;
					}
					case "vec3": {
						var val: Vec3 = cast node.defaults[i];
						var ret = Ui.drag_float3('##${socket.label}_$i', val.x, val.y, val.z, 0.1, 0, 0);
						val.x = ret.f1;
						val.y = ret.f2;
						val.z = ret.f3;
					}
				}
				Ui.pop_item_width();
			}
			if (!socket.hidden) {
				Ui.push_id(socket.uuid);
				if (draw_socket(socket.type, x - padding, iy + f.getHeight()/2, graph.is_connected(socket))) {
					if (tmp_wire != null) {
						var discon = graph.disconnect(socket);
						tmp_wire.output = socket;
						if (tmp_wire.input != null && tmp_wire.output != null) {
							graph.connect(tmp_wire.input, tmp_wire.output);
							graph.compile();
							tmp_wire = null;
						}
						else if (discon) {
							graph.compile();
						}
					}
					else {
						if (!graph.disconnect(socket)) {
							tmp_wire = {
								output: socket,
								input: null
							};
						}
						else {
							graph.compile();
						}
					}
				}
				Ui.pop_id();
			}
		}
		max = rmax;
		for (i in 0...node.outputs.length) {
			var socket = node.outputs[i];
			var ox = x + width - (max + padding);
			var oy = y + i * row_height;
			Lg.setColor(0, 0, 0, 1);
			Lg.print(socket.label, ox, oy);
			Ui.push_id(socket.uuid);
			if (draw_socket(socket.type, x + width, oy + f.getHeight()/2, graph.is_connected(socket))) {
				if (tmp_wire != null) {
					tmp_wire.input = socket;
					if (tmp_wire.input != null && tmp_wire.output != null) {
						graph.connect(tmp_wire.input, tmp_wire.output);
						graph.compile();
						tmp_wire = null;
					}
				}
				else {
					tmp_wire = {
						output: null,
						input: socket
					};
				}
			}
			Ui.pop_id();
		}

		if (node.display != null && node.display_height != null) {
			var display_w = width - padding;
			Ui.push_item_width(display_w);
			var display_y = y + rows * row_height;
			Ui.set_cursor_pos(x, display_y);
			Ui.begin_group();
			Lg.setColor(1, 1, 1, 1);
			Lg.push();
			Lg.translate(x, display_y);
			if (node.values.length == node.defaults.length) {
				node.display(node.values, display_w, node.display_height);
			}
			Lg.pop();
			Ui.end_group();
			Ui.pop_item_width();
		}
	}

	static function color_for(type: String, mul: Float = 1.0): lua.Table<Int, Float> {
		return switch (type) {
			case "float": cast [null, 0.87*mul, 0.44*mul, 0.15*mul];
			case "vec2": cast [null, 0.37*mul, 0.80*mul, 0.89*mul];
			case "vec3": cast [null, 0.41*mul, 0.75*mul, 0.19*mul];
			case "quat": cast [null, 0.84*mul, 0.48*mul, 0.73*mul];
			case "bool": cast [null, 0.37*mul, 0.80*mul, 0.89*mul];
			case "event": cast [null, 0.67*mul, 0.20*mul, 0.20*mul];
			default: cast [null, 1*mul, 1*mul, 1*mul];
		}
	}

	static function color_for_node(node: Node): lua.Table<Int, Float> {
		var mul = 1.0;
		if (!node.active) {
			mul = 0.5;
		}
		if (node.is_event) {
			return cast [null, 0.75*mul, 0.25*mul, 0.25*mul, 1.0];
		}
		if (node.is_output) {
			return cast [null, 0.2*mul, 0.25*mul, 0.8*mul, 1.0];
		}
		if (node.active) {
			return cast [null, 0.55, 0.125, 0.55, 1];
		}
		return cast [null, 0.5*mul, 0.5*mul, 0.5*mul, 1];
	}

	static function draw_noodle(type: String, first: Vec2, last: Vec2, active: Bool) {
		// 1-2 is mega-curvy, 0 is straight, >2 is a gentle curve.
		var curviness: Float = 3;
		var bezier: BezierCurve;
		var verts: lua.Table<Int, Float>;
		if (curviness == 0) {
			verts = cast [null, first.x, first.y, last.x, last.y];
		}
		else {
			verts = cast [null,
				first.x, first.y,
				first.x + (last.x - first.x) / curviness, first.y,
				last.x - (last.x - first.x) / curviness, last.y,
				last.x, last.y
			];
		}
		bezier = Lm.newBezierCurve(verts);

		Lg.setColor(color_for(type, active? 1.0 : 0.5));
		Lg.setLineWidth(2);

		// Arrows
		var arrow_width = 5;
		var arrow_length = 10;
		Lg.push();
		Lg.translate(last.x, last.y);

		var len = Vec2.distance(first, last);
		var pos = Utils.clamp((len - arrow_length * 1.5) / len, 0, 1);
		var eval = bezier.evaluate(pos);
		var angle = last.angle_to(new Vec2(eval.x, eval.y))-Math.PI/2;
		Lg.rotate(angle);

		Lg.polygon(Fill, -arrow_width, -arrow_length, arrow_width, -arrow_length, 0, 0);
		Lg.pop();

		// No need for subdivisions if it's straight.
		Lg.line(bezier.render(curviness == 0? 1 : 4));
	}

	static function render_graph(w: Float, h: Float, graph: NodeGraph) {
		Lg.clear(0, 0, 0, 0);
		Ui.begin_group();
		Lg.setBlendMode(Alpha);

		var f = Lg.getFont();
		var row_height = f.getHeight();
		var width = 200.0;
		var padding = 10.0;
		var title_height = row_height + padding*2;
		row_height *= 1.5;
		for (wire in graph.connections) {
			var lx = wire.input.node.position.x + width;
			var ly = wire.input.node.position.y + title_height + padding + f.getHeight()/2;
			ly += row_height * wire.input.index;

			var rx = wire.output.node.position.x;
			var ry = wire.output.node.position.y + title_height + padding + f.getHeight()/2;
			ry += row_height * wire.output.index;

			draw_noodle(wire.input.type, new Vec2(lx, ly), new Vec2(rx, ry), wire.output.node.active);
		}

		if (tmp_wire != null) {
			var wire = tmp_wire;
			var side = wire.input != null ? wire.input : wire.output;
			var start = new Vec2(0, 0);
			var end = new Vec2(0, 0);
			var mouse = Input.get_mouse_pos();
			var pos = Ui.get_window_pos();
			mouse.x -= pos.f1;
			mouse.y -= pos.f2;

			if (tmp_wire.input != null) {
				var lx = wire.input.node.position.x + width;
				var ly = wire.input.node.position.y + title_height + padding + f.getHeight()/2;
				ly += row_height * wire.input.index;
				start.x = lx;
				start.y = ly;
			}
			else {
				start.x = mouse.x;
				start.y = mouse.y;
			}

			if (tmp_wire.output != null) {
				var rx = wire.output.node.position.x;
				var ry = wire.output.node.position.y + title_height + padding + f.getHeight()/2;
				ry += row_height * wire.output.index;
				end.x = rx;
				end.y = ry;
			}
			else {
				end.x = mouse.x;
				end.y = mouse.y;
			}

			draw_noodle(side.type, start, end, true);
		}
		for (node in graph.nodes) {
			Ui.push_id(node.uuid);
			Ui.push_color("Text", 0.00, 0.00, 0.00, 1.00);
			Ui.push_color("FrameBg", 0.80, 0.80, 0.80, 1.0);
			draw_node(graph, node);
			Ui.pop_color(2);
			Ui.pop_id();
		}

		Ui.end_group();
	}

	static function add_node_menu(graph: NodeGraph) {
		var all_nodes = [
			{
				label: "Magic",
				nodes: [
					//
				]
			}
			// {
			// 	label: "Events",
			// 	nodes: [
			// 		{ label: "tick", build: node.EventNodes.tick },
			// 		{ label: "day", build: node.EventNodes.day }
			// 	]
			// },
			// {
			// 	label: "Transform",
			// 	nodes: [
			// 		{ label: "get_transform", build: node.TxNodes.get_transform },
			// 		{ label: "set_transform", build: node.TxNodes.set_transform }
			// 	]
			// },
			// {
			// 	label: "Convert",
			// 	nodes: [
			// 		{ label: "combine_vec3",  build: node.ConvertNodes.combine_vec3 },
			// 		{ label: "separate_vec3", build: node.ConvertNodes.separate_vec3 },
			// 		{ label: "branch", build: node.ConvertNodes.branch }
			// 	]
			// },
			// {
			// 	label: "Math",
			// 	nodes: [
			// 		{ label: "add", build: node.MathNodes.add },
			// 		{ label: "sub", build: node.MathNodes.sub },
			// 		{ label: "div", build: node.MathNodes.div },
			// 		{ label: "mul", build: node.MathNodes.mul },
			// 		{ label: "eq", build: node.MathNodes.eq }
			// 	]
			// },
			// {
			// 	label: "View",
			// 	nodes: [
			// 		{ label: "number", build: node.ViewNodes.number },
			// 		{ label: "vec2",   build: node.ViewNodes.vec2 },
			// 		{ label: "vec3",   build: node.ViewNodes.vec3 },
			// 		{ label: "quat",   build: node.ViewNodes.quat },
			// 		{ label: "string", build: node.ViewNodes.string }
			// 	]
			// },
			// {
			// 	label: "Vector",
			// 	nodes: [
			// 		{ label: "add",        build: node.Vec3Nodes.add },
			// 		{ label: "sub",        build: node.Vec3Nodes.sub },
			// 		{ label: "div",        build: node.Vec3Nodes.div },
			// 		{ label: "fdiv",       build: node.Vec3Nodes.fdiv },
			// 		{ label: "mul",        build: node.Vec3Nodes.mul },
			// 		{ label: "scale",      build: node.Vec3Nodes.scale },
			// 		{ label: "trim",       build: node.Vec3Nodes.trim },
			// 		{ label: "normalize",  build: node.Vec3Nodes.normalize },
			// 		{ label: "eq",         build: node.Vec3Nodes.eq },
			// 		{ label: "near",       build: node.Vec3Nodes.near },
			// 		{ label: "cross",      build: node.Vec3Nodes.cross },
			// 		{ label: "dot",        build: node.Vec3Nodes.dot },
			// 		{ label: "distance",   build: node.Vec3Nodes.distance },
			// 		{ label: "length",     build: node.Vec3Nodes.length },
			// 		{ label: "lengthsq",   build: node.Vec3Nodes.lengthsq },
			// 		{ label: "lerp",       build: node.Vec3Nodes.lerp },
			// 		{ label: "min",        build: node.Vec3Nodes.min },
			// 		{ label: "max",        build: node.Vec3Nodes.max },
			// 		{ label: "project_on", build: node.Vec3Nodes.project_on }
			// 	]
			// }
		];

		if (Ui.begin("Add Node")) {
			var size = Ui.get_content_region_max();
			for (cat in all_nodes) {
				if (Ui.tree_node(cat.label)) {
					for (node in cat.nodes) {
						if (Ui.button(node.label, size[0])) {
							graph.add(node.build(), new Vec3(50, 50, 0));
						}
					}
					Ui.tree_pop();
				}
			}
		}
		Ui.end();
	}

	public static function draw(entity: SceneNode, graph: NodeGraph) {
		var flags = [null, "NoScrollbar", "NoSavedSettings"];
		if (Ui.begin("Edit graph: " + graph.name + "@" + entity.name, true, cast flags)) {
			var size = Ui.get_content_region_max();
			size[0] += 5;
			size[1] += 5;
			if (!canvases.exists(graph)) {
				canvases[graph] = Lg.newCanvas(size[0], size[1]);
			}
			var canvas = canvases[graph];
			if (canvas.getWidth() != size[0] || canvas.getHeight() != size[1]) {
				canvas.release();
				canvas = Lg.newCanvas(size[0], size[1]);
				canvases[graph] = canvas;
			}
			Ui.set_cursor_pos_x(0);
			Ui.set_cursor_pos_y(0);
			Ui.image(canvas, size[0], size[1], 0, 0, 1, 1);
			canvas.renderTo(function() {
				var w = canvas.getWidth();
				var h = canvas.getHeight();
				Ui.push_id(graph.name+"@"+entity.name);
				render_graph(w, h, graph);
				Ui.pop_id();
			});
			add_node_menu(graph);
		}
		Ui.end();
	}
}
