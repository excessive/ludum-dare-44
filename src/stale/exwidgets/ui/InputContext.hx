package exwidgets.ui;

private class System {
	public static function setClipboardText(str: String) {}
	public static function getClipboardText(): String { return ""; }
}

class InputContext {
	public var value: String;
	public var cursor: Int;

	var _updating: Bool = true;
	var selectionEnd: Int;

	var onUpdate: Void->Void;

	// Creates a new InputContext with the given text, which defaults to
	// an empty string.
	public function new(?value: String = "") {
		this.value = value;
		this.cursor = value.length;
		this.selectionEnd = this.cursor;
	}

	// Internal method to trigger the onUpdate event.
	function _triggerUpdate() {
		if (this._updating) {
			return;
		}

		this._updating = true;

		if (this.onUpdate != null) {
			this.onUpdate();
		}

		this._updating = false;
	}

	// Call this method when receiving text from the user.
	public inline function textinput(text: String) {
		this.insert(text);
	}

	// Call this method when the user presses a key.
	public function keypressed(key) {
		var selection = this.selectionEnd;
		switch (key) {
			case "return":
				Keyboard.focus = null;
			case "backspace":
				this.backspace();
			case "delete":
				this.forwardDelete();
			case "left":
				this.moveCursor(-1);
				if (Keyboard.isShiftDown()) {
					this.selectionEnd = selection;
				}
			case "right":
				this.moveCursor(1);
				if (Keyboard.isShiftDown()) {
					this.selectionEnd = selection;
				}
			case "home":
				this.moveCursorHome();
				if (Keyboard.isShiftDown()) {
					this.selectionEnd = selection;
				}
			case "end":
				this.moveCursorEnd();
				if (Keyboard.isShiftDown()) {
					this.selectionEnd = selection;
				}
			default: /* nothing */
		}

		if (Keyboard.isMetaDown()) {
			if (key == "a") {
				this.selectAll();
			}
			else if (key == "c") {
				System.setClipboardText(this.getSelectedText());
			}
			else if (key == "x") {
				System.setClipboardText(this.getSelectedText());
				this.backspace();
			}
			else if (key == "v") {
				this.insert(System.getClipboardText());
			}
		}
	}

	// Inserts the given text at the current cursor position.
	function insert(text: String) {
		var bounds = this.getSelectionBounds();

		var before = this.value.substr(0, bounds.min);
		var after = this.value.substr(bounds.max);

		this.value = before + text + after;
		this.setCursor(bounds.min + text.length);

		this._triggerUpdate();
	}

	// Returns the bounds of the selection
	public function getSelectionBounds() {
		var min = Math.min(this.cursor, this.selectionEnd);
		var max = Math.max(this.cursor, this.selectionEnd);

		return { min: Std.int(min), max: Std.int(max) };
	}

	// Returns the currently selected text
	public function getSelectedText() {
		var bounds = this.getSelectionBounds();

		return this.value.substr(bounds.min, bounds.max);
	}

	// Equivalent to pressing the 'backspace' key.
	public function backspace() {
		var bounds = this.getSelectionBounds();

		if (bounds.min == bounds.max) {
			bounds.min = Std.int(Math.max(0, bounds.min-1));
		}

		var before = this.value.substr(0, bounds.min);
		var after = this.value.substr(bounds.max);

		this.value = before + after;
		this.setCursor(bounds.min);

		this._triggerUpdate();
	}

	// Equivalent to pressing the 'delete' key.
	public function forwardDelete() {
		var bounds = this.getSelectionBounds();

		if (bounds.min == bounds.max) {
			bounds.max = bounds.max + 1;
		}

		var before = this.value.substr(0, bounds.min);
		var after = this.value.substr(bounds.max);

		this.value = before + after;
		this.setCursor(bounds.min);

		this._triggerUpdate();
	}

	// Moves the cursor to the beginning of the line.
	public function moveCursorHome() {
		this.setCursor(-this.value.length);
	}

	// Moves the cursor for the end of the line.
	public function moveCursorEnd() {
		this.setCursor(this.value.length);
	}

	// Moves the cursor by the specified amount.
	public function moveCursor(x: Int) {
		this.setCursor(this.cursor + x);
	}

	// Sets the cursor to the given position.
	public function setCursor(x) {
		this.cursor = Std.int(Math.max(0, Math.min(this.value.length, x)));
		this.selectionEnd = this.cursor;
	}

	// Selects all text in the text box.
	public function selectAll() {
		this.moveCursorEnd();
		this.selectionEnd = 0;
	}
}
