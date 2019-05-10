package math;

import math.Mat4;

#if cpp
typedef F32 = cpp.Float32;
#elif hl
typedef F32 = hl.F32;
#else
typedef F32 = Float;
#end

@:publicFields
class MatrixUtils {
	static function toFloat32(matrix: Mat4) {
		var out: Array<F32> = [
			for (i in 0...16) matrix[i]
		];
		return out;
	}
}
