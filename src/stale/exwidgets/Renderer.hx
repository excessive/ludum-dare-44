package exwidgets;

import math.Vec3;
import math.Triangle;

enum Alignment {
	Left;
	Center;
	Right;
}

@:forward
abstract UiTriangle({ tri: Triangle, c0: Array<Float>, c1: Array<Float>, c2: Array<Float> }) {
	public inline function new(
		tri: Triangle,
		u0, v0,  c0,
		u1, v1,  c1,
		u2, v2,  c2
	) {
		this = {
			tri: tri,
			c0: c0,
			c1: c1,
			c2: c2
		};
	}
}

@:forward
abstract UiLine({ v0: Vec3, v1: Vec3, c0: Array<Float> }) {
	public inline function new(v0, v1, c0) {
		this = {
			v0: v0,
			v1: v1,
			c0: c0
		};
	}
}

interface Renderer {
	function draw_triangles(verts: Array<UiTriangle>): Void;
	function draw_lines(verts: Array<UiLine>): Void;
	function draw_text(x: Float, y: Float, str: String, color: Int, align: Alignment = Left): Void;
	function text_measure(str: String, wrap: Float = 0): { width: Float, height: Float };
	function text_line_height(): Float;
}
