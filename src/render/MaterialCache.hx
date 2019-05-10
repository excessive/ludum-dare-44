package render;

import console.Console;
import math.Vec3;
import backend.Fs;
import ini.IniFile;

typedef MaterialInfo = {
	material: {
		triplanar: Bool,
		albedo: String,
		roughness: Float,
		metalness: Float,
		opacity: Float,
		alpha_multiply: Float,
		double_sided: Bool,
		roughness_map: String,
		metalness_map: String,
		shadow: Bool,
		keep_hot: Bool,
		occlusion_mask: Bool
	}
};

class MaterialCache {
	static var cache = new Map<String, Material>();

	public static function flush() {
		cache = new Map<String, Material>();
	}

	public static function get(material: String): Material {
		material = material.toLowerCase();

		if (cache.exists(material)) {
			return cache.get(material);
		}

		var mat: Material = {
			color: new Vec3(1, 1, 1),
			alpha_multiply: 1.0,
			emission: 0.0,
			metalness: 0.0,
			roughness: 0.5,
			vampire: true,
			triplanar: false,
			shadow: false,
			double_sided: false,
			occlusion_mask: false,
			opacity: 1.0,
			textures: {
				albedo: null,
				roughness: null,
				metalness: null,
				scale: 1.0
			}
		}

		if (material == null || material == "") {
			return mat;
		}

		var filename = 'assets/materials/$material.ini';
		if (Fs.is_file(filename)) {
			var mat_base: MaterialInfo = {
				material: {
					triplanar: mat.triplanar,
					albedo: null,
					alpha_multiply: 1.0,
					roughness: mat.roughness,
					metalness: mat.metalness,
					opacity: mat.opacity,
					double_sided: mat.double_sided,
					roughness_map: null,
					metalness_map: null,
					shadow: false,
					keep_hot: false,
					occlusion_mask: false
				}
			};
			var material = IniFile.parse_typed(mat_base, filename).material;
			if (material.albedo != "" && material.albedo != null) {
				mat.textures.albedo = 'assets/${StringTools.trim(material.albedo)}';
				if (material.keep_hot) {
					TextureCache.pin(mat.textures.albedo, true);
				}
			}
			if (material.roughness_map != "" && material.roughness_map != null) {
				mat.textures.roughness = 'assets/${StringTools.trim(material.roughness_map)}';
				if (material.keep_hot) {
					TextureCache.pin(mat.textures.roughness, true);
				}
			}
			if (material.metalness_map != "" && material.metalness_map != null) {
				mat.textures.metalness = 'assets/${StringTools.trim(material.metalness_map)}';
				if (material.keep_hot) {
					TextureCache.pin(mat.textures.metalness, true);
				}
			}
			mat.alpha_multiply = material.alpha_multiply;
			mat.triplanar = material.triplanar;
			mat.roughness = material.roughness;
			mat.metalness = material.metalness;
			mat.opacity = material.opacity;
			mat.double_sided = material.double_sided;
			mat.shadow = material.shadow;
			mat.occlusion_mask = material.occlusion_mask;
			Console.ds('cached material $filename');
		}
		else {
			Console.ds('using fallback material for $material');
		}

		cache[material] = mat;

		return mat;
	}
}
