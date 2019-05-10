package components;

// import math.Capsule;
enum Item {
	Base;
	Portal;
	Ground(texture: String, height: Float);
	MapInfo(info: { width: Int, height: Int, nodes: Array<SceneNode> });
}
