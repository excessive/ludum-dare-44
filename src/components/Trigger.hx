package components;

import math.Capsule;
import math.Intersect.CapsuleCapsuleResult;

enum TriggerState {
	Entered;
	Inside;
	Left;
}

enum TriggerType {
	Radius;
	Volume;
	RadiusInFront;
	Circle;
	Capsule;
}

typedef TriggerCb = (a:Entity, b:Entity, s:TriggerState, caps:{a: Capsule, b: Capsule, hit: CapsuleCapsuleResult})->Void;

class Trigger {
	public var cb: TriggerCb;
	public var type: TriggerType;
	public var range: Float;
	public var max_angle_height: Float;
	public var inside: Bool = false;
	public function new(_cb: TriggerCb, _type: TriggerType, _range: Float, _max_angle_or_height: Float = 0.5) {
		this.cb = _cb;
		this.type = _type;
		this.range = _range;
		this.max_angle_height = _max_angle_or_height;
	}
}
