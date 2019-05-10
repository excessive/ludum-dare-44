import math.Intersect;
import math.Ray;
import math.Utils;
import math.Octree;
import math.Bounds;
import math.Vec3;
import love.graphics.Mesh;
import utils.RecycleBuffer;
import utils.Maybe;

class Scene {
	public var root = new SceneNode();
	var entities = new RecycleBuffer<Entity>();
	var octree: Octree<SceneNode>;

	function octree_add_r(node: SceneNode) {
		if (node.bounds != null) {
			this.octree.add(node, node.bounds);
		}
		for (child in node.children) {
			octree_add_r(child);
		}
	}

	public function update_octree() {
		var b = this.root.bounds;
		var extents = Utils.max(b.size.x, Utils.max(b.size.y, b.size.z));
		this.octree = new Octree(extents, b.center, 1.0, 1.1);
		octree_add_r(this.root);
	}

	public inline function get_colliding_nodes(min: Vec3, max: Vec3) {
		return this.octree.get_colliding(Bounds.from_extents(min, max));
	}

	public function cast_ray(r: Ray, cond: SceneNode->Bool, ?max_distance: Float): Maybe<{ p: Vec3, d: Float, o: SceneNode }> {
		var nearest = max_distance;
		var closest_point = null;
		var hit_node = null;
		if (max_distance != null) {
			closest_point = r.direction * max_distance;
		}
		this.octree.cast_ray(r, (ray, data) -> {
			for (o in data) {
				var hit_data = Intersect.ray_aabb(ray, o.bounds);
				if (!hit_data.exists()) {
					continue;
				}
				var hit = hit_data.sure();
				if (!cond(o.data)) {
					continue;
				}
				var dist = Vec3.distance(hit.point, ray.position);
				if (nearest == null) {
					nearest = dist;
				}
				if (dist <= nearest) {
					closest_point = hit.point;
					nearest = dist;
					hit_node = o.data;
				}
			}
			return false;
		});
		if (closest_point == null || hit_node == null) {
			return null;
		}
		return { p: closest_point, d: nearest, o: hit_node };
	}

	public function release() {
		var entities = this.get_entities();
		var meshes = new Map<Mesh, Bool>();
		for (e in entities) {
			var drawable = e.drawable;
			if (drawable.length == 0) {
				continue;
			}
			for (view in drawable) {
				var mesh = view.use();
				meshes[mesh] = true;
			}
		}
		for (m in meshes.keys()) {
			m.release();
			meshes.remove(m);
		}
	}

	public inline function get_child(name: String): Maybe<SceneNode> {
		return this.root.get_child(name);
	}

	public function new() {
		this.root.name = "Root";
	}

	public inline function get_entities(?cb: Entity->Bool): RecycleBuffer<Entity> {
		this.entities.reset();
		SceneNode.flatten_tree(this.root, this.entities);
		return this.entities;
	}

	public inline function get_visible_entities(): RecycleBuffer<Entity> {
		#if 0
		var culled = 0;
		return get_entities((e: Entity) -> {
			if (e.bounds != null && e.transform.is_static) {
				if (!Intersect.aabb_frustum(e.bounds, camera.frustum)) {
					culled += 1;
					return false;
				}
			}
			return true;
		});
		#end
		return get_entities();
	}

	function update_tree(base: SceneNode) {
		this.update_bounds(base);

		for (child in base.children) {
			child.parent = base;
			this.update_tree(child);
		}
	}

	function update_bounds(node: SceneNode) {
		// update scene root bounds
		if (this.root.bounds == null) {
			this.root.bounds = Bounds.from_extents(node.transform.position, node.transform.position);
		}

		if (node.bounds != null) {
			this.root.bounds = Bounds.from_extents(
				Vec3.min(this.root.bounds.min, node.bounds.min),
				Vec3.max(this.root.bounds.max, node.bounds.max)
			);
		}
		else {
			this.root.bounds = Bounds.from_extents(
				Vec3.min(this.root.bounds.min, node.transform.position),
				Vec3.max(this.root.bounds.max, node.transform.position)
			);
		}
	}

	public function add(node: SceneNode) {
		this.root.children.push(node);
		if (node.parent == null) {
			node.parent = root;
		}
		this.update_tree(node);
	}

	public function remove(node: SceneNode) {
		if (node.parent != null) {
			node.parent.children.remove(node);
		}
	}
}
