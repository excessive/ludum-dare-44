package actor;

import backend.Timer;
import love.graphics.GraphicsModule as Lg;
import love.graphics.Font;
import math.Vec3;

class BubbleActor extends Actor {
	var font: Font;
	var label: String;

	public static var flash(get, never): Int;
	static function get_flash(): Int {
		return flash_at(20);
	}

	public static function flash_at(rate: Int = 20): Int {
		var time = Std.int(Timer.get_time() * rate);
		return (time % 3 == 0) ? 1 : 0;		
	}

	public function new(id: Int, name: String, ?initfn: BubbleActor->Void) {
		super();

		this.label = name;
		this.set_name("bubble_" + id);
		this.set_aux(0, 1);
		this.register("show", () -> this.stop().decelerate(0.25).set_aux(1.0, 1));
		this.register("hide", () -> this.stop().decelerate(0.25).set_aux(0.0, 1).set_aux(-1));

		if (initfn != null) {
			initfn(this);
		}

		this.on_draw = function(_) {
			var of = Lg.getFont();
			var f = this.font;
			if (f == null) {
				f = of;
			}

			var lines = 1;

			var pos: Vec3 = this.user_data;
			var x = Math.ffloor(pos.x) + this.offset_x;
			var y = Math.ffloor(pos.y) + this.offset_y;
			var w = f.getWidth(this.label);
			var h = f.getHeight() * f.getLineHeight() * lines;
			var sx = this.actual.scale.x;
			var sy = this.actual.scale.y;
			var c = Lg.getColor();
			var pad = 5;
			var alpha = this.actual.aux[1] * pos.z;
			Lg.setColor(0, 0, 0, 0.95*alpha);
			Lg.rectangle(Fill, Math.floor(x - w/2 - pad), Math.floor(y - h/2 - pad), (w + pad*2) * sx, (h + pad*2) * sy, 5);
			Lg.setColor(1, 1, 1, 1*alpha);
			Lg.setFont(f);
			Lg.print(this.label, Math.floor(x - w/2), Math.floor(y - h/2), 0, sx, sy);
			Lg.setColor(c.r, c.g, c.b, c.a);
			Lg.setFont(of);
		}
	}

	public function set_font(f: Font) {
		this.font = f;
	}

	public function set_text(text: String) {
		this.label = text;
	}
}
