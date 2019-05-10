package systems;

// import math.Vec3;
// import math.Quat;
import systems.System;

class ItemEffect extends System {
	override function filter(e: Entity) {
		return e.item != null;
	}

	override function process(e: Entity, dt: Float) {
		if (GameInput.locked) {
			return;
		}

		switch (e.item) {
			default:
			// case Theme: {
			// 	e.transform.orientation *= Quat.from_angle_axis(-4 * dt, Vec3.up());
			// }
			// default: e.status.message = null;
		}
	}
}
