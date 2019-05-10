package render;

import utils.OptionHelper;
import backend.Timer;
#if lua
import love.graphics.Image;
import love.graphics.GraphicsModule as Lg;
#end
import utils.CacheResource;

import haxe.ds.Option;

class TextureCache {
	static var cache = new CacheResource<Image, Bool>((filename: String, mips: Bool) -> {
#if debug
		console.Console.ds('cached $filename');
#end
		if (mips) {
			var flags: lua.Table<String, Dynamic> = untyped __lua__("{ mipmaps = true }");
			return Lg.newImage(filename, flags);
		}
		return Lg.newImage(filename);
	});

	static var ages = new Map<String, Float>();

	// time in seconds until unused textures get released
	static var evict_age: Float = 30;

	public static function pin(filename: String, mips: Bool = false) {
		if (get(filename, mips) != null) {
			ages[filename] = -1;
		}
	}

	public static function get(filename: String, mips: Bool = false): Option<Image> {
		var now = Timer.get_time();
		return switch (cache.get(filename, mips)) {
			case Some(v):
				var age = ages[filename];
				if (age != null && age >= 0) {
					ages[filename] = now;
				}
				Some(v);
			case None: None;
		}
	}

	public static function flush() {
		cache.clear();
		ages = new Map<String, Float>();
	}

	public static function free_unused() {
		var now = Timer.get_time();
		for (k in ages.keys()) {
			if (ages[k] < 0) {
				continue;
			}
			if (now - ages[k] > evict_age) {
				OptionHelper.unwrap_fail(cache.get(k, false)).release();
				cache.evict(k);
				ages.remove(k);
#if debug
				console.Console.ds('evicted $k');
#end
			}
		}
	}
}
