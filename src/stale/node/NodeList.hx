package node;

import math.Vec3;
import haxe.ds.Option;
import node.Node;
import node.internal.*;

//
// this file is almost entirely some tables: it's kind of a hassle to
// maintain, but at least it's very simple.
//
// make damn sure you put everything in every table correctly.
//

enum NodeType {
	EventTick;
	ValueNumber;
	ValueString;
	ViewNumber;
	EventLoad;
	SceneAdd;
	DrawableNew;
	TransformNew;
	TransformGet;
	TransformSet;
}

class NodeList {
	//	used when saving
	public static function get_name(key: NodeType): String {
		return switch (key) {
			case EventTick: "event.tick";
			case ValueNumber: "value.number";
			case ValueString: "value.string";
			case ViewNumber: "view.number";
			case EventLoad: "event.load";
			case SceneAdd: "scene.add";
			case TransformNew: "transform.new";
			case TransformGet: "transform.get";
			case TransformSet: "transform.set";
			case DrawableNew: "drawable.new";
		}
	}

	// used when loading
	public static function get_key(id: String): Option<NodeType> {
		return switch (id) {
			case "event.tick": Some(EventTick);
			case "value.number": Some(ValueNumber);
			case "value.string": Some(ValueString);
			case "view.number": Some(ViewNumber);
			case "event.load": Some(EventLoad);
			case "scene.add": Some(SceneAdd);
			case "drawable.new": Some(DrawableNew);
			case "transform.new": Some(TransformNew);
			case "transform.get": Some(TransformGet);
			case "transform.set": Some(TransformSet);
			default: None;
		}
	}

	// used when spawning...
	public static function create(key: NodeType, position: Vec3): Node {
		var constructor: NodeType->Node = switch(key) {
			case EventTick: EventNodes.tick;
			case ValueNumber: ValueNodes.number;
			case ValueString: ValueNodes.string;
			case ViewNumber: ViewNodes.number;
			case EventLoad: EventNodes.load;
			case SceneAdd: SceneNodes.add;
			case TransformNew: TxNodes.new_transform;
			case TransformGet: TxNodes.get_transform;
			case TransformSet: TxNodes.set_transform;
			case DrawableNew: DrawableNodes.new_drawable;
		}
		var ret = constructor(key);
		ret.position = position;
		return ret;
	}
}
