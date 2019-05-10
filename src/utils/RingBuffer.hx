package utils;

// Basic ring buffer utility, to spare the hassle.
class RingBuffer<T> {
	public var items(default, null): Array<T>;
	public var current(default, null): Int;

	public function new(_items: Array<T>, _current: Int = 0) {
		this.items = _items != null ? _items : [];
		this.current = _current;
	}

	public inline function get_offset(offset: Int): T {
		if (offset == 0) {
			return this.items[this.current];
		}
		var idx = (this.current + offset) % this.items.length;
		while (idx < 0) {
			idx += this.items.length;
		}
		return this.items[idx % this.items.length];
	}

	public inline function get(): T {
		return this.items[this.current];
	}

	public function set(index: Int) {
		if (this.items.length == 0) {
			return;
		}
		this.current = index % this.items.length;
	}

	public function next(): T {
		this.current = (this.current + 1) % this.items.length;
		return this.get();
	}

	public function prev(): T {
		this.current = this.current - 1;
		if (this.current < 0) {
			this.current = this.items.length-1;
		}
		return this.get();
	}

	public inline function reset() {
		this.current = 0;
	}

	public inline function insert(item: T) {
		this.items.insert(this.current + 1, item);
	}

	public inline function push(item: T) {
		this.items.push(item);
	}

	public function remove(k: Int = 0): T {
		var pos: Int = (this.current + k) % this.items.length;
		while (pos < 1) {
			pos = pos + this.items.length;
		}

		var item = this.items.splice(pos, 1)[0];

		if (pos < this.current) {
			this.current = this.current - 1;
		}
		if (this.current >= this.items.length) {
			this.current = 1;
		}
		return item;
	}
}