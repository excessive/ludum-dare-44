package render;

import math.ColorUtils;
// if ever a file had too many dependencies, it is this one.
import backend.Fs;
import backend.love.GameLoop;
import backend.Profiler;
import backend.Window as PlatformWindow;
import excessive.Tricks;
// import exwidgets.Renderer;
import ini.IniFile;
import love.graphics.GraphicsModule as Lg;
import math.Intersect;
import math.Mat4;
import math.Quat;
import math.Utils;
import math.Vec3;
import render.*;
import utils.OptionHelper;
import utils.RecycleBuffer;
import utils.Maybe;

#if imgui
import imgui.ImGui as Ui;
#end

typedef RenderConfig = {
	quality: {
		fxaa: Bool,
		ssaa: Float,
		msaa: Int,
		glow: Bool,
		smoothing: Bool,
		anisotropic_filtering: Bool
	},
	color: {
		white_point: String,
		exposure: Float
	},
	post: {
		vignette: Float
	}
}

class Render {
	public static var camera = new Camera([ 0, 0, 0 ]);
	public static var player: Maybe<SceneNode>;
	public static var config(default, null): RenderConfig;
	public static var white_point: Array<Float>;
	public static var potato_mode: Bool = false;

	static var use_hud = true;

	public static function init(with_hud: Bool = true) {
		Tricks.prepare();
		Debug.init();
		Shader.init();

		use_hud = with_hud;
		if (use_hud) {
			Hud.init();
		}

		var default_config: RenderConfig = {
			quality: {
				fxaa: true,
				ssaa: 1.0,
				msaa: 1,
				glow: false,
				smoothing: true,
				anisotropic_filtering: true
			},
			color: {
				white_point: "7,14,16",
				exposure: 0.75,
				// exposure: 1.1,
			},
			post: {
				vignette: 0.35
			}
		};

		// load engine render config
		var config_file = "assets/render_config.ini";
		if (Fs.is_file(config_file)) {
			config = IniFile.parse_typed(default_config, config_file);
			config.quality.msaa = Std.int(untyped __lua__("tonumber({0})", config.quality.msaa));
			console.Console.ds('loaded config $config_file');
		}
		else {
			config = default_config;
		}

		var r: Float = 5;
		var g: Float = 5;
		var b: Float = 5;
		var rgb = config.color.white_point.split(",");
		if (rgb.length >= 3) {
			var pr = Std.parseInt(rgb[0]);
			if (pr != null) {
				r = pr;
			}
			var pg = Std.parseInt(rgb[1]);
			if (pg != null) {
				g = pg;
			}
			var pb = Std.parseInt(rgb[2]);
			if (pb != null) {
				b = pb;
			}
		}
		white_point = [ r, g, b ];
	}

	public static var shadow(default, null): {
		depth: love.graphics.Canvas
	}
	public static var sky_occlusion(default, null): {
		depth: love.graphics.Canvas
	}
	static var gbuffer: GBuffer;
	public static var gles_mode = false;
	public static var rgbm_const(default, null): Float = 1.125;
	public static var use_msaa(default, null) = false;

	public static function reset(w: Float, h: Float) {
		var renderer = Lg.getRendererInfo();
		gles_mode = renderer.name == "OpenGL ES";

		var lag = config.quality.ssaa;
		if (gbuffer != null) {
			for (c in gbuffer.layers) {
				c.release();
			}
			gbuffer.depth.release();
			gbuffer.out1.release();
			gbuffer.out2.release();
		}

		if (shadow != null) {
			// shadow.color.release();
			shadow.depth.release();
		}

		if (sky_occlusion != null) {
			// sky_occlusion.color.release();
			sky_occlusion.depth.release();
		}

		if (potato_mode) {
			lag = 0.25;
		}

		w *= lag;
		h *= lag;
		var formats: lua.Table<String, Bool> = cast Lg.getCanvasFormats();
		var fmt = "rgba8";
		if (formats.rgb10a2) {
			fmt = "rgb10a2";
		}

		// POTATO_MODE
		if (potato_mode) {
			fmt = "rgb565";
		}

		var hdr = "rgba8";
		if (formats.rgba16f) {
			hdr = "rgba16f";
		}
		if (formats.rg11b10f) {
			hdr = "rg11b10f";
		}
		var depth = "depth16";
		if (formats.depth24) {
			depth = "depth24";
		}

		var shadow_res = 256;
		var sw = shadow_res;
		var sh = shadow_res;

		use_msaa = config.quality.msaa > 1;

		shadow = {
			// color: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", sw, sh, "rgba8"),
			depth: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { readable = true, format = {2} } )", sw, sh, depth)
		};

		var sky_occlusion_res = 512;
		var sw = sky_occlusion_res;
		var sh = sky_occlusion_res;

		sky_occlusion = {
			// color: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", sw, sh, "rgba8"),
			depth: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { readable = true, format = {2} } )", sw, sh, depth)
		};

		if (use_msaa) {
			gbuffer = {
				layers: [
					// albedo (rgb) + roughness (a)
					// untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = 'rgba8' } )", w, h),
					// normal (rg) + distance (b) + unused (a)
					// untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", w, h, fmt),
				],
				// depth
				depth: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2}, msaa = {3} } )", w, h, depth, config.quality.msaa),
				// final combined rg11b10f buffer. might need to increase to rgba16f?
				out1: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2}, msaa = {3} } )", w, h, hdr, config.quality.msaa),
				// final tonemapped buffer we apply AA to
				out2: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2}, msaa = {3} } )", w, h, fmt, config.quality.msaa)
			};
		}
		else {
			gbuffer = {
				layers: [],
				depth: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", w, h, depth),
				out1: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { mipmaps = 'manual', format = {2} } )", w, h, hdr),
				out2: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", w, h, fmt)
			};
		}

		if (config.quality.ssaa < 1.0 && !config.quality.smoothing || gles_mode || potato_mode) {
			gbuffer.out1.setFilter(Linear, Nearest);
			gbuffer.out2.setFilter(Linear, Nearest);
		}
	}

	static var debug_draw = #if debug true #else false #end;
	public static var show_profiler = #if (profile && imgui) true #else false #end;
	static var forward = new RecycleBuffer<DrawCommand>();
	static var shadow_draws = new RecycleBuffer<DrawCommand>();

	public static var use_glow = false;

	static function render_game(width: Float, height: Float, state: RecycleBuffer<Entity>, alpha: Float) {
		var vp: Viewport = { x: 0, y: 0, w: width, h: height };
		camera.update(vp.w, vp.h, alpha);

		Lg.setColor(1, 1, 1, 1);

#if (imgui && debug)
		Profiler.push_block("Prepare");
#if render_debug
		var ret = Ui.slider_float("rgbm exp", rgbm_const, 0.1, 20.0);
		rgbm_const = ret.f1;

		ret = Ui.slider_float("exposure", config.color.exposure, -5, 5);
		config.color.exposure = ret.f1;

		if (Ui.begin("Render Options##Render")) {
			if (Ui.checkbox("FXAA", config.quality.fxaa)) {
				config.quality.fxaa = !config.quality.fxaa;
			}
			if (Ui.checkbox("MSAA", config.quality.msaa > 1)) {
				config.quality.msaa = config.quality.msaa > 1 ? 1 : 4;
				reset(width, height);
			}
			if (Ui.checkbox("Glow", use_glow)) {
				use_glow = !config.quality.glow;
			}
			if (Ui.checkbox("More Ghetto", config.quality.ssaa < 1.0)) {
				config.quality.ssaa = 0.5;
				reset(width, height);
			}
			if (Ui.checkbox("Less Ghetto", config.quality.ssaa > 1.0)) {
				config.quality.ssaa = 2.0;
				reset(width, height);
			}
			if (Ui.checkbox("Debug", debug_draw)) {
				debug_draw = !debug_draw;
			}
		}
		Ui.end();
#end
#end

		forward.reset();
		shadow_draws.reset();

		// interpolate dynamic objects and sort objects into the appropriate passes
		var player_pos = new Vec3(0, 0, 0);
		var player_size = 0.5;

		var overlays: Array<Hud.OverlayInfo> = [];
		// var overlay_vp = new Vec4(vp.x, vp.y, vp.w, vp.h);
		// var cam_vp = camera.projection * camera.view;
		var origin = Vec3.splat(0.0);

		// var ui_vp = backend.Anchor.get_viewport();

		// var v3_one = Vec3.splat(1.0);
		var m4_identity = Mat4.from_identity();
		var culled = 0;
		for (e in state) {
			for (emit in e.emitter) {
				if (emit.data.buffer == null || emit.data.particles.length == 0) {
					continue;
				}
				var mtx = Mat4.from_srt(
					origin,
					e.transform.orientation,
					e.transform.scale
				);
				var inv = Mat4.inverse(mtx);
				inv.transpose();
				// IT WILL WORK, BUT PLEASE DON'T DO THIS TO YOUR PARTICLES
				for (submesh in emit.drawable) {
					var mat = MaterialCache.get(submesh.material);
					var cmd: DrawCommand = {
						xform_mtx: m4_identity,
						normal_mtx: inv,
						mesh: submesh,
						material: mat,
						albedo_override: null,
						bones: null,
						instance_count: Std.int(Utils.min(emit.limit, emit.data.particles.length)),
						instance_buffer: emit.data.buffer
					};
					forward.push(cmd);
					if (mat.shadow) {
						shadow_draws.push(cmd);
					}
#if 0
					// TODO: no instancing fallback when not supported
					for (p in emit.data.particles) {
						var cmd: DrawCommand = {
							xform_mtx: m4_identity,
							normal_mtx: inv,
							mesh: submesh,
							material: mat,
							bones: null,
							instance_count: 1,
							instance_buffer: null
						};
						var life = p.despawn_time - p.spawn_time;
						var offset = emit.data.time - p.spawn_time;
						var scale = Utils.max(0.0, 1.0 - offset / life);

						cmd.xform_mtx = Mat4.from_srt(p.position, p.orientation, Vec3.splat(scale));
						forward.push(cmd);
						if (mat.shadow) {
							shadow_draws.push(cmd);
						}
					}
#end
				}
			}

			// if (e.bounds != null) {
			// 	Debug.aabb(e.bounds.min, e.bounds.max, 1, 0, 1);
			// }

			if (e.drawable.length <= 0) {
				continue;
			}

			// TODO: cull off screen animations
			if (e.bounds != null && e.transform.is_static) {
				if (!Intersect.aabb_frustum(e.bounds, camera.frustum)) {
					culled += 1;
					continue;
				}
			}

			var mtx = e.transform.matrix;
			var inv = e.transform.normal_matrix;

			var pos = e.transform.position;
			if (!e.transform.is_static) {
				var a = e.last_tx.position;
				var b = e.transform.position;
				pos = Vec3.lerp(a, b, alpha) + e.transform.offset;
				var rot = Quat.lerp(e.last_tx.orientation, e.transform.orientation, alpha);
				var scale = Vec3.lerp(e.last_tx.scale, e.transform.scale, alpha);
				mtx = Mat4.from_srt(pos, rot, scale);

				inv = Mat4.inverse(mtx);
				inv.transpose();

				if (e.player != null) {
					player_pos = pos;
				}

				if (e.collidable != null && e.player != null) {
					player_size = e.collidable.radius.length();
				}
			}

			var bones = null;
			if (e.animation != null) {
				bones = e.animation.current_pose;
			}

			for (submesh in e.drawable) {
				var mat = MaterialCache.get(submesh.material);
				var cmd: DrawCommand = {
					xform_mtx: mtx,
					normal_mtx: inv,
					// for sorting
					mesh: submesh,
					material: mat,
					albedo_override: e.item != null ? switch (e.item) {
						case Ground(texture, height): OptionHelper.unwrap_fail(TextureCache.get(texture, true));
						default: null;
					} : null,
					bones: bones,
					instance_count: 1,
					instance_buffer: null
				};
				// #if imgui
				// Ui.text('${submesh.material} => $mat');
				// #end
				forward.push(cmd);
				if (mat.shadow) {
					shadow_draws.push(cmd);
				}
			}
		}

		Lg.setColor(1, 1, 1, 1);

		Profiler.pop_block();

		Profiler.push_block("Render wait");
		Lg.setCanvas(untyped __lua__("{ {0}, depthstencil = {1} }", gbuffer.out1, gbuffer.depth));
		Lg.clear(cast Lg.getBackgroundColor(), cast false, cast true);
		Profiler.pop_block();

		var light = {
			pos: player_pos,
			dir: Time.sun_direction,
			size: player_size
		};
		var light_view = Mat4.look_at(light.pos, light.pos + light.dir, Vec3.up());
		var light_size = light.size * 2;
		var light_proj = Mat4.from_ortho(-light_size, light_size, -light_size, light_size, -10, 10);
		var light_vp = light_proj * light_view;
		final bias = Mat4.bias(0.0);
		var really_debug_draw = debug_draw;

		var skypos_quant = player_pos.copy();
		final so_res = sky_occlusion.depth.getWidth();
		skypos_quant.x = Math.ffloor(skypos_quant.x * so_res) / so_res;
		skypos_quant.y = Math.ffloor(skypos_quant.y * so_res) / so_res;
		skypos_quant.z = Math.ffloor(skypos_quant.z * so_res) / so_res;
		var sky_view = Mat4.look_at(player_pos + new Vec3(0, 0, 1), skypos_quant, Vec3.forward());
		var sky_size = 15;
		var sky_proj = Mat4.from_ortho(-sky_size, sky_size, -sky_size, sky_size, -50, 50);
		var sky_vp = sky_proj * sky_view;

		ShadowPass.render(shadow.depth, light_vp, shadow_draws);
		OcclusionPass.render(sky_occlusion.depth, sky_vp, forward);
		ForwardPass.render(gbuffer.out1, gbuffer.depth, bias * light_vp, bias * sky_vp, forward);
		Lg.setBlendMode(Alpha);

		if (really_debug_draw) {
			DebugPass.render(gbuffer.out1, gbuffer.depth);
		}
		else {
			Debug.draw(true);
			Debug.clear_capsules();
		}
		PostPass.render(gbuffer, vp, really_debug_draw);

#if (imgui && render_debug)
		if (Ui.begin("Render Buffers")) {
			var aspect = Math.min(width/height, height/width);
			Ui.image(shadow.depth, 256, 256, 0, 0, 1, 1);
			if (config.quality.fxaa) {
				Ui.image(gbuffer.out1, 256, 256*aspect, 0, 0, 1, 1);
			}
			else {
				Ui.image(gbuffer.out2, 256, 256*aspect, 0, 0, 1, 1);
			}
		}
		Ui.end();

		if (Ui.begin("Render Stats")) {
			var region = Ui.get_content_region_max();
			Ui.plot_lines("", Main.frame_graph, 0, null, 0, 1/20, region[0] - 10, 100);
			Ui.text('fps: ${backend.Timer.get_fps()}');
			Ui.text('culled: ${culled}');

			if (Ui.tree_node("Dirty Details")) {
				Ui.text('batches: ${forward.length}');
				Ui.same_line();
				Ui.text('(deferred: n/a, forward: ${forward.length})');
				var stats = Lg.getStats();
				var diff = stats.drawcalls - (forward.length);
				Ui.text('misc draws: $diff');
				Ui.text('auto-batched drawcalls: ${stats.drawcallsbatched}');
				Ui.text('total drawcalls: ${stats.drawcalls}');
				Ui.text('canvas switches: ${stats.canvasswitches}');
				Ui.text('texture memory (MiB): ${Std.int(stats.texturememory/1024/1024)}');
				Ui.tree_pop();
			}
		}
		Ui.end();
#end

		Lg.setColor(1, 1, 1, 1);
		Lg.setCanvas();
		Lg.setWireframe(false);
		Lg.setMeshCullMode(None);
		Lg.setDepthMode();
		Lg.setBlendMode(Alpha);
		Lg.setShader();

		// 2D stuff
		if (use_hud) {
			Hud.update_overlays(overlays);
			Hud.draw();
		}
		// Menu.draw();

		// reset
		Lg.setColor(1, 1, 1, 1);
	}

	public static function frame(window: PlatformWindow, state: RecycleBuffer<Entity>, alpha: Float) {
		GameInput.bind(GameInput.Action.Debug_F2, function() {
			GameLoop.show_imgui = !GameLoop.show_imgui;
			return true;
		});

		var size = window.get_size();
		if (gbuffer == null) {
			reset(size.width, size.height);
		}
		// editor.Editor.draw(window, state);
		render_game(size.width, size.height, state, alpha);

		// Profiler.push_block("Editor UI");
		// editor.Editor.context.draw();
		// Profiler.pop_block();

		TextureCache.free_unused();
	}
}
