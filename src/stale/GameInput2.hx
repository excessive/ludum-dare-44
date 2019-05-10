import haxe.ds.Map;
// import love.mouse.MouseModule;
// import love.joystick.GamepadButton;
// import love.joystick.GamepadAxis;
import love.joystick.JoystickModule;
import love.joystick.Joystick;
// import love.keyboard.KeyConstant;
// import love.keyboard.KeyboardModule;
import math.Utils;
// import math.Vec2;


// import ini.IniFile;
// import backend.Fs;

import haxe.ds.Option;
using utils.OptionHelper;

@:publicFields
class InputState2 {
	var pressed:      Float = -1;
	var value:        Float = 0;
	var deadzone:     Float = 0.35;
	var curve:        Float = 1.0;
	var offset:       Float = 0.0;
	var first_update: Bool  = true;
	var updated:      Bool  = false;

	inline function new() {}

	inline function is_down() {
		return Utils.threshold(value, deadzone) && pressed >= 0;
	}

	inline function value_full() {
		// x = in > deadzone ? pow((in - offset) / (1.0 - offset)), curve) : 0
	}

	inline function value_deadzone() {
		return Utils.deadzone(value, deadzone);
	}

	inline function first_press() {
		return is_down() && first_update;
	}

	function press(v: Float = 1) {
		if (pressed < 0) {
			first_update = true;
			pressed      = 0;
		}

		updated = true;
		value   = v;
	}

	function update(dt: Float) {
		if (!updated) {
			first_update = true;
			pressed      = -1;
			value        = 0;
		}

		if (pressed > 0) {
			first_update = false;
			updated      = false;
		}

		if (is_down()) {
			pressed += dt;
		}
	}
}

enum DeviceType {
	KeyboardMouse;
	// mappings use -1
	Gamepad(index: Int);
	Invalid;
}

private typedef InputMapping = {
	action: Option<String>,
	code: Option<String>, // devicetype:identifier
	device_type: DeviceType,
	// x = in > deadzone ? pow((in - offset) / (1.0 - offset)), curve) : 0
	curve: Float,
	deadzone: Float,
	offset: Float
}

private typedef InputConfig = {
	// comma separated game action names
	actions: String, // MenuConfirm, MenuCancel, ...
	mappings: Array<String> // input mapping strings
}


class GameInput2 {
	static var device_mappings: Map<String, Array<InputMapping>>;
	static var players: Array<DeviceType>;
	static var devices: Array<DeviceType>;
	static var gamepads: Map<Int, Joystick>;

	// todo: curve, deadzone, etc...
	static function parse_mapping_string(str: String): InputMapping {
		// "MenuToggle,kb:escape" ->
		// action: MenuToggle, code: escape, type: keyboard
		var segments = str.split(",");
		var map: InputMapping = {
			action: None,
			code: None,
			device_type: Invalid,
			curve: 1.0,
			deadzone: 0.5,
			offset: 0.0
		}
		if (segments.length >= 1) {
			map.action = Some(segments[0]);
		}
		if (segments.length >= 2) {
			var raw = segments[1];
			var parts = raw.split(":");
			map.device_type = switch (parts[0]) {
				case "kb": KeyboardMouse;
				case "gp": Gamepad(-1);
				default: Invalid;
			}
			map.code = Some(parts[1]); // todo: validate
		}
		return map;
	}

	public static function init() {
		device_mappings = new Map();
		var input_base: InputConfig = {
			actions: "MenuToggle,MenuConfirm,MenuCancel,MenuNext,MenuPrev,MenuUp,MenuDown,MenuLeft,MenuRight",
			mappings: [
				"MenuToggle,kb:escape",
				"MenuToggle,gp:y"
			]
		};
		var actions_split = input_base.actions.split(",");
		for (map_str in input_base.mappings) {
			var map = parse_mapping_string(map_str);
			if (map.code == None || map.action == None) {
				trace('bad keymap $map_str: skipping');
				continue;
			}
			var key = OptionHelper.unwrap_fail(map.action);
			if (actions_split.indexOf(key) < 0) {
				continue;
			}
			if (!device_mappings.exists(key)) {
				device_mappings[key] = [];
			}
			device_mappings[key].push(map);
		}
		trace(device_mappings);
		devices = [ KeyboardMouse ];
		players = [];
		detect_gamepads();
	}

	static function detect_gamepads() {
		gamepads = new Map();
		devices = [ devices[0] ];
		var joysticks = JoystickModule.getJoysticks();
		lua.PairTools.ipairsEach(joysticks, function(i: Int, js: Joystick) {
			if (!js.isGamepad()) {
				return;
			}
			var id = Std.int(js.getID().id);
			devices.push(Gamepad(id));
			gamepads[id] = js;
		});
		for (i in 0...players.length) {
			if (devices.indexOf(players[i]) < 0) {
				trace('player $i missing, replacing ${players[i]} with Invalid');
				players[i] = Invalid;
			}
		}
	}

	public inline function update(dt: Float) {
		detect_gamepads();
	}
}
