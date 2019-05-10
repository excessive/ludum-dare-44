package actor;

import math.Bounds;
import math.Intersect;
import love.graphics.GraphicsModule as Lg;
import math.Vec3;
import math.Vec4;
import math.Mat4;
import math.Quat;
import utils.RecycleBuffer;
import utils.Maybe;

abstract LayerInfo({
	x: Int,
	y: Int,
	width: Int,
	height: Int,
	padding_left: Int,
	padding_right: Int,
	padding_top: Int,
	padding_bottom: Int
}) {
	public function new(vp: Vec4, pl: Int, pr: Int, pt: Int, pb: Int) {
		this = {
			x: Std.int(vp.x),
			y: Std.int(vp.y),
			width: Std.int(vp.z),
			height: Std.int(vp.w),
			padding_left: pl,
			padding_right: pr,
			padding_top: pt,
			padding_bottom: pb
		}
	}

	public var top(get, never): Int;
	public var bottom(get, never): Int;
	public var left(get, never): Int;
	public var right(get, never): Int;
	public var width(get, never): Int;
	public var height(get, never): Int;
	public var center_x(get, never): Int;
	public var center_y(get, never): Int;

	function get_top(): Int {
		return this.y + this.padding_top;
	}

	function get_bottom(): Int {
		return Std.int(this.height + this.y - this.padding_bottom);
	}

	function get_left(): Int {
		return Std.int(this.x + this.padding_left);
	}

	function get_right(): Int {
		return Std.int(this.width + this.x - this.padding_right);
	}

	inline function get_width(): Int {
		return get_right() - get_left();
	}

	inline function get_height(): Int {
		return get_bottom() - get_top();
	}

	inline function get_center_x(): Int {
		return Std.int((get_left() + get_right()) / 2);
	}

	inline function get_center_y(): Int {
		return Std.int((get_top() + get_bottom()) / 2);
	}
}

class ActorLayer {
	public var padding_left: Int = 0;
	public var padding_right: Int = 0;
	public var padding_top: Int = 0;
	public var padding_bottom: Int = 0;

	public var position(default, null): Vec3 = new Vec3(0, 0, 0);
	public var scale(default, null): Vec3 = new Vec3(1, 1, 1);
	public var orientation(default, null): Quat = new Quat(0, 0, 0, 1);
	public var viewport(default, null): Vec4;

	var layer_info: LayerInfo;

	var root = new Actor();

	public var depth_test = true;
	public var scissor_test = false;
	public var show_debug = true;

	static var g_id: Int = 0;
	var name: String;

	public function new(create_actors: Void->Array<Actor>) {
		this.name = '<layer $g_id>';
		g_id++;

		this.viewport = new Vec4(0, 0, 0, 0);
		this.update_info();

		this.root.children = create_actors();
		this.broadcast("init");
		this.broadcast("resize");
	}

	function update_info() {
		this.layer_info = new LayerInfo(
			viewport,
			padding_left,
			padding_right,
			padding_top,
			padding_bottom
		);
	}

	public function update_bounds(vp: Vec4) {
		this.viewport.x = vp.x;
		this.viewport.y = vp.y;
		this.viewport.z = vp.z;
		this.viewport.w = vp.w;
		this.update_info();
		this.broadcast("resize");
	}

	var last_hover: Null<Actor>;
	public function hover(x: Float, y: Float) {
		var layer_bounds = Bounds.from_extents(
			new Vec3(this.layer_info.left, this.layer_info.top, 0),
			new Vec3(this.layer_info.right, this.layer_info.bottom, 0)
		);
		if (!Intersect.point_aabb(new Vec3(x, y, 0), layer_bounds)) {
			if (last_hover != null) {
				last_hover.on_hover(false);
				last_hover = null;
			}
			return;
		}

		var raw_hits = [];
		this.root.hit(x, y, raw_hits);

		var hits = [ for (h in raw_hits) if (h.on_hover != null) h ];
		if (hits.length == 0 && last_hover != null) {
			last_hover.on_hover(false);
			last_hover = null;
		}
		for (hit in hits) {
			if (last_hover != null && last_hover != hit && last_hover.on_hover != null) {
				last_hover.on_hover(false);
			}
			if (last_hover != hit) {
				hit.on_hover(true);
				last_hover = hit;
			}
		}
	}

	public function hit(x: Float, y: Float) {
		var layer_bounds = Bounds.from_extents(
			new Vec3(this.layer_info.left, this.layer_info.top, 0),
			new Vec3(this.layer_info.right, this.layer_info.bottom, 0)
		);
		if (!Intersect.point_aabb(new Vec3(x, y, 0), layer_bounds)) {
			return;
		}

		var hits = [];
		this.root.hit(x, y, hits);
		
		for (hit in hits) {
			if (hit.on_click != null) {
				hit.on_click();
			}
		}
	}

	function propagate_visibility(base: Actor, visibility: Bool) {
		if (!base.actual.visible) {
			visibility = false;
		}
		for (child in base.children) {
			child.render_visible = visibility;
			propagate_visibility(child, visibility);
		}
	}

	public function update(dt: Float) {
		this.root.force_transform = Mat4.from_srt(
			this.position,
			this.orientation,
			this.scale
		);
		this.root.update(dt, this.layer_info, this.show_debug);
		propagate_visibility(this.root, this.root.actual.visible);
	}

	public inline function broadcast(k: String) {
		root.trigger(k, true);
#if debug
		console.Console.ds('broadcast command "$k" on ${this.name}');
#end
	}

	public function find_actor(name: String, ?base: Actor): Maybe<Actor> {
		function find_internal(name: String, actor: Actor): Maybe<Actor> {
			if (actor.name == name) {
				return actor;
			}
			for (child in actor.children) {
				final result = find_internal(name, child);
				if (result.exists()) {
					return result;
				}
			}
			return null;
		}
		if (base != null) {
			return find_internal(name, base);
		}
		return find_internal(name, root);
	}

	static function draw_recursive(actor: Actor) {
		Lg.push(All);

		if (actor.scissor_test) {
			Lg.setScissor(
				actor.final_position.x,
				actor.final_position.y,
				actor.width,
				actor.height
			);
		}

		var actual = actor.actual;
		if (!actual.visible || !actor.render_visible) {
			Lg.pop();
			return;
		}
		var old_color = Lg.getColor();
		Lg.setColor(old_color.r, old_color.g, old_color.b, old_color.a * actor.actual.opacity);
		if (actor.on_draw != null) {
			actor.on_draw(actor.user_data);
		}
		actor.sprite.map((sprite) -> {
			var pos = actor.final_position;
			var sx = actual.scale.x;
			var sy = actual.scale.y;
			// trace(actor.name, pos);
			if (sprite.flip_x) {
				pos.x += sprite.frame_width() * sx;
				sx *= -1.0;
			}
			if (sprite.flip_y) {
				pos.y += sprite.frame_height() * sy;
				sy *= -1.0;
			}
			var ox = -actor.offset_x;
			var oy = -actor.offset_y;
			Lg.draw(sprite.image, sprite.get_quad(), Std.int(pos.x), Std.int(pos.y), 0, sx, sy, ox, oy);
		});
		Lg.setColor(old_color.r, old_color.g, old_color.b, old_color.a);

		for (child in actor.children) {
			draw_recursive(child);
		}

		Lg.pop();
	}

	public static function draw(layer: ActorLayer, alpha: Float = 1.0) {
		var old_color = Lg.getColor();
		var scissor = Lg.getScissor();
		// var old_blend = Lg.getBlendMode();
		if (layer.scissor_test) {
			Lg.setScissor(
				layer.layer_info.left,
				layer.layer_info.top,
				layer.layer_info.width,
				layer.layer_info.height
			);
		}
		draw_recursive(layer.root);
		Lg.setColor(old_color.r, old_color.g, old_color.b, old_color.a);
		Lg.setScissor(scissor.x, scissor.y, scissor.width, scissor.height);
	}
}
