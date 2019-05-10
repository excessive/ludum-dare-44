package exwidgets;

import math.ColorUtils;
import math.Triangle;
import math.Vec3;
import exwidgets.Renderer;
import exwidgets.ui.Skin;

@:publicFields
class Geometry {
	static function push_outline(buf: Array<UiLine>, x: Float, y: Float, w: Float, h: Float, inset: Bool, ?force_color: Int) {
		var bright = Skin.OUTLINE_COLOR_BRIGHT;
		var dim = Skin.OUTLINE_COLOR_DIM;
		if (inset) {
			var tmp = bright;
			bright = dim;
			dim = tmp;
		}
		if (force_color != null) {
			var c = ColorUtils.decodeRGBA8(force_color);
			bright = c;
			dim = c;
		}
		buf.push(new UiLine([x+1, y, 0], [x+w, y, 0], bright)); // top across
		buf.push(new UiLine([x+w, y, 0], [x+w, y+h, 0], bright)); // right down
		buf.push(new UiLine([x+1, y+h-1, 0], [x+w-1, y+h-1, 0], dim)); // bottom across
		buf.push(new UiLine([x+1, y+h, 0], [x+1, y, 0], dim)); // left up
	}
	static function push_rectangle(
		buf: Array<UiTriangle>,
		x: Float, y: Float,
		w: Float, h: Float,
		rgba: Int, ?adjust: Float = 0
	) {
		var t = ColorUtils.adjust(ColorUtils.decodeRGBA8(rgba), adjust);
		var b = ColorUtils.adjust(ColorUtils.decodeRGBA8(rgba), -adjust);
		buf.push(new UiTriangle(
			Triangle.without_normal(
				new Vec3(x, y, 0),
				new Vec3(x + w, y, 0),
				new Vec3(x + w, y + h, 0)
			),
			0, 1, t,
			1, 1, t,
			1, 0, b
		));
		buf.push(new UiTriangle(
			Triangle.without_normal(
				new Vec3(x, y, 0),
				new Vec3(x + w, y + h, 0),
				new Vec3(x, y + h, 0)
			),
			0, 1, t,
			1, 0, b,
			0, 0, b
		));
	}
}
