package backend;

enum Level {
	Debug;
	Info;
	Item;
	Quest;
	System;
	Render;
	Error;
	Perf;
	Custom(reason: String);
}

class Log {
	public static var messages(default, null): Array<String> = [];
	static var scrollback = 512;

	static var show_levels = new Map<Level, Bool>();

	public static inline function set_visibility(key: Level, v: Bool) {
		show_levels[key] = v;
	}

	static function round(value: Float, ?precision: Float): Float {
		if (precision != null) {
			return round(value / precision) * precision;
		}
		return value >= 0 ? Math.floor(value+0.5) : Math.ceil(value-0.5);
	}

	public static inline function perf(msg: String, time: Float, ?pos: haxe.PosInfos) {
		// var t = round(time*1000, 0.01);
		// write(Perf, '$msg took ${t}ms');
		perf_us(msg, time, pos);
	}

	public static function perf_us(msg: String, time: Float, ?pos: haxe.PosInfos) {
		var t = round(time*1000000, 0.01);
		write(Perf, '$msg took ${t}us');
	}

	public static inline function measure_perf(msg: String, cb: Void->Void, ?pos: haxe.PosInfos) {
		perf(msg, Timer.measure(cb));
	}

	public static inline function measure_perf_us(msg: String, cb: Void->Void, ?pos: haxe.PosInfos) {
		perf_us(msg, Timer.measure(cb));
	}

	public static function write(level: Level, msg: String, ?pos: haxe.PosInfos) {
		var param = level.getParameters();
		var line = "[" + level.getName() + "] ";
		if (param[0] != null) {
			line = "[" + param[0] + "] ";
		}

		if (level == Error) {
			msg += ' (from ${pos.fileName}:${pos.lineNumber}@${pos.methodName})';
		}

		line += msg;

		messages.push(line);
		while (messages.length >= scrollback) {
			messages.shift();
		}

		if (!show_levels.exists(level) || (show_levels.exists(level) && !show_levels.get(level))) {
			return;
		}

		Sys.println(line);
	}
}
