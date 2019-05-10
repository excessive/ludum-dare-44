package math;

class AABBUtils {
	public static inline function hit(
		x: Int, y: Int,
		min_x: Int, min_y: Int,
		max_x: Int, max_y: Int
	) {
		return x >= min_x && x <= max_x && y >= min_y && y <= max_y;
	}
}
