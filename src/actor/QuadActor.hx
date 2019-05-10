package actor;

import math.Vec3;
import love.graphics.GraphicsModule as Lg;

class QuadActor extends Actor {
	override function get_width() return this.actual.aux[0];
	override function get_height() return this.actual.aux[1];

	// override function hit(x: Float, y: Float, hits: Array<Actor>) {
	// 	trace("habbening");
	// }

	public function new(?initfn: QuadActor->Void) {
		super();

		this.set_size(1, 1);
		this.set_color(1, 1, 1, 1);
		if (initfn != null) {
			initfn(this);
		}

		this.on_draw = (_) -> {
			var col = Lg.getColor();

			var r = this.actual.aux[2];
			var g = this.actual.aux[3];
			var b = this.actual.aux[4];
			var a = this.actual.aux[5];

			var pos = this.final_position;
			var sca = this.actual.scale;
			Lg.setColor(r, g, b, a*col.a);
			Lg.rectangle(Fill, Std.int(pos.x + this.offset_x), Std.int(pos.y + this.offset_y), this.width*sca.x, this.height*sca.y);
			Lg.setColor(col.r, col.g, col.b, col.a);
		}
	}

	public function set_size(w: Float, h: Float) {
		this.set_aux(w, 0);
		this.set_aux(h, 1);
		return this;
	}

	public function set_color(r: Float, g: Float, b: Float, a: Float = 1.0) {
		this.set_aux(r, 2);
		this.set_aux(g, 3);
		this.set_aux(b, 4);
		this.set_aux(a, 5);
		return this;
	}
}
