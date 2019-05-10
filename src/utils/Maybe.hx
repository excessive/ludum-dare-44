package utils;

abstract Maybe<T>(Null<T>) from Null<T> {
	public inline function exists(): Bool {
		return this != null;
	}

	@:nullSafety(Off)
	public inline function sure(?pos: haxe.PosInfos): T {
#if debug
		return if (exists()) this else throw '${pos.fileName}:${pos.lineNumber}: No value';
#else
		return if (exists()) this else throw "No value";
#end
	}

	@:nullSafety(Off)
	public inline function or(def: T): T {
		return if (exists()) this else def;
	}

	@:nullSafety(Off)
	public inline function may(fn: T->Void): Void {
		if (exists()) fn(this);
	}

	@:nullSafety(Off)
	public inline function map<S>(fn: T->S): Maybe<S> {
		return if (exists()) fn(this) else null;
	}

	@:nullSafety(Off)
	public inline function mapDefault<S>(fn: T->S, def: S): S {
		return if (exists()) fn(this) else def;
	}
}
