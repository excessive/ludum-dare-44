package backend.love;

import lua.Lib;
import haxe.io.Bytes;
import love.filesystem.FilesystemModule as LoveFs;
import lua.PairTools;

class Fs {
	public static function is_user(filename: String): Bool {
		return LoveFs.getRealDirectory(filename) == LoveFs.getSaveDirectory();
	}

	public static function get_last_modified(filename: String): Float {
		var last_mod = LoveFs.getLastModified(filename);
		if (last_mod != null) {
			return last_mod.modtime;
		}
		return 0.0;
	}

	public static function is_file(filename: String): Bool {
		return LoveFs.isFile(filename);
	}

	public static function is_directory(filename: String): Bool {
		return LoveFs.isDirectory(filename);
	}

	public static function write(filename: String, data: String, ?size: Int): Bool {
		return LoveFs.write(filename, data, size);
	}

	public static function remove(filename: String): Bool {
		return LoveFs.remove(filename);
	}

	public static function read(filename: String, ?pos: haxe.PosInfos): Null<Bytes> {
		try {
			var data = LoveFs.read(filename);
			if (data != null && data.contents != null) {
				return Bytes.ofString(data.contents);
			}
			else {
				throw "read error";
			}
		}
		catch (e: String) {
			trace('read failure (from ${pos.fileName}:${pos.lineNumber}@${pos.methodName})');
			return null;
		}
	}

	public static function get_directory_items(path: String, full_path: Bool = true) {
		var items = LoveFs.getDirectoryItems(path);
		if (!full_path) {
			return Lib.tableToArray(items);
		}
		var ret = [];
		PairTools.ipairsEach(items, (_, file: String) -> ret.push(path + "/" + file));
		return ret;
	}
}
