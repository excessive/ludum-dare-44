package utils;

import haxe.ds.Option;

class CacheResource<T, Options> {
	var storage: Map<String, T>;
	var ignore: Map<String, Bool>;
	var loader: String->Options->T;

	public function new(load_cb: String->Options->T) {
		this.loader = load_cb;
		this.clear();
	}

	public function inject(name: String, data: T) {
		storage[name] = data;
	}

	@:nullSafety(Off)
	public function get(filename: String, options: Options): Option<T> {
		if (this.ignore.exists(filename)) {
			return None;
		}
		if (this.storage.exists(filename)) {
			return Some(this.storage[filename]);
		}
		var res = this.loader(filename, options);
		if (res == null) {
			this.ignore[filename] = true;
			if (res == null) {
				throw 'Unable to load resource $filename';
			}
			return None;
		}
		this.storage[filename] = res;
		return Some(res);
	}

	public function evict(key: String) {
		this.storage.remove(key);
		this.ignore.remove(key);
	}

	public inline function clear() {
		this.storage = new Map<String, T>();
		this.ignore = new Map<String, Bool>();
	}
}
