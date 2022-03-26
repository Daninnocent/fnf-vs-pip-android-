package ui;

import flixel.graphics.FlxGraphic;
import flixel.addons.ui.FlxButtonPlus;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.util.FlxDestroyUtil;
import flixel.ui.FlxButton;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.ui.FlxVirtualPad;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

// copyed from flxvirtualpad
class Hitbox extends FlxSpriteGroup
{
	public var hitbox:FlxSpriteGroup;

	var sizex:Int = 320;

	var screensizey:Int = 720;

	var frameshb:FlxAtlasFrames;

	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonDodge:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;
	
	public function new(type:HitboxType = DEFAULT)
	{
		super();

		trace(type);
		
		//add graphic
		hitbox = new FlxSpriteGroup();
		hitbox.scrollFactor.set();

        var hitbox_hint:FlxSprite = new FlxSprite(0, 0);
        hitbox_hint.alpha = 0.3;
        add(hitbox_hint);

		buttonLeft = new FlxButton(0, 0);
        buttonDown = new FlxButton(0, 0);
		buttonDodge = new FlxButton(0, 0);
        buttonUp = new FlxButton(0, 0);
        buttonRight = new FlxButton(0, 0);

		switch (type){
			default:
			{
				hitbox_hint.loadGraphic('assets/shared/images/hitbox/hitbox_hint.png');
		
				frameshb = FlxAtlasFrames.fromSparrow('assets/shared/images/hitbox/hitbox.png', 'assets/shared/images/hitbox/hitbox.xml');
		
				hitbox.add(add(buttonLeft = createhitbox(0, "left")));
				hitbox.add(add(buttonDown = createhitbox(320, "down")));
				hitbox.add(add(buttonUp = createhitbox(320 * 2, "up")));
				hitbox.add(add(buttonRight = createhitbox(320 * 3, "right")));
			}
			case DODGE:
			{
				hitbox_hint.loadGraphic('assets/shared/images/hitbox/hitbox_hint_pip.png');
		
				frameshb = FlxAtlasFrames.fromSparrow('assets/shared/images/hitbox/hitbox_pip.png', 'assets/shared/images/hitbox/hitbox_pip.xml');
		
				hitbox.add(add(buttonLeft = createhitbox(0, "left")));
				hitbox.add(add(buttonDown = createhitbox(320, "down")));
				hitbox.add(add(buttonDodge = createhitbox(542, "dodge")));
				hitbox.add(add(buttonUp = createhitbox(736, "up")));
				hitbox.add(add(buttonRight = createhitbox(960, "right")));
			}

	    }

	}

	public function createhitbox(X:Float, framestring:String) {
		var button = new FlxButton(X, 0);
		
		var graphic:FlxGraphic = FlxGraphic.fromFrame(frameshb.getByName(framestring));

		button.loadGraphic(graphic);

		button.alpha = 0;

	
		button.onDown.callback = function (){
			FlxTween.num(0, 0.75, .075, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		};

		button.onUp.callback = function (){
			FlxTween.num(0.75, 0, .1, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		}
		
		button.onOut.callback = function (){
			FlxTween.num(button.alpha, 0, .2, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		}

		return button;
	}

	override public function destroy():Void
		{
			super.destroy();
	
			buttonLeft = null;
			buttonDown = null;
			buttonUp = null;
			buttonRight = null;
		}
}

enum HitboxType {
    DEFAULT;
    DODGE;
}