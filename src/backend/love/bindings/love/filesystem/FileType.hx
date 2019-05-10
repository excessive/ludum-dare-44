package love.filesystem;

enum abstract FileType(String) {
	public static inline var File = "file";
	public static inline var Directory = "directory";
	public static inline var Symlink = "symlink";
	public static inline var Other = "other";

	@:to
	public inline function toString(): String {
		return this;
	}
}
