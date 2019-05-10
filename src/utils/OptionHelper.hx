package utils;

import haxe.ds.Option;

class OptionHelper {
	@:nullSafety(Off)
	public static function unwrap_fail<T>(option: Option<T>, ?pos: haxe.PosInfos): T {
		switch (option) {
			case Some(v): return v;
			case None: throw 'missing value from ${pos.className + "." + pos.methodName + "@" + pos.fileName + ":" + Std.string(pos.lineNumber)}';
		}
	}
	public static inline function unwrap_apply<T>(option: Option<T>, cb: T->Void) {
		switch (option) {
			case Some(v): cb(v);
			default:
		}
	}
	public static inline function unwrap<T>(option: Option<T>, _default: T): T {
		return switch (option) {
			case Some(v): v;
			case None: _default;
		}
	}
}
