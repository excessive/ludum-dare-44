package render;

import love.graphics.Canvas;
import love.graphics.GraphicsModule as Lg;
import math.Vec3;
import math.Quat;
import math.Mat4;
import render.Helpers.*;

import iqm.Iqm;

class DebugPass {
	static var sphere: IqmFile;
	static var cylinder: IqmFile;

	public static function render(shaded: Canvas, depth: Canvas) {
		if (sphere == null) {
			sphere = Iqm.load("assets/models/debug/unit-sphere.iqm");
		}
		if (cylinder == null) {
			cylinder = Iqm.load("assets/models/debug/unit-cylinder.iqm");
		}

		Lg.setCanvas(untyped __lua__(
			"{ {0}, depthstencil = {1} }",
			shaded, depth
		));
		Lg.setWireframe(true);
		Lg.setDepthMode(Lequal, false);

		var shader = Shader.get("debug");
		var camera = Render.camera;
		Lg.setShader(shader);
		Helpers.send_uniforms(camera, shader);

		var cfg = Render.config;
		var exposure = cfg.color.exposure;
		var rgb = Render.white_point;
		var r = rgb[0], g = rgb[1], b = rgb[2];

		var white = new Vec3(r, g, b);
		Helpers.send(shader, "u_white_point", white.unpack());
		Helpers.send(shader, "u_exposure", exposure);

		Lg.setMeshCullMode(None);
		Helpers.send(shader, "u_model", Mat4.from_identity().to_vec4s());

		Debug.draw(false);

		Lg.setWireframe(false);

		Lg.setBlendMode(Alpha, Alphamultiply);

		inline function mtx_for(capsule: Vec3, radius: Float) {
			return Mat4.translate(capsule)
				* Mat4.scale(new Vec3(radius, radius, radius))
			;
		}
		inline function mtx_srt(s: Vec3, r: Quat, t: Vec3) {
			return Mat4.from_srt(t, r, s);
		}

		for (cap_data in Debug.capsules) {
			Lg.setColor(cap_data.r, cap_data.g, cap_data.b, 0.5);
			var capsule = cap_data.capsule;

			var mtx = mtx_for(capsule.a, capsule.radius);
			send_mtx(shader, "u_model", mtx);
			Lg.draw(sphere.mesh);

			mtx = mtx_for(capsule.b, capsule.radius);
			send_mtx(shader, "u_model", mtx);
			Lg.draw(sphere.mesh);

			var dir = capsule.b - capsule.a;
			dir.normalize();

			var rot = Quat.from_direction(dir);
			rot.normalize();

			var length = Vec3.distance(capsule.a, capsule.b);
			mtx = mtx_srt(new Vec3(capsule.radius, capsule.radius, length * 0.5), rot, (capsule.a + capsule.b) * 0.5);

			send_mtx(shader, "u_model", mtx);
			Lg.draw(cylinder.mesh);
		}

		Debug.clear_capsules();
		Lg.setShader();
	}
}
