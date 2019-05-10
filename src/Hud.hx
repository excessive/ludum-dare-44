import math.Utils;
import actor.*;
import backend.Anchor;
import backend.GameLoop;
import backend.Profiler;
import math.Vec2;
import math.Vec3;
import math.Vec4;
import utils.Maybe;
import love.graphics.GraphicsModule as Lg;
import love.math.MathModule as Lm;

typedef OverlayInfo = { id: Int, text: String, location: Vec3 };

class Hud {
#if lua
	static inline function format(fmt: String, args: Array<Dynamic>): String {
		final _real = untyped __lua__("{}");
		for (i in 0...args.length) {
			untyped __lua__("table.insert({0}, {1})", _real, args[i]);
		}
		return untyped __lua__("string.format({0}, unpack({1}))", fmt, _real);
	}
#else
	static inline function format(fmt: String, args: Array<Dynamic>): String {
		return utils.Printf.format(fmt, args);
	}
#end

	static final overlays: Array<OverlayInfo> = [];
	static var layer: Maybe<ActorLayer>;

	static function mismatch_overlays(out: Array<OverlayInfo>, list_a: Array<OverlayInfo>, list_b: Array<OverlayInfo>) {
		for (a in list_a) {
			var is_new = true;
			for (b in list_b) {
				if (a.id == b.id) {
					is_new = false;
				}
			}
			if (is_new) {
				out.push(a);
			}
		}
	}

	// i don't want to know how slow this is with an n larger than a few
	public static function update_overlays(?_overlays: Array<OverlayInfo>) {
		if (layer == null) {
			return;
		}
		final layer = layer.sure();
		final bubbles = layer.find_actor("bubbles");
		if (!bubbles.exists()) {
			return;
		}
		final bubbles = bubbles.sure();
		if (_overlays == null || _overlays.length == 0) {
			bubbles.trigger("hide", true);
			overlays.resize(0);
			return;
		}

		final new_overlays = [];
		mismatch_overlays(new_overlays, _overlays, overlays);

		final old_overlays = [];
		mismatch_overlays(old_overlays, overlays, _overlays);

		for (o in new_overlays) {
			bubbles.children.push(new BubbleActor(o.id, o.text, (self) -> {
				self.user_data = o.location;
				// self.set_font(noto_sans_14);
				self.set_offset(0, -30);
				self.trigger("show");
			}));
		}

		for (o in old_overlays) {
			final result = layer.find_actor("bubble_" + o.id, bubbles);
			if (result.exists()) {
				result.sure().trigger("hide");
			}
			else {
				continue;
			}
		}

		overlays.resize(0);
		for (o in _overlays) {
			overlays.push(o);
		}

		final remove = [];
		for (c in bubbles.children) {
			if (c.actual.aux[0] < -0.99) {
				remove.push(c);
			}
		}

		for (c in remove) {
			bubbles.children.remove(c);
		}

		for (o in overlays) {
			final actor: BubbleActor = cast layer.find_actor("bubble_" + o.id, bubbles);
			if (actor == null) {
				continue;
			}
			actor.set_text(o.text);
			actor.user_data = o.location;
		}

		final center = new Vec2(Anchor.center_x, Anchor.center_y);
		final scale = Anchor.width / 1.5;
		for (a in bubbles.children) {
			final location: Vec3 = a.user_data;
			final pos = new Vec2(location.x, location.y);
			location.z = Math.max(1-Vec2.distance(pos, center) / scale, 0);
			location.z = Math.pow(location.z, 0.25);
		}
	}

	public static function init() {
		Signal.register("update", update);
		Signal.register("resize", (_vp) -> {
			if (layer == null) {
				return;
			}
			final vp: Vec4 = _vp;
			final layer = layer.sure();
			layer.update_bounds(vp);
		});

		final f18 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 18);

		layer = new ActorLayer(() -> [
			new Actor((self) -> {
				self.set_name("bubbles");
			}),
			new Actor((self) -> {
				self.set_name("bubble");
				self.load_sprite("assets/textures/thot-bubble.png");
				self.set_anchor((vp) -> new Vec3(vp.center_x-self.width*0.25 + 100, vp.center_y-self.height*0.25, 0));
				self.set_frame(0);
				self.scale_by(0.5, 0.5);
				self.set_visible(false);

				self.register("show-status", () -> {
					self.finish();
					self.set_visible(true).decelerate(1/4).set_opacity(1.0);
					self.sleep(2.0).decelerate(1/4).set_opacity(0.0).set_visible(false);
				});
				self.register("show-alert", () -> { self.trigger("show-status"); });
			}),
			new Actor((self) -> {
				self.set_name("emoji");
				self.load_sprite("assets/textures/jelly-sprites.png", 3, 2, 0);
				self.set_anchor((vp) -> new Vec3(vp.center_x-self.width*0.25 + 100 + 15, vp.center_y-self.height*0.25 - 15, 0));
				self.set_frame(0);
				self.scale_by(0.5, 0.5);
				self.set_visible(false);

				var last_frame = 0;
				self.register("reset", () -> self.finish().set_frame(last_frame));
				self.register("show-status", () -> {
					Sfx.alert.stop();
					Sfx.alert.play();
					self.finish();
					self.set_visible(true).decelerate(1/4).set_opacity(1.0);
					self.sleep(2.0).decelerate(1/4).set_opacity(0.0).set_visible(false);
				});
				self.register("show-alert", () -> {
					self.finish();
					self.set_frame(5);
					self.trigger("show-status");
					self.sleep(0.0).queue("reset"); // FIXME: finish doesn't execute the queued reset
				});

				self.on_update = (_, dt) -> {
					final player = render.Render.player.sure();
					final frame  = Std.int(Utils.map(player.collidable.radius.x, 0.125, 0.5, 4, 0));
					if (frame != last_frame) {
						last_frame = frame;
						self.trigger("reset");
						Signal.emit("hud-safe");
					}
				}
			}),
			new Actor((self) -> {
				self.set_visible(false);
				self.load_sprite("assets/announce/stay-jelly.png");
				self.set_offset(-self.width/2, -self.height/2);
				self.set_anchor((vp) -> new Vec3(vp.center_x, vp.center_y, 0));
				self.register("stay-jelly", () -> {
					final scale = Anchor.width / self.width;
					self.stop().sleep(0.25)
					.scale_to(0, 5 * scale).move_to(0, 250 * scale)
					.set_visible(true)
					.decelerate(1/6).scale_to(0.8 * scale, 0.8 * scale).move_to(0, 0)
					.decelerate(0.8).scale_by(1.05, 1.0)
					.decelerate(1/8).scale_to(2 * scale, 0)
					.set_visible(false)
					.queue("continue");
				});
				self.register("continue", () -> {
					GameInput.unlock();
				});
			}),
			new Actor((self) -> {
				self.set_visible(false);
				self.load_sprite("assets/announce/get-dunked.png");
				self.set_offset(-self.width/2, -self.height/2);
				self.set_anchor((vp) -> new Vec3(vp.center_x, vp.center_y, 0));
				self.register("get-dunked", () -> {
					final scale = Anchor.width / self.width;
					self.stop()
					.scale_to(2 * scale, 0).move_to(0, 0)
					.set_visible(true)
					.decelerate(1/20).scale_to(0.8 * scale, 0.8 * scale)
					.decelerate(1).scale_by(1.05, 1.0)
					.decelerate(1/6).scale_to(0, 5 * scale).move_by(0, -250 * scale)
					.set_visible(false).queue("continue");
				});
				self.register("continue", () -> {
					GameInput.unlock();
					Menu.dunked = true;
					GameLoop.change_game(new Menu());
				});
			}),
			new Actor((self) -> {
				self.set_visible(false);
				self.load_sprite("assets/announce/too-moist.png");
				self.set_offset(-self.width/2, -self.height/2);
				self.set_anchor((vp) -> new Vec3(vp.center_x, vp.center_y, 0));
				self.register("too-moist", () -> {
					final scale = Anchor.width / self.width;
					self.stop()
					.scale_to(2 * scale, 0).move_to(0, 0)
					.set_visible(true)
					.decelerate(1/20).scale_to(0.8 * scale, 0.8 * scale)
					.decelerate(1).scale_by(1.05, 1.0)
					.decelerate(1/6).scale_to(0, 5 * scale).move_by(0, -250 * scale)
					.set_visible(false).queue("continue");
				});
				self.register("continue", () -> {
					GameInput.unlock();
					Signal.emit("reset-now");
				});
			}),
			new Actor((self) -> {
				self.set_visible(false);
				self.load_sprite("assets/announce/aaaaaaaaa.png");
				self.set_offset(-self.width/2, -self.height/2);
				self.set_anchor((vp) -> new Vec3(vp.center_x, vp.center_y, 0));
				self.register("aaaaaaaaa", () -> {
					final scale = Anchor.width / self.width;
					self.stop()
					.scale_to(2 * scale, 0).move_to(0, 0)
					.set_visible(true)
					.decelerate(1/20).scale_to(0.8 * scale, 0.8 * scale)
					.decelerate(1).scale_by(1.05, 1.0)
					.decelerate(1/6).scale_to(0, 5 * scale).move_by(0, -250 * scale)
					.set_visible(false).queue("continue");
				});
				self.register("continue", () -> {
					GameInput.unlock();
					Signal.emit("reset-now");
				});
			}),
			new Actor((self) -> {
				self.set_name("tombstones");
				self.set_anchor((vp) -> new Vec3(vp.left, vp.bottom-64, 0));
				self.children = [];

				var i = 1;

				self.register("F", () -> {
					self.children.push(new Actor((self) -> {
						self.load_sprite("assets/textures/f.png");
						self.move_to(-(i++)*self.width, 0);
					}));

					if (self.children.length > 40) {
						self.children.shift();
					}

					self.hurry(4);
					self.decelerate(1/4).move_by(64, 0);
				});
			}),
			new TextActor((self) -> {
				self.set_name("check-flavor");
				self.set_anchor((vp) -> new Vec3(vp.center_x, vp.bottom-f18.getHeight()*4, 0));
				self.set_text("");
				self.set_font(f18);
				self.set_stroke(2, 0, 1);
				self.set_stroke_color(0, 0, 0, 1);
				self.set_visible(false);
				self.set_opacity(0);
				self.set_align(Center);

				self.register("checkpoint", () -> {
					final flavor = [
						"It's raining hard today... But I can do it!",
						"Dunking sure is difficult!",
						"I'm blue da ba dee da ba daa!",
						"Being pink could be nice, too~",
						"Everything's okay, everything's fine!",
						"I'm the little jelly who could!",
						"...Daikaizoku!",
						"I miss my family... But this is my destiny!",
						"Yawn~ Almost there...!",
						"Eureka! a + bi + cj + dk!",
						"I saw a scary puddle...",
						"Do or do not, there is no tri!"
					];
					final text = Std.int(Lm.random(0, flavor.length-1));

					self.finish();
					self.set_text(flavor[text]);
					self.set_visible(true).decelerate(1/4).set_opacity(1).sleep(2.0).decelerate(1/4).set_opacity(0).set_visible(false);
				});
			}),
			new Actor((self) -> {
				self.set_name("fade");
				self.set_aux(1.0, 0);
				self.queue("fade-in");
				self.register("fade-in", () -> self.set_aux(1.0, 0).set_visible(true).sleep(1/5).decelerate(1/2).set_aux(0.0, 0).set_visible(false));
				self.register("fade-out", () -> self.set_visible(true).decelerate(1/2).set_aux(1.0, 0));
				self.on_draw = (_) -> {
					final size = Lg.getDimensions();
					Lg.setColor(0, 0, 0, self.actual.aux[0]);
					Lg.rectangle(Fill, 0, 0, size.width, size.height);
					Lg.setColor(1, 1, 1, 1);
				}
			}),
		]);

		final layer = layer.sure();
		Signal.register("hud-stay-jelly",    (_) -> layer.broadcast("stay-jelly"));
		Signal.register("hud-get-dunked",    (_) -> layer.broadcast("get-dunked"));
		Signal.register("hud-too-moist",     (_) -> layer.broadcast("too-moist"));
		Signal.register("hud-aaaaaaaaa",     (_) -> layer.broadcast("aaaaaaaaa"));
		Signal.register("hud-danger",        (_) -> layer.broadcast("show-alert"));
		Signal.register("hud-safe",          (_) -> layer.broadcast("show-status"));
		Signal.register("hud-fade-in",       (_) -> layer.broadcast("fade-in"));
		Signal.register("hud-fade-out",      (_) -> layer.broadcast("fade-out"));
		Signal.register("checkpoint-flavor", (_) -> layer.broadcast("checkpoint"));
		Signal.register("pay-respects",      (_) -> layer.broadcast("F"));
		Signal.register("resize",            (_vp) -> {
			var vp: Vec4 = _vp;
			layer.update_bounds(vp);
		});
	}

	public static function update(dt) {
		Profiler.push_block("HudUpdate");
		if (layer.exists()) {
			layer.sure().update(dt);
		}
		Profiler.pop_block();
	}

	public static function draw() {
		Profiler.push_block("HudDraw");
		if (layer.exists()) {
			ActorLayer.draw(layer.sure());
		}
		Profiler.pop_block();
	}
}
