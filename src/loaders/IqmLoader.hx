package loaders;

import lua.PairTools;
import render.MeshView;
import iqm.Iqm;
import iqm.IqmAnim;

class IqmLoader {
	public static function get_views(data: IqmFile, ?anim: IqmAnim): Array<MeshView> {
		var ret = [];
		PairTools.ipairsEach(data.meshes, function(i: Int, mesh: MeshData) {
			var mv = new MeshView(data.mesh, mesh.first, mesh.last, mesh.material);
			mv.iqm_anim = anim;
			ret.push(mv);
		});
		return ret;
	}

	public static function load_file(filename: String, save: Bool = false): Array<MeshView> {
		var iqm = Iqm.load(filename, save);
		if (iqm.has_anims) {
			var anim = Iqm.load_anims(filename);
			return get_views(iqm, anim);
		}
		return get_views(iqm);
	}
}
