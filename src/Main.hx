import math.Mat4;
import backend.Input;
import anim9.Anim9; // for load_animated
import backend.Anchor;
import backend.BaseGame;
import backend.GameLoop;
import backend.Gc;
import backend.Profiler;
import components.*;
import components.Emitter.ParticleData;
import haxe.Json;
import loaders.IqmLoader;
import math.Vec3;
import math.Vec4;
import render.MaterialCache;
import render.Render;
import render.TextureCache;
import systems.*;
import utils.RecycleBuffer;

class Main extends BaseGame {
	public static var game_title = "Dunkin' Dogoos - LD44";
	public static var scene: Scene;

	var systems:       Array<System>;
	var lag:           Float = 0.0;
	var current_state: RecycleBuffer<Entity>;
	var spawn_tx:      Null<Transform>;
	public static final timestep: Float = 1 / 60;

	var rain: Emitter;

	function new_scene() {
		// paranoid memory release of everything in the old scene
		if (scene != null) {
			scene.release();
		}
		scene = new Scene();

		// clean out the old map and entities
		Gc.run(true);

		Time.set_time(10);

		CollisionWorld.clear();

		inline function load_exm(filename: String): Array<SceneNode> {
			final nodes = [];
			final iqm = iqm.Iqm.load(filename, true);
			var meta: iqm.Iqm.ExmMeta;
			if (iqm.metadata != null) {
				meta = Json.parse(iqm.metadata);
				if (meta != null) {
					final all_objects = meta.objects.concat(meta.trigger_areas);
					for (o in all_objects) {
						var position: Vec3 = [ o.position[0], o.position[1], o.position[2] ];
						var fixed_name = o.name.substr(0, o.name.lastIndexOf("."));
						final locator_node = new SceneNode();
						locator_node.name = fixed_name;
						locator_node.transform.position.set_from(position);

						locator_node.transform.orientation = new Mat4(o.transform_without_scale).to_quat();
						locator_node.transform.orientation.normalize();

						// triggers don't support non-uniform scaling, so make sure it is
						// uniform. this prevents mismatched render from hit tests, since
						// render DOES support non-uniform scaling.
						locator_node.transform.scale.set_from(o.size);
						var avg_scale = locator_node.transform.scale.length() / 2;
						locator_node.transform.scale.set_xyz(avg_scale, avg_scale, avg_scale);

						locator_node.transform.is_static = true;
						locator_node.transform.update();

						nodes.push(locator_node);
					}
				}
			}
			final collision_node = new SceneNode();
			collision_node.transform.is_static = true;
			collision_node.transform.update();
			collision_node.drawable = IqmLoader.get_views(iqm);
			nodes.push(collision_node);
			CollisionWorld.add(iqm, collision_node.transform.matrix, [ "water" ]);
			return nodes;
		}

		final hoop           = IqmLoader.load_file("assets/models/hoop.exm");
		final hoop_collision = iqm.Iqm.load("assets/models/hoop-collision.exm", true);
		final nodes          = load_exm("assets/maps/stage.exm");
		final original_tx = new Transform();
		for (node in nodes) {
			if (node.name == "spawn") {
				original_tx.set_from(node.transform);
			}
			if (node.name == "spawn" && spawn_tx == null) {
				spawn_tx = new Transform();
				spawn_tx.set_from(node.transform);
			}
			if (node.name == "goal") {
				node.drawable = hoop;
				CollisionWorld.add(hoop_collision, node.transform.matrix, []);

				final trigger_node = new SceneNode();
				trigger_node.transform.set_from(node.transform);
				// hoop trigger point is 1m down from net edge
				trigger_node.transform.position.z -= 1;
				trigger_node.transform.is_static = true;
				trigger_node.transform.update();
				trigger_node.trigger = new components.Trigger((a, b, s, d) -> {
					if (s == Entered) {
						spawn_tx.set_from(original_tx);
						if (b.player != null) {
							b.player.invulnerable = true;
						}
						Signal.emit('hud-get-dunked');
					}
				}, Radius, 0.5);
				scene.add(trigger_node);
			}
			if (node.name == "fake-goal") {
				node.drawable = hoop;
				CollisionWorld.add(hoop_collision, node.transform.matrix, []);

				final trigger_node = new SceneNode();
				trigger_node.transform.set_from(node.transform);
				// hoop trigger point is 1m down from net edge
				trigger_node.transform.position.z -= 1;
				trigger_node.transform.is_static = true;
				trigger_node.transform.update();
				trigger_node.trigger = new components.Trigger((a, b, s, d) -> {
					if (s == Entered) {
						Signal.emit('hud-sweet-dunks');
					}
				}, Radius, 0.5);
				scene.add(trigger_node);
			}
			if (node.name == "checkpoint") {
				final trigger_node = new SceneNode();
				trigger_node.transform.set_from(node.transform);
				trigger_node.transform.is_static = true;
				trigger_node.transform.update();
				trigger_node.trigger = new components.Trigger((a, b, s, d) -> {
					if (s == Entered) {
						scene.remove(trigger_node);
						spawn_tx.set_from(node.transform);
						Signal.emit("checkpoint-flavor");
					}
				}, Radius, 0.5);
				scene.add(trigger_node);
			}
			scene.add(node);
		}

		// clean out the temporary data from stage load
		// these help prevent a large memory usage spike on level reload
		Gc.run(true);

		inline function load_animated(filename, trackname) {
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
			return ret;
		}

		final player      = new SceneNode();
		player.player     = new Player();
		player.name       = "Korbo";
		player.collidable = new Collidable();
		player.collidable.radius.set_xyz(Player.full_size, Player.full_size, Player.full_size);
		player.physics    = new Physics();
		player.drawable   = IqmLoader.load_file("assets/models/slime.exm");

		player.transform.set_from(spawn_tx);
		player.transform.offset.z = 0.278856;
		player.transform.scale.set_from(player.collidable.radius);
		player.last_tx.set_from(player.transform);
		if (player.drawable.length > 0) {
			for (d in player.drawable) {
				// d.material = "player";
			}
			var anim = player.drawable[0].iqm_anim;
			if (anim != null && player.animation == null) {
				player.animation = new Anim9(anim);
			}
		}

		Weather.state = rain.enabled ? Rain : Clear;
		player.emitter.push(rain);

		// sparks
		player.emitter.push({
			data: new ParticleData(),
			enabled: false,
			limit: 5,
			pulse: 0.0,
			spawn_radius: 0.0,
			spread: 10,
			emission_rate: 60,
			emission_life_min: 1/20,
			emission_life_max: 1/10,
			drawable: IqmLoader.load_file("assets/models/spark.iqm")
		});

		scene.add(player);
		Render.player = player;

		var cam = new Camera([ 0, -5, 0.5 ]);
		// cam.orientation.set_from(Quat.from_angle_axis(Utils.rad(-90), [ 1, 0, 0 ]));
		cam.orientation.normalize();
		Render.camera = cam;

		GameInput.lock();
		Signal.emit("hud-stay-jelly");
		Signal.emit("hud-fade-in");
	}

	override function load(window, args) {
		love.mouse.MouseModule.setVisible(true);

		Sfx.init();
		Bgm.init();
		Bgm.load_tracks(["assets/bgm/bgm.ogg"]);

		rain = {
			data: new ParticleData(),
			enabled: false,
			limit: 1000,
			pulse: 0.0,
			spawn_radius: 8.5,
			spread: 0.1,
			emission_rate: 50,
			emission_life_min: 2.25,
			emission_life_max: 4.25,
			drawable: IqmLoader.load_file("assets/models/rain.iqm"),
			velocity: new Vec3(0, 0, -11),
			offset: new Vec3(0, 0, 8),
			cull_behind: true
		};

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

		GameInput.init();
		Time.init();
		Render.init();

		systems = [
			new ItemEffect(),
			new Trigger(),
			new PlayerController(),
			new ParticleEffect(),
			new Animation(),
		];

		Signal.register("reset-now", (_) -> {
			new_scene();
		});

		Signal.register('reset', (args: { ded: Bool, fall: Bool }) -> {
			if (args.ded != null && args.ded) {
				//Sfx.rip_in_pieces.stop();
				//Sfx.rip_in_pieces.play();
				Signal.emit("pay-respects");

				if (args.fall != null && args.fall) {
					GameInput.lock();
					Signal.emit("hud-aaaaaaaaa");
				} else {
					GameInput.lock();
					Signal.emit("hud-too-moist");
				}
			} else {
				Signal.emit("reset-now");
			}
		});

		Signal.register("toggle-rain", function(_) {
			rain.enabled = !rain.enabled;
			if (rain.enabled) {
				Weather.state = Rain;
				Sfx.rain.play();
			}
			else {
				Weather.state = Clear;
				Sfx.rain.stop();
			}
		});

		Signal.emit("resize", Anchor.get_viewport());
		Signal.emit("toggle-rain");
		Signal.emit("reset-now");

		// force a tick on the first frame if we're using fixed timestep.
		// this prevents init bugs
		if (timestep > 0) {
			tick(timestep, window);
		}
	}

	function tick(dt: Float, window: backend.Window) {
		Profiler.push_block("Tick");
		GameInput.update(dt);
		Time.update(dt);

		Signal.update(dt);
		Bgm.update(dt);

		// order-insensitive updates can self register
		Profiler.push_block("SelfUpdates");
		Signal.emit("update", dt);
		Profiler.pop_block();

		GameInput.bind(Debug_F5, function() {
			MaterialCache.flush();
			TextureCache.flush();
			new_scene();
			return true;
		});

		GameInput.bind(Debug_F6, function() {
			MaterialCache.flush();
			TextureCache.flush();
			return true;
		});

		GameInput.bind(Debug_F3, function() {
			Signal.emit("toggle-rain");
			return true;
		});

		var cam = Render.camera;
		cam.last_orientation.set_from(cam.orientation);
		cam.last_target.set_from(cam.target);
		cam.last_tilt.set_from(cam.tilt);

		var entities = scene.get_entities();

		Profiler.push_block("TransformCache");
		for (e in entities) {
			if (!e.transform.is_static) {
				e.last_tx.set_from(e.transform);
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

	override function mousepressed(x: Float, y: Float, button: Int) {
		if (GameInput.locked) Input.set_relative(false);
		GameInput.mousepressed(x, y, button);
	}

	override function mousereleased(x: Float, y: Float, button: Int) {
		if (GameInput.locked) Input.set_relative(false);
		GameInput.mousereleased(x, y, button);
	}

	override function wheelmoved(x: Float, y: Float) {
		GameInput.wheelmoved(x, y);
	}

	override function mousemoved(x:Float, y:Float, dx:Float, dy:Float) {
		if (GameInput.locked) Input.set_relative(false);
	}

	override function keypressed(key: String, scan: String, isrepeat: Bool) {
		Input.set_relative(true);
		if (!isrepeat) {
			GameInput.keypressed(scan);
		}
	}

	override function keyreleased(key: String, scan: String) {
		Input.set_relative(true);
		GameInput.keyreleased(scan);
	}

	override function resize(w, h) {
		Render.reset(w, h);
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
#if skip_menu
		return GameLoop.run(new Main());
#elseif (debug || !release)
		return GameLoop.run(new Menu());
#else
		return GameLoop.run(new Splash());
#end
	}
}
