package render;

import love.graphics.GraphicsModule as Lg;
import math.Vec3;

import backend.Profiler;

class PostPass {
	public static function render(gbuffer: GBuffer, vp: Viewport, debug_draw: Bool) {
		Profiler.marker("Post");

		var cfg = Render.config;
		var use_fxaa = cfg.quality.fxaa && !Render.potato_mode;
		var use_msaa = Render.use_msaa;

		var caps: lua.Table<String, Bool> = cast Lg.getSupported();
		if (!caps.glsl3 || Render.gles_mode) {
			use_fxaa = false;
		}

		var exposure = cfg.color.exposure;
		var vignette = cfg.post.vignette;
		var rgb = Render.white_point;
		var r = rgb[0], g = rgb[1], b = rgb[2];

		var rw = vp.w / gbuffer.out1.getWidth();
		var rh = vp.h / gbuffer.out1.getHeight();
		var shader = Shader.get("post");
		Lg.setShader(shader);
		if (use_fxaa) {
			Lg.setCanvas(gbuffer.out2); // ping
		}
		else {
			Lg.setCanvas();
		}
		Lg.setBlendMode(Replace, Premultiplied);
		Lg.setDepthMode();

		var use_glow = Render.use_glow && !use_msaa;

		// yolo glow is incompatible with msaa, because of mipmaps
		Helpers.send(shader, "u_yolo_glow", use_glow);
		Helpers.send(shader, "u_potato", Render.potato_mode ? 1 : 0);
		Helpers.send(shader, "u_white_point", new Vec3(r, g, b).unpack());
		Helpers.send(shader, "u_exposure", exposure);
		Helpers.send(shader, "u_vignette", vignette);
		Helpers.send(shader, "u_rgbm_mul", Render.rgbm_const);

		Lg.setColor(1.0, 1.0, 1.0, 1.0);
		if (!use_msaa) {
			gbuffer.out1.generateMipmaps();
		}
		if (use_fxaa) {
			Lg.draw(gbuffer.out1);

			var shader = Shader.get("fxaa");
			Lg.setShader(shader);
			Lg.setCanvas(gbuffer.out1); // pong
			Lg.draw(gbuffer.out2);
		}
		else {
			Lg.draw(gbuffer.out1, vp.x, vp.y, 0, rw, rh);
		}

		Lg.setCanvas();
		Lg.setShader();
		if (use_fxaa) {
			if (!use_msaa) {
				gbuffer.out1.generateMipmaps();
			}
			Lg.draw(gbuffer.out1, vp.x, vp.y, 0, rw, rh);
		}

		Lg.setBlendMode(Alpha);
	}
}
