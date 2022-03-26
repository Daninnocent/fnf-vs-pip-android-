package ui;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

import ui.FlxVirtualPad;
import ui.Hitbox;

import Config;

// i know this is stupid but every method i thought of just crashes :(

class DodgeControls extends FlxSpriteGroup
{
	public var mode:ControlsGroup1 = HITBOX;

	public var __hitbox:Hitbox;
	public var __virtualPad:FlxVirtualPad;

	var config:Config;

	public function new() 
	{
		super();
		
		config = new Config();

		// load control mode num from Config.hx
		mode = getModeFromNumber(config.getcontrolmode());
		trace(config.getcontrolmode());

		switch (mode)
		{
			case VIRTUALPAD_RIGHT:
				initVirtualPad(0);
			case VIRTUALPAD_LEFT:
				initVirtualPad(1);
			case VIRTUALPAD_CUSTOM:
				initVirtualPad(2);
			case HITBOX:
				__hitbox = new Hitbox(DODGE);
				add(__hitbox);
			case KEYBOARD:
		}
	}

	function initVirtualPad(vpadMode:Int) 
	{
		switch (vpadMode)
		{
			case 1:
					__virtualPad = new FlxVirtualPad(FULL, A);
				
			case 2:
				__virtualPad = new FlxVirtualPad(FULL, A);
				__virtualPad = config.loadcustom(__virtualPad);
			default: // 0
				__virtualPad = new FlxVirtualPad(RIGHT_FULL, A);
		}
		
		__virtualPad.alpha = 0.75;
		add(__virtualPad);	
	}


	public static function getModeFromNumber(modeNum:Int):ControlsGroup1 {
		return switch (modeNum)
		{
			case 0: VIRTUALPAD_RIGHT;
			case 1: VIRTUALPAD_LEFT;
			case 2: KEYBOARD;
			case 3: VIRTUALPAD_CUSTOM;
			case 4:	HITBOX;

			default: VIRTUALPAD_RIGHT;

		}
	}
}

enum ControlsGroup1 {
	VIRTUALPAD_RIGHT;
	VIRTUALPAD_LEFT;
	KEYBOARD;
	VIRTUALPAD_CUSTOM;
	HITBOX;
}