package math;

private typedef FrustumData = {
	final left: Vec4;
	final right: Vec4;
	final bottom: Vec4;
	final top: Vec4;
	final near: Vec4;
	final far: Null<Vec4>;
}

@:forward
abstract Frustum(FrustumData) {
	public inline function new(data: FrustumData) {
		this = data;
	}
#if lua
	public inline function to_cpml() {
		if (this.far != null) {
			return {
				left:   { a: this.left[0], b: this.left[1], c: this.left[2], d: this.left[3] },
				right:  { a: this.right[0], b: this.right[1], c: this.right[2], d: this.right[3] },
				bottom: { a: this.bottom[0], b: this.bottom[1], c: this.bottom[2], d: this.bottom[3] },
				top:    { a: this.top[0], b: this.top[1], c: this.top[2], d: this.top[3] },
				near:   { a: this.near[0], b: this.near[1], c: this.near[2], d: this.near[3] },
				far:    { a: this.far[0], b: this.far[1], c: this.far[2], d: this.far[3] }
			};
		}
		return {
			left:   { a: this.left[0], b: this.left[1], c: this.left[2], d: this.left[3] },
			right:  { a: this.right[0], b: this.right[1], c: this.right[2], d: this.right[3] },
			bottom: { a: this.bottom[0], b: this.bottom[1], c: this.bottom[2], d: this.bottom[3] },
			top:    { a: this.top[0], b: this.top[1], c: this.top[2], d: this.top[3] },
			near:   { a: this.near[0], b: this.near[1], c: this.near[2], d: this.near[3] },
			far:    null
		};
	}
#end
}
