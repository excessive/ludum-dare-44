package backend.love;

import love.graphics.GraphicsModule as Lg;
import love.window.WindowModule as Lw;
import love.event.EventModule as Le;
import lua.Table;

class Window {
	public function new() {}
	public function open(w: Int, h: Int) {
		var flags = Table.create([], {
			vsync: true,//#if debug false #else true #end,
			msaa: 1,
			resizable: true
		});
		var ps = Lw.getDPIScale();
		Lw.setMode(w*ps, h*ps, flags);
		Lw.setTitle(Main.game_title);
#if !debug
		Lw.maximize();
#end
	}
	public function close() {}
	public function get_framebuffer_size() {
		return {
			width: Std.int(Lg.getWidth()),
			height: Std.int(Lg.getHeight())
		};
	}
	public function is_open() {
		return Lw.isOpen();
	}
	public function present() {
		Lg.present();
	}
	public function poll_events() {
		Le.pump();
		return;
	}
	public static function to_pixels(dp: Float) {
		return Lw.toPixels(dp);
	}
}
