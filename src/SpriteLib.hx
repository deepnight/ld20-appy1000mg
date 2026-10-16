import flash.display.BitmapData;

class DSprite extends flash.display.Sprite {
	public static var ALL	= new List();
	
	public var lib		: SpriteLib;
	public var libGroup	: String;
	public var frame	: Int;
	var pt0				: flash.geom.Point;
	public var centerX	: Float;
	public var centerY	: Float;
	
	var animStep		: Int;
	var animCpt			: Int;
	var animId			: Null<String>;
	var anim			: Null<SpriteAnimation>;
	var animPlays		: Int;
	public var fl_killOnEndPlay	: Bool;
	
	public function new(l:SpriteLib, g:String, frame:Int) {
		super();
		lib = l;
		libGroup = g;
		centerX = 0.5;
		centerY = 1;
		animCpt = 0;
		fl_killOnEndPlay = false;
		pt0 = new flash.geom.Point(0, 0);
		setFrame(frame);
		ALL.add(this);
	}
	
	public override function toString() {
		return "DSprite "+libGroup+"["+frame+"]";
	}
	
	public inline function setFrame(f) {
		frame = f;
		redraw();
	}
	public function redraw() {
		var m = new flash.geom.Matrix();
		var rect = lib.getRectangle(libGroup, frame);
		m.translate(Std.int(-rect.x - centerX*rect.width), Std.int(-rect.y - centerY*rect.height));
		graphics.clear();
		graphics.beginBitmapFill(lib.bmp, m, false, false);
		graphics.drawRect(Std.int(-centerX*rect.width), Std.int(-centerY*rect.height), rect.width, rect.height);
		graphics.endFill();
	}
	
	public function stopAnim(frame:Int) {
		anim = null;
		animId = null;
		setFrame(frame);
	}
	
	public function playAnim(id:String, ?plays=999999) {
		if(id==animId)
			return;
		animId = id;
		animCpt = 0;
		animStep = 0;
		animPlays = plays;
		anim = lib.getAnim(id);
		setFrame(anim.frames[0]);
	}
	
	public function update() { // requis seulement en cas d'anim
		if(parent==null)
			ALL.remove(this);
		if(anim==null)
			return;
		animCpt++;
		var duration = animStep<anim.durations.length ? anim.durations[animStep] : anim.durations[anim.durations.length-1];
		if(animCpt>duration) {
			animCpt=0;
			if(animStep+1>=anim.frames.length) {
				animStep = 0;
				animPlays--;
				if(animPlays<=0)
					if(fl_killOnEndPlay) {
						parent.removeChild(this);
						ALL.remove(this);
						return;
					}
					else
						stopAnim(0);
				else
					setFrame(anim.frames[0]);
			}
			else {
				animStep++;
				setFrame(anim.frames[animStep]);
			}
		}
	}
	
	
	public static function updateAll() {
		var all = ALL;
		for(s in all)
			s.update();
	}
	
	//public function fastDraw(bd:BitmapData, x:Int, y:Int) {
		//bd.copyPixels(lib.bmp, libRect, new flash.geom.Point(x,y), true);
	//}
}

typedef SpriteAnimation = {frames:Array<Int>, durations:Array<Int>};

class SpriteLib {
	public var bmp	: BitmapData;
	var groups		: Hash<Array<flash.geom.Rectangle>>;
	var anims		: Hash<SpriteAnimation>;
	var lastGroup	: Null<String>;
	
	public function new(bd:BitmapData) {
		bmp = bd;
		groups = new Hash();
		anims = new Hash();
		lastGroup = null;
	}
	
	public inline function getGroup(?k:String) {
		if(k==null) {
			k = lastGroup;
			if(lastGroup==null)
				throw "no group selected previously";
		}
		return
			if(groups.exists(k))
				groups.get(k);
			else {
				var l = new Array();
				groups.set(k, l);
				l;
			}
	}
	
	public inline function getAnim(id) {
		return anims.get(id);
	}
	
	public function setGroup(k:String) {
		lastGroup = k;
	}
	
	public function setAnim(animId:String, ?k:String, frames:Array<Int>, durations:Array<Int>) {
		if(k==null)
			k = lastGroup;
		anims.set(animId, {
			frames		: frames.copy(),
			durations	: durations.copy(),
		});
		
	}
	
	public inline function getRectangle(k:String, idx:Int) {
		return getGroup(k)[idx];
	}
	
	public function getSprite(k:String, ?idx=0) {
		return new DSprite(this, k, idx);
	}
	
	public function paintIntoBitmap(k:String, ?idx:Null<Int>=0, bd:BitmapData, pt:flash.geom.Point) {
		bd.copyPixels( bmp, getGroup(k)[idx], pt, true );
	}
	
	public function slice(x, y, w, h, ?repeatX=1, ?repeatY=1) {
		var g = getGroup();
		for(iy in 0...repeatY)
			for(ix in 0...repeatX) {
				g.push( new flash.geom.Rectangle(x+ix*w, y+iy*h, w, h) );
				//var s = new DSprite();
				//s.libRect = new flash.geom.Rectangle(x+ix*w, y+iy*h, w, h);
				//s.lib = this;
				//g.push(s);
			}
	}
}

