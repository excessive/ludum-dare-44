package editor;

#if imgui

import imgui.ImGui as Ui;

enum WindowType {
	ProfilerWindow;
}

class MainMenu {
	static var visible_windows = [];

	public static function is_visible(window: WindowType) {
		return visible_windows.indexOf(window) >= 0;
	}

	public static function toggle_visible(window: WindowType) {
		if (visible_windows.indexOf(window) < 0) {
			visible_windows.push(window);
		}
		else {
			visible_windows.remove(window);
		}
	}

	public static function draw() {
		if (Ui.begin_main_menu_bar()) {
			if (Ui.begin_menu("View")) {
				if (Ui.menu_item("Profiler", null, is_visible(ProfilerWindow))) {
					toggle_visible(ProfilerWindow);
				}
				Ui.end_menu();
			}
			Ui.end_main_menu_bar();
		}
	}
}

#end
