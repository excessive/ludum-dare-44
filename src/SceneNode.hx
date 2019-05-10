import components.*;
import utils.RecycleBuffer;
import anim9.Anim9;
import math.Bounds;
// import node.NodeGraph;
import utils.Maybe;

class SceneNode {
	public var parent:   Null<SceneNode>  = null;
	public var children: Array<SceneNode> = [];
	public var name: String;

	// hide from the editor (for generated entities where it will not be useful)
	public var hidden: Bool = false;

	private static var g_id: Int = 0;

	private var data: Entity = {
		id: g_id++,
		// pawn: null,
		transform: new Transform(),
		last_tx: new Transform(),
		drawable: [],
		emitter: [],
		bounds: null,
		animation: null,
		item: null,
		collidable: null,
		player: null,
		trigger: null,
		physics: null,
	};

	public function get_child(name: String): Maybe<SceneNode> {
		if (this.name == name) {
			return this;
		}
		for (child in this.children) {
			final result = child.get_child(name);
			if (result.exists()) {
				return result;
			}
		}
		return null;
	}

	public inline function to_entity() {
		return data;
	}

	// read-only
	public var id(get, never): Int;
	@:noCompletion public inline function get_id() { return data.id; }

	// public var pawn(get, set): Pawn;
	// public inline function get_pawn() { return data.pawn; }
	// public inline function set_pawn(pawn: Pawn) { data.pawn = pawn; return pawn; }

	public var bounds(get, set): Bounds;
	@:noCompletion public inline function get_bounds() { return data.bounds; }
	@:noCompletion public inline function set_bounds(bounds: Bounds) { data.bounds = bounds; return bounds; }

	public var animation(get, set): Anim9;
	@:noCompletion public inline function get_animation() { return data.animation; }
	@:noCompletion public inline function set_animation(animation: Anim9) { data.animation = animation; return animation; }

	public var item(get, set): Item;
	@:noCompletion public inline function get_item() { return data.item; }
	@:noCompletion public inline function set_item(item: Item) { data.item = item; return item; }

	// redirect all data to entity fields for convenience. these get compiled out.
	// this makes usage a little nicer and saves a lot of allocations when flattening
	public var transform(get, never):  Transform;
	@:noCompletion public inline function get_transform() { return data.transform; }

	public var last_tx(get, never):  Transform;
	@:noCompletion public inline function get_last_tx() { return data.last_tx; }
	// public inline function set_last_tx(tx: Transform) { data.last_tx = tx; return tx; }

	public var collidable(get, set): Null<Collidable>;
	@:noCompletion public inline function get_collidable() { return data.collidable; }
	@:noCompletion public inline function set_collidable(coll: Null<Collidable>) { data.collidable = coll; return coll; }

	public var drawable(get, set): Drawable;
	@:noCompletion public inline function get_drawable() { return data.drawable; }
	@:noCompletion public inline function set_drawable(draw: Drawable) { if (draw == null) { draw = []; } data.drawable = draw; return draw; }

	public var physics(get, set): Null<Physics>;
	@:noCompletion public inline function get_physics() { return data.physics; }
	@:noCompletion public inline function set_physics(phys: Null<Physics>) { data.physics = phys; return phys; }

	public var player(get, set): Null<Player>;
	@:noCompletion public inline function get_player() { return data.player; }
	@:noCompletion public inline function set_player(tx: Player) { data.player = tx; return tx; }

	public var trigger(get, set): Null<Trigger>;
	@:noCompletion public inline function get_trigger() { return data.trigger; }
	@:noCompletion public inline function set_trigger(tr: Trigger) { data.trigger = tr; return tr; }

	public var emitter(get, never): Array<Emitter>;
	@:noCompletion public inline function get_emitter() { return data.emitter; }

	// public var scripts(get, never): Array<NodeGraph>;
	// public inline function get_scripts() { return data.scripts; }

	public inline function new() {
		name = '<unnamed ${data.id}>';
	}

	public static function flatten_tree(root: SceneNode, entities: RecycleBuffer<Entity>) {
		for (node in root.children) {
			entities.push(node.data);
			flatten_tree(node, entities);
		}
	}
}
