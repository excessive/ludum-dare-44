package console;

import love.graphics.Font;
import lua.Table;
import lua.Lib;

@:luaRequire("console")
extern class Console {
	static var fontSize(default, null): Float;
	static var visible(default, null): Bool;
	static var dopefish: Bool;

	static function load(?font: Font, ?keyRepeat: Bool = false, ?inputCallback: String->Void): Void;
	static function resize(w: Float, h: Float): Void;
	static function show(visible: Bool): Void;

	static function keypressed(k: String): Bool;
	static function textinput(t: String): Bool;
	static function textedited(t: String, s: String, l: String): Void;
	static function focus(f: Bool): Void;

	static function update(dt: Float): Void;
	static function draw(?popup: Bool): Void;

	@:native("defineCommand")
	private static function _define_command(command: String, help: String, fn: String->Table<Int, String>->Void, ?hidden: Bool): Void;

	static inline function define_command(command: String, help: String, fn: String->Array<String>->Void, ?hidden: Bool): Void {
		function _fn(raw: String, args: Table<Int, String>) {
			fn(raw, Lib.tableToArray(args));
		}
		_define_command(command, help, _fn, hidden);
	}

	static function es(s: String): Void;
	static function ds(s: String): Void;
	static function is(s: String): Void;
}
