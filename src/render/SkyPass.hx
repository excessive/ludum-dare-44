package render;

import love.graphics.GraphicsModule as Lg;
import love.graphics.Canvas;

class SkyPass {
	public static function render(shaded: Canvas, depth: Canvas) {
		// this shader depends on gl_FragDepth writing, which isn't
		// available on anything I can test
		if (Render.gles_mode) {
			return;
		}

		var caps: lua.Table<String, Bool> = cast Lg.getSupported();
		if (!caps.glsl3) {
			return;
		}
		var shader = Shader.get("sky");
		Lg.setShader(shader);
		Lg.setBlendMode(Replace, Premultiplied);
		Lg.setCanvas(untyped __lua__("{ {0}, depthstencil = {1} }", shaded, depth));
		Helpers.send_uniforms(Render.camera, shader);
		Lg.setDepthMode(Equal, false);
		Lg.rectangle(Fill, -1, -1, 2, 2);
	}
}
