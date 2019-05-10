package actor;

import math.Vec3;

@:publicFields
class TweenState {
	var tween_type: TweenType;
	var tween_duration: Float;

	var tween_time: Float = 0;
	var cmd_queue: Array<String> = [];

	var position: Vec3;
	var scale: Vec3;
	var visible: Bool;

	var opacity: Float;

	// TODO: handle mismatches when aux between A and B don't match
	// in channel count
	var aux: Array<Float>;

	function set_from(base: TweenState) {
		position = base.position.copy();
		scale = base.scale.copy();
		visible = base.visible;
		opacity = base.opacity;
		aux = base.aux.copy();
	}

	function new(type: TweenType, duration: Float) {
		tween_type = type;
		tween_duration = duration;
		position = new Vec3(0, 0, 0);
		scale = new Vec3(1, 1, 1);
		visible = true;
		opacity = 1.0;
		aux = [ for (i in 0...8) 0.0 ];
	}
}
