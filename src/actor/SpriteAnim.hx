package actor;

import utils.OptionHelper;
import math.Vec4;
import render.TextureCache;
import love.graphics.Image;
import love.graphics.Quad;
import love.graphics.GraphicsModule as Lg;
import utils.RingBuffer;

typedef FrameData = {
	x: Float,
	y: Float,
	w: Float,
	h: Float,
	length: Float
}

class SpriteAnim {
	var frames = new RingBuffer<FrameData>(null);
	var frame_time: Float = 0;
	var filename: String;
	public var image(get, null): Image;
	public var playing(default, null) = false;
	public var w(default, null): Float = 0;
	public var h(default, null): Float = 0;

	public var flip_x: Bool = false;
	public var flip_y: Bool = false;

	public function frame_width() {
		if (this.frames.items.length == 0) {
			return this.w;
		}
		return this.frames.get().w;
	}

	public function frame_height() {
		if (this.frames.items.length == 0) {
			return this.h;
		}
		return this.frames.get().h;
	}

	inline function get_image() {
		return OptionHelper.unwrap_fail(TextureCache.get(this.filename));
	}

	public function new(filename: String, frames_x = 0, frames_y = 0, frame_rate: Float = -1.0) {
		this.filename = filename;
		var image = OptionHelper.unwrap_fail(TextureCache.get(filename));
		this.w = image.getWidth();
		this.h = image.getHeight();
		if (frames_x + frames_y > 0) {
			this.frame_grid(frames_x, frames_y, frame_rate);
		}
	}

	public function set_frame(index: Int) {
		this.frames.set(index);
	}

	public inline function add_frame(x: Float, y: Float, w: Float, h: Float, length: Float) {
		this.frames.push({
			x: x,
			y: y,
			w: w,
			h: h,
			length: length
		});
	}

	public function frame_grid(frames_x: Int, frames_y: Int, rate: Float) {
		var _w = w / frames_x;
		var _h = h / frames_y;
		var len = 1/rate;
		if (rate < 0.0) {
			len = 0.0;
		}
		for (y in 0...frames_y) {
			for (x in 0...frames_x) {
				this.add_frame(_w*x, _h*y, _w, _h, len);
			}
		}
	}

	public function play(playing: Bool = true) {
		this.playing = playing;
	}

	public function stop() {
		this.playing = false;
		this.frame_time = 0;
	}

	public function update(dt: Float) {
		if (this.frames.items.length == 0 || !this.playing) {
			return;
		}

		this.frame_time += dt;
		var len = this.frames.get().length;
		while (this.frame_time >= len && len > 0) {
			this.frames.next();
			this.frame_time -= len;
			len = this.frames.get().length;
		}
	}

	public function get_vp(): Vec4 {
		if (this.frames.items.length == 0) {
			return new Vec4(0, 0, 1, 1);
		}
		var frame = this.frames.get();
		return new Vec4(frame.x/this.w, frame.y/this.h, frame.w/this.w, frame.h/this.h);
	}

	public function get_quad(): Quad {
		if (this.frames.items.length == 0) {
			return Lg.newQuad(0, 0, w, h, w, h);
		}
		var frame = this.frames.get();
		return Lg.newQuad(frame.x, frame.y, frame.w, frame.h, this.w, this.h);
	}
}
