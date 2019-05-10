package utils;

import backend.Timer;

class UUID {
	public static function uuid() {
		// Based on https://gist.github.com/LeverOne/1308368
		var uid = new StringBuf(), a = 8;
		uid.add(StringTools.hex(Std.int(Timer.get_time()), 8));
		while((a++) < 36) {
			uid.add(a*51 & 52 != 0
				? StringTools.hex(a^15 != 0 ? 8^Std.int(Math.random() * (a^20 != 0 ? 16 : 4)) : 4)
				: "-"
			);
		}
		return uid.toString().toLowerCase();
	}
}
