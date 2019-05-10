import math.Utils;
import love.audio.Source;
import love.audio.AudioModule as La;
import love.filesystem.FilesystemModule as Lf;
import love.math.MathModule as Lm;
import haxe.Json;

typedef SourceInfo = {
	name: String,
	source: Source,
	position: Float,
	length2: Float // keeping this here is useful for early transitions
}

class Bgm {
	static var queue: Array<SourceInfo> = [];
	static var volume = 0.8;
	static var crossfade = 1.0;
	static var duck = 1.0;

	public static var playing_user_tracks = false;

	public static inline function set_ducking(v: Float) {
		duck = v;
		Sfx.set_ducking(v);
	}

	public static function init() {
		final file = Lf.read("options.json").contents;
		if (file != null && file.length > 0) {
			final options = Json.parse(file);
			volume = options.music * options.master;
		}
	}

	static function load(name: String) {
		var src = La.newSource('$name', Stream);
		src.setVolume(volume);
		return {
			name: name,
			source: src,
			position: 0.0,
			length2: src.getDuration()
		};
	}

	public static function next() {
		if (queue.length < 2) {
			return;
		}
		queue[0].position = 0;
		queue[0].source.stop();
		queue.push(queue.shift());
	}

	public static function prev() {
		if (queue.length < 2) {
			return;
		}
		queue[0].position = 0;
		queue[0].source.stop();
		queue.unshift(queue.pop());
	}

	public static function load_tracks(new_tracks: Array<String>, transition_now: Bool = false, shuffle: Bool = false) {
		function do_shuffle(list: Array<String>): Array<String> {
			var shuffled = [];
			var count = list.length;
			var rng = Lm.newRandomGenerator();
			rng.setSeed(backend.Timer.get_time());
			for (i in 0...count) {
				var rand = Std.int(rng.random(0, list.length-1));
				shuffled.push(list[rand]);
				list.splice(rand, 1);
			}
			return shuffled;
		}

		if (shuffle) {
			new_tracks = do_shuffle(new_tracks);
			#if debug
			for (file in new_tracks) {
				console.Console.ds('queued bgm $file');
			}
			#end
		}

		if (transition_now && queue.length > 0) {
			var playing = queue[0];
			playing.length2 = Utils.min(playing.position + crossfade, playing.length2);
			// handle transitioning when we're already in a crossfade
			var new_queue = [ playing ];
			if (queue.length > 1) {
				var next = queue[1];
				if (next.position > 0) {
					next.length2 = Utils.min(next.length2, next.position + crossfade);
				}
				new_queue.push(next);
			}
			queue = new_queue;
		}
		for (track in new_tracks) {
			queue.push(load(track));
		}
	}

	static inline function get_volume() {
		return volume*duck;
	}

	static var last_playing = null;
	public static var effect_vol = 0.0;

	public static function update(dt: Float) {
		if (queue.length == 0) {
			return;
		}

		final t = untyped __lua__("{
			type = 'equalizer',
			lowmidbandwidth = 0.0,
			highmidbandwidth = 0.0,
			highmidgain = 0.0,
			highgain = 0.0,
			lowmidgain = 0,
			highcut = 0.0,
		}");
		// lowgain = 0,
		// lowcut = 0,
		// highmidfrequency = 0,
		untyped __lua__("love.audio.setEffect({0}, {1})", 'lowpass', t);

		var playing = queue[0];
		playing.source.play();
		playing.source.setEffect('lowpass', untyped __lua__("{
			type = 'lowpass',
			volume = {0},
			highgain = 0.0,
		}", effect_vol));
		// playing.source.setVolume(1.0 - effect_vol);
		playing.source.setLooping(queue.length == 1);
		playing.position += dt;

		if (playing != last_playing) {
			console.Console.is('now playing: ${playing.name}');
		}
		last_playing = playing;

		if (queue.length > 1) {
			var next = queue[1];
			if (next.source.isPlaying()) {
				next.position += dt;
			}
			var position = playing.position;
			var fade_start = playing.length2 - crossfade;
			if (position > fade_start && crossfade > 0) {
				var fade_out = Utils.min(1.0, 1.0 - (position - fade_start) / crossfade);
				var fade_in = Utils.min(1.0, (position - fade_start) / crossfade);
				next.source.play();
				next.source.setVolume(get_volume()*fade_in);
				playing.source.setVolume(get_volume()*fade_out);

// #if imgui
// 				// cycle finished items to the end of the playlist
// 				imgui.ImGui.value("fade in", fade_in);
// 				imgui.ImGui.value("fade out", fade_out);
// #end
				if (fade_in >= 1.0) {
					playing.position = 0.0;
					playing.source.stop();
					playing.source.seek(0);
					queue.push(queue.shift());
				}
			}
			else {
				playing.source.setVolume(get_volume());
				playing.source.play();
			}
		}
		else {
			playing.source.setVolume(get_volume());
			playing.source.play();
		}
	}
}
