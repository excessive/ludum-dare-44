package exwidgets;

// import exwidgets.Document;

class OperatorList {
	static var ops = new Map<String, Void->Bool>();
	public static function register(list: Map<String, Void->Bool>) {
		for (op in list.keyValueIterator()) {
			ops.set(op.key, op.value);
		}
	}
	public static function execute(name: String) {
		if (!ops.exists(name)) {
			trace("/!\\ invalid operator: " + name);
			return;
		}
		var fn = ops.get(name);
		var commit = fn();
		if (commit) {
			// Document.setDirty();
			// Document.historyCommit();
		}
	}
	public static function lookup(name: String) {
		return ops.exists(name);
	}
}
