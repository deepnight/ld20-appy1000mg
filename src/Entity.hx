import Manager;
import mt.deepnight.Types;
import mt.deepnight.Tweenie;
import SpriteLib;

enum EType {
	ET_Player;
	ET_Zombie;
	ET_Elder;
	ET_Item(item:String);
	ET_Scen(nice:String,nframe:Int, dark:String,dframe:Int);
}

class Entity {
	static var UNIQ = 0;
	
	public var id		: String;
	public var type		: EType;
	public var man		: Manager;
	public var mx		: Int;
	public var my		: Int;
	public var gx		: Int;
	public var gy		: Int;
	public var dx		: Float;
	public var dy		: Float;
	public var fl_stable	: Bool;
	
	public var frictX	: Float;
	public var frictY	: Float;
	
	public var spr		: DSprite;
	public var niceSpr	: Null<DSprite>;
	var bd				: BD;
	var lastTalk		: Null<interf.Talk>;
	public var stun		: Int;
	public var fl_object: Bool;
	public var fl_outOfSight	: Bool;
	public var fl_dead	: Bool;
	public var dcutOff	: Float;

	
	public function new(m, t:EType) {
		id = Std.string(t)+(UNIQ++);
		man = m;
		type = t;
		mx = 0;
		my = 0;
		fl_stable = true;
		fl_object = false;
		fl_dead = false;
		fl_outOfSight = false;
		dx = 0;
		dy = 0;
		frictX = 0.5;
		frictY = 0.9;
		stun = 0;
		dcutOff = 0.01;
	}
	
	public function moveTo(x, y) {
		mx = x;
		my = y;
		gx = x*8;
		gy = y*8;
	}
	
	public function getCase(x, y) {
		return
			if(x<0 || y<0 || x>=man.gworld.width || y>=man.gworld.height)
				Manager.C_STONE;
			else
				man.map[x][y];
	}
	
	public function toString() {
		return type+"@"+mx+","+my+" stable="+fl_stable+" dx="+dx+" dy="+dy;
	}
	
	public function die() {
		if(fl_dead)
			return;
			
		fl_dead = true;
		
		if(type==ET_Player) {
			setVis(false);
			man.onPlayerDeath();
		}
		else {
			if(spr!=null && spr.parent!=null)
				spr.parent.removeChild(spr);
			if(niceSpr!=null && niceSpr.parent!=null)
				niceSpr.parent.removeChild(niceSpr);
			man.entities.remove(this);
		}
		if(lastTalk!=null && lastTalk.parent!=null)
			lastTalk.parent.removeChild(lastTalk);
	}
	
	public function say(msg:String, ?fl_force=false) {
		if(lastTalk!=null && !fl_force)
			return;
		var mc = new interf.Talk();
		mc.field.text = msg;
		var tf = new flash.text.TextFormat();
		//tf.size = if(msg.length>=8) 12 else 20;
		mc.field.setTextFormat(tf);
		mc.alpha = 0;
		mc.filters = [
			new flash.filters.GlowFilter(0x0,0.8, 2,2, 4),
			new flash.filters.GlowFilter(0x0,0.6, 4,4, 2),
		];
		Manager.TW.create(mc, "alpha", 1, TEaseOut, 400);
		var me = this;
		haxe.Timer.delay(
			function() {
				Manager.TW.create(mc, "alpha", 0, TEase, 1000).onEnd = function() {
					if(mc.parent!=null)
						mc.parent.removeChild(mc);
					me.lastTalk = null;
				}
			}, 1000 + msg.length*50 );
		man.root.addChild(mc);
		lastTalk = mc;
		updateLastTalkPos();
	}
	
	inline function updateLastTalkPos() {
		if(spr!=null && lastTalk!=null) {
			lastTalk.x = spr.x * Manager.UPSCALE - 54;
			lastTalk.y = spr.y * Manager.UPSCALE - 12 * Manager.UPSCALE - lastTalk.field.textHeight;
		}
	}
	
	public function getPixelHit(x, y) {
		if(x>0 && y>0 && x<man.buffer.width && y<man.buffer.height)
			return man.sworld.getPixel32(x, y);
		else
			return getCase(man.viewPort.x+Std.int(x/8), man.viewPort.y+Std.int(y/8));
	}
	
	public function lock() {
		dx = 0;
		stun = 999999;
		spr.stopAnim(0);
		if(niceSpr!=null)
			niceSpr.stopAnim(0);
	}
	
	public function unlock() {
		stun = 0;
	}
	
	public function microJump(d) {
		dx = 1*d;
		dy = -0.5;
		var me = this;
		haxe.Timer.delay(function() {
			me.dx = 0;
		},200);
	}
	
	public inline function isNear(x,y, ?maxDist=5) {
		var d = (mx-x)*(mx-x) + (my-y)*(my-y);
		if(d<=maxDist*maxDist)
			return Math.sqrt(d)<=maxDist;
		else
			return false;
	}
	
	public function setVis(b:Bool) {
		spr.visible = b;
		if(niceSpr!=null)
			niceSpr.visible = b;
		if(lastTalk!=null)
			lastTalk.visible = b;
	}
	
	public function update() {
		if(fl_dead)
			return;
		if(stun>0)
			stun--;

		// hors-écran
		if( type!=ET_Player && !fl_object && !man.viewPort.contains(mx,my) ) {
			setVis(false);
			fl_outOfSight = true;
			return;
		}
		else {
			if(fl_outOfSight)
				setVis(true);
			fl_outOfSight = false;
		}
		
		var sx = gx-man.viewPort.x*8;
		var sy = gy-man.viewPort.y*8;
		if( getPixelHit(sx, sy+1)==0 ) {
			fl_stable = false;
			dy += 0.25;
		}
		
		if(stun<=0)
			dx*=frictX;
		if(dx>-dcutOff && dx<dcutOff)		dx = 0;
		dy*=frictY;
		if(dy>-dcutOff && dy<dcutOff)		dy = 0;

		var ymoves = Math.abs(dy);
		var idy = if(dy>0) 1 else if(dy<0) -1 else 0;
		while(ymoves>0) {
			//trace(sy+" idy="+idy);
			if( dy>0 && getPixelHit(sx, sy+idy)!=0 ) {
				// atterrissage
				ymoves = 0;
				dy = 0;
				fl_stable = true;
			}
			if( dy<0 && getPixelHit(sx, sy+idy)!=0 ) {
				var stepY = man.getHighestY(man.sworld, sx, sy+idy, 7);
				if(sy+idy-stepY<7) {
					sy = stepY;
					gy = sy+man.viewPort.y*8;
				}
				else {
					ymoves = 0;
					dy=0;
				}
			}
			if(ymoves>0) {
				sy+=idy;
				gy+=idy;
			}
			ymoves--;
		}

		var xmoves = Math.abs(dx);
		var idx = if(dx>0) 1 else if(dx<0) -1 else 0;
		while(xmoves>0) {
			if(getPixelHit(sx+idx, sy)!=0) {
				var max = 5;
				var stepY = man.getHighestY(man.sworld, sx+idx, sy, max);
				if(sy-stepY<max) {
					// recal
					sy = stepY;
					gy = sy+man.viewPort.y*8;
				}
				else {
					// blocage
					xmoves = 0;
					dx = 0;
				}
			}
			if(xmoves>0) {
				sx+=idx;
				gx+=idx;
			}
			xmoves--;
		}
		
		spr.x = sx;
		spr.y = sy+1;
		if(niceSpr!=null) {
			niceSpr.x = spr.x;
			niceSpr.y = spr.y;
		}
		mx = Std.int(gx/8);
		my = Std.int(gy/8);

		if( fl_stable && getCase(mx,my+1)==Manager.C_WATER ) {
			var s = man.tiles.getSprite("water");
			s.playAnim("water",1);
			s.x = spr.x;
			s.y = spr.y;
			s.fl_killOnEndPlay = true;
			man.buffer.addChild( s );
			die();
		}

		
		if(this==man.player) {
			// joueur
			#if debug
			man.debugField.text = mx+","+my+" d="+Std.int(dx*100)/100+","+Std.int(dy*100)/100;
			#end
			var xmargin = 40;
			var ymargin = 30;
			if(sx<=xmargin)
				man.refocus(-1,0);
			if(sx>=man.buffer.width-xmargin)
				man.refocus(1,0);
			if(sy<=ymargin)
				man.refocus(0, 0.5);
			if(sy>=man.buffer.height-ymargin)
				man.refocus(0, 0.5);
		}
		else {
			var player = man.player;
			if(Math.abs(mx-player.mx)<2 && Math.abs(my-player.my)<2) {
				var d = Math.sqrt((spr.x-player.spr.x)*(spr.x-player.spr.x) + (spr.y-player.spr.y)*(spr.y-player.spr.y));
				if(d<=6)
					man.onHitPlayer(this);
			}
			if(type==ET_Zombie && man.drug==0 && Std.random(1000)<5)
				say( Manager.TXT_ZOMBIES[Std.random(Manager.TXT_ZOMBIES.length) ] );
		}
		
		if(lastTalk!=null)
			updateLastTalkPos();
	}
}

