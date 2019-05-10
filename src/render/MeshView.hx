package render;

import love.graphics.Mesh;
import iqm.IqmAnim;

class MeshView {
	var mesh: Mesh;
	var first: Int;
	var last: Int;

	public var iqm_anim: IqmAnim;
	public var material: String;

	public function new(mesh: Mesh, first: Int, last: Int, material: String) {
		this.mesh = mesh;
		this.first = first;
		this.last = last;
		this.material = material;
	}
	public function use() {
		// special case, reset
		if (this.last == this.first) {
			this.mesh.setDrawRange();
			return this.mesh;
		}
		this.mesh.setDrawRange(this.first, this.last - this.first);
		return this.mesh;
	}
}
