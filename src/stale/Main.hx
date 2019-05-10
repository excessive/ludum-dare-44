// import backend.Log;
import utils.OptionHelper;
import math.Quat;
import render.TextureCache;
import render.MaterialCache;
import backend.Input;
import anim9.Anim9;
import math.Utils;
import math.Vec3;
import backend.BaseGame;
import backend.GameLoop;
import backend.Gc;
import backend.Profiler;
import components.*;
import math.Vec4;
import systems.*;
import backend.Anchor;
import utils.RecycleBuffer;
import loaders.IqmLoader;
import loaders.TiledMapLoader;
import node.*;
import editor.Editor;

class Main extends BaseGame {
	public static var game_title = "Minigaea";
	public static var scene: Scene;

	var systems:       Array<System>;
	var lag:           Float = 0.0;
	var current_state: RecycleBuffer<Entity>;
	public static var timestep(default, never): Float = 1 / 60;

	public static function get_map(): SceneNode {
		return scene.get_child("Map").sure();
	}

	public static var spawn_transform(default, null): Transform;

	public static function new_scene() {
		// paranoid memory release of everything in the old scene
		if (scene != null) {
			scene.release();
		}
		scene = new Scene();

		// clean out the old map and entities
		Gc.run(true);

		Time.set_time(10);

		// scene.add(World.load("assets/models/token.iqm", false, true));
		// scene.add(World.load("assets/stages/city.exm", true, true));

		inline function load_extras(filename: String, collision: Bool) {
			if (collision) {
				return World.load(filename, true, false);
			}
			var node = new SceneNode();
			node.drawable = IqmLoader.load_file(filename, collision);
			return node;
		}

		var axis = load_extras("assets/models/debug/axis.iqm", false);
		axis.transform.position.z += 1.0;
		axis.transform.scale *= 0.1;
		axis.transform.is_static = true;
		axis.transform.update();
		scene.add(axis);
		scene.add(TiledMapLoader.load_map("assets/map.json"));
		scene.update_octree();

		// scene.add(load_extras("assets/models/ricarten.exm", false));

		spawn_transform = TiledMapLoader.home_tile.transform.copy();

		// scene.add(load_extras("assets/stages/terrain.exm", false));

		// clean out the temporary data from stage load
		// these help prevent a large memory usage spike on level reload
		Gc.run(true);

		GameInput.lock();

		inline function load_animated(filename, trackname, pos) {
			var ret = new SceneNode();
			ret.drawable = IqmLoader.load_file(filename);
			if (ret.drawable.length > 0) {
				var anim = ret.drawable[0].iqm_anim;
				if (anim != null) {
					ret.animation = new Anim9(anim);

					var t = ret.animation.new_track(trackname);
					ret.animation.play(t);
					ret.animation.update(0);
				}
				else {
					trace("no anim");
				}
			}
			else {
				trace("load fail");
			}
			ret.transform.position.set_from(pos);
			return ret;
		}

		// scene.add(load_animated("assets/models/farmer.exm", "run", new Vec3(0, 0, 0)));
		// scene.add(load_animated("assets/models/hunter.iqm", "idle", new Vec3(5, 0, 0)));

		var player        = new SceneNode();
		player.player     = new Player();
		player.name       = "Korbo";
		player.collidable = new Collidable();
		player.collidable.radius.set_xyz(0.35, 0.35, 0.85);
		player.drawable   = IqmLoader.load_file("assets/models/hunter.iqm");
		player.pawn       = Unit;

		player.transform.position = spawn_transform.position;
		if (player.drawable.length > 0) {
			for (d in player.drawable) {
				d.material = "player";
			}
			var anim = player.drawable[0].iqm_anim;
			if (anim != null) {
				player.animation = new Anim9(anim);
			}
		}

		scene.add(player);
		Render.player = player;

		var cam = new Camera(player.transform.position);

		cam.orientation = new Quat(0, 0, 0, 1)
			* Quat.from_angle_axis(Utils.rad(-30), Vec3.right())
			* Quat.from_angle_axis(Utils.rad(-45), Vec3.up())
		;
		cam.orientation.normalize();
		Render.camera = cam;

		var g = new NodeGraph("Map");
		var e = NodeList.create(EventLoad, new Vec3(0, 0, 0));
		var add = NodeList.create(SceneAdd, new Vec3(0, 0, 0));
		g.add(e);
		g.add(add);
		g.connect(e.outputs[0], add.inputs[0]);

		var file = NodeList.create(ValueString, new Vec3(0, 0, 0));
		file.defaults[0] = "assets/models/token.iqm";
		g.add(file);

		var d = NodeList.create(DrawableNew, new Vec3(0, 0, 0));
		g.add(d);
		g.connect(d.outputs[0], add.inputs[1]);

		g.connect(file.outputs[0], d.inputs[0]);

		var b = NodeList.create(TransformNew, new Vec3(0, 0, 0));
		g.add(b);
		g.connect(b.outputs[0], add.inputs[2]);

		if (g.compile()) {
			trace('compiled graph, running...');
			g.execute("load");
		}
	}

	override function quit(): Bool {
		return false;
	}

	override function load(window, args) {
		love.mouse.MouseModule.setVisible(true);

		backend.Log.set_visibility(Custom("UI"), true);

		// Bgm.load_tracks(["assets/bgm/12. Beneath the Mask -rain-.mp3"]);

		Sfx.init();

		Signal.register("quiet", (_) -> { Bgm.set_ducking(0.25); Sfx.menu_pause(true);  });
		Signal.register("loud",  (_) -> { Bgm.set_ducking(0.5);  Sfx.menu_pause(false); });
		Signal.emit("loud");

		// TODO: only fire on the currently active gamepad(s)
		Signal.register("vibrate", function(params: { power: Float, duration: Float, ?weak: Bool  }) {
			var lpower = params.power;
			var rpower = params.power;
			if (params.weak != null && params.weak) {
				rpower *= 0;
			}

			var js: lua.Table<Int, love.joystick.Joystick> = cast love.joystick.JoystickModule.getJoysticks();
			var i = 0;
			while (i++ < love.joystick.JoystickModule.getJoystickCount()) {
				if (!js[i].isGamepad()) {
					continue;
				}
				js[i].setVibration(lpower, rpower, params.duration);
			}
		});

		Signal.register("rail-on", (_) -> {
			Sfx.grind.play();
		});

		Signal.register("rail-off", (_) -> {
			Sfx.grind.stop();
		});

		Signal.register("collected-item", (_) -> {
			Sfx.coin.play();
		});

		GameInput.init();
		GameInput2.init();
		Time.init();
		Render.init();

		editor.Editor.init();

		systems = [
			new ItemEffect(),
			new Trigger(),
			new PawnUnit(),
			new PawnCursor(),
			new ParticleEffect(),
			new Animation(),
		];
		new_scene();

		Signal.emit("resize", Anchor.get_viewport());

		// hack: this should be done in a non-bindy way in PlayerController
		GameInput.bind_scroll(function(x, y) {
			if (GameInput.locked /* || lose */) { return; }

			var p = Render.player.player;
			p.target_distance -= y * 0.5;
			// player clamps this
			// p.target_distance = Utils.clamp(orbit, p.orbit_min, p.orbit_max);
		});
		// force a tick on the first frame if we're using fixed timestep.
		// this prevents init bugs
		if (timestep > 0) {
			tick(timestep, window);
		}
	}

	public static var node_context(default, null): {
		entity: Entity,
		scene: Scene
	} = {
		entity: null,
		scene: null
	};
	public static var current_entity(default, null): Entity;

	function tick(dt: Float, window: backend.Window) {
		Profiler.push_block("Tick");
		GameInput.update(dt);
		Time.update(dt);
		// Stage.update(dt);

		var show_mouse = GameInput.locked;
		show_mouse = show_mouse || Input.is_down("lalt") || Input.is_down("ralt");
		show_mouse = !show_mouse;
		editor.Editor.context.input_locked(show_mouse);
		Input.set_relative(show_mouse);

		editor.Editor.update(dt);

		Signal.update(dt);
		Bgm.update(dt);

		// order-insensitive updates can self register
		Profiler.push_block("SelfUpdates");
		Signal.emit("update", dt);
		Profiler.pop_block();

#if (imgui || debug)
		GameInput.bind(Debug_F8, function() {
			Signal.emit("advance-day");
			return true;
		});
#end

		GameInput.bind(Debug_F6, function() {
			Render.potato_mode = !Render.potato_mode;
			var size = window.get_size();
			Render.reset(size.width, size.height);
			return true;
		});

		GameInput.bind(Debug_F5, function() {
			MaterialCache.flush();
			TextureCache.flush();
			new_scene();
			return true;
		});

#if 0
		GameInput.bind(Debug_F6, function() {
			trace("nvm back");
			Bgm.prev();
			return true;
		});

		GameInput.bind(Debug_F7, function() {
			trace("skip");
			Bgm.next();
			return true;
		});
#end

		GameInput.bind(Debug_F3, function() {
			Signal.emit("toggle-rain");
			return true;
		});

		var cam = Render.camera;
		cam.last_orientation = cam.orientation;
		cam.last_target   = cam.target;

		var entities = scene.get_entities();

		Profiler.push_block("TransformCache");
		for (e in entities) {
			current_entity = e;
			if (e.item != null) {
				switch (e.item) {
					// case Rail(capsules): {
					// 	for (segment in capsules) {
					// 		Debug.capsule(segment, 1, 0, 1);
					// 	}
					// 	rails.push(e);
					// }
					default:
				}
			}
			if (!e.transform.is_static) {
				e.last_tx.position.set_from(e.transform.position);
				e.last_tx.orientation.set_from(e.transform.orientation);
				e.last_tx.scale.set_from(e.transform.scale);
				e.last_tx.velocity.set_from(e.transform.velocity);
			}
		}
		Profiler.pop_block();

		var relevant = [];
		for (system in systems) {
			Profiler.push_block(system.PROFILE_NAME, system.PROFILE_COLOR);
			relevant.resize(0);
			for (entity in entities) {
				if (system.filter(entity)) {
					relevant.push(entity);
					system.process(entity, dt);
				}
			}
			system.update(relevant, dt);
			Profiler.pop_block();
		}

		Profiler.pop_block();
	}

	public static var frame_graph(default, null): Array<Float> = [ for (i in 0...250) 0.0 ];

	var last_vp: Vec4;

	override function update(window, dt: Float) {
		var vp = Anchor.get_viewport();
		if (vp != last_vp) {
			last_vp = vp;
			Signal.emit("resize", vp);
		}

		frame_graph.push(dt);
		while (frame_graph.length > 250) {
			frame_graph.shift();
		}

		if (timestep < 0) {
			tick(dt, window);
			current_state = scene.get_entities();
			return;
		}

		lag += dt;

		while (lag >= timestep) {
			lag -= timestep;
			if (lag >= timestep) {
				Debug.draw(true);
				Debug.clear_capsules();
			}
			tick(timestep, window);
		}

		current_state = scene.get_entities();
	}

	override function mousemoved(x: Float, y: Float, dx: Float, dy: Float) {
		Editor.context.mouse_moved(Std.int(x), Std.int(y), Std.int(dx), Std.int(dy));
	}

	override function mousepressed(x: Float, y: Float, button: Int) {
		GameInput.mousepressed(x, y, button);
		Editor.context.mouse_pressed(Std.int(x), Std.int(y), button);
	}

	override function mousereleased(x: Float, y: Float, button: Int) {
		GameInput.mousereleased(x, y, button);
		Editor.context.mouse_released(Std.int(x), Std.int(y), button);
	}

	override function textinput(str: String) {
		Editor.context.text_input(str);
	}

	override function wheelmoved(x: Float, y: Float) {
		GameInput.wheelmoved(x, y);
		Editor.context.mouse_wheel(Std.int(x), Std.int(y));
	}

	override function keypressed(key: String, scan: String, isrepeat: Bool) {
		if (!isrepeat) {
			GameInput.keypressed(scan);
		}
		Editor.context.key_pressed(key, isrepeat);
	}

	override function keyreleased(key: String, scan: String) {
		GameInput.keyreleased(scan);
		Editor.context.key_released(key);
	}

	override function resize(w, h) {
		Render.reset(w, h);
		Editor.context.resize(w, h);
	}

	override function draw(window) {
		var alpha = lag / timestep;
		if (timestep < 0) {
			alpha = 1;
		}
		var visible = scene.get_visible_entities();
		Profiler.push_block("Render");
		Render.frame(window, visible, alpha);
		Profiler.pop_block();
	}

	static function main() {
		// var g = new BaseGameX();
		// g.hook(Update, () -> {
		// 	//
		// });
#if (debug || !release)
		return GameLoop.run(new Main());
#else
		return GameLoop.run(new Splash());
#end
	}
}
