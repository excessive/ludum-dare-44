package iqm;

import love.graphics.Mesh;
import haxe.Json;

import haxe.ds.Option;

extern typedef Bounds = {
	var min: lua.Table<Int, Float>;
	var max: lua.Table<Int, Float>;
}

typedef MeshData = {
	var first: Int;
	var last: Int;
	var count: Int;
	var material: String;
	var name: String;
}

typedef IqmFile = {
	var has_joints: Bool;
	var has_anims: Bool;
	var mesh: Mesh;
	var metadata: String;
	var bounds: lua.Table<Int, Bounds>;
	var meshes: lua.Table<Int, MeshData>;
	var triangles: lua.Table<Int, Dynamic>;
	var joint_map: lua.Table<Dynamic, Dynamic>;
}

typedef ExmMeta = {
	var objects: Array<{
		name: String,
		position: Array<Float>,
		size: Array<Float>,
		transform: Array<Float>,
		transform_without_scale: Array<Float>,
		type: String
	}>;
	var paths: Array<{
		name: String,
		points: Array<{
			handle_left: Array<Float>,
			handle_right: Array<Float>,
			position: Array<Float>
		}>,
		type: String
	}>;
	var trigger_areas: Array<{
		name: String,
		position: Array<Float>,
		size: Array<Float>,
		transform: Array<Float>,
		transform_without_scale: Array<Float>,
		type: String
	}>;
}

@:luaRequire("iqm")
extern class Iqm {
	static function load(filename: String, save_data: Bool = false, preserve_cw: Bool = false): IqmFile;
	static function load_anims(filename: String): IqmAnim;

	static inline function decode_meta(data: IqmFile): Option<ExmMeta> {
		if (data.metadata == null) {
			return None;
		}
		return Some(Json.parse(data.metadata));
	}
}
