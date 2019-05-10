import backend.Fs;
import backend.Input;
import actor.*;
import backend.Anchor;
import backend.BaseGame;
import backend.GameLoop;
import backend.Gc;
import components.*;
import haxe.Json;
import loaders.IqmLoader;
import love.event.EventModule           as Le;
import love.filesystem.FilesystemModule as Lf;
import love.graphics.GraphicsModule     as Lg;
// import math.Quat;
// import math.Utils;
import math.Vec3;
import math.Vec4;
import render.MaterialCache;
import render.Render;
import render.TextureCache;
import systems.*;
import utils.Maybe;
import utils.RecycleBuffer;

class Menu extends BaseGame {
	public static var scene: Scene;

	var systems:       Array<System>;
	var lag:           Float = 0.0;
	var current_state: RecycleBuffer<Entity>;
	public static final timestep: Float = 1 / 60;
	public static var dunked = false;

	var layer: Maybe<ActorLayer>;

	var current_items: Array<Actor> = [];
	var cursor: Map<String, Int> = [
		"main"    => 0,
		"options" => 0,
		"credits" => 0
	];
	var current_cursor = "main";
	var finish_the_job: Maybe<Void->Void>;

	var volume: Map<String, Float> = [
		"master" => 0.8,
		"music"  => 0.8,
		"sfx"    => 1.0
	];

	static final hover_fade       = 1/10;
	static final opacity          = 0.85;
	static final opacity_inactive = 0.0;
	static final padding          = 8;
	static final iw               = 200;
	static final ih               = 40;
	static final mh               = ih*4 + padding*3;
	static final oh               = ih*7 + padding*6;
	static final typeface         = "assets/fonts/animeace2_reg.ttf";

	function basic_button(label: String, position: Float, font, ?click:(self: QuadActor)->Void, ?hover: (self:QuadActor, enter:Bool)->Void): QuadActor {
		return new QuadActor((self) -> {
			self.set_padding(padding, padding);
			self.set_size(iw, ih);
			self.move_to(0, ih*position);
			self.children = [
				new TextActor((self) -> {
					self.set_text(label);
					self.set_font(font);
				})
			];

			if (hover != null) {
				self.on_hover = (enter) -> hover(self, enter);
			}
			else {
				self.on_hover = (enter) -> {
					if (enter) {
						self.finish().decelerate(hover_fade);
						self.set_color(0.0, 0.25, 0.5, opacity);
					} else {
						self.finish().decelerate(hover_fade);
						self.set_color(0, 0, 0, opacity_inactive);
					}
				}

			}
			self.on_click = () -> click(self);

			self.on_hover(false);
		});
	}

	function load_layer() {
		final f18 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 18);
		// final f36 = Lg.newFont(typeface, 36);

		return new ActorLayer(() -> [
			// background dim
			new QuadActor((self) -> {
				self.set_color(0, 0, 0, 0.85);
				self.on_update = (_, _) -> {
					final size = Lg.getDimensions();
					self.finish();
					self.set_size(size.width, size.height);
				}
			}),

			new Actor((self) -> {
				self.load_sprite("assets/textures/logo.png");
				self.set_anchor((vp) -> new Vec3(vp.center_x / 4, vp.center_y - self.height + 50, 0));
				self.move_to(0, -padding);
			}),

			// Main Menu
			new Actor((self) -> {
				self.set_name("main");
				self.set_anchor((vp) -> new Vec3(vp.center_x / 4, vp.center_y, 0));

				var i = 0;
				self.children = [
					basic_button("New Game", i++, f18, (self) -> {
						self.stop();
						if (!finish_the_job.exists()) {
							finish_the_job = () -> Signal.emit("load-game");
							layer.sure().broadcast("fade-out");
						}
					}),
					basic_button("Options", i++, f18, (self) -> {
						self.stop();
						Signal.emit("menu-show", "options");
					}),
					basic_button("Credits", i++, f18, (self) -> {
						self.stop();
						Signal.emit("menu-show", "credits");
					}),
					basic_button("Exit", i++, f18, (self) -> {
						self.stop();
						if (!finish_the_job.exists()) {
							finish_the_job = () -> Le.quit();
							layer.sure().broadcast("fade-out");
						}
					}, (self, enter) -> {
						if (enter) {
							self.finish().decelerate(hover_fade);
							self.set_color(0.5, 0, 0, opacity);
						} else {
							self.finish().decelerate(hover_fade);
							self.set_color(0, 0, 0, opacity_inactive);
						}
					})
				];
			}),

			// Options Menu
			new Actor((self) -> {
				self.set_name("options");
				self.set_anchor((vp) -> new Vec3(vp.center_x / 4 + iw + padding, vp.center_y, 0));
				self.set_visible(false);

				var i = 0;
				self.children = [
					basic_button("Master Volume +", i++, f18, (self) -> {
						self.stop();
						Signal.emit("volume-up", "master");
					}),
					basic_button("Master Volume -", i++, f18, (self) -> {
						self.stop();
						Signal.emit("volume-down", "master");
					}),
					basic_button("Music Volume +", i++, f18, (self) -> {
						self.stop();
						Signal.emit("volume-up", "music");
					}),
					basic_button("Music Volume -", i++, f18, (self) -> {
						self.stop();
						Signal.emit("volume-down", "music");
					}),
					basic_button("SFX Volume +", i++, f18, (self) -> {
						self.stop();
						Signal.emit("volume-up", "sfx");
					}),
					basic_button("SFX Volume -", i++, f18, (self) -> {
						self.stop();
						Signal.emit("volume-down", "sfx");
					}),
					basic_button("Back", i++, f18, (self) -> {
						self.stop();
						Signal.emit("menu-hide", "options");
					})
				];

				self.register("show", () -> self.set_visible(true));
				self.register("hide", () -> self.set_visible(false));
			}),

			// Credits Menu
			new Actor((self) -> {
				self.set_name("credits");
				self.set_anchor((vp) -> new Vec3(vp.center_x / 4 + iw + padding, vp.center_y, 0));
				self.set_visible(false);

				self.children = [
					new QuadActor((self) -> {
						self.set_color(0, 0, 0, 0.9);
						self.set_size(375, 215);
						self.set_padding(padding, padding);

						self.children = [
							new TextActor((self) -> {
								final text = Fs.read("assets/credits.txt").toString();
								self.set_text(text);
								self.set_font(f18);
							})
						];

						self.on_hover = (enter) -> {};
						self.on_click = () -> {};
					}),

					basic_button("Back", 5.5, f18, (self) -> {
						self.stop();
						Signal.emit("menu-hide", "credits");
					})
				];

				self.register("show", () -> self.set_visible(true));
				self.register("hide", () -> self.set_visible(false));
			}),

			new Actor((self) -> {
				self.set_name("fade");
				self.set_aux(1.0, 0);
				self.decelerate(1/2).set_aux(0.0, 0).set_visible(false);
				self.register("complete", () -> {
					var cb = finish_the_job.sure();
					finish_the_job = null;
					cb();
				});
				self.register("fade-out", () -> {
					GameInput.lock();
					self.set_visible(true).decelerate(1/2).set_aux(1.0, 0).queue("complete");
				});
				self.on_draw = (_) -> {
					final size = Lg.getDimensions();
					Lg.setColor(0, 0, 0, self.actual.aux[0]);
					Lg.rectangle(Fill, 0, 0, size.width, size.height);
					Lg.setColor(1, 1, 1, 1);
				}
			}),
		]);
	}

	function new_scene() {
		// paranoid memory release of everything in the old scene
		if (scene != null) {
			scene.release();
		}
		scene = new Scene();

		// clean out the old map and entities
		Gc.run(true);

		Time.set_time(10);

		inline function load_exm(filename: String): Array<SceneNode> {
			final nodes = [];
			final iqm = iqm.Iqm.load(filename, true);
			var meta: iqm.Iqm.ExmMeta;
			if (iqm.metadata != null) {
				meta = Json.parse(iqm.metadata);
				if (meta != null) {
					for (o in meta.objects) {
						var position: Vec3 = [ o.position[0], o.position[1], o.position[2] ];
						var fixed_name = o.name.substr(0, o.name.lastIndexOf("."));
						final locator_node = new SceneNode();
						locator_node.name = fixed_name;
						locator_node.transform.position.set_from(position);
						nodes.push(locator_node);
					}
				}
			}
			final node = new SceneNode();
			node.transform.is_static = true;
			node.transform.update();
			node.drawable = IqmLoader.get_views(iqm);
			nodes.push(node);
			return nodes;
		}

		final spawn_transform = new Transform();
		final nodes = load_exm("assets/maps/spooky.exm");
		for (node in nodes) {
			if (node.name == "spawn") {
				spawn_transform.set_from(node.transform);
			}
			scene.add(node);
		}

		// clean out the temporary data from stage load
		// these help prevent a large memory usage spike on level reload
		Gc.run(true);

		var cam = new Camera([ 0, -5, 0.5 ]);
		// cam.orientation.set_from(rad(-90), [ 1, 0, 0 ]));
		cam.orientation.normalize();
		Render.camera = cam;

		var file = Lf.read("options.json").contents;
		if (file != null && file.length > 0) {
			var options = Json.parse(file);

			if (options.master != null) {
				volume["master"] = options.master;
			}

			if (options.music != null) {
				volume["music"] = options.music;
			}

			if (options.sfx != null) {
				volume["sfx"] = options.sfx;
			}
		}

		// Signals
		Signal.register("menu-show", (_menu: String) -> {
			// trigger action on actor
			final layer = layer.sure();
			final actor = layer.find_actor(_menu).sure();
			actor.trigger("show");

			// change menu
			current_cursor = _menu;
			current_items  = layer.find_actor(current_cursor).sure().children;
		});

		Signal.register("menu-hide", (_menu: String) -> {
			// trigger action on actor
			final layer = layer.sure();
			final actor = layer.find_actor(_menu).sure();
			actor.trigger("hide");

			// reset highlight of current actor
			final cc = layer.find_actor(current_cursor).sure();
			var actor: QuadActor = cast cc.children[cursor[current_cursor]];
			actor.on_hover(false);
			cursor[current_cursor] = 0;

			// reset highlight of first actor
			actor = cast cc.children[cursor[current_cursor]];
			actor.on_hover(true);

			// change menu
			current_cursor = "main";
			current_items  = layer.find_actor(current_cursor).sure().children;

			// commit options
			var options = Json.stringify(volume);
			Lf.write("options.json", options);
		});

		Signal.register("volume-up", (_type: String) -> {
			if (_type != null && volume[_type] != null) {
				volume[_type] = Math.min(1.0, volume[_type] + 0.1);
			}
		});

		Signal.register("volume-down", (_type: String) -> {
			if (_type != null && volume[_type] != null) {
				volume[_type] = Math.max(0, volume[_type] - 0.1);
			}
		});
	}

	override function load(window, args) {
		love.mouse.MouseModule.setVisible(true);

		Sfx.init();

		GameInput.init();
		Time.init();
		Render.init(false);

		systems = [
			new ItemEffect(),
			new Trigger(),
			new ParticleEffect()
		];

		Signal.register("resize", (_vp) -> {
			if (layer == null) {
				return;
			}
			final vp: Vec4 = _vp;
			final layer = layer.sure();
			layer.update_bounds(vp);
			layer.update(0);
		});

		layer         = load_layer();
		final layer   = layer.sure();
		current_items = layer.find_actor(current_cursor).sure().children;

		var actor: QuadActor = cast current_items[cursor[current_cursor]];
		actor.on_hover(true);

		Signal.emit("resize", Anchor.get_viewport());
		layer.update(0);

		Signal.register("load-game", (_) -> GameLoop.change_game(new Main()));

		new_scene();

		if (dunked) {
			dunked = false;
			Signal.emit("menu-show", "credits");
		}

		// force a tick on the first frame if we're using fixed timestep.
		// this prevents init bugs
		if (timestep > 0) {
			tick(timestep, window);
		}
	}

	function tick(dt: Float, window: backend.Window) {
		GameInput.update(dt);
		Time.update(dt);
		Signal.update(dt);

		GameInput.bind(Debug_F5, function() {
			MaterialCache.flush();
			TextureCache.flush();
			new_scene();
			return true;
		});

		var cam = Render.camera;
		cam.last_orientation.set_from(cam.orientation);
		cam.last_target.set_from(cam.target);
		cam.last_tilt.set_from(cam.tilt);

		var entities = scene.get_entities();

		for (e in entities) {
			if (!e.transform.is_static) {
				e.last_tx.set_from(e.transform);
			}
		}

		var relevant = [];
		for (system in systems) {
			relevant.resize(0);
			for (entity in entities) {
				if (system.filter(entity)) {
					relevant.push(entity);
					system.process(entity, dt);
				}
			}
			system.update(relevant, dt);
		}

		if (layer.exists()) {
			layer.sure().update(dt);
		}
	}

	var last_vp: Vec4;

	override function update(window, dt: Float) {
		var vp = Anchor.get_viewport();
		if (vp != last_vp) {
			last_vp = vp;
			Signal.emit("resize", vp);
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

		// Input
		if (GameInput.pressed(MenuUp)) {
			Input.set_relative(true);
			final len   = current_items.length;
			final layer = layer.sure();
			final cc    = layer.find_actor(current_cursor).sure();
			var actor: QuadActor = cast cc.children[cursor[current_cursor]];
			actor.on_hover(false);

			if (cursor[current_cursor] == 0) {
				cursor[current_cursor] = len-1;
			} else {
				cursor[current_cursor] -= 1;
			}

			actor = cast cc.children[cursor[current_cursor]];
			actor.on_hover(true);
		}

		if (GameInput.pressed(MenuDown)) {
			Input.set_relative(true);
			final len   = current_items.length;
			final layer = layer.sure();
			final cc    = layer.find_actor(current_cursor).sure();
			var actor: QuadActor = cast cc.children[cursor[current_cursor]];
			actor.on_hover(false);

			if (cursor[current_cursor] == len-1) {
				cursor[current_cursor] = 0;
			} else {
				cursor[current_cursor] += 1;
			}

			actor = cast cc.children[cursor[current_cursor]];
			actor.on_hover(true);
		}

		if (GameInput.pressed(MenuConfirm)) {
			Input.set_relative(true);
			current_items[cursor[current_cursor]].on_click();
		}
	}

	override function mousepressed(x: Float, y: Float, button: Int) {
		Input.set_relative(false);
		GameInput.mousepressed(x, y, button);
	}

	override function mousereleased(x: Float, y: Float, button: Int) {
		Input.set_relative(false);
		GameInput.mousereleased(x, y, button);

		if (button == 1) {
			layer.sure().hit(x, y);
		}
	}

	override function mousemoved(x:Float, y:Float, dx:Float, dy:Float) {
		Input.set_relative(false);
		layer.sure().hover(x, y);
	}

	override function wheelmoved(x: Float, y: Float) {
		Input.set_relative(false);
		GameInput.wheelmoved(x, y);
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
		Render.frame(window, visible, alpha);

		if (layer.exists()) {
			ActorLayer.draw(layer.sure());
		}
	}
}
