import love.audio.AudioModule as La;
import love.audio.Source;
import love.filesystem.FilesystemModule as Lf;
import haxe.Json;

class Sfx {
	public static var rain: Source;
	public static var rip_in_pieces: Source;
	public static var alert: Source;
	public static var plop: Source;

	static var all_sounds: Array<Source> = [];

	static var volume = 1.0;

	static var rain_vol = 1.5;
	public static function set_ducking(v: Float) {
		rain.setVolume((1.0-v)*volume*rain_vol);
	}

	public static function init() {
		final file = Lf.read("options.json").contents;
		if (file != null && file.length > 0) {
			final options = Json.parse(file);
			volume = options.sfx * options.master;
		}

		//if (rip_in_pieces == null) {
		//	rip_in_pieces = La.newSource("assets/tmp/mgs game over.mp3", Static);
		//	rip_in_pieces.setVolume(volume);
		//}

		if (alert == null) {
			alert = La.newSource("assets/sfx/thot.ogg", Static);
			alert.setVolume(volume);
		}

		if (plop == null) {
			plop = La.newSource("assets/sfx/plop.ogg", Static);
			plop.setVolume(volume*0.85);
		}

		if (rain == null) {
			rain = La.newSource("assets/sfx/rain.ogg", Static);
			rain.setVolume(volume*rain_vol);
			rain.setLooping(true);
		}

		// add all long or looping sfx here
		all_sounds = [
			// rip_in_pieces,
			alert,
			plop,
			rain
		];
	}

	static var holding = [];

	public static function menu_pause(set: Bool) {
		if (set) {
			for (s in all_sounds) {
				if (s.isPlaying()) {
					s.pause();
					if (holding.indexOf(s) < 0) {
						holding.push(s);
					}
				}
			}
		}
		else {
			for (s in holding) {
				s.play();
			}
			holding.resize(0);
		}
	}

	public static function get_volume() {
		return volume;
	}

	public static function stop_all() {
		for (s in all_sounds) {
			s.stop();
		}
	}
}
