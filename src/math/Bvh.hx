package math;

import utils.Maybe;

@:nullSafety
class BvhNode {
	public final extentsMin: Vec3;
	public final extentsMax: Vec3;
	public var startIndex = -1;
	public var endIndex = -1;
	public var level = -1;
	public var node0: Maybe<BvhNode> = null;
	public var node1: Maybe<BvhNode> = null;

	public function new(_extentsMin, _extentsMax, _startIndex, _endIndex, _level) {
		this.extentsMin = _extentsMin;
		this.extentsMax = _extentsMax;
		this.startIndex = _startIndex;
		this.endIndex   = _endIndex;
		this.level      = _level;
		this.node0      = null;
		this.node1      = null;
	}

	public inline function count() return this.endIndex - this.startIndex;
	public inline function centerX() return 0.5 * (this.extentsMin.x + this.extentsMax.x);
	public inline function centerY() return 0.5 * (this.extentsMin.y + this.extentsMax.y);
	public inline function centerZ() return 0.5 * (this.extentsMin.z + this.extentsMax.z);
	public inline function clearShapes() {
		this.startIndex = -1;
		this.endIndex   = -1;
	}
}

@:nullSafety(Off)
class Bvh<T> {
	static inline final EPSILON = 1e-6;
	final _bboxArray: Array<Float> = [];
	final _bboxHelper: Array<Float> = [];
	final _dataArray: Array<T> = [];
	final _maxTrianglesPerNode: Int;
	final _rootNode: BvhNode;

	public function new(_data: Array<T>, bounds: Array<Bounds>, maxTrianglesPerNode: Int = 10) {
		if (_data.length != bounds.length) {
			throw "data and bounds lengths must match!";
		}

		this._dataArray           = _data;
		this._maxTrianglesPerNode = maxTrianglesPerNode;
		this._bboxArray           = calcBoundingBoxes(bounds);

		// clone a helper array
		this._bboxHelper = [];
		for (bbox in this._bboxArray) {
			this._bboxHelper.push(bbox);
		}

		// create the root node, add all the bounds to it
		final triangleCount = bounds.length;
		final extents = this.calcExtents(0, triangleCount, EPSILON);
		this._rootNode = new BvhNode(extents[0], extents[1], 0, triangleCount, 1);

		function split_r(node) {
			final split = this.splitNode(this._rootNode);
			if (split.left != null) split_r(split.left);
			if (split.right != null) split_r(split.right);
		}
		split_r(this._rootNode);
	}

	public function ray_cast(rayOrigin: Vec3, rayDirection: Vec3, backfaceCulling: Bool = false) {
		final nodesToIntersect: Array<BvhNode> = [ this._rootNode ];
		final dataInIntersectingNodes: Array<Int> = []; //a list of nodes that intersect the ray (according to their bounding box)
		final invRayDirection = new Vec3(1 / rayDirection.x, 1 / rayDirection.y, 1 / rayDirection.z);

		// go over the BVH tree, and extract the list of triangles that lie in nodes that intersect the ray.
		// note. these triangles may not intersect the ray themselves
		while (nodesToIntersect.length > 0) {
			final node = nodesToIntersect.pop();
			if (intersectNodeBox(rayOrigin, invRayDirection, node)) {
				if (node.node0.exists()) {
					nodesToIntersect.push(node.node0.sure());
				}
				if (node.node1.exists()) {
					nodesToIntersect.push(node.node1.sure());
				}
				for (i in node.startIndex...node.endIndex) {
					dataInIntersectingNodes.push(i*7);
				}
			}
		}

		// go over the list of candidate objects, and check each of them using ray triangle intersection
		final ray = new Ray(
			new Vec3(rayOrigin.x,    rayOrigin.y,    rayOrigin.z),
			new Vec3(rayDirection.x, rayDirection.y, rayDirection.z)
		);

		final intersectingObjects = [];
		for (i in 0...dataInIntersectingNodes.length) {
			final boxIndex = dataInIntersectingNodes[i];
			final bounds = Bounds.from_extents(
				new Vec3(this._bboxArray[boxIndex+1], this._bboxArray[boxIndex+2], this._bboxArray[boxIndex+3]),
				new Vec3(this._bboxArray[boxIndex+4], this._bboxArray[boxIndex+5], this._bboxArray[boxIndex+6])
			);
			final hit = Intersect.ray_aabb(ray, bounds);
			if (hit.exists()) {
				var hit_data = hit.sure();
				var dataIndex = Std.int(this._bboxArray[boxIndex]);
				intersectingObjects.push({
					data                : this._dataArray[dataIndex],
					dataIndex           : dataIndex,
					intersectionPoint   : hit_data.point,
					intersectionDistance: hit_data.distance
				});
			}
		}

		return intersectingObjects;
	}

	inline function intersectNodeBoxBounds(check_bounds: Bounds, node: BvhNode): Bool {
		final node_bounds = Bounds.from_extents(node.extentsMin, node.extentsMax);
		return Intersect.aabb_aabb(check_bounds, node_bounds);
	}

	public function get_colliding(min: Vec3, max: Vec3) {
		final nodesToIntersect: Array<BvhNode> = [ this._rootNode ];
		final boundsInIntersectingNodes: Array<Int> = []; //a list of nodes that intersect the ray (according to their bounding box)

		// go over the BVH tree, and extract the list of triangles that lie in nodes that intersect the ray.
		// note. these triangles may not intersect the ray themselves
		final bounds = Bounds.from_extents(min, max);
		while (nodesToIntersect.length > 0) {
			final node = nodesToIntersect.pop();
			if (intersectNodeBoxBounds(bounds, node)) {
				if (node.node0.exists()) {
					nodesToIntersect.push(node.node0.sure());
				}
				if (node.node1.exists()) {
					nodesToIntersect.push(node.node1.sure());
				}
				for (i in node.startIndex...node.endIndex) {
					boundsInIntersectingNodes.push(i*7);
				}
			}
		}

		final intersectingObjects = [];
		for (i in 0...boundsInIntersectingNodes.length) {
			final boxIndex = boundsInIntersectingNodes[i];

			final hit = Intersect.aabb_aabb_floats(
				this._bboxArray[boxIndex+1], // min
				this._bboxArray[boxIndex+2],
				this._bboxArray[boxIndex+3],
				this._bboxArray[boxIndex+4], // max
				this._bboxArray[boxIndex+5],
				this._bboxArray[boxIndex+6],
				min.x, min.y, min.z,
				max.x, max.y, max.z
			);

			if (hit) {
				var dataIndex = Std.int(this._bboxArray[boxIndex]);
				intersectingObjects.push(this._dataArray[dataIndex]);
			}
		}
		return intersectingObjects;
	}

	static function calcBoundingBoxes(boundsArray: Array<Bounds>) {
		final bboxArray = [];
		for (i in 0...Std.int(boundsArray.length)) {
			final bounds = boundsArray[i];
			setBox(
				bboxArray, i, i,
				bounds.min.x, bounds.min.y, bounds.min.z,
				bounds.max.x, bounds.max.y, bounds.max.z
			);
		}
		return bboxArray;
	}

	function calcExtents(startIndex: Int, endIndex: Int, expandBy: Float = 0) {
		if (startIndex >= endIndex) {
			return [ new Vec3(0, 0, 0), new Vec3(0, 0, 0) ];
		}

		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var minZ = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		var maxZ = Math.NEGATIVE_INFINITY;

		for (i in startIndex...endIndex) {
			minX = Utils.min(this._bboxArray[i*7+1], minX);
			minY = Utils.min(this._bboxArray[i*7+2], minY);
			minZ = Utils.min(this._bboxArray[i*7+3], minZ);
			maxX = Utils.max(this._bboxArray[i*7+4], maxX);
			maxY = Utils.max(this._bboxArray[i*7+5], maxY);
			maxZ = Utils.max(this._bboxArray[i*7+6], maxZ);
		}

		return [
			new Vec3(minX - expandBy, minY - expandBy, minZ - expandBy),
			new Vec3(maxX + expandBy, maxY + expandBy, maxZ + expandBy)
		];
	}

	function splitNode(node: BvhNode) {
		final num_elements = node.count();
		if ((num_elements <= this._maxTrianglesPerNode) || (num_elements == 0)) {
			return { left: null, right: null };
		}

		final startIndex = node.startIndex;
		final endIndex   = node.endIndex;

		final leftNode  = [ [],[],[] ];
		final rightNode = [ [],[],[] ];
		final extentCenters = [ node.centerX(), node.centerY(), node.centerZ() ];

		final extentsLength = [
			node.extentsMax.x - node.extentsMin.x,
			node.extentsMax.y - node.extentsMin.y,
			node.extentsMax.z - node.extentsMin.z
		];

		final objectCenter = [];
		for (i in startIndex...endIndex) {
			//center = (min + max) / 2
			objectCenter[0] = 0.5 * (this._bboxArray[i*7+1] + this._bboxArray[i*7+4]);
			objectCenter[1] = 0.5 * (this._bboxArray[i*7+2] + this._bboxArray[i*7+5]);
			objectCenter[2] = 0.5 * (this._bboxArray[i*7+3] + this._bboxArray[i*7+6]);

			for (j in 0...2) {
				if (objectCenter[j] < extentCenters[j]) {
					leftNode[j].push(i);
				}
				else {
					rightNode[j].push(i);
				}
			}
		}

		//check if we couldn't split the node by any of the axes (x, y or z). halt
		//here, dont try to split any more (cause it will always fail, and we'll
		//enter an infinite loop
		final splitFailed = [
			leftNode[0].length == 0 || rightNode[0].length == 0,
			leftNode[1].length == 0 || rightNode[1].length == 0,
			leftNode[2].length == 0 || rightNode[2].length == 0
		];

		if (splitFailed[0] && splitFailed[1] && splitFailed[2]) {
			return { left: null, right: null };
		}

		//choose the longest split axis. if we can't split by it, choose next best one.
		final splitOrder = [ 0, 1, 2 ];
		splitOrder.sort(function(a, b) {
			return Std.int(extentsLength[b] - extentsLength[a]);
		});

		var leftElements = [];
		var rightElements = [];

		for (i in 0...2) {
			final candidateIndex = splitOrder[i];
			if (!splitFailed[candidateIndex]) {
				leftElements  = leftNode[candidateIndex];
				rightElements = rightNode[candidateIndex];
				break;
			}
		}

		final concatenatedElements = [];
		for (element in leftElements) {
			concatenatedElements.push(element);
		}

		for (element in rightElements) {
			concatenatedElements.push(element);
		}

		var helperPos = node.startIndex;
		for (i in 0...concatenatedElements.length) {
			final currElement = concatenatedElements[i];
			copyBox(this._bboxArray, currElement, this._bboxHelper, helperPos);
			helperPos = helperPos + 1;
		}

		// copy results back to main array
		for (i in node.startIndex*7...node.endIndex*7) {
			this._bboxArray[i] = this._bboxHelper[i];
		}

		// sort the elements in range (startIndex, endIndex) according to which node they should be at
		final node0Start = startIndex;
		final node0End   = node0Start + leftElements.length;
		final node1Start = node0End;
		final node1End   = endIndex;

		// create 2 new nodes for the node we just split, and add links to them from the parent node
		final node0Extents = this.calcExtents(node0Start, node0End, EPSILON);
		final node1Extents = this.calcExtents(node1Start, node1End, EPSILON);

		final node0 = new BvhNode(node0Extents[0], node0Extents[1], node0Start, node0End, node.level + 1);
		final node1 = new BvhNode(node1Extents[0], node1Extents[1], node1Start, node1End, node.level + 1);

		node.node0 = node0;
		node.node1 = node1;
		node.clearShapes();

		// add new nodes to the split queue
		return {
			left: node0,
			right: node1
		};
	}

	static function calcTValues(minVal: Float, maxVal: Float, rayOriginCoord: Float, invdir: Float) {
		final res = { min: 0.0, max: 0.0 };

		if (invdir >= 0.0) {
			res.min = (minVal - rayOriginCoord) * invdir;
			res.max = (maxVal - rayOriginCoord) * invdir;
		}
		else {
			res.min = (maxVal - rayOriginCoord) * invdir;
			res.max = (minVal - rayOriginCoord) * invdir;
		}

		return res;
	}

	function intersectNodeBox(rayOrigin: Vec3, invRayDirection: Vec3, node: BvhNode) {
		final t  = calcTValues(node.extentsMin.x, node.extentsMax.x, rayOrigin.x, invRayDirection.x);
		final ty = calcTValues(node.extentsMin.y, node.extentsMax.y, rayOrigin.y, invRayDirection.y);

		if (t.min > ty.max || ty.min > t.max) {
			return false;
		}

		//These lines also handle the case where tmin or tmax is NaN
		//(result of 0 * Infinity). x !== x returns true if x is NaN
		if (ty.min > t.min || t.min != t.min) {
			t.min = ty.min;
		}

		if (ty.max < t.max || t.max != t.max) {
			t.max = ty.max;
		}

		final tz = calcTValues(node.extentsMin.z, node.extentsMax.z, rayOrigin.z, invRayDirection.z);

		if (t.min > tz.max || tz.min > t.max) {
			return false;
		}

		if (tz.min > t.min || t.min != t.min) {
			t.min = tz.min;
		}

		if (tz.max < t.max || t.max != t.max) {
			t.max = tz.max;
		}

		// return point closest to the ray (positive side)
		if (t.max < 0) {
			return false;
		}

		return true;
	}

	static function setBox(bboxArray: Array<Float>, pos: Int, triangleId: Int, minX: Float, minY: Float, minZ: Float, maxX: Float, maxY: Float, maxZ: Float) {
		bboxArray[pos*7]   = triangleId;
		bboxArray[pos*7+1] = minX;
		bboxArray[pos*7+2] = minY;
		bboxArray[pos*7+3] = minZ;
		bboxArray[pos*7+4] = maxX;
		bboxArray[pos*7+5] = maxY;
		bboxArray[pos*7+6] = maxZ;
	}

	static function copyBox(sourceArray: Array<Float>, sourcePos: Int, destArray: Array<Float>, destPos: Int) {
		destArray[destPos*7]   = sourceArray[sourcePos*7];
		destArray[destPos*7+1] = sourceArray[sourcePos*7+1];
		destArray[destPos*7+2] = sourceArray[sourcePos*7+2];
		destArray[destPos*7+3] = sourceArray[sourcePos*7+3];
		destArray[destPos*7+4] = sourceArray[sourcePos*7+4];
		destArray[destPos*7+5] = sourceArray[sourcePos*7+5];
		destArray[destPos*7+6] = sourceArray[sourcePos*7+6];
	}
}
