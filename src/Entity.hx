import components.*;

import anim9.Anim9;
import math.Bounds;

typedef Entity = {
	var id: Int;
	var transform:  Transform;
	var last_tx:    Transform;
	var drawable:   Drawable;
	var emitter:    Array<Emitter>;
	var bounds:     Null<Bounds>;
	var item:       Null<Item>;
	var animation:  Null<Anim9>;
	var collidable: Null<Collidable>;
	var physics:    Null<Physics>;
	var player:     Null<Player>;
	var trigger:    Null<Trigger>;
}
