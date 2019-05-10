package actor;

enum TweenType {
	Constant;
	Linear;

	InQuad;
	InCubic;

	// "flipped" curves
	OutQuad;
	OutCubic;

	// chained in+out curves
	SmoothQuad;
	SmoothCubic;
}
