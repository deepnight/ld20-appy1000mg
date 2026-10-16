class IntRectangle {
	public var x		: Int;
	public var y		: Int;
	public var width	: Int;
	public var height	: Int;
	
	public function new(x,y,w,h) {
		this.x = x;
		this.y = y;
		width = w;
		height = h;
	}
	
	public inline function contains(x,y) {
		return x>=this.x && x<this.x+width && y>=this.y && y<this.y+height;
	}
	public inline function containsInclusive(x,y) {
		return x>=this.x && x<this.x+width+1 && y>=this.y && y<this.y+height+1;
	}
	
	public function toString() {
		return "IntRectangle : "+x+","+y+" "+width+","+height;
	}
	
	public inline function getRandomPoint(?rand:Int->Int) {
		if(rand==null)
			rand = Std.random;
		return {
			x	: x+rand(width),
			y	: y+rand(width),
		}
	}
}