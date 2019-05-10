package ini;

import lua.Table;

// config files shouldn't be finicky. make them more forgiving.
abstract BuildNoCase<T>(T) {
	public function new(build: T, data: Dynamic) {
		// remove whitespace, casing and underscores so we can match
		// things like `white_point` to `WhitePoint `
		function mangle(name: String) {
			var s = name.toLowerCase();
			s = StringTools.trim(s);
			s = StringTools.replace(s, "_", "");
			return s;
		}
		function match_fields(a: T, b: Dynamic): Array<{src: String, dst: String}> {
			var afields = new Map<String, String>();
			for (f in Reflect.fields(a)) {
				afields[mangle(f)] = f;
			}
			var bfields = new Map<String, String>();
			for (f in Reflect.fields(b)) {
				bfields[mangle(f)] = f;
			}
			var fields = [];
			for (f in afields.keys()) {
				if (bfields.exists(f)) {
					var pair = { src: bfields[f], dst: afields[f] }
					fields.push(pair);
					// trace('${pair.src} => ${pair.dst}');
				}
			}
			return fields;
		}
		var sections = match_fields(build, data);
		for (f in sections) {
			var section_type = Reflect.field(build, f.dst);
			var section_data = Reflect.field(data, f.src);
			var keys = match_fields(section_type, section_data);
			for (k in keys) {
				var value = Reflect.field(section_data, k.src);
				// trace('${f.src}.${k.src} => ${f.dst}.${k.dst} = $value');
				Reflect.setField(section_type, k.dst, value);
			}
			Reflect.setField(build, f.dst, section_type);
		}
		this = build;
	}
	@:to
	public function toData(): T {
		return this;
	}
}

@:luaRequire("inifile")
extern class IniFile {
	static function parse(name: String, ?backend: String): Dynamic;
	static inline function parse_typed<T>(build: T, filename: String): T {
		var data = IniFile.parse(filename);
		return new BuildNoCase<T>(build, data);
	}

	@:native("save")
	private static function _save(name: String, data: lua.Table<String, Dynamic>, ?backend: String): Void;
	static inline function save(name: String, data: Dynamic, ?backend: String): Void {
		var fields = Reflect.fields(data);
		var t: Table<String, Dynamic> = Table.create();
		for (f in fields) {
			t[cast f] = Reflect.getProperty(data, f);
		}
		return _save(name, t, backend);
	}
}
