package exwidgets.ui;

import math.Triangle;
import math.AABBUtils;
import exwidgets.Editor;
import exwidgets.Renderer.UiLine;
import exwidgets.Renderer.UiTriangle;

class View {
	public var x: Int;
	public var y: Int;
	public var w: Int;
	public var h: Int;
	public var padding: Int;

	public var data: Editor;
	public var dirty: Bool = true;

	var split_amount: Float = 0.0;
	var split_horiz: Bool = false;

	public var id: Int = -1;
	public var children: Array<View> = [];

	public var active: Bool = false;
	public final renderer: Renderer;
	public var bounding_lines(default, null): Array<UiLine> = [];
	public var corner_tris(default, null): Array<UiTriangle> = [];

	public function new(
		renderer: Renderer,
		editor: Editor,
		x: Int, y: Int,
		w: Int, h: Int
	) {
		this.renderer = renderer;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		this.data = editor;
	}

	public function split(?amount: Float = 0.5, ?horizontal: Bool = false) {
		if (this.children.length != 0)
			return;

		var v1: View;
		var v2: View;
		this.split_amount = amount;
		this.split_horiz  = horizontal;
		var other = this.data.clone();
		if (horizontal) {
			// flip horizontal splits because OpenGL origin is bottom left.
			this.split_amount = 1.0 - this.split_amount;

			var height = Math.floor(Math.max(this.h * split_amount, 20));
			v1 = new View(this.renderer, other, this.x, this.y + height, this.w, this.h - height);
			v2 = new View(this.renderer, this.data, this.x, this.y, this.w, height);
		}
		else {
			var width = Math.floor(Math.max(this.w * split_amount, 20));
			v1 = new View(this.renderer, other, this.x + width, this.y, this.w - width, this.h);
			v2 = new View(this.renderer, this.data, this.x, this.y, width, this.h);
		}

		for (v in [ v1, v2 ])
			this.children.push(v);

		this.updateSplits();
	}

	public function updateSplits() {
		if (this.children.length == 2) {
			var a = this.children[0];
			var b = this.children[1];
			if (this.split_horiz) {
				var height = Math.floor(Math.max(this.h * this.split_amount, 20));
				a.x = this.x;
				a.y = this.y;
				a.w = this.w;
				a.h = height;

				b.x = this.x;
				b.y = this.y + height;
				b.w = this.w;
				b.h = this.h - height;
			}
			else {
				var width = Math.floor(Math.max(this.w * this.split_amount, 20));
				a.x = this.x;
				a.y = this.y;
				a.w = width;
				a.h = this.h;

				b.x = this.x + width;
				b.y = this.y;
				b.w = this.w - width;
				b.h = this.h;
			}
		}

		this.dirty = true;

		this.updateCorners();

		for (child in this.children) {
			child.updateSplits();
		}
	}

	function updateCorners() {
		var r1 = 1, g1 = 1, b1 = 1, a1 = 0.25;
		var r2 = 0, g2 = 0, b2 = 0, a2 = 0.25;
		var dpi = 1;
		var cs = 12 * dpi;
		var is = 8  * dpi;
		var c0 = [ r1, g1, b1, a1 ];
		var c1 = [ r2, g2, b2, a2 ];
		// holy allocations batman
		this.corner_tris = [
			new UiTriangle(
				Triangle.without_normal(
					[ -1 + x + w - cs, 1 + y, 0 ],
					[ -1 + x + w, 1 + y, 0 ],
					[ -1 + x + w, 1 + y + cs, 0 ]
				),
				0, 0, c0, 0, 0, c0, 0, 0, c0
			),
			new UiTriangle(
				Triangle.without_normal(
					[ -1 + x + w - is, 1 + y, 0 ],
					[ -1 + x + w, 1 + y, 0 ],
					[ -1 + x + w, 1 + y + is, 0 ]
				),
				0, 0, c1, 0, 0, c1, 0, 0, c1
			),
			new UiTriangle(
				Triangle.without_normal(
					[ 1 + x, -1 + y + h - cs, 0 ],
					[ 1 + x, -1 + y + h, 0 ],
					[ 1 + x + cs, -1 + y+h, 0 ]
				),
				0, 0, c0, 0, 0, c0, 0, 0, c0
			),
			new UiTriangle(
				Triangle.without_normal(
					[ 1 + x, -1 + y + h - is, 0 ],
					[ 1 + x, -1 + y + h, 0 ],
					[ 1 + x + is, -1 + y + h, 0 ]
				),
				0, 0, c1, 0, 0, c1, 0, 0, c1
			)
		];

		// outline
		this.bounding_lines.resize(0);
		Geometry.push_outline(this.bounding_lines, x, y, w, h, true, 0xff);
			// top across
			// new UiLine([x+2, y+1, 0], [x+w, y+1, 0], bright),
			// right down
			// new UiLine([x+w, y+1, 0], [x+w, y+h-1, 0], bright),
			// bottom across
			// new UiLine([x+1, y+h-1, 0], [x+w-1, y+h-1, 0], dim),
			// left up
			// new UiLine([x+1, y+h-1, 0], [x+1, y+1, 0], dim)
		// ];
	}

	public function setEditor(editor: Editor) {
		this.data = editor;
		this.data.view = this;
		this.dirty = true;
	}

	static var all_views = [];
	public static function getViews(): Array<View> {
		return all_views;
	}

	public inline function hit_free(x: Int, y: Int) {
		return { x: x - this.x, y: y - this.y };
	}

	public function hit(x: Int, y: Int) {
		if (AABBUtils.hit(x, y, this.x, this.y, this.x + this.w, this.y + this.h)) {
			return this.hit_free(x, y);
		}
		return null;
	}

	// build the view tree into an array to make life easier.
	// this prevents you from needing to filter them everywhere.
	public function updateIndex(?first: Bool = false) {
		if (first) {
			all_views.resize(0);
		}

		if (this.children.length == 0) {
			// view id's skip a number so that UI can be drawn over the top of
			// the view's actual contents.
			this.id = all_views.length*2;
			all_views.push(this);
			this.dirty = true;
		} else {
			this.id = -1;
		}

		for (child in this.children) {
			child.updateIndex();
		}
	}
}
