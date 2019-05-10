package actor;

import math.Bounds;
import math.Intersect;
import math.Vec4;
import math.Utils;
import math.Vec3;
import math.Mat4;
import utils.Maybe;

import actor.ActorLayer.LayerInfo;

#if imgui
import imgui.ImGui as Ui;
#end

typedef TweenFn = Float->Float;
typedef CommandFn = Void->Void;

class Actor {
	var tween_stack: Array<TweenState> = [];
	var current: TweenState;
	public var actual(default, null) = new TweenState(Constant, 0);
	var commands = new Map<String, CommandFn>();

	public var render_visible = true;
	public var scissor_test = false;

	public var user_data: Any;
	public var on_update: Any->Float->Void;
	public var on_draw: Any->Void;

	public var name(default, null): String;
	public var children: Array<Actor> = [];
	public var matrix = Mat4.from_identity();
	public var force_transform: Null<Mat4> = null;
	public var sprite(default, null): Maybe<SpriteAnim> = null;

	public var offset_x(default, null): Float = 0.0;
	public var offset_y(default, null): Float = 0.;

	public var offset_matrix(default, null) = Mat4.from_identity();

	public var padding_x(default, null): Float = 0.0;
	public var padding_y(default, null): Float = 0.0;

	public var on_click: Null<Void->Void>;
	public var on_hover: Null<(enter:Bool)->Void>;

	static var ORIGIN = new Vec3(0, 0, 0);
	var anchor = (info: LayerInfo) -> ORIGIN;

	static var g_id: Int = 0;

	public final final_position: Vec3 = new Vec3(0, 0, 0);

	public function hit(x: Float, y: Float, hits: Array<Actor>) {
		if (this.final_position == null || !this.render_visible || !this.actual.visible) {
			return;
		}
		var size = new Vec3(this.width, this.height, 0);
		if (Intersect.point_aabb(new Vec3(x, y, 0), Bounds.from_extents(this.final_position, this.final_position + size))) {
			hits.push(this);
		}
		for (child in this.children) {
			child.hit(x, y, hits);
		}
	}

	function push(type: TweenType, t: Float) {
		var state = new TweenState(type, t);
		var len = tween_stack.length;
		if (len > 0) {
			state.set_from(tween_stack[len-1]);
		}
		tween_stack.push(state);
		current = state;
	}

	public function load_sprite(filename: String, frames_x: Int = 0, frames_y: Int = 0, frame_rate: Float = 0) {
		this.sprite = new SpriteAnim(filename, frames_x, frames_y, frame_rate);
		if (frame_rate > 0) {
			this.animate(true);
		}
	}

	public function set_offset(x: Float, y: Float) {
		this.offset_x = x;
		this.offset_y = y;
	}

	public function set_name(name: String) {
		this.name = name;
	}

	public function set_flip(x: Bool, y: Bool) {
		this.sprite.map((sprite) -> {
			sprite.flip_x = x;
			sprite.flip_y = y;
		});
	}

	public function set_frame(frame_index: Int) {
		this.sprite.map((sprite) -> {
			sprite.set_frame(frame_index);
		});
	}

	public function animate(run: Bool) {
		this.sprite.map((sprite) -> {
			sprite.play(run);
		});
	}

	public function new(?initfn: (self:Actor)->Void) {
		this.name = '<actor $g_id>';
		g_id++;
		this.push(Constant, 0);
		if (initfn != null) {
			initfn(this);
		}
	}

	public function stop() {
		current.position = actual.position;
		current.scale = actual.scale;
		current.visible = actual.visible;
		current.opacity = actual.opacity;
		finish();
		return this;
	}

	public function hurry(factor: Float) {
		var inv = 1/factor;
		for (state in tween_stack) {
			if (state.tween_time > 0.0) {
				var remain = state.tween_duration - state.tween_time;
				state.tween_duration = remain * inv + state.tween_time;
				continue;
			}
			state.tween_duration *= inv;
		}
		return this;
	}

	public function finish() {
		current.tween_time = current.tween_duration;
		tween_stack.resize(1);
		tween_stack[0] = current;
		return this;
	}

	public function register(k: String, v: CommandFn) {
		this.commands[k] = v;
	}

	public function trigger(k: String, recursive: Bool = false) {
		if (this.commands.exists(k)) {
			this.commands[k]();
		}
		if (!recursive) {
			return;
		}
		for (child in this.children) {
			child.trigger(k, recursive);
		}
	}

	public function queue(cmd: String) {
		if (this.current.cmd_queue.indexOf(cmd) < 0) {
			this.current.cmd_queue.push(cmd);
		}
		return this;
	}

	public function sleep(t: Float) {
		this.push(Constant, t);
		return this;
	}

	public function linear(t: Float) {
		this.push(Linear, t);
		return this;
	}

	public function accelerate(t: Float) {
		this.push(InQuad, t);
		return this;
	}

	public function decelerate(t: Float) {
		this.push(OutQuad, t);
		return this;
	}

	public function smooth(t: Float) {
		this.push(SmoothQuad, t);
		return this;
	}

	function tween_for(type: TweenType): TweenFn {
		inline function out(f: TweenFn) {
			return function(s: Float): Float { return 1 - f(1-s); };
		}
		inline function chain(f1: TweenFn, f2: TweenFn) {
			return function(s: Float): Float { return (s < .5 ? f1(2*s) : 1 + f2(2*s-1)) * .5; }
		}
		function quad(t: Float) {
			return t*t;
		}
		function cubic(t: Float) {
			return t*t*t;
		}

		return switch(type) {
			case Constant: return function(t) { return 0; }
			case Linear: return function(t) { return t; }
			case InQuad: return quad;
			case InCubic: return cubic;
			case OutQuad: return out(quad);
			case OutCubic: return out(cubic);
			case SmoothQuad: return chain(quad, out(quad));
			case SmoothCubic: return chain(cubic, out(cubic));
		}
	}

	function mix(a: TweenState, b: TweenState, t: Float) {
		var tween = tween_for(b.tween_type);
		var tc = tween(t);
		actual.position = Vec3.lerp(a.position, b.position, tc);
		actual.scale = Vec3.lerp(a.scale, b.scale, tc);
		actual.visible = a.visible;
		actual.opacity = Utils.lerp(a.opacity, b.opacity, tc);
		for (i in 0...actual.aux.length) {
			actual.aux[i] = Utils.lerp(a.aux[i], b.aux[i], tc);
		}
	}

	function debug_dump() {
#if (!actor_debug)
		return;
#end
#if imgui
		Ui.push_id(this.name);
		Ui.text(this.name);
		var retf2 = Ui.slider_float2("padding", this.padding_x, this.padding_y, 0, 32);
		this.padding_x = retf2.f1;
		this.padding_y = retf2.f2;

		var retf2 = Ui.slider_float2("offset", this.offset_x, this.offset_y, -100, 100);
		this.offset_x = retf2.f1;
		this.offset_y = retf2.f2;

		var pos = this.current.position;
		var retf3 = Ui.input_float3("position", pos.x, pos.y, pos.z);
		pos.x = retf3.f1;
		pos.y = retf3.f2;
		pos.z = retf3.f3;

		Ui.pop_id();
#end
	}

	function update_tweens(b: TweenState, dt: Float): Float {
		if (b == null) {
			return 0.0;
		}

		b.tween_time += dt;
		var progress = b.tween_time / b.tween_duration;

		// we need at least one thing left on the stack at all times.
		if (progress >= 1 && tween_stack.length > 1) {
			this.tween_stack.splice(0, 1);

			if (b.cmd_queue.length > 0) {
				for (cmd in b.cmd_queue) {
					if (this.commands.exists(cmd)) {
						this.commands[cmd]();
					}
				}
				b.cmd_queue.resize(0);
			}

			// if a tween was overshot, don't lose the time.
			this.tween_stack[0].tween_time += b.tween_time - b.tween_duration;
		}

		return progress;
	}

	public function update(dt: Float, info: LayerInfo, show_debug: Bool, ?parent: Actor): Void {
		if (show_debug) {
			debug_dump();
		}

		var child_info = new LayerInfo(
			new Vec4(info.left, info.top, info.width, info.height),
			Math.floor(this.padding_x), Math.floor(this.padding_x),
			Math.floor(this.padding_y), Math.floor(this.padding_y)
		);

		this.sprite.map((sprite) -> {
			sprite.update(dt);
		});

		var a = this.tween_stack[0];
		var b = this.tween_stack[1];

		// if the parent is invisible, short circuit the updates.
		if (parent != null) {
			if (!parent.actual.visible) {
				update_tweens(b, dt);
				var visible = this.actual.visible;
				this.actual.visible = false;
				var open = false;
				#if (actor_debug && imgui)
				if (show_debug && this.children.length > 0) {
					open = Ui.tree_node('children of ${this.name}', false);
				}
				#end
				for (child in this.children) {
					child.update(dt, child_info, show_debug && open, this);
					#if (actor_debug && imgui)
					if (open) {
						Ui.spacing();
					}
					#end
				}
				this.actual.visible = visible;
				#if (actor_debug && imgui)
				if (show_debug && open && this.children.length > 0) {
					Ui.tree_pop();
				}
				#end
				return;
			}
		}

		// actor_buffer.push(this);

		if (this.on_update != null) {
			this.on_update(this.user_data, dt);
		}

		if (b == null) {
			this.actual = a;
			// should this use child info?
			this.update_matrix(info, parent);

			var open = false;
			#if (actor_debug && imgui)
			if (show_debug && this.children.length > 0) {
				open = Ui.tree_node('children of ${this.name}', false);
			}
			#end
			for (child in this.children) {
				child.update(dt, child_info, show_debug && open, this);
				#if (actor_debug && imgui)
				if (open) {
					Ui.spacing();
				}
				#end
			}
			#if (actor_debug && imgui)
			if (show_debug && open && this.children.length > 0) {
				Ui.tree_pop();
			}
			#end
			return;
		}

		var progress = update_tweens(b, dt);
		this.mix(a, b, Utils.clamp(progress, 0, 1));
		this.update_matrix(info, parent);

		for (child in this.children) {
			child.update(dt, child_info, show_debug, this);
		}
	}

	function update_matrix(info: LayerInfo, ?parent: Actor) {
		if (this.force_transform != null) {
			this.matrix = this.force_transform;
		}
		else {
			this.offset_matrix = Mat4.translate(new Vec3(this.padding_x, this.padding_y, 0));
			this.matrix = Mat4.from_st(
				this.anchor(info) + this.actual.position,
				// new Quat(0, 0, 0, 1),
				this.actual.scale
			);
			if (parent != null) {
				this.matrix = parent.offset_matrix * parent.matrix * this.matrix;
			}
		}
		this.final_position.set_from(this.matrix * ORIGIN);
	}

	public function set_padding(x: Float, y: Float) {
		this.padding_x = x;
		this.padding_y = y;
	}

	public var width(get, never): Float;
	function get_width() {
		return sprite.mapDefault((sprite) -> sprite.frame_width(), 0.0);
	}

	public var height(get, never): Float;
	function get_height() {
		return sprite.mapDefault((sprite) -> sprite.frame_height(), 0.0);
	}

	public function set_anchor(anchor_fn: (layer:LayerInfo)->Vec3) {
		this.anchor = anchor_fn;
		return this;
	}

	public function move_by(x: Float, y: Float, z: Float = 0.0) {
		var c = current.position;
		current.position.set_xyz(
			c.x + x,
			c.y + y,
			c.z + z
		);
		return this;
	}

	public function scale_to(x: Float, y: Float, z: Float = 1.0) {
		current.scale.set_xyz(x, y, z);
		return this;
	}

	public function scale_by(x: Float, y: Float, z: Float = 1.0) {
		var c = current.scale;
		current.scale.set_xyz(
			c.x * x,
			c.y * y,
			c.z * z
		);
		return this;
	}

	public function set_opacity(opacity: Float) {
		current.opacity = opacity;
		return this;
	}

	public function set_aux(aux: Float, channel: Int = 0) {
		if (channel >= 8) {
			trace('clamped aux channel from $channel on $name. only 8 channels available!');
			channel = 7;
		}
		current.aux[channel] = aux;
		return this;
	}

	public function set_visible(visible: Bool) {
		current.visible = visible;
		return this;
	}

	public function move_to(x: Float, y: Float, z: Float = 0.0) {
		current.position.set_xyz(x, y, z);
		return this;
	}
}
