package utils;

class RecycleIterator<T> {
	var items: Array<T>;
	var limit: Int;
	var i: Int;
	public inline function new(items: Array<T>, size: Int) {
		this.items = items;
		this.limit = size;
		this.i = 0;
	}
	public inline function hasNext() {
		return this.i < this.limit;
	}
	public inline function next() {
		return this.items[this.i++];
	}
}

abstract RecycleBuffer<T>({ count: Int, items: Array<T>}) {
	public inline function new() {
		#if debug
		console.Console.ds("creating new recyclebuffer");
		#end
		this = {
			count: 0,
			items: []
		}
	}

	/* clear & resize the backing array to zero */
	public inline function clear() {
		this.count = 0;
		this.items.resize(0);
	}

	/* clear & resize the backing array to the size used last frame */
	public inline function reset() {
		this.items.resize(this.count);
		this.count = 0;
	}

	public function indexOf(x: T, ?fromIndex: Int) {
		var idx = this.items.indexOf(x, fromIndex);
		if (idx > this.count) {
			return -1;
		}
		return idx;
	}

	// this could very well be an @:to, but taking things out of recycle
	// buffers implicitly is definitely a footgun
	public function copy_to_array() {
		var ret = [];
		for (v in 0...this.count) {
			ret.push(v);
		}
		return ret;
	}

	public function push(item: T) {
		if (this.items.length <= this.count) {
			this.items.push(item);
		}
		else {
			this.items[this.count] = item;
		}
		this.count++;
	}

	public var capacity(get, never): Int;
	inline function get_capacity(): Int {
		return this.items.length;
	}

	public var length(get, never): Int;
	inline function get_length(): Int {
		return this.count;
	}

	public function resize_and_sort(cb: T->T->Int) {
		this.items.resize(this.count);
		this.items.sort(cb);
	}

	public static function from_array<T>(arr: Array<T>): RecycleBuffer<T> {
		return cast {
			count: arr.length,
			items: arr
		}
	}

	@:arrayAccess
	public function get(k: Int): T {
		return this.items[k];
	}

	public function iterator() {
		return new RecycleIterator(this.items, this.count);
	}
}
