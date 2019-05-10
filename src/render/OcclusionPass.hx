package render;

import love.graphics.Canvas;
import love.graphics.GraphicsModule as Lg;
import backend.Profiler;
import utils.RecycleBuffer;
import math.Mat4;

class OcclusionPass {
	public static function render(depth: Canvas, light_vp: Mat4, draws: RecycleBuffer<DrawCommand>) {
		if (draws.length == 0) {
			return;
		}

		Profiler.push_block("Shadow");

		Lg.setCanvas(untyped __lua__("{ depthstencil = {0} }", depth));
		Lg.clear(untyped __lua__("{ 0, 0, 0, 0 }"), cast false, cast true);

		var shader = Shader.get("shadow");

		Lg.setShader(shader);
		Helpers.send_mtx(shader, "u_viewproj", light_vp);
		
		Lg.setFrontFaceWinding(Cw);
		Lg.setDepthMode(Less, true);
		Lg.setMeshCullMode(Back);
		Lg.setColorMask(false, false, false, false);
		Lg.setBlendMode(Replace, Premultiplied);

		for (d in draws) {
			if (d.bones != null) {
				Helpers.send(shader, "u_rigged", 1);
				untyped __lua__("{0}:send({1}, \"column\", unpack({2}))", shader, "u_pose", d.bones);
			}
			else {
				Helpers.send(shader, "u_rigged", 0);
			}
			Helpers.send_mtx(shader, "u_model", d.xform_mtx);
			Lg.draw(d.mesh.use());
		}

		Lg.setDepthMode();
		Lg.setMeshCullMode(None);
		Lg.setColorMask(true, true, true, true);

		Profiler.pop_block();
	}

}
