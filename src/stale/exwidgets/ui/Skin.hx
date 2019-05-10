package exwidgets.ui;

// import graphics.Font;
// import graphics.Window;

@:publicFields
class Skin {
	// static var FONT: Font;
	static var FONT_SIZE: Int = 14;
	static var BACKGROUND_COLOR: Int = 0x333333ff;
	static var BACKGROUND_ACTIVE_COLOR: Int = 0x383838ff;

	static var ITEM_SPACING: Int = 1;
	static var ITEM_PADDING: Int = 5;

	static var REGION_PADDING: Int = 5;

	static var SELECTION_COLOR: Int = 0xff00ff7f;
	static var SELECTION_ROLLOVER: Int = 0x00ffff5f;

	static var CURSOR_COLOR: Int = 0xffffffff;
	static var HIGHLIGHT_COLOR: Int = 0xff55cc55;

	static var TEXTINPUT_BACKGROUND_COLOR: Int = 0x000000ff;
	static var TEXTINPUT_TEXT_COLOR: Int = 0xffffffff;
	static var TEXTINPUT_GRADIATE: Float = 0.1;

	static var BUTTON_BACKGROUND_COLOR: Int = 0x555555ff;
	static var BUTTON_TEXT_COLOR: Int = 0xffffffff;
	static var BUTTON_BIND_COLOR: Int = 0xaaaaaaff;
	static var BUTTON_ROLLOVER: Int = 0x00ffff2f;
	static var BUTTON_GRADIATE: Float = 0.025;
	static var BUTTON_BORDER_DEPTH: Int = 1;

	static var OUTLINE_COLOR_BRIGHT = [ 0.6, 0.6, 0.6, 1 ];
	static var OUTLINE_COLOR_DIM = [ 0.5, 0.5, 0.5, 1 ];


	static var HEADER_BACKGROUND_COLOR: Int = 0x222222ff;
	static var HEADER_TEXT_COLOR: Int = 0xe5e5e5ff;
	static var HEADER_GRADIATE: Float = 0.0;
	static var HEADER_SPACING: Float = 10;

	static function init() {
		// ITEM_SPACING *= Window.DPI;
		// ITEM_PADDING *= Window.DPI;
		reload();
	}

	static function reload() {
		// FONT = Font.load(FONT_SIZE);
	}
}
