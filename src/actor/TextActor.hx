package actor;

import math.Vec3;
import love.graphics.GraphicsModule as Lg;

class TextActor extends Actor {
	var text: String = "";
	var font: love.graphics.Font;
	var alignment: love.graphics.AlignMode = Left;
	var limit: Float = 0.0;
	var prefix: String;
	var suffix: String;

	var stroke_r: Float = 0.0;
	var stroke_g: Float = 0.0;
	var stroke_b: Float = 0.0;
	var stroke_a: Float = 0.0;

	override function get_width() return this.font.getWidth(this.text);
	override function get_height() return this.font.getHeight();

	// this code is gonna give me a stroke
	function stroke_cb(cb: Float->Float->Void, x: Float, y: Float, size: Float, ox: Float, oy: Float, sr: Float, sg: Float, sb: Float, sa: Float) {
		var color = Lg.getColor();

		Lg.setColor(sr, sg, sb, sa);
		cb(ox + x,        oy + y + size);
		cb(ox + x + size, oy + y + size);
		cb(ox + x + size, oy + y       );
		cb(ox + x + size, oy + y - size);
		cb(ox + x,        oy + y - size);
		cb(ox + x - size, oy + y - size);
		cb(ox + x - size, oy + y       );
		cb(ox + x - size, oy + y + size);

		Lg.setColor(color.r, color.g, color.b, color.a);
		cb(x, y);
	}

	public function new(?initfn: TextActor->Void) {
		super();

		this.set_color(1, 1, 1, 1);
		this.set_stroke(0, 0, 0);
		if (initfn != null) {
			initfn(this);
		}

		this.on_draw = (_) -> {
			if (this.text == null) {
				return;
			}
			var str = this.text;
			var pos = this.final_position.copy();
			var sca = this.actual.scale;
			var f = Lg.getFont();
			if (this.prefix != null) {
				str = this.prefix + str;
			}
			if (this.suffix != null) {
				str = str + this.suffix;
			}
			var of = Lg.getFont();
			if (this.font != null) {
				Lg.setFont(this.font);
				f = this.font;
			}

			var width = limit;
			var offset = 0.0;
			if (width <= 0) {
				width = f.getWidth(str);
				offset = switch (this.alignment) {
					default: 0;
					case Center: width/2;
					case Right: width;
				}
			}
			pos.x += this.offset_x;
			pos.y += this.offset_y;

			var col = Lg.getColor();
			var r = this.actual.aux[3];
			var g = this.actual.aux[4];
			var b = this.actual.aux[5];
			var a = this.actual.aux[6];

			var stroke = this.actual.aux[0];
			var sox = this.actual.aux[1];
			var soy = this.actual.aux[2];
			
			Lg.setColor(r, g, b, a*col.a);
			if (stroke > 0 || sox != 0 || soy != 0) {
				stroke_cb(
					function(x, y) { Lg.printf(str, x, y, width, this.alignment, 0, sca.x, sca.y); },
					Std.int(pos.x - offset), Std.int(pos.y), stroke, sox, soy, this.stroke_r, this.stroke_g, this.stroke_b, this.stroke_a
				);
			}
			else {
				Lg.printf(str, Std.int(pos.x - offset), Std.int(pos.y), width, this.alignment, 0, sca.x, sca.y);
			}
			Lg.setFont(of);
			Lg.setColor(col.r, col.g, col.b, col.a);
		}
	}

	public function set_stroke_color(r: Float, g: Float, b: Float, a: Float = 1.0) {
		this.stroke_r = r;
		this.stroke_g = g;
		this.stroke_b = b;
		this.stroke_a = a;
	}

	public function set_stroke(thickness: Float, x: Float, y: Float) {
		this.set_aux(thickness, 0);
		this.set_aux(x, 1);
		this.set_aux(y, 2);

		return this;
	}

	public function set_color(r: Float, g: Float, b: Float, a: Float = 1.0) {
		this.set_aux(r, 3);
		this.set_aux(g, 4);
		this.set_aux(b, 5);
		this.set_aux(a, 6);
		return this;
	}

	public function set_limit(width: Float) {
		this.limit = width;
	}

	public function set_font(f: love.graphics.Font) {
		this.font = f;
	}

	public function set_align(align: love.graphics.AlignMode) {
		this.alignment = align;
	}

	public function set_prefix(text: String) {
		this.prefix = text;
	}

	public function set_suffix(text: String) {
		this.suffix = text;
	}

	public function set_text(text: String) {
		this.text = text;
	}
}
