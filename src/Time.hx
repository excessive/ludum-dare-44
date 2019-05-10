import math.Quat;
import math.Vec3;
import math.Utils;

import backend.Fs;
import ini.IniFile;

private typedef TimeConfig = {
	time: {
		day_length_minutes: Float,
		year_length_days: Float,
		time_scale: Float
	}
}

abstract ClockTime(Float) {
	public static function load_config() {
		var time_base: TimeConfig = {
			time: {
				day_length_minutes: 24,
				year_length_days: 40,
				time_scale: 1.0
			}
		}

		var cfg = time_base;
		var filename = 'assets/time_config.ini';
		if (Fs.is_file(filename)) {
			cfg = IniFile.parse_typed(time_base, filename);
			console.Console.ds('loaded config $filename');
		}

		YEAR_LENGTH_DAYS = Utils.max(1.0, cfg.time.year_length_days);
		DAY_LENGTH_MINUTES = Utils.max(0.01, cfg.time.day_length_minutes);
		TIME_SCALE = Utils.max(0.0, cfg.time.time_scale);
	}

	static var TIME_SCALE = 1.0;

	public static var YEAR_LENGTH_DAYS(get, null): Float;
	static inline function get_YEAR_LENGTH_DAYS() return 40.0;

	public static var DAY_LENGTH_MINUTES(get, null): Float;
	static inline function get_DAY_LENGTH_MINUTES() return 5.0;

	public static var HOURS_PER_MINUTE(get, null): Float;
	static inline function get_HOURS_PER_MINUTE() return 24.0 / DAY_LENGTH_MINUTES;

	public inline function new(v: Float) {
		this = v;
	}

	public inline static function from_hour(v: Float) {
		return new ClockTime(v / HOURS_PER_MINUTE * 60.0);
	}

	public inline function to_hour24f() {
		return this * HOURS_PER_MINUTE / 60.0;
	}

	public inline function to_hour24() {
		return Std.int(this * HOURS_PER_MINUTE / 60.0);
	}

	public inline function to_hour12() {
		var h12 = to_hour24() % 12;
		return h12 == 0 ? 12 : h12;
	}

	public inline function to_minute() {
		return Std.int(this * HOURS_PER_MINUTE) % 60;
	}

	public inline function update(dt: Float) {
		this += dt * TIME_SCALE;
	}

	@:to
	inline function to_float(): Float {
		return this;
	}
}

@:native("GameTime")
class Time {
	static var SEASON_INFLUENCE = 0.85;
	// static var SEASON_INFLUENCE = 0.99;
	static var time: ClockTime;
	static var day = 1;

	public static var current_day(get, never): Int;
	public static inline function get_current_day() { return day; }

	public static var current_time(get, set): ClockTime;
	public static inline function get_current_time() { return time; }
	public static inline function set_current_time(_t: ClockTime) { time = _t; return _t; }

	public static var sun_direction(default, null): Vec3;
	public static var sun_brightness(default, null): Float;

	public static inline function init() {
		ClockTime.load_config();
		set_time(10);
	}

	public static function set_time(wall_time: Float) {
		time = ClockTime.from_hour(wall_time);
		update(0);
	}

	static function wrap_clock() {
		var now: Float = time;

		// reset timer every day.
		while (now >= ClockTime.DAY_LENGTH_MINUTES * 60.0) {
			now -= ClockTime.DAY_LENGTH_MINUTES * 60.0;
			time = new ClockTime(now);
			day += 1;
		}
	}

	static function update_sun() {
		var now: Float = time;
		
		// Sun rises in the east
		// LD42: BUT NOT ON THIS PLANET
		var rotation = Quat.from_angle_axis(Utils.rad(90.0), Vec3.unit_z());
		rotation *= Quat.from_angle_axis(now * (Math.PI * 2) / 60 / ClockTime.DAY_LENGTH_MINUTES, Vec3.unit_x());

		// start at -1 so midnight is down.
		var basis = new Vec3(0, 0, -1);
		basis.normalize();

		sun_direction = rotation * basis;
		var bend = Math.sin((day / ClockTime.YEAR_LENGTH_DAYS) * Math.PI * 2.0);
		sun_direction.z += bend * SEASON_INFLUENCE;
		sun_direction.normalize();

		sun_brightness = Math.pow(Utils.clamp(Vec3.dot(sun_direction, Vec3.up()) + 0.35, 0, 1), 3);
	}

	public static function update(dt: Float) {
		if (GameInput.locked || console.Console.visible) {
			dt = 0;
		}
		time.update(dt);
		wrap_clock();
		update_sun();
	}
}
