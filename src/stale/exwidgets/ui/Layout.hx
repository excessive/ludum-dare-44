package exwidgets.ui;

import backend.Log;
import utils.OptionHelper;
import exwidgets.ui.Skin;
import exwidgets.Keyboard;
import exwidgets.Renderer;

import math.AABBUtils;
import math.ColorUtils;

enum LayoutItemType {
	Category;
	Label;
	Button;
	Canvas;
	TextInput;
}

typedef LayoutDrawCb = (renderer: Renderer, x: Float, y: Float, w: Float, h: Float)->Void;

typedef LayoutItem = {
	type: LayoutItemType,
	label: String,
	?op: String,
	?context: InputContext,
	?enabled: Bool,
	?draw_cb: LayoutDrawCb,
	?draw_aspect: Float
}

typedef LayoutRow = {
	var items: Array<LayoutItem>;
	var height: Float;
}

typedef LayoutItemHitBox = {
	var max: { x: Int, y: Int };
	var min: { x: Int, y: Int };
	var item: LayoutItem;
}

class Window {
	public static var DPI = 1.0;
}

class Text {
	public function getHeight(): Float { return 0.0; }
	public function print(x: Float, y: Float, str: String, fg: Int, align: String = "left") {}
	public function measure(str: String) { return { width: 0.0 }; }
	public function draw(id: Int) {}
}

class Layout {
	var buffer: Array<UiTriangle> = [];
	var line_buffer: Array<UiLine> = [];
	var draw_buffer: Array<Void->Void> = [];
	var text_buffer: Array<{
		x: Float,
		y: Float,
		str: String,
		color: Int,
		align: Alignment
	}> = [];
	var layout: Array<LayoutRow> = [];

	var hitboxes: Array<LayoutItemHitBox> = [];
	final editor: Editor;
	var renderer(get, never): Renderer;
	inline function get_renderer() {
		if (this.editor == null) {
			throw "AAAAAAAAAAAAAAAAAAAAAAA";
		}
		if (this.editor.view == null) {
			throw "BBBBBBBBBBBBBBBBBBBB";
		}
		return this.editor.view.renderer;
	}

	public inline function new(editor) {
		this.editor = editor;
	}

	public var scroll_offset(default, set): Float = 0.0;
	function set_scroll_offset(v: Float) {
		// scroll_offset = Math.max(0, v);
		return scroll_offset;
	}

	inline function buffer_text(x: Float, y: Float, str: String, color: Int, align: Alignment = Left) {
		this.text_buffer.push({
			x: x,
			y: y,
			str: str,
			color: color,
			align: align
		});
	}

	public function reflow(w: Int, h: Int) {
		var buf = this.buffer;
		buf.resize(0);

		var lbuf = this.line_buffer;
		lbuf.resize(0);

		var tbuf = this.text_buffer;
		tbuf.resize(0);

		var hits = this.hitboxes;
		hits.resize(0);

		var draws = this.draw_buffer;
		draws.resize(0);

		var single_column = false;
		if (w < 200*Window.DPI) {
			single_column = true;
		}

		var renderer = this.renderer;
		var height = scroll_offset * renderer.text_line_height();
		for (i in 0...this.layout.length) {
			var row = this.layout[i];
			var cw = Math.floor((w - Skin.REGION_PADDING * 2) / row.items.length);
			var last_item = row.items[row.items.length-1];

			if (single_column) {
				cw = w;
				last_item = row.items[0];
			}

			row.height = Math.floor(renderer.text_line_height()*1.5);
			var rh = row.height;
			var y = Math.floor(height);

			inline function next_row_spaced(size: Float) {
				height += size;
				y = Math.floor(height);
			}

			inline function next_row() {
				if (!single_column || row.items.length == 0) {
					next_row_spaced(rh + Skin.ITEM_SPACING);
				}
			}

			// skip anything off the top of the view
			if (height + rh < 0) {
				next_row();
				continue;
			}

			var advance = 0;
			for (item in row.items) {
				if (item.type == Category && i > 0) {
					height += Skin.HEADER_SPACING;
					y = Math.floor(height);
				}
				var bg = switch(item.type) {
					case Button: Skin.BUTTON_BACKGROUND_COLOR;
					case Category: Skin.HEADER_BACKGROUND_COLOR;
					case TextInput: Skin.TEXTINPUT_BACKGROUND_COLOR;
					default: 0x000000ff;
				}
				var fg = switch(item.type) {
					case Button: Skin.BUTTON_TEXT_COLOR;
					case Category: Skin.HEADER_TEXT_COLOR;
					case TextInput: Skin.TEXTINPUT_TEXT_COLOR;
					default: 0xffffffff;
				}
				var adjust = switch(item.type) {
					case Button: Skin.BUTTON_GRADIATE;
					case Category: Skin.HEADER_GRADIATE;
					case TextInput: Skin.TEXTINPUT_GRADIATE;
					default: 0.0;
				}

				var enabled = item.enabled != null && item.enabled;
				if (!enabled) {
					fg = (fg & 0xffffff00) | Std.int((fg & 0xff) * 0.5);
					bg = (bg & 0xffffff00) | Std.int((bg & 0xff) * 0.5);
				}

				var x = advance + Skin.REGION_PADDING - 1;
				var sw = cw;
				if (item != last_item && !single_column) {
					sw -= Skin.ITEM_SPACING;
				}

				var v = this.editor.view;
				var v_ox = v.x;
				var v_oy = v.y;

				// skip draw if alpha is 0, to save a bit on fillrate.
				// this is probably useful on mobile.
				if (ColorUtils.decodeA8(bg) > 0) {
					var shrink = 0;
					if (item.type == Button) {
						shrink = Skin.BUTTON_BORDER_DEPTH;
						for (i in 0...shrink) {
							Geometry.push_outline(lbuf, i + x + v_ox, i + y + v_oy, sw - i * 2, rh - i * 2, false);
						}
					}
					Geometry.push_rectangle(buf, x + v_ox + shrink, y + v_oy + shrink, sw - shrink * 2, rh - shrink * 2, bg, adjust);
				}
				hits.push({
					min: { x: Math.floor(x), y: Math.floor(y) },
					max: { x: Math.floor(x + sw), y: Math.floor(y + rh) },
					item: item
				});

				// text inputs need the label updated dynamically
				var label: String;
				if (item.type == TextInput) {
					label = item.context.value;
				}
				else {
					label = item.label;
				}

				// cursor and selection highlight
				var focused = OptionHelper.unwrap(Keyboard.focus, null);
				if (item.type == TextInput && focused == item.context) {
					var renderer = this.renderer;
					var cx = Math.ffloor(x + renderer.text_measure(label.substr(0, item.context.cursor)).width);
					cx += Skin.ITEM_PADDING;
					var csw: Float = 2 * Window.DPI;
					var ch = rh - Skin.ITEM_PADDING * 2;
					var cy = y + Skin.ITEM_PADDING;

					var sel = item.context.getSelectionBounds();
					var selx = Math.ffloor(renderer.text_measure(label.substr(0, sel.min)).width);
					var selw = Math.ffloor(renderer.text_measure(label.substr(0, sel.max)).width);
					selw -= selx;
					selx += Skin.ITEM_PADDING;
					var sely = Math.ffloor(y + Skin.ITEM_PADDING / 2);
					var selh = Math.ffloor(rh - Skin.ITEM_PADDING);
					Geometry.push_rectangle(buf, v_ox + selx, v_oy + sely, selw, selh, Skin.HIGHLIGHT_COLOR);
					Geometry.push_rectangle(buf, v_ox + cx, v_oy + cy, csw, ch, Skin.CURSOR_COLOR);
				}

				// label
				var ty = Math.floor(y + rh / 1.5);
				this.buffer_text(x + Skin.ITEM_PADDING, ty, label, fg);

				// key binding
				var bind = Keybind.get(item.op);
				if (item.type == Button && bind != null && (true || enabled)) {
					this.buffer_text(
						x + sw - Skin.ITEM_PADDING, ty,
						bind.mapping, Skin.BUTTON_BIND_COLOR, Right
					);
				}

				if (item.type == Canvas) {
					var space_height = sw / item.draw_aspect;
					draws.push(() -> item.draw_cb(this.renderer, x + v_ox, y + v_oy - space_height, sw, space_height));
					next_row_spaced(space_height);
				}

				advance += cw;
				if (single_column) {
					advance = 0;
					next_row_spaced(rh + Skin.ITEM_SPACING);
				}
			}

			next_row();

			// don't buffer items out of view.
			if (height > h) {
				break;
			}
		}
	}

	public function hit_scan(x: Int, y: Int): Null<LayoutItemHitBox> {
		for (hit in this.hitboxes) {
			if (AABBUtils.hit(x, y, hit.min.x, hit.min.y, hit.max.x, hit.max.y)) {
				return hit;
			}
		}
		return null;
	}

	var highlight: Null<LayoutItemHitBox> = null;

	public function clear_highlight() {
		this.highlight = null;
	}

	public function check_highlight(x: Int, y: Int) {
		var hit = hit_scan(x, y);
		this.highlight = null;
		if (hit != null && hit.item.enabled && hit.item.op != null) {
			this.highlight = hit;
		}
	}

	public function hit(x: Int, y: Int, ?match: LayoutItemHitBox) {
		var hit = null;
		if (match != null) {
			if (AABBUtils.hit(x, y, match.min.x, match.min.y, match.max.x, match.max.y)) {
				hit = match;
			}
		}
		else {
			hit = hit_scan(x, y);
		}
		if (hit != null) {
			switch (hit.item.type) {
				case Button:
					OperatorList.execute(hit.item.op);
				case TextInput:
					Keyboard.focus = Some(hit.item.context);
				case Category: // TODO: collapse section?
				case Canvas:
				case Label:
			}
		}
	}

	public function row() {
		this.layout.push({
			items: [],
			height: 0
		});
	}

	inline function push(v) {
		var top = this.layout[this.layout.length-1];
		top.items.push(v);
	}

	public function input(label, context: InputContext) {
		this.push({
			type: TextInput,
			label: label,
			context: context
		});
	}

	public function category(label) {
		this.push({
			type: Category,
			label: label
		});
	}

	public function canvas(label, aspect: Float, cb: LayoutDrawCb) {
		this.layout.push({
			items: [{
				type: Canvas,
				label: label,
				draw_cb: cb,
				draw_aspect: aspect
			}],
			height: 0
		});
	}

	public function label(label) {
		this.push({
			type: Label,
			label: label
		});
	}

	public function button(label: String, op: String) {
		var disabled = false;
		if (!OperatorList.lookup(op)) {
			Log.write(Custom("UI"), '/!\\ operator $op not found. disabling.');
			disabled = true;
		}
		this.push({
			type: Button,
			label: label,
			op: op,
			enabled: !disabled
		});
	}

	public function draw(id: Int) {
		var renderer = this.renderer;
		renderer.draw_triangles(this.buffer);
		renderer.draw_lines(this.line_buffer);

		for (cb in this.draw_buffer) {
			cb();
		}

		var v = this.editor.view;
		var v_ox = v.x;
		var v_oy = v.y;

		if (this.highlight != null) {
			var hl = this.highlight;
			var cx = hl.min.x;
			var cy = hl.min.y;
			var cw = hl.max.x - cx;
			var ch = hl.max.y - cy;
			var highlight_buf = [];
			Geometry.push_rectangle(highlight_buf, v_ox + cx, v_oy + cy, cw, ch, Skin.BUTTON_ROLLOVER);
			renderer.draw_triangles(highlight_buf);
		}

		for (str in this.text_buffer) {
			renderer.draw_text(v_ox + str.x, v_oy + str.y, str.str, str.color, str.align);
		}
	}
}
