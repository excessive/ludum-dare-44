package systems;

import systems.System;

class Animation extends System {
	override function filter(e: Entity): Bool {
		return e.animation != null;
	}
	override function process(e: Entity, dt: Float) {
		if (GameInput.locked) {
			dt = 0;
		}
		e.animation.update(dt);
	}
}
