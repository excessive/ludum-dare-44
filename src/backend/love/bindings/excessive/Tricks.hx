package excessive;

@:luaRequire("tricks")
extern class Tricks {
	static function prepare(): Void;
	static function set_alpha_to_coverage(enabled: Bool): Void;
}
