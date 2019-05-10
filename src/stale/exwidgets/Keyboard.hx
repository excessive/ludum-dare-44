package exwidgets;

import haxe.ds.Option;

class Keyboard {
	public static var focus: Option<exwidgets.ui.InputContext> = None;

	// static var remaps = [
	// 	"lctrl"  => "Left Ctrl",
	// 	"lshift" => "Left Shift",
	// 	"lalt"   => "Left Alt",
	// 	"lmeta"  => "Left Meta",
	// 	"rctrl"  => "Right Ctrl",
	// 	"rshift" => "Right Shift",
	// 	"ralt"   => "Right Alt",
	// 	"rmeta"  => "Right Meta"
	// ];

	public static var keystate = new Map<String, Bool>();

	public static function isDown(a: String, ?b: String) {
		var check = a;
		// check = remaps.get(a);
		if (keystate.exists(check) && keystate.get(check)) {
			return true;
		}

		if (b != null) {
			return isDown(b);
		}

		return false;
	}

	public static function isMetaDown() {
		#if macos
			return isDown("lmeta", "rmeta");
		#else
			return isDown("lctrl", "rctrl");
		#end
		return false;
	}

	public static inline function isShiftDown() {
		return isDown("lshift", "rshift");
	}

	public static function isBindable(k: String) {
		return switch (k) {
			case "lshift": false;
			case "rshift": false;
			case "lctrl":  false;
			case "rctrl":  false;
			case "lalt":   false;
			case "ralt":   false;
			case "lmeta":  false;
			case "rmeta":  false;
			default: true;
		}
	}
}
