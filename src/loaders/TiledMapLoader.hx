package loaders;

import backend.Fs;
import haxe.Json;
// import love.math.MathModule as Lm;
import components.Item;
import math.Vec3;
// import math.Quat;
// import math.Utils;
import math.Bounds;

typedef TiledMap = {
	width: Int,
	height: Int,
	hexsidelength: Int,
	infinite: Bool,
	layers: Array<{
		data: Array<Int>,
		// data: [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
		height: Int,
		id: Int,
		name: String,
		// name: Tile Layer 1,
		opacity: Float,
		// type: tilelayer,
		visible: Bool,
		width: Int,
		x: Int,
		y: Int
	}>,
 	nextlayerid: Int,
	nextobjectid: Int,
	orientation: String, // hex
	renderorder: String, // left-up
	staggeraxis: String, // x
	staggerindex: String, // even
	tiledversion: String, // 2018.08.06
	tileheight: Int,
	tilesets: Array<{
		columns: Int,
		firstgid: Int,
		grid: {
			height: Int,
			orientation: String, //orthogonal,
			width: Int
		},
		margin: Int,
		name: String, // stuff
		spacing: Int,
		tilecount: Int,
		tileheight: Int,
		tiles: Array<{
			id: Int,
			image: String, //dirt tile.png,
			imageheight: Int,
			imagewidth: Int,
			type: String,
			properties: Array<{
				name: String,
				type: String,
				value: Dynamic
			}>
		}>,
		tilewidth: Int
	}>,
 	tilewidth: Int,
	type: String, // map
	version: Float // 1.2,
}

class TiledMapLoader {
	static var mesh_types: Map<String, Array<render.MeshView>>;
	static function get_drawable(tile: SceneNode) {
		var tile_item = tile.item;
		if (mesh_types == null) {
			mesh_types = [
				"grass" => IqmLoader.load_file("assets/models/tiles/grass.iqm"),
				"cube" => IqmLoader.load_file("assets/models/debug/unit-cube.iqm")
			];
		}
		var base = switch (tile_item) {
			case Base: mesh_types["grass"];
			case Portal: mesh_types["grass"];
			default: mesh_types["grass"];
		}
		if (tile_item == null) {
			trace("missing tile info");
			return base;
		}
		base = base.copy();
		switch (tile_item) {
			case Ground(texture, height): return base;
			// case Base: return base.concat(mesh_types["door"]);
			// case Portal: return base.concat(mesh_types["mailbox"]);
			default:
		}
		trace('no drawable for this tile type: ${tile_item.getName()}');
		return base;
	}

	static var textures = [
		"fallback" => "assets/textures/terrain.png",
		"dirt" => "assets/textures/red-grid_1x1.png",
		"grass" => "assets/textures/blue-grid_1x1.png"
	];

	static function get_texture(tex: String) {
		if (textures.exists(tex)) {
			return textures[tex];
		}
		return textures["fallback"];
	}

	public static var home_tile(default, null): SceneNode;
	public static function load_map(filename: String): SceneNode {
		var raw = Fs.read(filename).toString();
		var data: TiledMap = Json.parse(raw);

		var root = new SceneNode();
		root.name = "Map";

		home_tile = null;

		var base_layer = data.layers[0];
		var texture_layer = null;
		for (layer in data.layers) {
			switch (layer.name.toLowerCase()) {
				case "terrain": base_layer = layer;
				case "texture": texture_layer = layer;
				default:
			}
		}
		if (base_layer == null) {
			root.item = MapInfo({
				width: 1,
				height: 1,
				nodes: root.children
			});
			var tile = new SceneNode();
			tile.transform.is_static = true;
			tile.transform.update();
			tile.item = Ground(get_texture("fallback"), 0.0);
			tile.drawable = get_drawable(tile);
			root.children.push(tile);
			home_tile = tile;
			return root;
		}

		root.item = MapInfo({
			width: base_layer.width,
			height: base_layer.height,
			nodes: root.children
		});

		var tile_types: Map<Int, Item> = new Map();
		for (def in data.tilesets[0].tiles) {
			var tile_type = "ground";
			if (def.type != null && def.type != "") {
				tile_type = def.type;
			}
			var texture = "fallback";
			var height: Float = 0.0;
			if (def.properties != null) {
				for (prop in def.properties) {
					// this is probably not very reliable
					if (prop.name == "height" && (prop.type == "float" || prop.type == "int")) {
						height = prop.value;
					}
					if (prop.name == "texture" && prop.type == "string") {
						texture = prop.value;
					}
				}
			}
			tile_types[def.id] = switch(tile_type) {
				case "ground": Ground(get_texture(texture), height * 4);
				case "texture": Ground(get_texture(texture), 0.0);
				case "base": Base;
				case "portal": Portal;
				default: Ground(get_texture("fallback"), -1.0);
			}
		}

		var tile_size = 1.0;
		for (idx in 0...base_layer.data.length) {
			var x = idx % base_layer.width;
			var y = Std.int(idx / base_layer.width);

			var tid = base_layer.data[idx]-1;
			var tile_item = switch (tile_types[tid]) {
				case Ground(texture, height): {
					// combine texture layer info
					// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
					if (texture_layer != null) {
						var tex_tile_item = tile_types[texture_layer.data[idx]-1];
						if (tex_tile_item != null) {
							switch (tex_tile_item) {
								case Ground(real_texture, _): {
									texture = real_texture;
								}
								default: 
							}
						}
					}

					Ground(texture, height);
				}
				default: tile_types[tid];
			};
			if (tile_item == null) {
				tile_item = Ground(get_texture("fallback"), -1);
			}

			var tile = new SceneNode();
			if (data.orientation == "isometric") {
				tile.transform.position.x = x * tile_size;
				tile.transform.position.y = -y * tile_size + (data.height - 1) * tile_size;
			}
			else {
				var hahafuckyou = 0.433012; // hexagonal ratio bullshit
				var y_offset = ((x+1) % 2) * tile_size * hahafuckyou;
				tile.transform.position.x = x * (tile_size * 0.75);
				tile.transform.position.y = -y * tile_size * (hahafuckyou * 2) + y_offset;
			}
			var tile_height = 0.0;
			tile.transform.position.z = switch (tile_item) {
				case Ground(texture, height): tile_height = height; height * 0.25;
				default: 0.0;
			};

			if (tile.transform.position.z < 0) {
				continue;
			}

			tile.transform.is_static = true;
			tile.transform.update();
			tile.item = tile_item;
			tile.drawable = get_drawable(tile);
			tile.bounds = new Bounds(tile.transform.position, new Vec3(1, 1, 1));
			root.children.push(tile);

			if (tile.item == Base || home_tile == null) {
				home_tile = tile;
			}
		}

		if (home_tile == null) {
			throw "AAAAAAAAAAA";
		}

		return root;
	}

}
