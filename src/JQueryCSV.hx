
extern class JQueryCSV implements jQuery.haxe.Plugin {
	static public var csv: {
		public function toArrays(csv:String, ?option:Dynamic, ?callback:String->Dynamic->Void):Array<Array<Dynamic>>;
		public function toObjects(csv:String, ?option:Dynamic, ?callback:String->Dynamic->Void):Array<Dynamic>;
	};
}