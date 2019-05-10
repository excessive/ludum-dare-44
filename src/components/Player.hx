package components;

import math.Quat;
import math.Utils;
import math.Vec3;

import ini.IniFile;
import backend.Fs;

private typedef PlayerConfig = {
	camera: {
		orbit_min: Float,
		orbit_max: Float
	},
	ground: {
		friction: Float,
		speed: Float,
		max_speed: Float
	}
}

enum State {
	Safe;
	Danger;
}

class Player {
	public var state = Safe;

	// config settings, use the ini!
	public var friction:            Float;
	public var speed:               Float;
	public var speed_limit:         Float;

	public var orbit_min:           Float;
	public var orbit_max:           Float;

	public var target_distance: Float = 0.0;
	public var last_target_heading: Null<Float>;
	public var last_heading: Null<Float>;
	public var last_pitch: Null<Float>;

	public var turn_weight: Int = 3;
	public var accel: Vec3 = new Vec3(0, 0, 0);

	public var last_speed: Float = 0.0;
	public var last_vel: Float = 0.0;

	public var current_tile: Null<SceneNode>;
	public var reset_orientation: Null<Quat>;

	public var spin: Quat = new Quat(0, 0, 0, 1);
	public var lag_tilt = new Quat(0, 0, 0, 1);
	public var slope: Float = 0.0;
	public var last_target_pitch: Null<Float> = null;
	public var last_valid_positions: Array<{position: Vec3, orientation: Quat}> = [];
	public var invulnerable = false;

	public static final full_size  = 0.5;
	public static final death_size = 0.125;
	public static final hard_size  = death_size + 0.000001;

	public inline function new() {
		var player_base: PlayerConfig = {
			camera: {
				orbit_min: 2.5,
				orbit_max: 7.5
			},
			ground: {
				friction: 0.005,
				speed: 0.5,
				max_speed: 1e4
			}
		};
		var cfg = player_base;

		var filename = 'assets/physics_config.ini';
		if (Fs.is_file(filename)) {
			cfg = IniFile.parse_typed(player_base, filename);
			console.Console.ds('loaded config $filename');
		}

		this.friction = Utils.clamp(cfg.ground.friction, 0.0, 100.0);
		this.speed = Utils.max(0.0, cfg.ground.speed);
		this.speed_limit = Utils.max(0.0, cfg.ground.max_speed);

		// swap if needed
		this.orbit_min = Utils.min(cfg.camera.orbit_min, cfg.camera.orbit_max);
		this.orbit_max = Utils.max(cfg.camera.orbit_min, cfg.camera.orbit_max);
	}
}
