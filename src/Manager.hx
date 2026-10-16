import mt.deepnight.Types;
import mt.deepnight.Types;
import mt.deepnight.Color;
import mt.deepnight.Tweenie;
import SpriteLib;
import flash.ui.Keyboard;
import Entity;

using mt.deepnight.SuperMovie;
class GfxTiles extends flash.display.BitmapData {}

typedef TMap = Array<Array<UInt>>;

enum FxType {
	FX_DustWind;
	FX_SunLight;
	FX_Debris;
}

class Fx implements haxe.Public {
	var type	: FxType;
	var spr		: SPR;
	var x		: Float;
	var y		: Float;
	var dx		: Float;
	var dy		: Float;
	var fx		: Float;
	var fy		: Float;
	var gx		: Float;
	var gy		: Float;
	var r		: Int;
	var life	: Null<Int>;

	public function new(t,spr:SPR,px,py) {
		type = t;
		this.spr = spr;
		moveTo(px,py);
		dx = 0;
		dy = 0;
		gx = 0;
		gy = 0;
		r = 0;
		fx = 1;
		fy = 1;
		life = null;
	}
	
	public inline function moveTo(x,y) {
		this.x = spr.x = x;
		this.y = spr.y = y;
	}
}

typedef TProp = {drug:Null<Bool>, spr:DSprite};

class Manager {//}
	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	public static var ME : Manager;
	public static var TW : Tweenie;
	
	public static var SFX_LIB = new Hash();
	public static var MAIN_VOLUME = 0.3;
	static var BELOVED = "Pixelle";
	
	public static var UPSCALE = 5;
	public static var VIEW_WID = 25;
	public static var VIEW_HEI = 18;
	public static var MAX_JETPACK = 32;
	public static var MAX_LIFE = 1;
	
	public static var SCALE_2X_ALGORITHM = true;

	public static var C_GROUND	= Color.addAlphaChannel(0xa2471c);
	public static var C_GRASS	= Color.addAlphaChannel(0x8D911A);
	public static var C_STONE	= Color.addAlphaChannel(0x4A2020);
	public static var C_WATER	= Color.addAlphaChannel(0x277276);
	
	public static var TXT_ZOMBIES = [
		"we can be friends...",
		"I won't hurt you",
		"have any Appy ?",
		"we can be Appy",
		"give me... MORE.",
		"come to me",
		"you are not Alone",
	];
	public static var TXT_DRUG_OFF = [
		"OMG...",
		"What the...",
		"Not again...",
		"Me... Lost?",
		"Please.. no...",
	];
	public static var TXT_DRUG_ON = [
		"Me better...",
		"Me must.. not.. wake up.. again..",
		"Me... Appy..... AGAIN..",
		"Appy good for me",
		"Me feel... better...",
		"Me... feel safe again.",
	];
	
	var rseed			: mt.Rand;
	public var root		: MC;
	//var sbuffer		: BD;
	public var buffer	: mt.deepnight.Buffer;
	public var gworld	: BD;
	var pt0				: flash.geom.Point;
	public var tiles	: SpriteLib;
	var props			: List<TProp>;
	var propsWind		: List<TProp>;
	var propCont		: SPR;
	
	public var sworld	: BD;
	public var sworldBmp: BMP;
	public var farscape	: BMP;
	var darkSky			: SPR;
	var niceSky			: SPR;
	var dustCont		: SPR;
	var fxCont			: SPR;
	var darkness		: SPR;
	public var map		: TMap;
	public var randMap	: Array<Array<Int>>;
	public var viewPort	: IntRectangle;
	
	public var entities	: List<Entity>;
	public var player	: Entity;
	public var plight	: SPR;
	
	var fallDuration	: Int;
	var lockedKeys		: IntHash<Bool>;
	var jetpack			: Int;
	var fl_jetpack		: Bool;
	var fl_digger		: Bool;
	
	var fxList			: List<Fx>;
	var fxSprites		: List<DSprite>;
	
	public var drug		: Float;
	public var life		: Int;
	public var shield	: Int;
	var spawnCD			: Int;
	
	var doOnce			: Hash<Bool>;
	
	var fl_started		: Bool;
	var fl_pause		: Bool;
	var fl_desinteg		: Bool;
	var pop				: SPR;
	var notipool		: List<String>;
	var checkpoints		: List<{x:Int, y:Int}>;
	var lastCheck		: {x:Int, y:Int};
	var intro			: SPR;
	var logo			: interf.Logo;
	#if debug
	public var debugField	: TF;
	#end
		
	
	
	public function new(r) {
		ME = this;
		root = r;
		TW = new Tweenie();
		root.stage.quality = flash.display.StageQuality.LOW;
		haxe.Log.setColor(0xffffff);
		#if debug
		haxe.Firebug.redirectTraces();
		#end
		root.addEventListener( flash.events.Event.ENTER_FRAME, main );
		pt0 = new flash.geom.Point(0, 0);
		entities = new List();
		jetpack = MAX_JETPACK;
		lockedKeys = new IntHash();
		props = new List();
		propsWind = new List();
		fxList = new List();
		fxSprites = new List();
		fallDuration = 0;
		viewPort = new IntRectangle(0,0,1,1);
		drug = 1;
		life = MAX_LIFE;
		shield = 0;
		spawnCD = 0;
		doOnce = new Hash();
		fl_pause = false;
		fl_jetpack = false;
		notipool = new List();
		checkpoints = new List();
		fl_started = false;
		fl_desinteg = false;
		Key.init();
		
		#if debug
		fl_jetpack = true;
		#end
		
		
		buffer = new mt.deepnight.Buffer(VIEW_WID*8, VIEW_HEI*8, UPSCALE, false);
		var t = new BD(UPSCALE, UPSCALE, false, 0x808080);
		t.setPixel(0, 0, 0xffffff);
		t.setPixel(UPSCALE-1, UPSCALE-1, 0x0);
		for(x in 1...UPSCALE-1) {
			t.setPixel(x, 0, 0xE0E0E0);
			t.setPixel(x, 1, 0xffffff);
			t.setPixel(x, UPSCALE-1, 0x0);
		}
		for(y in 1...UPSCALE-1) {
			t.setPixel(0, y, 0xffffff);
			t.setPixel(UPSCALE-1, y, 0x0);
		}
		buffer.setTexture(t, 0.3, true);
		root.addChild(buffer.render);

		tiles = new SpriteLib( new GfxTiles(0,0) );
		tiles.setGroup("player");
		tiles.slice(0,0, 7,13, 11);
		tiles.setAnim("playerWalk", [1,7,9,0], [2,2,2,2]);
		tiles.setAnim("playerStand", [0,3,0,4], [40,32,32,32]);
		tiles.setAnim("playerFly", [5,6], [2,2]);
		
		tiles.setGroup("specialPlayer");
		tiles.slice(63,17, 8,11, 3);
		tiles.setAnim("specialDie", [0,1,2], [64,40,999999]);
		
		tiles.setGroup("darkGrass");
		tiles.slice(0,26, 12,10, 3);
		tiles.setGroup("niceGrass");
		tiles.slice(0,37, 12,10, 6);
		tiles.setGroup("bones");
		tiles.slice(0,47, 12,10, 4);
		tiles.setGroup("darkRoot");
		tiles.slice(0,57, 12,10, 4);
		tiles.setGroup("niceRoot");
		tiles.slice(48,57, 12,10, 4);
		tiles.setGroup("niceTree");
		tiles.slice(0,73, 60,61, 4);
		tiles.setGroup("darkTree");
		tiles.slice(0,134, 60,61, 4);
		tiles.setGroup("blob");
		tiles.slice(0,17, 9,6, 2);
		tiles.setGroup("explosion");
		tiles.slice(0,223, 23,23, 4);
		tiles.setAnim("explosion", [0,1,2,3], [2]);
		
		tiles.setGroup("items");
		tiles.slice(18,13, 9,10, 4);
		
		tiles.setGroup("arrow");
		tiles.slice(0,251, 7,9, 3);
		tiles.setAnim("arrow", [0,1,2,1,0], [1,1,1,1,4]);
		
		tiles.setGroup("waterTop");
		tiles.slice(0,265, 8,8, 8);
		tiles.setAnim("waterTopNice", [0,1,2,3,2,1],[5,3,3,5,3,3]);
		tiles.setAnim("waterTopDark", [4,5,6,7],[3,2,2,2]);
		tiles.setGroup("water");
		tiles.slice(0,197, 13,18, 10);
		tiles.setAnim("water", [0,1,2,3,4,5,6,7,8,9], [1]);
		
		tiles.setGroup("map");
		tiles.slice(0,300, 400,100);
		
		tiles.setGroup("elder");
		tiles.slice(112,0, 9,16);
		
		tiles.setGroup("tombs");
		tiles.slice(0,273, 36,14);
		
		#if !debug
		intro = new SPR();
		root.addChild(intro);
		intro.graphics.beginFill(0x0);
		intro.graphics.drawRect(0,0,WID,HEI);
		logo = new interf.Logo();
		intro.addChild(logo);
		logo.x = Std.int(WID*0.5-logo.width*0.5);
		logo.y = Std.int(HEI*0.5-logo.height*0.5);
		logo.hero.alpha = 0;
		logo.alpha = 0;
		logo.logo.alpha = 0;
		logo.white.filters = [new flash.filters.GlowFilter(0xffffff,0.75, 16,16, 1)];
		var a = TW.create(logo, "alpha", 1, TEaseIn, 400);
		a.onEnd = function() {
			TW.create(ME.logo.white, "alpha", 0, TEaseOut, 1000);
			TW.create(ME.logo.logo, "alpha", 1, TEaseOut, 700).onUpdateT = function(t) {
				ME.logo.logo.filters = [ new flash.filters.GlowFilter(0x946841, t*0.3, 32,32, 1, 2) ];
			}
		}
		var author = new interf.Talk();
		intro.addChild(author);
		author.field.width = 600;
		author.field.textColor = 0x544434;
		//author.alpha = 0.2;
		author.x = Std.int( WID*0.5-author.width*0.5 );
		author.y = HEI-35;
		author.field.text = "Created by Sebastien Benard in 48h for Ludum Dare 20\nwww.motion-twin.com";
		#else
		start();
		#end
	}
		
	
	
	function start() {
		if(fl_started)
			return;
		fl_started = true;
		darkSky = new SPR();
		buffer.addChild(darkSky);
		var g = darkSky.graphics;
		var m = new flash.geom.Matrix();
		m.rotate(-3.14/2);
		g.beginGradientFill(flash.display.GradientType.LINEAR, [0x2C0A0A, 0x474459], [1, 1], [90, 130], m);
		g.drawRect(0, 0, buffer.width, buffer.height);
		g.endFill();
		
		niceSky = new SPR();
		buffer.addChild(niceSky);
		var g = niceSky.graphics;
		var m = new flash.geom.Matrix();
		m.rotate(-3.14*0.5);
		g.beginGradientFill(flash.display.GradientType.LINEAR, [0x114266, 0xC96A01, 0xFDE86F], [1, 1, 1], [110, 120, 128], m);
		g.drawRect(0, 0, buffer.width, buffer.height);
		g.endFill();
		
		rseed = new mt.Rand(0);
		gworld = new BD(400, 100, true, 0x0);
		#if debug
		var wbmp = new BMP(gworld);
		wbmp.y = buffer.height*buffer.upscale;
		wbmp.filters = [ new flash.filters.GlowFilter(0x0, 1, 2, 2, 10) ];
		wbmp.scaleX = 1;
		wbmp.scaleY = wbmp.scaleX;
		root.addChild(wbmp);
		#end
		
		
		sworld = new BD(8*(VIEW_WID+2), 8*(VIEW_HEI+2), true, 0x0);
		farscape = new BMP( new BD(VIEW_WID, VIEW_HEI, true, 0x0) );
		farscape.scaleX = 8;
		farscape.scaleY = 8;
		var ct = new flash.geom.ColorTransform();
		ct.color = 0x260F0F;
		farscape.transform.colorTransform = ct;
		farscape.filters = [ new flash.filters.BlurFilter(4,4,2) ];
		buffer.addChild(farscape);
		
		dustCont = new SPR();
		buffer.addChild(dustCont);

	
		player = new Entity(this, ET_Player);
		
		var seed = Std.random(999999);
		var seed = 843944;
		generateWorld(seed);
		
		
		player.spr = tiles.getSprite("player", 0);
		plight = new SPR();
		plight.graphics.beginFill(0xffffff);
		plight.graphics.drawRect(0, 0, 1, 1);
		plight.x = -1;
		plight.y = -12;
		player.spr.addChild(plight);
		buffer.addChild(player.spr);
		entities.add(player);
		updatePlayerLight();
		
		propCont = new SPR();
		buffer.addChild(propCont);

		sworldBmp = new BMP(sworld);
		buffer.addChild(sworldBmp);
		
		fxCont = new SPR();
		buffer.addChild(fxCont);
		
		darkness = new SPR();
		var b = 64;
		darkness.x = -b;
		darkness.y = -b;
		darkness.filters = [ new flash.filters.BlurFilter(b, b) ];
		darkness.alpha = 0.8*(1-drug);
		var g = darkness.graphics;
		g.beginFill(0x0, 1);
		g.drawRect(0, 0, buffer.width+b*2, buffer.height+b*2);
		g.drawEllipse(b, b, buffer.width, buffer.height);
		g.endFill();
		buffer.addChild(darkness);

		refocus(0, 0);
		#if debug
		var stats = new mt.kiroukou.debug.Stats(WID-60);
		root.addChild(stats);
		spawnEntity(ET_Item("test"), player.mx+6, player.my-2);
		#end
		
		
		for(i in 0...200)
			fxUpdate();

		spawnEntity(ET_Item("jetpack"), 33,81);
		spawnEntity(ET_Elder, 98,62).id = "elder";
		spawnEntity(ET_Item("drug"), 128,42);
		spawnEntity(ET_Item("drug"), 173,90);
		spawnEntity(ET_Item("canon"), 162,52);
		spawnEntity(ET_Elder, 316,83).id = "aquaelder";
		
		
		spawnBeloved(58,46, "beloved1");
		spawnBeloved(351,18, "beloved2");

		#if debug
		player.moveTo(340,15);
		doOnce.set("drugOff",true);
		doOnce.set("drugOn",true);
		//doOnce.set("beloved",true);
		//doOnce.set("tombsReveal",true);
		//doOnce.set("repeatName",true);
		//doOnce.set("tombs",true);
		debugField = new TF();
		debugField.filters = [new flash.filters.GlowFilter(0x0,1,2,2,5)];
		debugField.text = "debug";
		debugField.textColor = 0xffffff;
		debugField.width = 100;
		debugField.x = WID-60-debugField.width;
		root.addChild(debugField);
		#end
		
		main(null);
		
		#if !debug
		haxe.Timer.delay( function() {
			ME.chainNotifies([
				"0x2092EE|Use LEFT/RIGHT arrows to move around, UP to jump and SPACE to skip messages.",
				"You look around you, but you can't remember how you came to this place...",
				"You feel like you just woke up from an incredibly long night.",
				"[player]Me feel ... Appy.",
			]);
		}, 2000);
		#end
	}
	
	function updatePlayerLight() {
		var col = switch(life) {
			case 0	: 0xFF2000;
			//case 1	: 0xFF8000;
			//case 2	: 0xFFF142;
			default	: 0x97F4FF;
		}
		plight.filters = [
			new flash.filters.GlowFilter(col, 1, 2,2, 4),
			new flash.filters.GlowFilter(col, 1, 8,8, 3, 2),
			new flash.filters.GlowFilter(col, 1, 32,32, 2),
			new flash.filters.GlowFilter(col, 1, 16,16, 1),
		];
	}
	
	public function createFx(t:FxType, x:Float,y:Float, col:Int, size:Int) {
		var spr = new SPR();
		fxCont.addChild(spr);
		var g = spr.graphics;
		g.beginFill(col, 0.5+Std.random(50)/100);
		g.drawRect(0,0,size,size);
		var fx = new Fx(t, spr, x+(Std.random(2)*2-1)*Std.random(8), y+(Std.random(2)*2-1)*Std.random(8));
		fx.dx = 1 + Std.random(200)/100 * (Std.random(2)*2-1);
		fx.dy = -Std.random(500)/100;
		fx.gy = 0.4;
		fx.fx = 0.96;
		fx.fy = 0.97;
		fx.life = 5+Std.random(24);
		fxList.add(fx);
		return fx;
	}

	public function explosion(x:Float,y:Float, col:Int) {
		explosionAnim(x,y, 1);
		for(i in 0...40) {
			var fx = createFx(FX_Debris, x,y, col, Std.random(2)+1);
			if(i<5) {
				fx.dx = Std.random(30)/100 * (Std.random(2)*2-1);
				fx.dy = -Std.random(300)/100 - 6;
			}
			else if(i<10) {
				fx.dx = Std.random(80)/10 * (Std.random(2)*2-1);
				fx.dy = (Std.random(2)*2-1) * Std.random(100)/100;
			}
			else {
				fx.dx = 1 + Std.random(200)/100 * (Std.random(2)*2-1);
				fx.dy = -Std.random(500)/100;
			}
		}
	}
	
	public function lightExplosion(x:Float,y:Float, col:Int) {
		for(n in 0...15) {
			var f = createFx(FX_Debris, player.spr.x, player.spr.y, 0xffffff, 1);
			f.moveTo(x + (Std.random(2)*2-1)*Std.random(50)/10, y-Std.random(3));
			f.dx = Std.random(50)/100 * (Std.random(2)*2-1);
			f.dy = -(0.1+Std.random(30)/100);
			f.fy = 1;
			f.life = Std.int(32*15 + Std.random(640)/10);
			f.spr.alpha = 0.4 +Std.random(60)/100;
			f.gy = 0;
			f.spr.filters = [ new flash.filters.GlowFilter(col,1, 4,4,5) ];
		}
		//for(i in 0...40) {
			//var fx = createFx(FX_Debris, x,y, col, Std.random(2)+1);
			//if(i<5) {
				//fx.dx = Std.random(30)/100 * (Std.random(2)*2-1);
				//fx.dy = -Std.random(300)/100 - 6;
			//}
			//else if(i<10) {
				//fx.dx = Std.random(80)/10 * (Std.random(2)*2-1);
				//fx.dy = (Std.random(2)*2-1) * Std.random(100)/100;
			//}
			//else {
				//fx.dx = 1 + Std.random(200)/100 * (Std.random(2)*2-1);
				//fx.dy = -Std.random(500)/100;
			//}
		//}
	}
	
	public function explosionAnim(x:Float,y:Float, n) {
		for(i in 0...n) {
			var s = tiles.getSprite("explosion");
			buffer.addChild(s);
			s.x = Std.int( x + (n>1 ? Std.random(30)*(Std.random(2)*2-1) : 0) );
			s.y = Std.int( y + (n>1 ? Std.random(30)*(Std.random(2)*2-1) : 0) );
			s.blendMode = flash.display.BlendMode.SCREEN;
			s.rotation = Std.random(4)*90;
			s.centerY = 0.5;
			s.fl_killOnEndPlay = true;
			s.playAnim("explosion", 1);
			fxSprites.add(s);
		}
	}
	
	function spawnBeloved(x,y,id) {
		var e = spawnEntity(ET_Scen(null,0, "player",10), x,y);
		e.id = id;
		var light = new SPR();
		light.graphics.beginFill(0xffffff);
		light.graphics.drawRect(0, 0, 1, 1);
		light.x = -1;
		light.y = -12;
		e.niceSpr.addChild(light);
		var col = 0xDB82DB;
		light.filters = [
			new flash.filters.GlowFilter(col, 1, 2,2, 10),
			new flash.filters.GlowFilter(col, 1, 8,8, 6, 3),
			new flash.filters.GlowFilter(col, 1, 32,32, 2),
			new flash.filters.GlowFilter(col, 1, 16,16, 1),
		];
	}
	
	function spawnEntity(t:EType, x,y) {
		var e = new Entity(this, t);
		switch(t) {
			case ET_Zombie :
				e.spr = tiles.getSprite("player", 2);
				e.niceSpr = tiles.getSprite("blob");
			case ET_Item(i) :
				e.fl_object = true;
				var frame = switch(i) {
					case "drug"		: 0;
					case "jetpack"	: 1;
					case "coffee"	: 2;
					case "canon"	: 3;
				}
				e.spr = tiles.getSprite("items", frame);
				e.spr.filters = [
					new flash.filters.GlowFilter(0xDAF1FA, 0.3, 4,4, 2),
					new flash.filters.GlowFilter(0x98D9F1, 0.9, 16,16, 3, 2),
				];
			case ET_Player :
				e.spr = tiles.getSprite("player");
			case ET_Elder :
				e.fl_object = true;
				e.spr = tiles.getSprite("elder");
			case ET_Scen(dark,df, nice,nf) :
				e.fl_object = true;
				e.spr = tiles.getSprite(dark,df);
				if(nice!=null)
					e.niceSpr = tiles.getSprite(nice,nf);
		}
		e.frictX = 1;
		buffer.addChild(e.spr);
		if(e.niceSpr!=null)
			buffer.addChild(e.niceSpr);
		e.moveTo(x, y);
		entities.add(e);
		return e;
	}
	
	function deathSequence(fall:Bool) {
		if(fall)
			player.setVis(false);
		var mask = new mt.deepnight.SPR();
		buffer.addChild(mask);
		mask.graphics.beginFill(0x0);
		mask.graphics.drawRect(0,0,buffer.width, buffer.height);
		mask.alpha = 0;
		
		if(fall)
			TW.create(mask, "alpha", 1, TEaseIn, 3000);
		else
			haxe.Timer.delay(function() {
				TW.create(mask, "alpha", 1, TEaseIn, 7000);
			}, 2500);
		
		if(fall) {
			haxe.Timer.delay( function() {
				var bigPlayer = ME.tiles.getSprite("specialPlayer");
				ME.buffer.addChild(bigPlayer);
				bigPlayer.centerY = 0.8;
				bigPlayer.redraw();
				bigPlayer.playAnim("specialDie");
				bigPlayer.x = ME.buffer.width*0.5;
				bigPlayer.y = ME.buffer.height*0.5;
				bigPlayer.scaleX = 8;
				bigPlayer.scaleY = bigPlayer.scaleX;
				bigPlayer.alpha = 0;
				TW.create(bigPlayer, "alpha", 1, TEaseIn, 3000);
				var a = TW.create(bigPlayer, "scaleX", 0, TEaseIn, 10000);
				a.onEnd = function() {
					ME.endTitle();
				}
				a.onUpdateT = function(t) {
					bigPlayer.scaleY = bigPlayer.scaleX;
					bigPlayer.rotation+=2;
					if(t>0.5)
						bigPlayer.alpha = 1-(t-0.5)/0.5;
				}
			}, 3000);
		}
		else {
			haxe.Timer.delay(endTitle, 10500);
		}
	}
	
	function endTitle() {
		var s = new interf.Talk();
		ME.buffer.addChild(s);
		s.field.text = "Appy 1000mg";
		s.field.textColor = 0xA0836D;
		s.x = Std.int(ME.buffer.width*0.5-s.width*0.5);
		s.y = Std.int(ME.buffer.height*0.5-s.height*0.5)+30;
		s.alpha = 0;
		TW.create(s, "alpha", 1, TEaseIn, 3000);
		var s = new interf.Talk();
		ME.root.addChild(s);
		s.field.width = 400;
		if(fl_desinteg)
			s.field.text = "Good job for finding the alternate ending!";
		else
			s.field.text = "Thank you for playing :)";
		s.field.textColor = 0x665142;
		s.x = Std.int(WID*0.5-s.width*0.5);
		s.y = HEI-20;
		s.alpha = 0;
		TW.create(s, "alpha", 1, TEaseIn, 7000);
	}
	
	
	public function refocus(dx:Float,dy:Float) {
		var x = Std.int(player.mx-VIEW_WID*0.5 + dx*VIEW_WID*0.22);
		var y = Std.int(player.my-VIEW_HEI*0.5 + dy*VIEW_HEI*0.15);
		if(y>gworld.height-VIEW_HEI)
			y = gworld.height-VIEW_HEI;
		if(x!=viewPort.x || y!=viewPort.y)
			generateSubWorld(x, y);
		
	}
	
	public function redraw() {
		generateSubWorld(viewPort.x, viewPort.y);
	}
	
	public function getHighestY(bd:BD, x:Int, ?y:Int, ?limit=99999) {
		if(y==null)
			y = bd.height-1;
		while(y>0 && limit-->0) {
			if(bd.getPixel(x, y)==0x0)
				return y;
			y--;
		}
		return y;
	}
	
	function generateWorld(seed:Int) {
		#if debug
		trace("seed="+seed);
		#end
		
		gworld.fillRect(gworld.rect, 0x0);
		tiles.paintIntoBitmap("map", gworld, new flash.geom.Point(0,0));
		
		var start = Color.addAlphaChannel(0xffffff);
		var mob = Color.addAlphaChannel(0xff0000);
		var cp = Color.addAlphaChannel(0x00FF00);
		for(y in 0...gworld.height)
			for(x in 0...gworld.width) {
				if(gworld.getPixel32(x,y)==start) {
					player.moveTo(x,y);
					lastCheck = {x:x, y:y};
					gworld.setPixel32(x,y, 0x0);
				}
				if(gworld.getPixel32(x,y)==mob) {
					var e = spawnEntity(ET_Zombie, x,y);
					gworld.setPixel32(x,y, 0x0);
				}
				
				if(gworld.getPixel32(x,y)==cp) {
					checkpoints.add({x:x, y:y});
					gworld.setPixel32(x,y, 0x0);
				}
			}
		
		// lignes du fond
		for(n in 0...6)
			for(x in 0...gworld.width)
				gworld.setPixel32(x, gworld.height-1-n, C_STONE);

		dotRain(gworld, 1, gworld.width, C_GRASS);

		/*
		rseed.initSeed(seed);
		// falaises
		for(i in 0...rseed.random(10)+10) {
			var h = rseed.random(15)+6;
			gworld.fillRect( new flash.geom.Rectangle(rseed.random(gworld.width), gworld.height-6-h, rseed.random(30)+5, h), C_GROUND);
		}

		
		// terre
		dotRain(gworld, rseed.random(100)+100, 40, C_GROUND);
		gworld.fillRect( new flash.geom.Rectangle(70,70, 10,10), 0x0);
		// grass
		dotRain(gworld, 1, gworld.width, C_GRASS);

		for(n in 0...rseed.random(20)+15)
			digCircle(rseed.random(gworld.width), rseed.random(25)+70, rseed.random(5)+5);

		// lakes
		for(i in 0...2) {
			var x = rseed.random(gworld.width);
			var y = getHighestY(gworld, x);
			fillLake(gworld, x, y, C_WATER);
		}
			
		// lignes du fond
		for(n in 0...6)
			for(x in 0...gworld.width)
				gworld.setPixel32(x, gworld.height-1-n, C_STONE);
				
		// élément forcés (level design)
		fillLake(gworld, 0,86, C_WATER);
		*/
		buildMap();
	}
	
	function buildMap() {
		randMap = new Array();
		map = new Array();
		for(x in 0...gworld.width) {
			randMap[x] = new Array();
			map[x] = new Array();
			for(y in 0...gworld.height) {
				map[x][y] = gworld.getPixel32(x, y);
				randMap[x][y] = rseed.random(9999999);
			}
		}
	}
	
	function fillLake(bd:BD,  x, y, col:Int) {
		bd.setPixel32(x, y, col);
		if(x>0 && bd.getPixel32(x-1,y)==0)
			fillLake(bd, x-1, y, col);
		if(x<bd.width-1 && bd.getPixel32(x+1,y)==0)
			fillLake(bd, x+1, y, col);
		if(y<bd.height-1 && bd.getPixel32(x,y+1)==0)
			fillLake(bd, x, y+1, col);
	}
	
	function generateSubWorld(tx:Int, ty:Int) {
		var old = viewPort;
		viewPort = new IntRectangle(tx,ty, VIEW_WID, VIEW_HEI);
		var wid = VIEW_WID;
		var hei = VIEW_HEI;
		var work = new BD(sworld.width, sworld.height, true, 0x0);
		work.copyPixels(gworld, new flash.geom.Rectangle(tx-1, ty-1, wid+2, wid+2), new flash.geom.Point(0, 0));
		sworld.fillRect(sworld.rect, 0x0);
		farscape.bitmapData.fillRect(farscape.bitmapData.rect, 0x0);
		
		var sc2x = SCALE_2X_ALGORITHM;
		for(i in 0...3) {
			var scale = Std.int( Math.pow(2, i+1) );
			for(y in 0...(hei+2)*scale) {
				for(x in 0...(wid+2)*scale) {
					var p = work.getPixel32(x, y);
					// SCALE 2x algorithm : http://en.wikipedia.org/wiki/Pixel_art_scaling_algorithms
					//	IF C==A AND C!=D AND A!=B => 1=A
					//	IF A==B AND A!=C AND B!=D => 2=B
					//	IF B==D AND B!=A AND D!=C => 4=D
					//	IF D==C AND D!=B AND C!=A => 3=C
					var sx = x*2;
					var sy = y*2;
					if( sc2x ) {
						var a = work.getPixel32(x, y-1);
						var b = work.getPixel32(x+1, y);
						var c = work.getPixel32(x-1, y);
						var d = work.getPixel32(x, y+1);
						sworld.setPixel32(sx, sy, if(c==a && c!=d && a!=b) a else p);
						sworld.setPixel32(1+sx, sy, if(a==b && a!=c && b!=d) b else p);
						sworld.setPixel32(1+sx, 1+sy, if(b==d && b!=a && d!=c) d else p);
						sworld.setPixel32(sx, 1+sy, if(d==c && d!=b && c!=a) c else p);
					}
					else {
						sworld.setPixel32(sx, sy, p);
						sworld.setPixel32(sx+1, sy, p);
						sworld.setPixel32(sx, sy+1, p);
						sworld.setPixel32(sx+1, sy+1, p);
					}
				}
			}
			work.copyPixels(sworld, sworld.rect, pt0);
		}
		
		sworld.fillRect(sworld.rect, 0x0);
		sworld.copyPixels(work, new flash.geom.Rectangle(8, 8, work.width-16, work.height-16), pt0);
		farscape.bitmapData.copyPixels(gworld, new flash.geom.Rectangle(tx+100, ty-1, wid+2, wid+2), pt0);
		
		// props
		//work.fillRect(work.rect, 0x0);
		rseed.initSeed(0);
		for(p in props)
			p.spr.parent.removeChild(p.spr);
		props = new List();
		propsWind = new List();
		for(y in ty...ty+hei)
			for(x in tx...tx+wid) {
				if(randMap[x]==null)
					continue;
				var rand = randMap[x][y];
				var col = map[x][y];
				if(col==0x0 && map[x][y+1]==C_WATER) {
					// nice
					var x = (x-tx)*8;
					var y = (y-ty)*8+8;
					var spr = tiles.getSprite("waterTop", 0);
					spr.playAnim("waterTopNice");
					spr.centerX = 0;
					spr.centerY = 1;
					spr.x = x;
					spr.y = y;
					spr.redraw();
					propCont.addChild(spr);
					props.add({drug:true, spr:spr});
					// dark
					var spr = tiles.getSprite("waterTop", 1);
					spr.playAnim("waterTopDark");
					spr.centerX = 0;
					spr.centerY = 1;
					spr.x = x;
					spr.y = y;
					spr.alpha = -1-drug;
					spr.redraw();
					propCont.addChild(spr);
					props.add({drug:false, spr:spr});
					
				}
				if(col==0x0 && map[x][y+1]==C_GRASS) {
					if(rand % 100<10) {
						// arbres
						var g = tiles.getGroup("niceTree");
						var spr = tiles.getSprite( "niceTree", rand % g.length);
						spr.x = (x-tx)*8 + 3 + ((rand) % 6);
						spr.y = fallToGround(sworld, Std.int(spr.x), (y-ty)*8) +8;
						spr.scaleX = (rand % 2)*2-1;
						spr.alpha = drug;
						propCont.addChild(spr);
						props.add({drug:true, spr:spr});
						// dark
						var g = tiles.getGroup("darkTree");
						var spr2 = tiles.getSprite( "darkTree", rand % g.length);
						spr2.x = spr.x;
						spr2.y = spr.y;
						spr2.scaleX = spr.scaleX;
						spr2.alpha = 1-drug;
						propCont.addChild(spr2);
						props.add({drug:false, spr:spr2});
					}
					// herbes
					var niceGrass = tiles.getGroup("niceGrass");
					var darkGrass = tiles.getGroup("darkGrass");
					for(n in 0...2+rand % 2) {
						// jolie
						var x = (x-tx)*8 + 3 + ((rand*n) % 6);
						var y = fallToGround(sworld, x, (y-ty)*8) +2;
						var spr = tiles.getSprite("niceGrass", rand % niceGrass.length);
						spr.centerY = 0.5;
						spr.x = x;
						spr.y = y;
						spr.redraw();
						spr.alpha = drug;
						propCont.addChild(spr);
						props.add({drug:true, spr:spr});
						propsWind.add(props.last());
						// dark
						var spr = tiles.getSprite("darkGrass", rand % darkGrass.length);
						spr.centerY = 0.5;
						spr.redraw();
						spr.x = x;
						spr.y = y;
						spr.alpha = 1-drug;
						propCont.addChild(spr);
						props.add({drug:false, spr:spr});
						propsWind.add(props.last());
					}
				}
				if(col==0x0 && map[x][y+1]==C_GROUND) {
					var group = tiles.getGroup("darkRoot");
					for(n in 0...1+rand % 3) {
						// racines
						var x = (x-tx)*8 + 3 + ((rand*n) % 6);
						var y = fallToGround(sworld, x, (y-ty)*8) +0;
						var spr = tiles.getSprite("darkRoot", rand % group.length);
						spr.centerY = 0.5;
						spr.x = x;
						spr.y = y;
						spr.redraw();
						spr.alpha = 1-drug;
						propCont.addChild(spr);
						props.add({drug:false, spr:spr});
						// racines
						var spr = tiles.getSprite("niceRoot", rand % group.length);
						spr.centerY = 0.5;
						spr.x = x;
						spr.y = y;
						spr.redraw();
						spr.alpha = drug;
						propCont.addChild(spr);
						props.add({drug:true, spr:spr});
						propsWind.add(props.last());
					}
				}
				if( col==0x0 && map[x][y+1]!=0 && map[x][y+1]!=C_WATER ) {
					var group = tiles.getGroup("bones");
					for(n in 0...(rand % 3)-1) {
						// ossements
						var x = (x-tx)*8 + 3 + ((rand*n) % 6);
						var y = fallToGround(sworld, x, (y-ty)*8) +0;
						var spr = tiles.getSprite("bones", rand % group.length);
						spr.centerY = 0.5;
						spr.x = x;
						spr.y = y;
						spr.redraw();
						spr.alpha = 1-drug;
						propCont.addChild(spr);
						props.add({drug:false, spr:spr});
						//propsWind.add(props.last());
					}
				}
			}
		//sworld.copyPixels(work, work.rect, pt0, true);

		sworld.applyFilter(sworld, sworld.rect, pt0, new flash.filters.DropShadowFilter(1,90,0x723416,1, 0,1, 1) );
		//sworld.applyFilter(sworld, sworld.rect, pt0, new flash.filters.DropShadowFilter(2,-90,0xFCCE43,0.4, 2,0, 1,1,true) );
		//sworld.applyFilter(sworld, sworld.rect, pt0, new flash.filters.DropShadowFilter(4,-90,0x843D1A,0.7, 2,12, 1,1,true) );
		
		//sworld.applyFilter(sworld, sworld.rect, pt0, new flash.filters.DropShadowFilter(4,90,0xD6FB42,0.2, 2,8, 1,1,true) );
		//sworld.applyFilter(sworld, sworld.rect, pt0, new flash.filters.GlowFilter(0x4E2D0E, 1, 2, 2, 10, 1, false) );
		//sworld.applyFilter(sworld, sworld.rect, pt0, new flash.filters.GlowFilter(0x0, 1, 16, 16, 1, 1, false) );
		
		work.dispose();
		
		// décalage des FX
		var dx = (viewPort.x - old.x)*8;
		var dy = (viewPort.y - old.y)*8;
		for(f in fxList)
			if(f.type!=FX_DustWind && f.type!=FX_SunLight)
				f.moveTo(f.x-dx, f.y-dy);
		for(s in fxSprites)
			if(s==null || s.parent==null)
				fxSprites.remove(s);
			else {
				s.x-=dx;
				s.y-=dy;
			}
		
		// spawn d'ennemis
		/*
		if(spawnCD<=0) {
			var tries = 20;
			var n = Std.random(4)-1;
			if(n>0)
				spawnCD = 32*n*2;
			while (n>0 && tries-->0) {
				var pt = viewPort.getRandomPoint();
				if( pt.x>=0 && pt.x<gworld.width && pt.y<gworld.height ) {
					while( pt.y<gworld.height-1 && map[pt.x][pt.y+1]==0x0)
						pt.y++;
					if( !old.containsInclusive(pt.x,pt.y) && map[pt.x][pt.y]==0x0 && map[pt.x][pt.y]!=C_WATER ) {
						//trace("old="+old+" new="+viewPort+" pt="+pt.x+","+pt.y);
						spawnEntity(ET_Zombie, pt.x, pt.y);
						n--;
					}
				}
			}
		}
		*/
	}
	
	function fallToGround(bd:BD, x, y) {
		var limit = 20;
		while(limit-->0 && bd.getPixel32(x,y)==0x0)
			y++;
		return y-1;
	}
	
	function dotRain(bd:BD, passes:Int, wid, col:Int) {
		//var col = Color.addAlphaChannel(col);
		for(n in 0...passes) {
			var min = rseed.random(bd.width-wid);
			var max = min+wid;
			for(x in min...max) {
				var y = 0;
				while( bd.getPixel32(x,y+1)==0x0 )
					y++;
				if( bd.getPixel32(x,y+1)!=C_WATER )
					bd.setPixel32(x, y, col);
			}
			
		}
	}
		
	
	inline function isDownWithLock(k:Int) {
		if ( !Key.isDown(k) && lockedKeys.exists(k) )
			lockedKeys.remove(k);
		return if (Key.isDown(k) && !lockedKeys.exists(k) ) {
			lockedKeys.set(k,true);
			true;
		}
		else false;
	}
	
	public function hitPlayer(x) {
		if(shield<=0) {
			life--;
			shield = 64;
		}
		updatePlayerLight();
		player.dy = -2;
		player.dx = (3 + Std.random(10)/10) * (x<player.spr.x ? 1 : -1) ;
		player.spr.scaleX = (x<player.spr.x?-1:1);
		player.stun = 26;
		if(life<0)
			player.die();
	}
	
	public function onPlayerDeath() {
		var mask = new SPR();
		buffer.addChild(mask);
		var g = mask.graphics;
		var m = new flash.geom.Matrix();
		m.rotate(-3.14*0.5);
		g.beginGradientFill(flash.display.GradientType.LINEAR, [0x6A0D0D, 0x0], [1, 1], [110, 128], m);
		g.drawRect(0,0, buffer.width, buffer.height);
		
		mask.alpha = 0;
		TW.create(mask, "alpha", 1, TEase, 1000).onEnd = function() {
			ME.resetGame();
			TW.create(mask, "alpha", 0, TEaseIn, 700).onEnd = function() {
				mask.parent.removeChild(mask);
			}
		}
	}
	
	public function resetGame() {
		player.setVis(true);
		player.fl_dead = false;
		player.moveTo(lastCheck.x, lastCheck.y);
		player.dx = 0;
		player.dy = 0;
		player.unlock();
		player.spr.stopAnim(0);
		life = MAX_LIFE;
		shield = 96;
		updatePlayerLight();
		refocus(0,0);
	}
		
	public function playSound(skey:String, ?vol=1.0) {
		if ( !SFX_LIB.exists(skey) )
			SFX_LIB.set( skey, Type.createEmptyInstance(Type.resolveClass("sfx."+skey)) );
		
		var chan = SFX_LIB.get(skey).play();
		chan.soundTransform = new flash.media.SoundTransform(vol*MAIN_VOLUME);
	}
	
	public function onHitPlayer(e:Entity) {
		switch(e.type) {
			case ET_Zombie	:
				if(drug==0) {
					explosion(e.spr.x, e.spr.y, 0xFF0000);
					explosionAnim(e.spr.x, e.spr.y, 2);
					e.die();
					hitPlayer(e.spr.x);
					digCircle(e.mx, e.my, 3);
					redraw();
				}
			case ET_Player :
			case ET_Scen(_) :
			case ET_Item(i) :
				switch(i) {
					case "drug" :
						toggleDrugStatus();
					case "coffee" :
						if(drug>0)
							toggleDrugStatus();
						digCircle(91,49,2);
					case "jetpack" :
						fl_jetpack = true;
						chainNotifies([
							"You found what is like an antique JETPACK. Press UP arrow to fly. It's power is limited thus...",
							"[player]Me fly?",
						]);
					case "canon" :
						fl_digger = true;
						chainNotifies([
							"You found a strange device which looks like a gun... but BIGGER.",
							"Use SPACE + ARROWS keys to dig the walls !",
						]);
					default :
						throw "unknown item "+i;
				}
				e.die();
			case ET_Elder :
				if( e.id=="aquaelder" && canDoOnce("aquarium") )
					notify("[elder]Nice view isn't it?");

				if( e.id=="elder" && canDoOnce("elder") )
					chainNotifies([
						"[elder]Hello subject 612.",
						"[player]...",
						"[elder]I told you to stay away from these caverns. ",
						"[elder]But I guess you forgot, again.",
						"[player]Forgot ? Me not know you.",
						"[elder]It's dangerous to go Alone.",
						"[player]Me not alone! Me bloobies.",
						"[player]... Me "+BELOVED+"...",
						"[elder]Fantastic world, for sure.",
						"[elder]Face truth. Take this.",
					]);
		}
	}
	
	function getEntity(id:String) {
		for(e in entities)
			//if(Type.enumIndex(e.type)==Type.enumIndex(t))
			if(e.id.toLowerCase()==id.toLowerCase())
				return e;
		return null;
	}
	
	public inline function hasDone(id) {
		return doOnce.exists(id);
	}
	
	public inline function canDoOnce(id:String) {
		return
			if(doOnce.exists(id))
				false;
			else {
				doOnce.set(id, true);
				true;
			}
	}
	
	function onNotifyDone() {
		if(hasDone("tombsReveal") && canDoOnce("repeatName")) {
			player.say("Me... Alone?", true);
			player.unlock();
		}
		if(hasDone("beloved") && canDoOnce("tombs")) {
			player.dx = 0;
			haxe.Timer.delay(function() {
				ME.getEntity("beloved2").niceSpr.scaleX = -1;
			}, 1000);
			haxe.Timer.delay(function() {
				ME.player.dx = 0;
				ME.setDrug(0);
				//timer.stop();
			}, 3000);
		}
		if(hasDone("belovedFirst") && canDoOnce("belovedFirstHide")) {
			var e = ME.getEntity("beloved1");
			haxe.Timer.delay(function() {
				e.niceSpr.scaleX = -1;
			}, 1000);
			haxe.Timer.delay(function() {
				e.setVis(false);
				ME.lightExplosion(e.spr.x, e.spr.y, 0xD973EE);
				var mask = new mt.deepnight.SPR();
				ME.buffer.addChild(mask);
				mask.graphics.beginFill(0xFFBFFF);
				mask.graphics.drawRect(0,0,ME.buffer.width, ME.buffer.height);
				mask.alpha = 0.3;
				TW.create(mask, "alpha", 0, TEaseIn, 3000).onEnd = function() {
					mask.parent.removeChild(mask);
				}
				//TW.create(ME.root,"y", ME.root.y+5, TShakeBoth, 1500);
				//TW.create(e, "", 0, TEaseIn, 1500);
				haxe.Timer.delay( function() {
					ME.player.say("NO!", true);
					ME.player.unlock();
				}, 250);
				haxe.Timer.delay( function() {
					ME.player.say("Where you go?", true);
				}, 2500);
				haxe.Timer.delay( function() {
					ME.player.say(BELOVED+" :(", true);
				}, 7000);
			}, 3000);
		}
		
		if(hasDone("alternate1") && canDoOnce("alternate2")) {
			haxe.Timer.delay(callback(player.microJump,1), 2000);
			haxe.Timer.delay(function() {
				ME.chainNotifies([
					"[player]We?",
					"[player]... Appy?",
				]);
				ME.fl_desinteg = true;
			},3500);
			haxe.Timer.delay(callback(deathSequence,false), 6000);
		}
		
		if(hasDone("foundAgain") && canDoOnce("alternate1")) {
			//player.unlock();
			haxe.Timer.delay(callback(player.microJump,1), 1000);
			haxe.Timer.delay(callback(player.microJump,1), 2500);
			haxe.Timer.delay(function() {
				ME.chainNotifies([
					"[player]...",
					"[player]We?",
				]);
			},3500);
		}
	}
	
	public function chainNotifies(arr:Array<String>) {
		for(s in arr)
			notipool.add(s);
		notify(notipool.pop());
	}
	
	public function notify(msg:String) {
		var bgCol = 0x86321A;
		pop = new mt.deepnight.SPR();
		
		var tf = new interf.Notify();
		if( msg.indexOf("|")>=0 ) {
			bgCol = Std.parseInt(msg.split("|")[0]);
			msg = msg.substr( msg.indexOf("|")+1 );
		}
		var speaker : DSprite = null;
		if( msg.indexOf("[player]")>=0 ) {
			msg = StringTools.replace(msg,"[player]","");
			speaker = tiles.getSprite("player");
			speaker.x = 6;
			speaker.y = 12;
			bgCol = 0x6C7E9B;
		}
		if( msg.indexOf("[elder]")>=0 ) {
			msg = StringTools.replace(msg,"[elder]","");
			speaker = tiles.getSprite("elder");
			speaker.x = 6;
			speaker.y = 17;
			speaker.scaleX = -1;
			bgCol = 0x91180B;
		}
		
		if(speaker!=null) {
			speaker.filters = [ new flash.filters.DropShadowFilter(2,0, 0x0,0.2, 0,0) ];
			msg = "\""+msg+"\"";
			tf.field.x+=10;
			//tf.field.width=100;
		}
		tf.filters = [ new flash.filters.GlowFilter(0x0, 0.5, 2,2) ];
		tf.field.text = msg;
		tf.field.height = tf.field.textHeight + 5;
		
		var bg = new SPR();
		var g = bg.graphics;
		g.beginFill(bgCol, 1);
		g.drawRect(0,0, tf.field.width+tf.field.x, tf.field.textHeight+15);
		g.endFill();
		bg.filters = [
			new flash.filters.DropShadowFilter(1, 90,0x0,0.6, 2,2,1, 1,true),
			new flash.filters.GlowFilter(0xffffff,1, 4,4, 10),
			new flash.filters.GlowFilter(0x0,1, 2,2, 10),
		];
		
		var arrow = tiles.getSprite("arrow");
		//arrow.filters = [new flash.filters.GlowFilter(0x0,1, 2,2, 10)];
		arrow.x = tf.field.width-5;
		arrow.y = tf.field.height+9;
		arrow.playAnim("arrow");
		
		fl_pause = true;
		
		pop.addChild(bg);
		pop.addChild(tf);
		pop.addChild(arrow);
		if(speaker!=null)
			pop.addChild(speaker);

		pop.x = Std.int( buffer.width*0.5 - pop.width*0.5);
		pop.y = 10;
		buffer.addChild(pop);
	}
	
	
	function dig(x, y) {
		if(map!=null && (map[x][y]==C_STONE || map[x][y]==C_WATER || map[x][y]==0x0))
			return false;
		gworld.setPixel32(x, y, 0x0);
		if(map!=null)
			map[x][y] = 0x0;
		return true;
	}
	
	function digCircle(cx:Int, cy:Int, r) {
		for(x in cx-r...cx+r+1)
			for(y in cy-r...cy+r+1)
				if(Math.sqrt( (x-cx)*(x-cx) + (y-cy)*(y-cy) ) <= r+0.5)
					dig(x, y);
	}

	function fxUpdate() {
		// poussières noires
		var f = createFx(FX_DustWind, 0, Std.random( buffer.height ), 0x0, 1+Std.random(3));
		f.spr.parent.removeChild(f.spr);
		dustCont.addChild(f.spr);
		f.spr.alpha = 0.1 + Std.random(30)/100;
		f.r = 3;
		f.dx = 0.1 + Std.random(150)/100;
		f.dy = 0.1 + Std.random(20)/100;
		f.gx = f.gy = 0;
		f.fx = f.fy = 1;
		
		// soleil
		var f = createFx(FX_SunLight, Std.random(buffer.width), 0, 0xFFF4A6, 1);
		if(Std.random(100)<50) {
			f.spr.parent.removeChild(f.spr);
			niceSky.addChild(f.spr);
			f.spr.alpha = 0.1+Std.random(20)/100;
		}
		f.spr.filters = [ new flash.filters.GlowFilter(0xFFD52B, 0.5+Std.random(50)/100, 4, 4, 4) ];
		f.dx = 0.1 + Std.random(20)/100;
		f.dy = 0.1 + Std.random(150)/100;
		f.gx = f.gy = 0;
		f.fx = f.fy = 1;
		
		// desintégration des héros
		if(fl_desinteg && Std.random(100)<30) {
			var aSpd = 0.02;
			var e = player;
			if(e.spr.alpha>0) {
				var f = createFx(FX_Debris, e.spr.x, e.spr.y, 0xffffff, 1);
				f.moveTo(e.spr.x + 3 + Std.random(30)/10*(Std.random(2)*2-1), e.spr.y- Std.random(60)/10);
				f.dx = 0.1+Std.random(3)/10;
				f.fx = 1;
				f.dy = -0.1-Std.random(300)/1000;
				f.gy = -0.0005-Std.random(100)/100000;
				f.life = 32*2 + Std.random(32*6);
				f.spr.alpha = 0.4 +Std.random(60)/100;
				f.spr.filters = [ new flash.filters.GlowFilter(0x79DBEC,1, 4,4,5) ];
				e.spr.alpha-=aSpd;
			}
			var e = getEntity("beloved2");
			if(e.niceSpr.alpha>0) {
				var f = createFx(FX_Debris, e.spr.x, e.spr.y, 0xffffff, 1);
				f.moveTo(e.spr.x + 3 + Std.random(30)/10*(Std.random(2)*2-1), e.spr.y- Std.random(60)/10);
				f.dx = 0.1+Std.random(3)/10;
				f.fx = 1;
				f.dy = -0.1-Std.random(300)/1000;
				f.gy = -0.0005-Std.random(100)/100000;
				f.life = 32*2 + Std.random(32*6);
				f.spr.alpha = 0.4 +Std.random(60)/100;
				f.spr.filters = [ new flash.filters.GlowFilter(0xFF80FF,1, 4,4,5) ];
				e.niceSpr.alpha-=aSpd;
			}
		}
		
		// update
		for(f in fxList) {
			if(f.life!=null)
				f.life--;
			f.dx+=f.gx; // gravité
			f.dy+=f.gy;
			f.dx*=f.fx; // friction
			f.dy*=f.fy;
			f.x+=f.dx; // mouvement
			f.y+=f.dy;
			f.spr.x = Std.int(f.x);
			f.spr.y = Std.int(f.y);
			if(f.type==FX_DustWind)
				f.spr.alpha = 0.3*(1-drug);
			f.spr.rotation+=f.r;
			if(f.type==FX_SunLight)
				f.spr.alpha = drug * Math.sin(3*f.y/buffer.height);
			if(f.life!=null && f.life<=0)
				f.spr.alpha-=0.05;
			if( !buffer.rect.contains(f.x, f.y) || f.spr.alpha<=0 ) {
				f.spr.parent.removeChild(f.spr);
				fxList.remove(f);
			}
		}
	}
	
	
	function setDrug(d:Float) {
		if(d!=drug)
			toggleDrugStatus();
	}
	
	function toggleDrugStatus() {
		var to = (drug==1?0:1);
		var med = (drug==1?0.7:0.2);
		var anim = TW.create(this, "drug", med, TShake, 750);
		anim.onUpdateT = function(t) {
			var r = Math.sin(t*3.14);
			ME.root.filters = [ new flash.filters.BlurFilter(4*r,4*r) ];
		}
		anim.onEnd = function() {
			var a = TW.create(ME, "drug", to, TEaseOut);
			a.onUpdateT = function(t) {
				var rx = if(t<0.7) Math.sin(t*4.396) else 0;
				var ry = if(t>=0.3) -Math.sin(1.884+t*4.396) else 0;
				ME.root.filters = [ new flash.filters.BlurFilter(16*rx,16*ry) ];
			}
			a.onEnd = function() {
				ME.root.filters = [];
				if(ME.drug==0)
					ME.player.say( TXT_DRUG_OFF[Std.random(TXT_DRUG_OFF.length)] );
				else
					ME.player.say( TXT_DRUG_ON[Std.random(TXT_DRUG_ON.length)] );
				ME.onDrugStatus();
			}
		}
	}
	
	function onDrugStatus() {
		if(drug==0 && canDoOnce("drugOff"))
			chainNotifies([
				"[player]Oh no.. NO....",
				"[player]Woke up....",
				"[player]Me Remember..",
				"[player]Why woke up ME?",
				"[player]..me... WHY?!",
			]);
		if(drug==0 && hasDone("tombs") && canDoOnce("tombsReveal"))
			chainNotifies([
				"[player]... "+BELOVED+"...",
				"[player]No....",
				"[player]...",
			]);
		if(drug==1 && canDoOnce("drugOn"))
			chainNotifies([
				"[player]Me don't want know..",
				"[player]Me want Appy !",
			]);
	}
	
	function main(_) {
		if(!fl_started) {
			TW.update();
			if(isDownWithLock(Keyboard.SPACE)) {
				start();
				TW.create(logo.hero, "alpha", 1, TEaseIn, 600);
				TW.create(logo.logo, "alpha", 0, TEaseIn, 600).onEnd = function() {
					TW.create(ME.intro, "alpha", 0, TEaseIn, 1000).onEnd = function() {
						ME.intro.parent.removeChild(ME.intro);
					}
				}
			}
			return;
		}
		
		if(fl_pause) {
			if( isDownWithLock(Keyboard.SPACE) || isDownWithLock(Keyboard.ENTER) || isDownWithLock(Keyboard.NUMPAD_ENTER) || isDownWithLock(Keyboard.ESCAPE) || isDownWithLock("X".charCodeAt(0)) ) {
				fl_pause = false;
				if(notipool.length>0) {
					pop.parent.removeChild(pop);
					notify(notipool.pop());
				}
				else {
					// fermeture notify
					var mc = pop;
					TW.create(mc, "y", mc.y-30, TEaseIn);
					TW.create(mc, "alpha", 0, TEaseOut).onEnd = function() {
						mc.parent.removeChild(mc);
					}
					onNotifyDone();
				}
			}
			DSprite.updateAll();
			buffer.update();
			return;
		}
		
		
		TW.update();
		
		if(shield>0) {
			shield--;
			if(shield<=0)
				player.spr.alpha = 1
			else
				player.spr.alpha = shield % 2;
		}
		
		if(spawnCD>0)
			spawnCD--;
		
		// contrôles
		if( player.stun<=0 && !player.fl_dead ) {
			var speed = 0.6;
			#if debug
			//if(Key.isDown(Keyboard.SHIFT))
				speed = 1.5;
			#end
			if(Key.isDown(Keyboard.LEFT)) {
				if(player.fl_stable)
					player.spr.playAnim("playerWalk");
				player.spr.scaleX = -1;
				player.dx-=speed;
			}
			if(Key.isDown(Keyboard.RIGHT)) {
				if(player.fl_stable)
					player.spr.playAnim("playerWalk");
				player.spr.scaleX = 1;
				player.dx+=speed;
			}
			if(player.fl_stable && !Key.isDown(Keyboard.LEFT) && !Key.isDown(Keyboard.RIGHT))
				player.spr.playAnim("playerStand");
				
			if(Key.isDown(Keyboard.UP) ) {
				if( fl_jetpack && jetpack>0) {
					player.spr.playAnim("playerFly");
					jetpack--;
					var col = (drug<0.5 ? 0xff8000 : 0xFFF200 );
					var f = createFx(FX_Debris, player.spr.x, player.spr.y, col, 1);
					f.moveTo(player.spr.x - 2*player.spr.scaleX, player.spr.y-Std.random(3));
					f.dx = 0;
					f.dy = 0.1+Std.random(3)/10;
					f.gy = 0;
					if(player.fl_stable) {
						player.dy = -3;
						for(n in 0...15) {
							var f = createFx(FX_Debris, player.spr.x, player.spr.y, col, 1);
							f.moveTo(player.spr.x, player.spr.y-Std.random(3));
							f.dx = Std.random(10)/10 * (Std.random(2)*2-1);
							f.dy = 0.1+Std.random(3)/10;
							f.gy = 0;
						}
					}
					player.dy-=0.35;
					player.fl_stable = false;
				}
				if(!fl_jetpack && player.fl_stable) {
					player.fl_stable = false;
					player.dy = -3.5;
					for(n in 0...5) {
						var f = createFx(FX_Debris, player.spr.x, player.spr.y, C_GROUND, 1);
						f.moveTo(player.spr.x, player.spr.y-Std.random(3));
						f.dx = Std.random(5)/10 * (Std.random(2)*2-1);
						f.dy = 0.1+Std.random(3)/10;
						f.gy = 0;
					}
				}
			}
			if( !player.fl_stable && (!Key.isDown(Keyboard.UP) || jetpack<=0) && fallDuration++>3 )
				player.spr.stopAnim(0);
				
			for(cp in checkpoints)
				if(lastCheck!=cp && player.isNear(cp.x, cp.y, 3)) {
					lastCheck = cp;
					checkpoints.remove(cp);
					break;
				}
		}
		else {
			if(player.stun<1000)
				player.spr.stopAnim(8);
			else
				player.spr.stopAnim(0);
		}
		
		if(!Key.isDown(Keyboard.UP) && jetpack<MAX_JETPACK)
			jetpack += (player.fl_stable ? 2 : 1);
			
		if(player.fl_stable)
			fallDuration = 0;
			
		if(fl_digger && player.stun<=0 && isDownWithLock(Keyboard.SPACE)) {
			// creuser
			var dx = 0;
			var dy = -1;
			if(Key.isDown(Keyboard.LEFT))	{ dx = -1; dy = 0; }
			if(Key.isDown(Keyboard.RIGHT))	{ dx = 1; dy = 0; }
			if(Key.isDown(Keyboard.DOWN))	{ dx = 0; dy = 1; }
			var mx = player.mx + dx;
			var my = player.my + dy;
			if(map[mx][my]==C_GROUND || map[mx][my]==C_GRASS) {
				var c = Color.rgbaToInt( Color.offsetColorRgba(Color.intToRgba(map[mx][my]), -20) );
				explosion(player.spr.x+dx*16, player.spr.y-4+dy*16, c);
				//digCircle(player.mx, player.my, 1);
				dig(mx, my);
				dig(mx + (dy==0?0:-1), my+(dx==0?0:-1));
				TW.create(root,"x", root.x+10, TShakeBoth, 400);
				redraw();
			}
			else
				explosionAnim(player.spr.x+dx*16, player.spr.y-4+dy*16, 1);
		}
		
		
		#if debug
		if(isDownWithLock(Keyboard.END)) {
			toggleDrugStatus();
		}
		if(isDownWithLock(Keyboard.HOME)) {
			fl_desinteg = true;
		}
		if(!fl_digger && isDownWithLock(Keyboard.SPACE)) {
			digCircle(player.mx, player.my, 3);
			explosion(player.spr.x, player.spr.y, C_GROUND);
			explosionAnim(player.spr.x, player.spr.y, 5);
			TW.create(root,"y", root.y+10, TShakeBoth, 700);
			redraw();
			//if(Key.isDown(Keyboard.LEFT))
				//dig(player.mx-1, player.my);
			//else if(Key.isDown(Keyboard.RIGHT))
				//dig(player.mx+1, player.my);
			//else if(Key.isDown(Keyboard.UP))
				//dig(player.mx, player.my-1);
			//else
				//dig(player.mx, player.my+1);
		}
		if(Key.isDown(Keyboard.NUMPAD_ADD)) {
			drug+=0.1;
			if(drug>1)
				drug = 1;
		}
		if(Key.isDown(Keyboard.NUMPAD_SUBTRACT)) {
			drug-=0.1;
			if(drug<0)
				drug = 0;
		}
		#end
		
		
		// scénario
		if(!fl_pause) {
			if( player.isNear(42,55,2) && canDoOnce("firstBlob") )
				chainNotifies([
					"You see a \"blooby\" in the distance, a completely harmless creature.",
					"[player]Me like bloobies.",
					"[player]Me lol.",
				]);
			if(player.isNear(98,62,4) && hasDone("elder") && canDoOnce("elderItem")) {
				getEntity("elder").say("Take this.");
				spawnEntity(ET_Item("coffee"), 102,61);
			}
			if(player.isNear(98,61,1) && hasDone("drugOff") && canDoOnce("askAppy"))
				notify("[player]Give me APPY !");
			if(player.isNear(155,37,5) && canDoOnce("loseDrug"))
				toggleDrugStatus();
			if(player.isNear(252,14,5) && canDoOnce("moutain"))
				setDrug(0);
			if(player.isNear(314,18,8) && canDoOnce("approchEnd"))
				setDrug(1);
			if(player.mx>=345 && canDoOnce("beloved")) {
				player.lock();
				notify("[player]... "+BELOVED+"?");
				refocus(0.5,0);
			}
			if( player.mx>=355 && player.my>=21 && hasDone("tombsReveal") && canDoOnce("jumpSuicide") )
				notify(BELOVED+"!!!");
				
			if( player.isNear(55,46,2) && canDoOnce("belovedFirst")) {
				refocus(0.5,0);
				player.lock();
				chainNotifies([
					"[player]"+BELOVED+"?",
					"[player]...",
					"[player]Me... You?",
				]);
			}
			if(player.mx>=347 && hasDone("tombsReveal") && drug==1 && canDoOnce("foundAgain")) {
				player.lock();
				notify("[player]Me you!");
				refocus(0.5,0);
			}
			if( hasDone("tombsReveal") && player.mx>=322 && player.my>=64 && player.my<=74 && canDoOnce("suicide")) {
				player.gy = 0;
				player.dy = 0;
				player.fl_dead = true;
				deathSequence(true);
			}
		}
			
			
			
		
		// drug : colors
		if(drug<1)
			sworldBmp.filters = [Color.getSaturationFilter((1-drug)*-0.2)];
		else
			sworldBmp.filters = [];
		var ct = new flash.geom.ColorTransform();
		ct.redMultiplier = 1-(1-drug)*0.33;
		ct.blueMultiplier = 1+(1-drug)*0.20;
		ct.greenMultiplier = 1-(1-drug)*0.45;
		sworldBmp.transform.colorTransform = ct;
		
		// drug : elements visibility
		darkness.alpha = (1-drug)*0.9;
		farscape.alpha = 0.25+(1-drug)*0.75;
		niceSky.alpha = drug;
		for(p in props)
			if(p.drug!=null)
				p.spr.alpha = (p.drug? drug : 1-drug);
	
				
		for(e in entities) {
			// IA ennemis
			if(e.type!=ET_Player) {
				var dir = (player.mx<e.mx ? -1 : 1);
				if(e.fl_stable)
					e.dx = 0;
				// suivi du joueur (direction)
				if(!e.fl_object || e.type==ET_Elder) {
					e.spr.scaleX = dir;
					if(e.niceSpr!=null)
						e.niceSpr.scaleX = dir;
				}
				if(!e.fl_object) {
					if(e.fl_stable && Std.random(100)<10)
						e.dx=dir*0.01;
					// saut
					if(e.fl_stable && Std.random(1000)<30) {
						switch(e.type) {
							case ET_Zombie :
								e.dy = -1;
								e.dx = 0.5*dir;
							case ET_Player :
							case ET_Item(_) :
							case ET_Elder :
							case ET_Scen(_) :
						}
						e.fl_stable = false;
						if(e.niceSpr!=null)
							e.niceSpr.setFrame(1);
					}
					if(e.fl_stable && e.niceSpr!=null)
						e.niceSpr.setFrame(0);
				}
			}
			if(e.niceSpr!=null && !fl_desinteg) {
				// dark/drug version
				e.niceSpr.alpha = drug;
				e.spr.alpha = 1-drug;
			}
			e.update();
		}
		
		fxUpdate();
		
		// vent herbe
		for(p in propsWind) {
			if(p.drug) {
				if( Std.random(100)<10 )
					p.spr.rotation += (2+Std.random(4)) * (p.spr.rotation>10?-1:1);
			}
			else
				if( Std.random(100)<30 )
					p.spr.rotation+= (2+Std.random(4));
		}
		
		DSprite.updateAll();
		buffer.update();
		//trace("ent="+entities.length+" fx="+fxList.length);
	}
}
