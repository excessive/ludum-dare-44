package exwidgets.ui;

private enum BindStatus {
	Default;
	User;
}

typedef BindData = {
	var type: BindStatus;
	var mapping: String;
}

class Keybind {
	static var binds = new Map<String, BindData>();
	static var reverse = new Map<String, String>();

	public static final Default = Default;
	public static final User    = User;

	public static function check() {
		for (k in Keyboard.keystate.keys()) {
			if (!Keyboard.isBindable(k)) {
				continue;
			}

			var kstr = "";
			if (Keyboard.isMetaDown()) {
				kstr += "Ctrl-";
			}
			if (Keyboard.isShiftDown()) {
				kstr += "Shift-";
			}
			// Ctrl-q -> Ctrl-Q, etc
			kstr += k.toUpperCase();

			if (reverse.exists(kstr)) {
				OperatorList.execute(reverse[kstr]);
			}
		}
	}

	public static function get(op: String): Null<BindData> {
		if (binds.exists(op)) {
			return binds.get(op);
		}
		return null;
	}

	public static function set(op: String, mapping: BindData) {
		binds.set(op, mapping);
		reverse.set(mapping.mapping, op);
	}
}
