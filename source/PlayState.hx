package;

import haxe.macro.Expr.Function;
import flixel.util.FlxGradient;
import flixel.graphics.frames.FlxFrame;
import haxe.macro.Compiler.IncludePosition;
import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.Shader;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import ui.Mobilecontrols;
import ui.DodgeControls;
// import Shaders;

import Sys;
import sys.FileSystem;
import openfl.Assets;
import sys.io.File;


using StringTools;

class PlayState extends MusicBeatState
{
	#if mobileC
	var mcontrols:Mobilecontrols; 
	var dcontrols:DodgeControls; 
	#end


	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	// public var shader_chromatic_abberation:ChromaticAberrationEffect;
	// public var camGameShaders:Array<ShaderEffect> = [];
	// public var camHUDShaders:Array<ShaderEffect> = [];
	// public var camOtherShaders:Array<ShaderEffect> = [];
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	var boyfriendCamPos:Int = 100;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var dadanim_x:Float = 613.8;
	public var dadanim_y:Float = 173.95;

	var amongusDrip:FlxSprite;
	public var dadanim:FlxSprite = new FlxSprite();
	var exDad:Bool = false;
	var cutscenebg:FlxSprite; // so cutscene is skipable
	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var shaderUpdates:Array<Float->Void> = [];
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;
	public var boyfriend_extra:Character;
	public var dad2:Character;

	// static var playedAnim:Int = 0;
	var startSoon = false;
	var flashMovement = false;
	public var notes:FlxTypedGroup<Note>;
	//public var spaceNotes:FlxTypedGroup<FlxSprite>;

	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	// LAST SAVED SHIT xd
	private static var lastSavedHealth:Float = 1;
	private static var lastSavedScore:Int = 0;
	private static var lastSavedMisses:Int = 0;
	private static var lastSavedPercent:Float = 0.0;
	private static var lastSavedRating:String = "";
	private static var lastSavedFC:String = '';

	private static var lastSavedScoretxt:String = "";

	private static var fuckCutscene:Bool = false;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public static var mania:Int = 0;

	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	private var daninnocentTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camcontrol:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;
	var completedVideo = false;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';
	public static var gameOverStateChanged = false;

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Array<Dynamic>>;

	var vCutsce:BGSprite;
	// pip death background
	var blackScreenOfPip:FlxSprite;
	var pipAudio:FlxSound;

	override public function create()
	{
		Paths.clearStoredMemory();


		keysArray = Keybinds.fill();

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray[mania].length)
		{
			keysPressed.push(false);
		}

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		Achievements.loadAchievements();

	

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// shader_chromatic_abberation = new ChromaticAberrationEffect();

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camcontrol = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camcontrol.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		FlxG.cameras.add(camcontrol);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;
		
		mania = SONG.mania;
		if (mania < Note.minMania || mania > Note.maxMania)
			mania = Note.defaultMania;


		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		//trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'pip' | 'fuck' | 'cray-cray':
					curStage = 'alleyways';
				default:
					curStage = 'stage';
			}
		}

		// FIX SCORETXT BUG
		if (SONG.song.toLowerCase() == 'fuck' && isStoryMode && !seenCutscene)
			fuckCutscene = true;
		else
			fuckCutscene = false;


		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
			case 'alleyways': // week pip stage NOW with low quality support

				pipAudio = new FlxSound();
				pipAudio = FlxG.sound.load(Paths.sound('Pip_Cutscene_Audio', 'main'));
		
				// if(!ClientPrefs.lowQuality) {
				// 	var bg:BGSprite = new BGSprite('bgs/Sky', -287.6, -91.95, 0.9, 0.9);
				// 	bg.antialiasing = ClientPrefs.globalAntialiasing;
				// 	add(bg);
				
				// 	var city:BGSprite = new BGSprite('bgs/City', -275.05, -37.45, 0.9, 0.9);
				// 	city.antialiasing = ClientPrefs.globalAntialiasing;
				// 	add(city);
				// }
				// else
					// {
						var bg:BGSprite = new BGSprite('bgs/LowQualityBg', -287.6, -91.95, 0.9, 0.9);
						bg.antialiasing = false;
						add(bg);
					// }

				// if (!ClientPrefs.lowQuality){
				// 	var stagefront:BGSprite = new BGSprite('bgs/Street', -307.55, -0.4, 0.9, 0.9);
				// 	stagefront.antialiasing = ClientPrefs.globalAntialiasing;
				// 	add(stagefront);
				// }

				var stageAlleyway:BGSprite = new BGSprite('bgs/Alleyway', -307.55, -0.4, 1, 1);
				stageAlleyway.antialiasing = ClientPrefs.globalAntialiasing;
				add(stageAlleyway);

				// if(!ClientPrefs.lowQuality) {
				// 	var stageLights:BGSprite = new BGSprite('bgs/stageLights', -307.55, -0.4, 1, 1); // fixed these ddamn lights!
				// 	stageLights.antialiasing = ClientPrefs.globalAntialiasing;
				// 	add(stageLights);
				// }

				GameOverSubstate.deathSoundName = 'fnf_loss_sfx';
				GameOverSubstate.loopSoundName = 'death_by_the_swag';
				GameOverSubstate.endSoundName = 'gameOverEnd';
				GameOverSubstate.characterName = 'bf'; 

			if(!ClientPrefs.lowQuality) {
				vCutsce = new BGSprite('optimized-cutscene-a', -300, -160, 0.0, 0.0, ['cutscene']);
				vCutsce.animation.addByPrefix('idle', 'cutscene', 14, false);
				vCutsce.antialiasing = ClientPrefs.globalAntialiasing;
				vCutsce.setGraphicSize(1920, 1080);
				vCutsce.updateHitbox();
				// garcello type of optimization lol -Daninnocent
			}
			else
			{
				vCutsce = new BGSprite('brb', 0,0, 0.0, 0.0);
				vCutsce.antialiasing = ClientPrefs.globalAntialiasing;
				vCutsce.setGraphicSize(1920, 1080);
				vCutsce.updateHitbox();
				vCutsce.screenCenter();
			}

			if (SONG.song.toLowerCase() == 'cray cray'){
				blackScreenOfPip = new BGSprite('bgs/meWhen', -287.6, -51.95, 1, 1);
				blackScreenOfPip.alpha = 0;
				add(blackScreenOfPip);
			}

			// doing this because it's laggy af in android lmao -Daninnocent

				
				CoolUtil.precacheSound('pipdies', 'main');
				CoolUtil.precacheSound('bfgetshotanddies');
				CoolUtil.precacheSound('Pip_Cutscene_Audio', 'main');

			case 'spooky': //Week 2
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				CoolUtil.precacheSound('thunder_1');
				CoolUtil.precacheSound('thunder_2');

			case 'philly': //Week 3
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}
				
				//addShaderToCamera('game', chromAb);
				//chromAb.setChrome(0.01);

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyCityLights = new FlxTypedGroup<BGSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:BGSprite = new BGSprite('philly/win' + i, city.x, city.y, 0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					phillyCityLights.add(light);
				}

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				CoolUtil.precacheSound('train_passes');
				FlxG.sound.list.add(trainSound);

				var street:BGSprite = new BGSprite('philly/street', -40, 50);
				add(street);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					CoolUtil.precacheSound('dancerdeath');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				CoolUtil.precacheSound('Lights_Shut_off');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/
				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		if(!ClientPrefs.nodad){
		add(dadGroup);
		}
		add(boyfriendGroup);
		
		if(curStage == 'spooky') {
			add(halloweenWhite);
		}
		if (SONG.song.toLowerCase() == 'cray cray'){
			add(vCutsce);
		
			// dad2.visible = true; 

			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				vCutsce.visible = false;
				// dad2.visible = false; 
			});

			// precache stuff
		}
		



		

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if(curStage == 'philly') {
			phillyCityLightsEvent = new FlxTypedGroup<BGSprite>();
			for (i in 0...5)
			{
				var light:BGSprite = new BGSprite('philly/win' + i, -10, 0, 0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				phillyCityLightsEvent.add(light);
			}
		}


		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		

		// STAGE SCRIPTS
		var doPush:Bool = false;
		if(openfl.utils.Assets.exists("assets/stages/" + curStage + ".lua"))
		{
			var path = Paths.luaAsset("stages/" + curStage);
			var luaFile = openfl.Assets.getBytes(path);

			FileSystem.createDirectory(Main.path + "assets");
			FileSystem.createDirectory(Main.path + "assets/stages");

			File.saveBytes(Paths.lua("stages/" + curStage), luaFile);

			doPush = true;
		}

		if(doPush) 
			luaArray.push(new FunkinLua(Paths.lua("stages/" + curStage)));

		if(!modchartSprites.exists('blammedLightsBlack')) { //Creates blammed light black fade in case you didn't make your own
			blammedLightsBlack = new ModchartSprite(FlxG.width * -0.5, FlxG.height * -0.5);
			blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
			var position:Int = members.indexOf(gfGroup);
			if(members.indexOf(boyfriendGroup) < position) {
				position = members.indexOf(boyfriendGroup);
			} else if(members.indexOf(dadGroup) < position) {
				position = members.indexOf(dadGroup);
			}
			insert(position, blammedLightsBlack);

			blammedLightsBlack.wasAdded = true;
			modchartSprites.set('blammedLightsBlack', blammedLightsBlack);
		}
		if(curStage == 'philly') insert(members.indexOf(blammedLightsBlack) + 1, phillyCityLightsEvent);
		blammedLightsBlack = modchartSprites.get('blammedLightsBlack');
		blammedLightsBlack.alpha = 0.0;

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		gf = new Character(0, 0, gfVersion);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		startCharacterLua(gf.curCharacter);
		
		if (SONG.song.toLowerCase() == 'cray cray') exDad = true;

		if (exDad){
			dad2 = new Character(202.9, 395.55, "violet");
			dad2.setGraphicSize(326, 463);
			//dad2.setGraphicSize(Std.int(dad2.width * 1.07));
			gfGroup.add(dad2);
			dad2.visible = false;
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		
		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			gf.visible = false;
		}
		if (dad.curCharacter == "pimposter"){
				//dad.setGraphicSize(572, 327);
				dad.x -= 250;
				dad.y += 130;
		}
		if (dad.curCharacter == "pip")
			dad.setGraphicSize(320, 490);


		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
			
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				insert(members.indexOf(dadGroup) - 1, evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;



		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		if (SONG.song.toLowerCase() == 'fuck' && isStoryMode && !seenCutscene)
			{
				timeTxt.text = "0:00";
				
				if(ClientPrefs.timeBarType == 'Song Name')
					{
						timeTxt.text = 'Pip';
					}
				songPercent = 1;
				timeBar.alpha = 1;
				timeTxt.alpha = 1;
			}

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

									





		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var doPush:Bool = false;
			if(openfl.utils.Assets.exists("assets/custom_notetypes/" + notetype + ".lua"))
			{
				var path = Paths.luaAsset("custom_notetypes/" + notetype);
				var luaFile = openfl.Assets.getBytes(path);
		
				FileSystem.createDirectory(Main.path + "assets");
				FileSystem.createDirectory(Main.path + "assets/custom_notetypes");
		
				File.saveBytes(Paths.lua("custom_notetypes/" + notetype), luaFile);
		
				doPush = true;
			}
			if (doPush)
			    luaArray.push(new FunkinLua(Paths.lua("custom_notetypes/" + notetype)));
		}
		for (event in eventPushedMap.keys())
		{
			var doPush:Bool = false;
			if(openfl.utils.Assets.exists("assets/custom_events/" + event + ".lua"))
			{
				var path = Paths.luaAsset("custom_events/" + event);
				var luaFile = openfl.Assets.getBytes(path);
		
				FileSystem.createDirectory(Main.path + "assets");
				FileSystem.createDirectory(Main.path + "assets/custom_events");
		
				File.saveBytes(Paths.lua("custom_events/" + event), luaFile);
		
				doPush = true;
			}
			if (doPush)
			    luaArray.push(new FunkinLua(Paths.lua("custom_events/" + event)));
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		if ((SONG.song != 'fuck') && isStoryMode)
			moveCameraSection(0);

		if (!isStoryMode)
			moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);

		daninnocentTxt = new FlxText(876, 648, 348);
        daninnocentTxt.text = "PORTED BY DANINNOCENT";
        daninnocentTxt.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        daninnocentTxt.scrollFactor.set();
        add(daninnocentTxt);

		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		if(ClientPrefs.downScroll) {
			daninnocentTxt.y = 148;
		}

		// holy shit daninnocent watermark downscroll support?!?!?!?!?

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		//spaceStatic.cameras = [camHUD];
		//spaceNotes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		daninnocentTxt.cameras = [camHUD];

		// less mem is used when low quality 
		if (SONG.song.toLowerCase() == 'pussy'){
			amongusDrip = new FlxSprite(0,0).loadGraphic(Paths.image('AmongDrip', 'main'));
			amongusDrip.antialiasing = true;	
			amongusDrip.alpha = 0;
			amongusDrip.updateHitbox();
			add(amongusDrip);
			amongusDrip.cameras = [camHUD];
		}

		#if mobileC
		mcontrols = new Mobilecontrols();
		switch (mcontrols.mode)
		{
			case VIRTUALPAD_RIGHT | VIRTUALPAD_LEFT | VIRTUALPAD_CUSTOM:
				controls.setVirtualPad(mcontrols._virtualPad, FULL, NONE);
			case HITBOX:
				controls.setHitBox(mcontrols._hitbox);
			default:
		}
		var trackedinputs = controls.trackedinputs;
		controls.trackedinputs = [];

		mcontrols.cameras = [camcontrol];

		mcontrols.visible = false;

		add(mcontrols);

		dcontrols = new DodgeControls();
		switch (dcontrols.mode)
		{
			case VIRTUALPAD_RIGHT | VIRTUALPAD_LEFT | VIRTUALPAD_CUSTOM:
				controls.setVirtualPad(dcontrols.__virtualPad, FULL, A);
			case HITBOX:
				controls.setHitBox(dcontrols.__hitbox);
			default:
		}

		dcontrols.cameras = [camcontrol];

		dcontrols.visible = false;

		add(dcontrols);
	    #end

		// _hitbox = new Hitbox(DODGE);

		// var camcontrol = new FlxCamera();
		// FlxG.cameras.add(camcontrol);
		// camcontrol.bgColor.alpha = 0;
		// _hitbox.cameras = [camcontrol];

		// _hitbox.visible = false;
		
		// add(_hitbox);


		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var doPush:Bool = false;

		if(openfl.utils.Assets.exists("assets/data/" + Paths.formatToSongPath(SONG.song) + "/" + "script.lua"))
		{
			var path = Paths.luaAsset("data/" + Paths.formatToSongPath(SONG.song) + "/" + "script");
			var luaFile = openfl.Assets.getBytes(path);

			FileSystem.createDirectory(Main.path + "assets");
			FileSystem.createDirectory(Main.path + "assets/data");
			FileSystem.createDirectory(Main.path + "assets/data/");
			FileSystem.createDirectory(Main.path + "assets/data/" + Paths.formatToSongPath(SONG.song));

			File.saveBytes(Paths.lua("data/" + Paths.formatToSongPath(SONG.song) + "/" + "script"), luaFile);

			doPush = true;
		}
		if(doPush) 
			luaArray.push(new FunkinLua(Paths.lua("data/" + Paths.formatToSongPath(SONG.song) + "/" + "script")));

		#end
		
		var daSong:String = Paths.formatToSongPath(curSong);

		if (!seenCutscene)
		{
			switch (daSong)
			{
				case "pip": // rip the old first cutscene
					startSoon = true;
					startCountdown();

				case "fuck": // FUNNICUTSCENE
				if (isStoryMode){
					FlxG.camera.zoom = defaultCamZoom;
					generateStaticArrows(0);
					generateStaticArrows(1);

					timeBarBG.visible = showTime;
					timeBar.visible = showTime;
					timeTxt.visible = showTime;
					timeTxt.text = "0:00";
								
				if(ClientPrefs.timeBarType == 'Song Name')
					{
						timeTxt.text = 'Pip';
					}

					health = lastSavedHealth;
					scoreTxt.text = lastSavedScoretxt;
					trace(lastSavedScoretxt);

					
					inCutscene = true;
					isCameraOnForcedPos = true;

					//fakebops
					new FlxTimer().start(0.58, function(fuckingtmr:FlxTimer) {
					
						if (!gf.specialAnim)
						{			
						gf.dance();
						}
						if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
						{
							boyfriend.dance();
						}
					},8);

					dad.playAnim('idle');
		
					pipAudio.play();

					var partType:Int = -1;
					var time:Float = 0.01; 
					var stepsLmao = 0;
						 
					new FlxTimer().start(time, function(tmr:FlxTimer) // better code i think, its less clunky and much smaller
						{
							trace(pipAudio.time +" da millsecond in pippy time!!");
							if (pipAudio.time >= 1800 && partType == -1) // da audio check so no delay or whatever
								partType = 0;

							switch(partType){
							case 0:
								FlxTween.tween(camHUD, {alpha: 0}, 0.6, {ease: FlxEase.quadInOut, onComplete: function (loltween:FlxTween) {
									camHUD.visible = false;
								}});

								FlxTween.tween(camFollow, {x: dad.getMidpoint().x + 320, y: dad.getMidpoint().y + 50}, 1.1, {ease: FlxEase.quadInOut});
								FlxTween.tween(camFollowPos, {x: dad.getMidpoint().x + 320, y: dad.getMidpoint().y + 50}, 1.1, {ease: FlxEase.quadInOut});
								FlxTween.tween(FlxG.camera, {zoom: 1.1}, 1, {ease: FlxEase.quadInOut});
								dad.playAnim('Cutscene');
								partType++;
								tmr.reset(2.4);
							case 1:
								if (stepsLmao != 1){ 
								FlxTween.tween(camFollow, {x: gf.getMidpoint().x - 80, y: gf.getMidpoint().y - 10}, 1.2, {ease: FlxEase.quadOut});
								FlxTween.tween(camFollowPos, {x: gf.getMidpoint().x - 80, y: gf.getMidpoint().y - 10}, 1.2, {ease: FlxEase.quadOut});
								FlxTween.tween(FlxG.camera, {zoom: 1.2}, 1, {ease: FlxEase.quadInOut});
								gf.playAnim('cutscene', true);
								gf.specialAnim = true;
								stepsLmao++;
								}
									
						if (!gf.animation.finished && gf.animation.curAnim.name == 'cutscene')
							{
								trace("animation loop");
								tmr.reset(0.01);
					
								switch(gf.animation.curAnim.curFrame)
								{
								case 41:
								partType++;
								timeBar.alpha = 1;
								timeTxt.alpha = 1;
								timeTxt.text = "2:20";
											
								if(ClientPrefs.timeBarType == 'Song Name')
									{
										timeTxt.text = 'Pip';
									}
								health = 1;
								FlxTween.tween(this, {songPercent: 0}, .25);
								}
								}
							else
								{
									tmr.reset(0.01);
								}
							case 2:
								startSoon = true;
								skipCountdown = true;
								inCutscene = !inCutscene;
								ratingName = '?';
								scoreTxt.text = 'Score: ' + '0' + ' | Misses: ' + '0' + ' | Rating: ' + ratingName;

								startCountdown();
							}
								if (partType == -1)
									tmr.reset(0.01);

							});
							
						}
						else
							startCountdown();

				case "cray-cray":
				    if (isStoryMode){
					startVideo('shoot-new');
					} else {
						startCountdown();
					}
	
				case "pussy": // also fixed werid cam
					FlxG.camera.zoom = .9;
					defaultCamZoom = .9;
					camHUD.visible = false;
					inCutscene = true;
					snapCamFollowToPos(dad.getGraphicMidpoint().x + 70, dad.getGraphicMidpoint().y - 50);

					dad.visible = true;
					var daTiming = 0;
					new FlxTimer().start(0.01, function(tmr:FlxTimer)
						{
							if (daTiming == 0){
								FlxG.camera.zoom = 1.2;
								dad.playAnim('Vent', true);
							}

							if (daTiming <= 17)
								{
									if (dad.animation.curAnim.curFrame >= 7)
										{
											dad.playAnim('Vent', true);
										}
								}

							if (daTiming == 15)
								FlxG.sound.play(Paths.sound('ventt'), 2.3);


							if (daTiming >= 37){
								camHUD.visible = true;
								startCountdown();
							}
							daTiming++;

							tmr.reset(0.01);
						});


							
		
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				

				default:
					startCountdown();
			}
			if (daSong != 'fuck' && daSong != 'pussy')
				seenCutscene = true;
	

		} else {
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');


		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		// if(!ClientPrefs.controllerMode)
		// {
		// 	FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		// 	FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		// }

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);
		
		super.create();

		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(!gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		// #if LUA_ALLOWED
		// var doPush:Bool = false;
		// var luaFile:String = 'characters/' + name + '.lua';
		// if(FileSystem.exists(Paths.modFolders(luaFile))) {
		// 	luaFile = Paths.modFolders(luaFile);
		// 	doPush = true;
		// } else {
		// 	luaFile = Paths.getPreloadPath(luaFile);
		// 	if(FileSystem.exists(luaFile)) {
		// 		doPush = true;
		// 	}
		// }
		
		// if(doPush)
		// {
		// 	for (lua in luaArray)
		// 	{
		// 		if(lua.scriptName == luaFile) return;
		// 	}
		// 	luaArray.push(new FunkinLua(luaFile));
		// }
		// #end
	}

	
	
//   public function addShaderToCamera(cam:String,effect:ShaderEffect){//STOLE FROM ANDROMEDA
	  
	  
	  
// 		switch(cam.toLowerCase()) {
// 			case 'camhud' | 'hud':
// 					camHUDShaders.push(effect);
// 					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
// 					for(i in camHUDShaders){
// 					  newCamEffects.push(new ShaderFilter(i.shader));
// 					}
// 					camHUD.setFilters(newCamEffects);
// 			case 'camother' | 'other':
// 					camOtherShaders.push(effect);
// 					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
// 					for(i in camOtherShaders){
// 					  newCamEffects.push(new ShaderFilter(i.shader));
// 					}
// 					camOther.setFilters(newCamEffects);
// 			case 'camgame' | 'game':
// 					camGameShaders.push(effect);
// 					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
// 					for(i in camGameShaders){
// 					  newCamEffects.push(new ShaderFilter(i.shader));
// 					}
// 					camGame.setFilters(newCamEffects);
// 			default:
// 				if(modchartSprites.exists(cam)) {
// 					Reflect.setProperty(modchartSprites.get(cam),"shader",effect.shader);
// 				} else if(modchartTexts.exists(cam)) {
// 					Reflect.setProperty(modchartTexts.get(cam),"shader",effect.shader);
// 				} else {
// 					var OBJ = Reflect.getProperty(PlayState.instance,cam);
// 					Reflect.setProperty(OBJ,"shader", effect.shader);
// 				}
			
			
				
				
// 		}
	  
	  
	  
	  
//   }

//   public function removeShaderFromCamera(cam:String,effect:ShaderEffect){
	  
	  
// 		switch(cam.toLowerCase()) {
// 			case 'camhud' | 'hud': 
//     camHUDShaders.remove(effect);
//     var newCamEffects:Array<BitmapFilter>=[];
//     for(i in camHUDShaders){
//       newCamEffects.push(new ShaderFilter(i.shader));
//     }
//     camHUD.setFilters(newCamEffects);
// 			case 'camother' | 'other': 
// 					camOtherShaders.remove(effect);
// 					var newCamEffects:Array<BitmapFilter>=[];
// 					for(i in camOtherShaders){
// 					  newCamEffects.push(new ShaderFilter(i.shader));
// 					}
// 					camOther.setFilters(newCamEffects);
// 			default: 
// 				camGameShaders.remove(effect);
// 				var newCamEffects:Array<BitmapFilter>=[];
// 				for(i in camGameShaders){
// 				  newCamEffects.push(new ShaderFilter(i.shader));
// 				}
// 				camGame.setFilters(newCamEffects);
// 		}
		
	  
//   }
	
	
	
//   public function clearShaderFromCamera(cam:String){
	  
	  
// 		switch(cam.toLowerCase()) {
// 			case 'camhud' | 'hud': 
// 				camHUDShaders = [];
// 				var newCamEffects:Array<BitmapFilter>=[];
// 				camHUD.setFilters(newCamEffects);
// 			case 'camother' | 'other': 
// 				camOtherShaders = [];
// 				var newCamEffects:Array<BitmapFilter>=[];
// 				camOther.setFilters(newCamEffects);
// 			default: 
// 				camGameShaders = [];
// 				var newCamEffects:Array<BitmapFilter>=[];
// 				camGame.setFilters(newCamEffects);
// 		}
		
	  
//   }
	
	
	
	
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String, ?isCutscene:Bool = true):Void {
		var fileName:String = "assets/videos/" + name;
    
		var bg:FlxSprite;
		bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.cameras = [camHUD];
		add(bg);

		(new FlxVideo(fileName)).finishCallback = function() {
			remove(bg);
			startAndEnd();
		}
		if (isCutscene)
		startAndEnd();
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	var perfectMode:Bool = false;

	public function startCountdown():Void
	{
		mcontrols.visible = true;

		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (!skipCountdown){
			generateStaticArrows(0);
			generateStaticArrows(1);
			}

			if (SONG.song.toLowerCase() == 'pip' ||SONG.song.toLowerCase() == 'cray cray')
				FlxG.camera.zoom = .9;

			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;
			
			
			var random:Int = FlxG.random.int(0, 3);
			if (random == 3 && (SONG.song.toLowerCase() == 'pip'))
				{
					moveCamera(false);
					dad.y -= 600;
					dad.x -= 600;
					flashMovement = true;
				}	

			if (skipCountdown){
				Conductor.songPosition = 0;
				Conductor.songPosition -= Conductor.crochet;
				swagCounter = 3;
			}
			
			var arrayAnims:Array<String> = ['VoltzEntrance', 'GarcelloEntrance', 'RonEntrance', 'FlashEntrance'];

			if (SONG.song.toLowerCase() == 'pip'){
			startSoon = true;
			dad.stunned = true;
		}

		if (SONG.song.toLowerCase() == 'pip'){
			
			dad.playAnim(arrayAnims[random]);
			// no optimization? -Daninnocent
		}

				
		if (flashMovement)
			FlxTween.tween(dad, {x: dad.x + 600, y:  dad.y + 600}, 1, {ease: FlxEase.quadInOut});

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
		
				if (fuckCutscene && tmr.loopsLeft % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
				{
					gf.dance();
				}
				if(tmr.loopsLeft % 2 == 0) {
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
					{
						boyfriend.dance();
					}
					
					if (startSoon != true && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					{
						dad.dance();
					}
					if (!startSoon && exDad == true)
						{
							dad2.dance();
						}
				}
				else if(startSoon != true && dad.danceIdle && dad.animation.curAnim != null && !dad.stunned && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing"))
				{
					dad.dance();
					
				}

				if (exDad == true)
					{
						dad2.dance();
					}
				

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);
	
					bottomBoppers.dance(true);
					santa.dance(true);
				}
				// if (isStoryMode && SONG.song.toLowerCase() == 'fuck' && fuckCutscene)
				// 	gf.dance();

				if (dad.animation.finished && !flashMovement && SONG.song.toLowerCase() == 'pip'){
					dad.dance();
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
				
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);

			
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						if (flashMovement)						
							dad.dance();
					case 3:
						if (!skipCountdown){
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						}


						if (startSoon && skipCountdown && SONG.song.toLowerCase() == 'fuck')
							dad.playAnim('Start', true);

					case 4:
					if (SONG.song.toLowerCase() == 'pip')
						dad.stunned = false;
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if(ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha *= 0.5;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');

			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		if (SONG.song.toLowerCase() != 'fuck' && (seenCutscene || SONG.song.toLowerCase() == 'pussy')){
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}
	
		if (isStoryMode && SONG.song.toLowerCase() == 'fuck' && !seenCutscene){
		camHUD.visible = true;
		camHUD.alpha = 0;
		gf.recalculateDanceIdle();
		FlxTween.tween(camHUD, {alpha: 1}, 0.9, {ease: FlxEase.backOut, onComplete: function (twen:FlxTween) {
			opponentStrums.forEach(function(spr:StrumNote)
				{
					if (ClientPrefs.middleScroll)
					FlxTween.tween(spr, {alpha: 0.6},0.6, {ease: FlxEase.quadInOut});
				});
				seenCutscene = true;
				fuckCutscene = false;
		}});
		
		camZooming = false;
		FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1.3, {ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween) {
				camZooming = true;
			}
		});
	}
	// what the fuck
	if (SONG.song.toLowerCase() != 'fuck' && !seenCutscene)
		{
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}
		
	if (SONG.song.toLowerCase() == 'fuck' && seenCutscene)
		{
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}
	if (SONG.song.toLowerCase() == 'fuck' && !isStoryMode)
		{
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}
	


		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}
		
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));
		
		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;
		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		// #if sys
		// if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		// #else
		if (OpenFlAssets.exists(file)) {
		// #end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:Array<Dynamic> = [newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote), newEventNote[1], newEventNote[2], newEventNote[3]];
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
			{
				for (songNotes in section.sectionNotes)
				{
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % Note.ammo[mania]);
	
					var gottaHitNote:Bool = section.mustHitSection;
	
					if (songNotes[1] > (Note.ammo[mania] - 1))
					{
						gottaHitNote = !section.mustHitSection;
					}
	
					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;
	
					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
					swagNote.noteType = songNotes[3];
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
					
					swagNote.scrollFactor.set();
	
					var susLength:Float = swagNote.sustainLength;
	
					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);
	
					var floorSus:Int = Math.floor(susLength);
	
					var type = 0;
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
	
							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);
	
							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
							else if(ClientPrefs.middleScroll)
							{
								sustainNote.x += 310;
								if(daNoteData > 1) //Up and Right
								{
									sustainNote.x += FlxG.width / 2 + 25;
								}
							}
	
							
						}
					}
	
					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else if(ClientPrefs.middleScroll)
					{
						swagNote.x += 310;
						if(daNoteData > 1) //Up and Right
						{
							swagNote.x += FlxG.width / 2 + 25;
						}
					}
	
					if(!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
				}
				daBeats += 1;
			}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:Array<Dynamic> = [newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote), newEventNote[1], newEventNote[2], newEventNote[3]];
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>) {
		switch(event[1]) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event[2].toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event[2]);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event[3];
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event[1])) {
			eventPushedMap.set(event[1], true);
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[1]]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event[1]) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	function fixArrowsPos(babyArrow:StrumNote, player:Int, ?middleScrollFunni:Bool = false) // stupid way of fixing the arrow positions
		{
			if (!middleScrollFunni){
			if (player == 1 && mania == 4) // crae wants the space bar in the middle AAAAAAAAAA 
				{
			switch(babyArrow.ID)
			{
			case 0:
				babyArrow.x	= 732;
			case 1:
				babyArrow.x = 844;
			case 3:
				babyArrow.x = 956;
			case 2:
				babyArrow.x = 582;
				babyArrow.setGraphicSize(Std.int(babyArrow.width * 1.54));
			case 4:
				babyArrow.x = 1068;
			}
		}
		else if (player == 0 && mania == 4) 
			{
			switch(babyArrow.ID)
			{
			case 0:
				babyArrow.x	= 92;
			case 1:
				babyArrow.x = 204;
			case 3:
				babyArrow.x = 316;
			case 2:
				babyArrow.x = -300; // hide it lmao
				babyArrow.alpha = 1;
			case 4:
				babyArrow.x = 428;
			}	
			}
		}
		else
			{
				if (player == 1 && mania == 4) // who uses middlescroll
					{
				switch(babyArrow.ID)
				{
				case 0:
					babyArrow.x	= 412;
				case 1:
					babyArrow.x = 524;
				case 3:
					babyArrow.x = 636;
				case 2:
					babyArrow.x = 582;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 1.54));
				case 4:
					babyArrow.x = 748;
				}
			}
			else if (player == 0 && mania == 4) 
				{
				switch(babyArrow.ID)
				{
				case 0:
					babyArrow.x	= 82;
				case 1:
					babyArrow.x = 194;
				case 3:
					babyArrow.x = 971;
				case 2:
					babyArrow.x = -320; // hide it lmao
				case 4:
					babyArrow.x = 1083;
				}	
			}

			}
		}
		

	private function generateStaticArrows(player:Int):Void
		{
			for (i in 0...Note.ammo[mania])
			{
				// FlxG.log.add(i);
				var targetAlpha:Float = 1;
				if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.35;

				var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
				babyArrow.downScroll = ClientPrefs.downScroll;
				babyArrow.ID = i;

				if (babyArrow.ID == 2 && mania == 4) targetAlpha = 0;

				if (isStoryMode && SONG.song.toLowerCase() != 'fuck')
				{
					babyArrow.y -= 10;
					babyArrow.alpha = 0;
					FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

				}
				else
				{
					babyArrow.alpha = targetAlpha;					
				}
	
				if (player == 1)
				{
					playerStrums.add(babyArrow);
				}
				else
				{
					if(ClientPrefs.middleScroll)
					{
						var separator:Int = Note.separator[mania];
	
						babyArrow.x += 310;
						if(i > separator) { //Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}
					
					opponentStrums.add(babyArrow);

			
				}
				
				strumLineNotes.add(babyArrow);
				babyArrow.postAddedToGroup();
				if(!ClientPrefs.middleScroll)
				fixArrowsPos(babyArrow, player);
				else
				fixArrowsPos(babyArrow, player, true);

			}
		}
	

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = false;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{

			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = true;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = true;
			
			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/
		// weird way of skipping
		// if (FlxG.keys.justPressed.SPACE  && isStoryMode && SONG.song.toLowerCase() == 'cray cray' && inCutscene){
		// 	VideoPlayerD.finishCallback();
		// 	remove(cutscenebg);
		// 	completedVideo = true;

		// 	startAndEnd();
		// }

		callOnLuas('onUpdate', [elapsed]);

	

		switch (curStage)
		{
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if (!fuckCutscene){ // isStoryMode && SONG.song.toLowerCase() == 'fuck' && !seenCutscene

		if(ratingName == '?') {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
		} else {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
		}

	}

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (#if android FlxG.android.justReleased.BACK #end && controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}
		
				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			if (SONG.song.toLowerCase() != 'pussy') // no cheating pls
				openChartEditor();
			else{
				vocals.volume = 0;
				health -= 69; 
				doDeathCheck(true);	
			}
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}


		if (generatedMusic)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if(!daNote.mustPress) strumGroup = opponentStrums;
	
					if (mania != SONG.mania && !daNote.isSustainNote) {
						daNote.applyManiaChange();
					}
	
					if (strumGroup.members[daNote.noteData] == null) daNote.noteData = mania;
	
					var strumX:Float = strumGroup.members[daNote.noteData].x;
					var strumY:Float = strumGroup.members[daNote.noteData].y;
					var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
					var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
					var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
					var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;
					var strumHeight:Float = strumGroup.members[daNote.noteData].height;
	
					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;
	
					if (strumScroll) //Downscroll
					{
						//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
						daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					}
					else //Upscroll
					{
						//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
						daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					}
	
					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;
	
					if(daNote.copyAlpha)
						daNote.alpha = strumAlpha;
					
					if(daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
	
					if(daNote.copyY)
					{
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;
	
						//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if(strumScroll && daNote.isSustainNote)
						{
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
								if(PlayState.isPixelStage) {
									daNote.y += 8;
								} else {
									daNote.y -= 19;
								}
							} 
							daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1) * Note.scales[mania];
						}
					}
	
					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					{
						opponentNoteHit(daNote);
					}
	
					if(daNote.mustPress && cpuControlled) {
						if(daNote.isSustainNote) {
							if(daNote.canBeHit) {
								goodNoteHit(daNote);
							}
						} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
							goodNoteHit(daNote);
						}
					}
					
					var center:Float = strumY + strumHeight / 2;
					if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
						(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						if (strumScroll)
						{
							if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
	
								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
	
								daNote.clipRect = swagRect;
							}
						}
					}
	
					// Kill extremely late notes and cause misses
					if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
					{
						if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
							noteMiss(daNote);
						}
	
						daNote.active = false;
						daNote.visible = false;
	
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
	

				});
			}
		checkEventNote();

		if (!inCutscene) {
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}
		
		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime + 800 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime + 800 >= Conductor.songPosition) {
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
			if(FlxG.keys.justPressed.THREE) { 
				cpuControlled = !cpuControlled;
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		
		callOnLuas('onUpdatePost', [elapsed]);
		for (i in shaderUpdates){
			i(elapsed);
		}
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0][0];
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0][2] != null)
				value1 = eventNotes[0][2];

			var value2:String = '';
			if(eventNotes[0][3] != null)
				value2 = eventNotes[0][3];

			triggerEventNote(eventNotes[0][1], value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Blammed Lights':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				if(lightId > 0 && curLightEvent != lightId) {
					if(lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

					var color:Int = 0xffffffff;
					switch(lightId) {
						case 1: //Blue
							color = 0xff31a2fd;
						case 2: //Green
							color = 0xff31fd8c;
						case 3: //Pink
							color = 0xfff794f7;
						case 4: //Red
							color = 0xfff96d63;
						case 5: //Orange
							color = 0xfffba633;
					}
					curLightEvent = lightId;

					if(blammedLightsBlack.alpha == 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = FlxTween.color(chars[i], 1, FlxColor.WHITE, color, {onComplete: function(twn:FlxTween) {
								chars[i].colorTween = null;
							}, ease: FlxEase.quadInOut});
						}
					} else {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = null;
						blammedLightsBlack.alpha = 1;

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = null;
						}
						dad.color = color;
						boyfriend.color = color;
						gf.color = color;
					}
					
					if(curStage == 'philly') {
						if(phillyCityLightsEvent != null) {
							phillyCityLightsEvent.forEach(function(spr:BGSprite) {
								spr.visible = false;
							});
							phillyCityLightsEvent.members[lightId - 1].visible = true;
							phillyCityLightsEvent.members[lightId - 1].alpha = 1;
						}
					}
				} else {
					if(blammedLightsBlack.alpha != 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});
					}

					if(curStage == 'philly') {
						phillyCityLights.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});

						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if(memb != null) {
							memb.visible = true;
							memb.alpha = 1;
							if(phillyCityLightsEventTween != null)
								phillyCityLightsEventTween.cancel();

							phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
								phillyCityLightsEventTween = null;
							}, ease: FlxEase.quadInOut});
						}
					}

					var chars:Array<Character> = [boyfriend, gf, dad];
					for (i in 0...chars.length) {
						if(chars[i].colorTween != null) {
							chars[i].colorTween.cancel();
						}
						chars[i].colorTween = FlxTween.color(chars[i], 1, chars[i].color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
							chars[i].colorTween = null;
						}, ease: FlxEase.quadInOut});
					}

					curLight = 0;
					curLightEvent = 0;
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;
		
						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}
				case 'Trolled':
					var leTween:FlxTween = null;
					var isTransIn:Bool = true;
					var transBlack:FlxSprite;
					var transGradient:FlxSprite;
					var zoom:Float = CoolUtil.boundTo(FlxG.camera.zoom, 0.05, 1);
					var width:Int = Std.int(FlxG.width / zoom);
					var height:Int = Std.int(FlxG.height / zoom);
					transGradient = FlxGradient.createGradientFlxSprite(width, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
					transGradient.scrollFactor.set();
					add(transGradient);
			
					transBlack = new FlxSprite().makeGraphic(width, height + 400, FlxColor.BLACK);
					transBlack.scrollFactor.set();
					add(transBlack);
			
					transGradient.x -= (width - FlxG.width) / 2;
					transBlack.x = transGradient.x;
			
					if(isTransIn) {
						transGradient.y = transBlack.y - transBlack.height;
						FlxTween.tween(transGradient, {y: transGradient.height + 50}, 0.7, {
							onComplete: function(twn:FlxTween) {
								transGradient.destroy();
								transBlack.destroy();
							},
						ease: FlxEase.linear});
					} else {
						transGradient.y = -transGradient.height;
						transBlack.y = transGradient.y - transBlack.height + 50;
						leTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, 0.7, {
							onComplete: function(twn:FlxTween) {
								transGradient.destroy();
								transBlack.destroy();
							},
						ease: FlxEase.linear});
				

					}
			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf) {
									gf.visible = true;
								}
							} else {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf.curCharacter != value2) {
							if(!gfMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = gf.alpha;
							gf.alpha = 0.00001;
							gf = gfMap.get(value2);
							gf.alpha = lastAlpha;
						}
						setOnLuas('gfName', gf.curCharacter);
				}
				reloadHealthBarColors();
			
			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();
			
			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
			case 'Add ExDad': // fixed
		        if(!ClientPrefs.noexdad){
				exDad = true;
				dad2.visible = true;

				dad.setPosition(-84.4, 434.05);
				dad2.setPosition(222.9, 425.55);
				dad2.setGraphicSize(326, 463);

				iconP2.changeIcon("both"); // carlito was here

				// lolllll
				dad.x -= 6; 
				dad2.x -= 16;
				dad2.y -= 255;
				dad.y -= 170;
				}

			case "Show Space":
				if (ClientPrefs.middleScroll) trace("MOVE ARROWS MOVE");
				playerStrums.forEach(function(spr:StrumNote)
					{
						if (ClientPrefs.middleScroll){
							switch(spr.ID)
							{
								case 0:
									spr.x -= 60;
								case 1:
									spr.x -= 60;
								case 3:
									spr.x += 60;
								case 4:
									spr.x += 60;
							}
						}
						if (spr.ID == 2)
						{
							spr.y += 60;
							if (!ClientPrefs.downScroll)
							FlxTween.tween(spr, {alpha: 1, y: 50}, .3, {ease: FlxEase.circInOut});
							else
							FlxTween.tween(spr, {alpha: 1, y: 570}, .3, {ease: FlxEase.circInOut});
						}
					});

			case 'Play The Cutscene': 
				if (canPause){
					mcontrols.visible = false;
					dcontrols.visible = true;

					vocals.volume = 1;
					canPause = false;

					if (!ClientPrefs.lowQuality){
						defaultCamZoom = 0.7;
						FlxG.camera.zoom = 0.7;
					}
					if (!ClientPrefs.nomidsongcutscene){
					vCutsce.visible = true;
					}

					if (!ClientPrefs.lowQuality)
						vCutsce.animation.play('idle');
					else{
						vCutsce.alpha = 0;
						FlxTween.cancelTweensOf(vCutsce);
						FlxTween.tween(vCutsce, {alpha: 1}, 0.4, {ease: FlxEase.quadInOut});

					}


					new FlxTimer().start(2.05, function(tmr:FlxTimer)
						{
							defaultCamZoom = 1.6;
							FlxG.camera.zoom = 1.6;

							//if(!ClientPrefs.lowQuality) {
							remove(vCutsce);
						//	}
						// 	else
						// 	{
						// 	FlxTween.tween(vCutsce, {alpha: 0}, 0.4, {ease: FlxEase.quadInOut, onComplete: function(lol:FlxTween)
						// 	{
						// 		remove(vCutsce);
						// 	}
						// });

						//	}
							//gf.visible = true;
							boyfriend.playAnim('dodge');
							boyfriend.specialAnim = true;
							snapCamFollowToPos(boyfriend.getMidpoint().x + 32, boyfriend.getMidpoint().y - 80);
							isCameraOnForcedPos = true;
							boyfriendCamPos = -32;

					new FlxTimer().start(.05, function(tmr:FlxTimer)
						{
							boyfriend.specialAnim = true;
							defaultCamZoom = 1.6;

							new FlxTimer().start(0.1, function(tmr:FlxTimer)
								{
									defaultCamZoom = 0.9;

									FlxTween.cancelTweensOf(camHUD);
									FlxTween.cancelTweensOf(camcontrol);
									FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1.2, {ease: FlxEase.quadInOut, onComplete: function(twen:FlxTween)
										{
											canPause = true;
										}
									});
									FlxTween.tween(camHUD, {alpha: 1}, 0.6);
									FlxTween.tween(camcontrol, {alpha: 1}, 0.6);

									new FlxTimer().start(1.7, function(tmr:FlxTimer)
										{
								
										isCameraOnForcedPos = false;
										boyfriendCamPos = 100;

										});
								});

						});
					});
			}
		
	
			case "hidehud":
				FlxTween.cancelTweensOf(camHUD);
				FlxTween.cancelTweensOf(camcontrol);
				if (value1 != 'slow'){
				FlxTween.tween(camHUD, {alpha: 0}, 0.4);
				FlxTween.tween(camcontrol, {alpha: 0}, 0.4, {
					onComplete: function(tween:FlxTween)
					{
                       mcontrols.visible = false;
					}
				});
				} else {
				FlxTween.tween(camHUD, {alpha: 0}, 0.6);
				FlxTween.tween(camcontrol, {alpha: 0}, 0.6, {
					onComplete: function(tween:FlxTween)
					{
                       mcontrols.visible = false;
					}
				});
				}

			case "bringBackhud":
				FlxTween.cancelTweensOf(camHUD);
				FlxTween.cancelTweensOf(dcontrols);
				FlxTween.tween(camHUD, {alpha: 1}, 0.06);
				FlxTween.tween(dcontrols, {alpha: 1}, 0.06);
			case "forcedCamPos":
				isCameraOnForcedPos = !isCameraOnForcedPos;
			}
							
		
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0];
			camFollow.y += gf.cameraPosition[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
			tweenCamIn();
		}
		else
		{
			if (!isCameraOnForcedPos == false){
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}

		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		if (SONG.song.toLowerCase() == 'cray cray' && isStoryMode)
			{
				finishCallback = pipDiesOfDeath; 
			}

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();

		if (SONG.song.toLowerCase() == 'pip' && isStoryMode)
			{
				lastSavedHealth = health;

				lastSavedScore = songScore;
				lastSavedMisses = songMisses;
				lastSavedPercent = ratingPercent;
				lastSavedRating = ratingName;
				lastSavedFC = ratingFC;
				lastSavedScoretxt = 'Score: ' + lastSavedScore + ' | Misses: ' + lastSavedMisses + ' | Rating: ' + lastSavedRating + ' (' + Highscore.floorDecimal(lastSavedPercent * 100, 2) + '%)' + ' - ' + lastSavedFC;
				trace(lastSavedScoretxt);
				FlxTween.tween(FlxG.camera, {x: 0, y: 0, zoom: defaultCamZoom}, 0.55, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {
					finishCallback();
				}});

				}
				else{ // do normal end song
					if(ClientPrefs.noteOffset <= 0) {
						finishCallback();
					} else {
						finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
							finishCallback();
						});
					}
				}
				
	}
	

	public var transitioning = false;
  public function endSong():Void
	{
		#if mobileC
		mcontrols.visible = false;
		#end

		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.0475;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.0475;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}
		
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:Int = checkForAchievement([1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15]);
			if(achieve > -1) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		var ret:Dynamic = callOnLuas('onEndSong', []);

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()


						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
					cpuControlled = false;
				}
				else
				{
					var difficulty:String = '' + CoolUtil.difficultyStuff[storyDifficulty][1];

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelFadeTween();
							//resetSpriteCache = true;
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelFadeTween();
						//resetSpriteCache = true;
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
				cpuControlled = false;
			}
			transitioning = true;
		}
	}

	function pipDiesOfDeath():Void // just a copy of finish song but pip dies lmao
		{
			//Should kill you if you tried to cheat
			if(!startingSong) {
				notes.forEach(function(daNote:Note) {
					if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
						health -= 0.05 * healthLoss;
					}
				});
				for (daNote in unspawnNotes) {
					if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
						health -= 0.05 * healthLoss;
					}
				}
	
				if(doDeathCheck()) {
					return;
				}
			}
			
			timeBarBG.visible = false;
			timeBar.visible = false;
			timeTxt.visible = false;
			canPause = false;
			endingSong = true;
			camZooming = false;
			inCutscene = false;
	
			deathCounter = 0;
			seenCutscene = false;
			updateTime = false;
	
			if (curSong.toLowerCase() == 'cray cray'){
					if (exDad)
					dad2.visible = false;
	
					FlxG.camera.zoom = 0.86;
					boyfriend.visible = false;
					gf.visible = false;
	
					blackScreenOfPip.alpha = 1;
					FlxG.sound.music.volume = 0;
					dad.stunned = true;
				
					dad.playAnim('Death');
					FlxG.sound.play(Paths.sound('pipdies', 'main'), 3);
			}
	
			#if ACHIEVEMENTS_ALLOWED
			if(achievementObj != null) {
				return;
			} else {
				var achieve:String = checkForAchievement();
	
				if(achieve != null) {
					startAchievement(achieve);
					return;
				}
			}
			#end
	
			
			// #if LUA_ALLOWED
			var ret:Dynamic = callOnLuas('onEndSong', []);
			// #else
			// var ret:Dynamic = FunkinLua.Function_Continue;
			// #end
	
			if(ret != FunkinLua.Function_Stop && !transitioning) {
				if (SONG.validScore)
				{
					#if !switch
					var percent:Float = ratingPercent;
					if(Math.isNaN(percent)) percent = 0;
					Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
					#end
				}
	
				var daTimer:Float = 3; // watch him die!!!!!!!!!!
				new FlxTimer().start(daTimer, function(shitTmr:FlxTimer) {
				
	
				if (isStoryMode)
				{
					campaignScore += songScore;
					campaignMisses += songMisses;
	
					storyPlaylist.remove(storyPlaylist[0]);
	
					if (storyPlaylist.length <= 0)
					{
	
											
					if (Paths.formatToSongPath(SONG.song) == 'cray-cray' && !ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)){
						FlxG.save.data.PipModWeekCompleted = 1;
						trace("yay trophy!");
						if ((ratingFC == 'FC' || ratingFC == 'GFC' || ratingFC =='SFC')){
							trace("yay gold trophy!");
							FlxG.save.data.PipModFC = 3;
							FlxG.save.data.PipModFCedCray = true;

						}
					}

						if (Paths.formatToSongPath(SONG.song) == 'pussy' && !ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) // only if we complete it in story mode
							if (FlxG.save.data.PussyModWeekCompleted != 2) // so you dont lose the gold lmao
							FlxG.save.data.PussyModWeekCompleted = 1;
						else if (Paths.formatToSongPath(SONG.song) == 'pussy' && (ratingFC == 'FC' || ratingFC == 'GFC' || ratingFC =='SFC') && !ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
							FlxG.save.data.PussyModWeekCompleted = 2;

						FlxG.save.flush();

	
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
	
						cancelMusicFadeTween();
						if(FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}
						MusicBeatState.switchState(new StoryMenuState());
	
						// if ()
						if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
							StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
	
							if (SONG.validScore)
							{
								Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
							}
	
							FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
							FlxG.save.flush();
						}
						changedDifficulty = false;
					}
	
				
					}
				});
			}
	}
	
		

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public function healthbarshake(intensity:Float)
		{
		new FlxTimer().start(0.01, function(tmr:FlxTimer)
			{
				iconP1.y += (10 * intensity);
				iconP2.y += (10 * intensity);
				healthBar.y += (10 * intensity);
				healthBarBG.y += (10 * intensity);
			});
			new FlxTimer().start(0.05, function(tmr:FlxTimer)
			{
				iconP1.y -= (15 * intensity);
				iconP2.y -= (15 * intensity);
				healthBar.y -= (15 * intensity);
				healthBarBG.y -= (15 * intensity);
			});
			new FlxTimer().start(0.10, function(tmr:FlxTimer)
			{
				iconP1.y += (8 * intensity);
				iconP2.y += (8 * intensity);
				healthBar.y += (8 * intensity);
				healthBarBG.y += (8 * intensity);
			});
			new FlxTimer().start(0.15, function(tmr:FlxTimer)
			{
				iconP1.y -= (5 * intensity);
				iconP2.y -= (5 * intensity);
				healthBar.y -= (5 * intensity);
				healthBarBG.y -= (5 * intensity);
			});
			new FlxTimer().start(0.20, function(tmr:FlxTimer)
			{
				iconP1.y += (3 * intensity);
				iconP2.y += (3 * intensity);
				healthBar.y += (3 * intensity);
				healthBarBG.y += (3 * intensity);
			});
			new FlxTimer().start(0.25, function(tmr:FlxTimer)
			{
				iconP1.y -= (1 * intensity);
				iconP2.y -= (1 * intensity);
				healthBar.y -= (1 * intensity);
				healthBarBG.y -= (1 * intensity);
			});
		}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);


		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				score = 50;
				shits++;

				if (mania == 4 && note.noteData == 2 && !ClientPrefs.noAntimash) // anti cheat enabled
					health -= 0.2;

			case "bad": // bad
				totalNotesHit += 0.5;
				score = 100;
				bads++;

				if (mania == 4 && note.noteData == 2 && !ClientPrefs.noAntimash)
					health -= 0.1;

			case "good": // good
				totalNotesHit += 0.75;
				score = 200;
				goods++;
			case "sick": // sick
				totalNotesHit += 1;
				sicks++;
				
		}


		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			// if (mania == 4 && note.noteData == 2)
			// 	trace("nothing lmao")
			// 	else
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			songHits++;
			totalPlayed++;
			RecalculateRating();

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];


		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		var dodgeSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('Dodge'));
		dodgeSpr.setGraphicSize(343, 138);
		dodgeSpr.cameras = [camHUD];
		dodgeSpr.screenCenter();
		dodgeSpr.x = coolText.x - 30;
		dodgeSpr.y += 80;
		dodgeSpr.acceleration.y = 600;
		dodgeSpr.velocity.y -= 150;
		dodgeSpr.visible = !ClientPrefs.hideHud;
		dodgeSpr.x += ClientPrefs.comboOffset[0];
		dodgeSpr.y -= ClientPrefs.comboOffset[1];
		//dodgeSpr.setGraphicSize(Std.int(dodgeSpr.width * 0.85));
		
		if (mania == 4 && note.noteData == 2 && (daRating == 'shit' ||daRating == 'bad') && !ClientPrefs.noAntimash){
			dodgeSpr.loadGraphic(Paths.image(daRating));
			healthbarshake(1.0);
		}


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		dodgeSpr.velocity.x += FlxG.random.int(1, 10);

		if (mania == 4 && note.noteData != 2)
		insert(members.indexOf(strumLineNotes), rating);
		else if (mania != 4)
		insert(members.indexOf(strumLineNotes), rating);


		if (mania == 4 && note.noteData == 2)
			insert(members.indexOf(strumLineNotes),dodgeSpr);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
			dodgeSpr.setGraphicSize(Std.int(dodgeSpr.width * 0.2));
			dodgeSpr.antialiasing = ClientPrefs.globalAntialiasing;

			if (mania == 4 && note.noteData == 2 && (daRating == 'shit' ||daRating == 'bad') && !ClientPrefs.noAntimash){
				dodgeSpr.setGraphicSize(Std.int(rating.width * 0.7));
			}
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
			dodgeSpr.setGraphicSize(Std.int(dodgeSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		dodgeSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});
		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(dodgeSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();
				dodgeSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + fP);
	}
	
	//fuck this im using the previous engine code cuz im dumb

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + fP);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray[mania].length)
			{
				for (j in 0...keysArray[mania][i].length)
				{
					if(key == keysArray[mania][i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	private function keysArePressed():Bool
	{
		for (i in 0...keysArray[mania].length) {
			for (j in 0...keysArray[mania][i].length) {
				if (FlxG.keys.checkStatus(keysArray[mania][i][j], PRESSED)) return true;
			}
		}

		return false;
	}

	private function dataKeyIsPressed(data:Int):Bool
	{
		for (i in 0...keysArray[mania][data].length) {
			if (FlxG.keys.checkStatus(keysArray[mania][data][i], PRESSED)) return true;
		}

		return false;
	}

	private function keyShit():Void
	{
		//stolen from vs shaggy android port made by sirox lmao -Daninnocent
		 
		// vars
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down =  controls.NOTE_DOWN;
		var left =  controls.NOTE_LEFT;
		var dodge = controls.DODGE;

		var upP =  controls.NOTE_UP_P;
		var rightP = controls.NOTE_RIGHT_P;
		var downP =  controls.NOTE_DOWN_P;
		var leftP =  controls.NOTE_LEFT_P;
		var dodgeP = controls.DODGE_P;

		var upR =  controls.NOTE_UP_R;
		var rightR = controls.NOTE_RIGHT_R;
		var downR =  controls.NOTE_DOWN_R;
		var leftR =  controls.NOTE_LEFT_R;
		var dodgeR = controls.DODGE_R;

		// var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
		// var controlReleaseArray:Array<Bool> = [leftR, downR, upR, rightR];
		// var controlHoldArray:Array<Bool> = [left, down, up, right];

		var fP:Array<Bool> = [leftP, downP, upP, rightP];
		var fR:Array<Bool> = [leftR, downR, upR, rightR];
		var fH:Array<Bool> = [left, down, up, right];

		if (mania == 4){
		fP = [leftP, downP, dodgeP, upP, rightP];
		fR = [leftR, downR, dodgeR, upR, rightR];
		fH = [left, down, dodge, up, right];
		}

		var anyH = false;
		var anyP = false;
		var anyR = false;
		for (i in 0...fP.length)
		{
			if (fH[i])
				anyH = true;
			if (fP[i])
				anyP = true;
			if (fR[i])
				anyR = true;
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			if(anyH && !endingSong) {
				notes.forEachAlive(function(daNote:Note) {
					if(daNote.isSustainNote && fH[daNote.noteData] && daNote.canBeHit && daNote.mustPress) {
						goodNoteHit(daNote);
					}
				});

				#if ACHIEVEMENTS_ALLOWED
				var achieve:Int = checkForAchievement([11]);
				if(achieve > -1) {
					startAchievement(achieve);
				}
				#end
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}

			if(anyP && !endingSong) {
				if(!ClientPrefs.ghostTapping)
					boyfriend.holdTimer = 0;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				var notesHitArray:Array<Note> = [];
				var notesDatas:Array<Int> = [];
				var dupeNotes:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note) {
					if (!daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
						if (notesDatas.indexOf(daNote.noteData) != -1) {
							for (i in 0...notesHitArray.length) {
								var prevNote = notesHitArray[i];
								if (prevNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - prevNote.strumTime) < 10) {
									dupeNotes.push(daNote);
								} else if (prevNote.noteData == daNote.noteData && daNote.strumTime < prevNote.strumTime) {
									notesHitArray.remove(prevNote);
									notesHitArray.push(daNote);
								}
							}
						} else {
							notesHitArray.push(daNote);
							notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});

				for (i in 0...dupeNotes.length) {
					var daNote = dupeNotes[i];
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
				notesHitArray.sort(sortByShit);

				var alreadyHit:Array<Int> = new Array<Int>();

				if (perfectMode)
					goodNoteHit(notesHitArray[0]);
				else if (notesHitArray.length > 0) {
					for (i in 0...fP.length) {
						if(fP[i] && notesDatas.indexOf(i) == -1) {
							/*if(canMiss) {
								noteMiss(i);
								callOnLuas('noteMissPress', [i]);
								break;
							}*/ 
							// fuck ur anti mash
						}
					}
					for (i in 0...notesHitArray.length) {
						var daNote = notesHitArray[i];
						if(fP[daNote.noteData] && !alreadyHit.contains(daNote.noteData)) {
							alreadyHit.push(daNote.noteData);
							goodNoteHit(daNote);
							if(ClientPrefs.ghostTapping)
								boyfriend.holdTimer = 0;
						}
					}
				} else if(canMiss) {
					for (i in 0...fP.length) {
						noteMissPress(i);
						callOnLuas('noteMissPress', [i]);
					}
				}

				for (i in 0...keysPressed.length) {
					if(!keysPressed[i] && fP[i]) keysPressed[i] = true;
				}
			}
		}

		playerStrums.forEach(function(spr:StrumNote)
		{
			if(fP[spr.ID] && spr.animation.curAnim.name != 'confirm') {
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			if(fR[spr.ID]) {
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		});
	}

	function badNoteHit():Void {
		var fP:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];


	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove

		healthbarshake(1.0);
		notes.forEachAlive(function(note:Note) {		
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		
	if (mania == 4 && daNote.noteData == 2)
		{
			trace("fuck");
			gameOverStateChanged = true;
			GameOverSubstate.deathSoundName = 'bfgetshotanddies';
			GameOverSubstate.endSoundName = 'gameOverEnd';
			GameOverSubstate.characterName = 'bf-fucking-dies';
			GameOverSubstate.loopSoundName = 'cheeseballs-death_dance';

			vocals.volume = 0;
			health -= 69; //instakill requested by CRAE THE DIRECTOR (DONT YOU TRY VIDZ)
			doDeathCheck(true);
		}
		
		health -= daNote.missHealth * healthLoss;
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

	
		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;
		
		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char.hasMissAnimations)
		{
			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[daNote.noteData] + 'miss' + daAlt;

			if (mania == 4 && daNote.noteData == 2) // carlito was here
				animToPlay = "hurt";

			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		var cannotHIT = false;
		if (mania == 4 && direction ==2 )
			cannotHIT = true; 

		if (!boyfriend.stunned && !cannotHIT)
		{
			healthbarshake(1.0);
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if(ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				if (mania == 4 && direction == 2) // carlito was here
					boyfriend.playAnim('hurt', true);
					else
					boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		
		} 
		else if(note.noteType == 'ExDad Anim') {
			var char:Character = dad2;
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
			if(note.gfNote) {
				char = gf;
			}

			char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}
		else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		var hittingHard:Bool = false; //ayo???
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					// if (mania == 4 && note.noteData == 2)
					// 	trace("nothing lmao")
					// 	else
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}

					case 'Sus Note': //Sus note
						FlxTween.cancelTweensOf(amongusDrip);
						amongusDrip.alpha = 1;
						FlxG.sound.play(Paths.sound('vine-boom'));
						FlxTween.tween(amongusDrip, {alpha: 0}, 1.4);
						
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);

				var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
				var daRating:String = Conductor.judgeNote(note, noteDiff);

				if (daRating == "shit" || daRating == "bad" && !ClientPrefs.noAntimash) // HIT IT RIGHT GOD DAMN
					hittingHard = true;						
				

				if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';
	
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
				if (mania == 4 && note.noteData == 2)
					{
						if (!hittingHard)
							animToPlay= 'dodge';
						else
							animToPlay= 'hurt';

					}
				//if (note.isSustainNote){ wouldn't this be fun : P. i think it would be swell
					
					//if(note.gfNote) {
					//  var anim = animToPlay +"-hold" + daAlt;
					//	if(gf.animation.getByName(anim) == null)anim = animToPlay + daAlt;
					//	gf.playAnim(anim, true);
					//	gf.holdTimer = 0;
					//} else {
					//  var anim = animToPlay +"-hold" + daAlt;
					//	if(boyfriend.animation.getByName(anim) == null)anim = animToPlay + daAlt;
					//	boyfriend.playAnim(anim, true);
					//	boyfriend.holdTimer = 0;
					//}
				//}else{
					if(note.gfNote) {
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					} else {
						boyfriend.playAnim(animToPlay + daAlt, true);
						boyfriend.holdTimer = 0;
					}
				//}
				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
	
					if(gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
			} else {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
				
						if (mania == 4 && spr.ID == 2)
							StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
						else
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}


	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		if (data == 2 && mania == 4)
		splash.setupNoteSplash(x+8, y, data, skin, hue, sat, brt);
		else
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);

		grpNoteSplashes.add(splash);
	}


	// function DaSpaceNote(note:FlxSprite, killDa:Bool) {
	// 	if (killDa == false){

	// 		var NewspaceNote:FlxSprite = new FlxSprite(225, 600);
	// 		NewspaceNote.frames = Paths.getSparrowAtlas('SPACEBAR_NOTE_assets', 'preload');
	// 		NewspaceNote.animation.addByPrefix('arrow', "ABCD-spacebar arrow", 24);
	// 		NewspaceNote.animation.play('arrow', true);
	// 		NewspaceNote.setGraphicSize(Std.int(NewspaceNote.width * 0.1));

	// 	spaceNotes.add(NewspaceNote);

	// 	FlxTween.tween(NewspaceNote, {y: note.y - 240}, 1, // uh i can explain-  i love tweens
	// 	{
	// 		ease: FlxEase.linear,
	// 		onComplete: function(twn:FlxTween)
	// 		{
				
	// 			health -= 0.2;
	// 			combo = 0;

	// 			vocals.volume = 0;
			
		
	// 			//For testing purposes
	// 			//trace(daNote.missHealth);
	// 			songMisses++;
	// 			vocals.volume = 0;
	// 			if(!practiceMode) songScore -= 10;

	// 			NewspaceNote.kill();
	// 			spaceNotes.remove(NewspaceNote, true);
	// 			NewspaceNote.destroy();
	// 			remove(NewspaceNote);
	// 		}
	// 	});
	// }

	// else
	// 	{
	// 		playBF_ExtraAnim('singLEFT');
	// 		trace('killed space note');
	// 		vocals.volume = 1;

	// 		FlxTween.cancelTweensOf(note);
	// 		note.kill();
	// 		spaceNotes.remove(note, true);
	// 		note.destroy();
	// 		remove(note);
	// 	}

	// }

	function playBF_ExtraAnim(anim:String) {
		boyfriend.visible = false;
		boyfriend_extra.playAnim(anim, true);
		add(boyfriend_extra);
		FlxTween.cancelTweensOf(FlxG.camera);
		FlxTween.tween(FlxG.camera, {zoom:1.1}, .5, {ease: FlxEase.quadOut, type: BACKWARD});
		var coolTimer:FlxTimer = new FlxTimer().start(1.2, function(tmr:FlxTimer)
			{
				remove(boyfriend_extra);
				boyfriend.visible = true;
	
			boyfriend.playAnim('idle');
			});
	
			coolTimer.reset();
			//coolTimer.start();
	
	}
	


	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
			gf.specialAnim = true;
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.danced = false; //Sets head to the correct position once the animation ends
		gf.playAnim('hairFall');
		gf.specialAnim = true;
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}
		if(gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		// if(!ClientPrefs.controllerMode)
		// {
		// 	FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		// 	FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		// }
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	
	
	
	
	override function beatHit()
	{
		super.beatHit();



		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}

		if(curBeat % 2 == 0) {
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
				dad.dance();
			}
			if (exDad && dad2.animation.curAnim.name != null && !dad2.animation.curAnim.name.startsWith("sing") && !dad2.stunned)
			{
				dad2.dance();
			}
		} else if(dad.danceIdle && dad.animation.curAnim.name != null && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned) {
			dad.dance();
		}
		
		if (exDad && dad2.danceIdle && dad2.animation.curAnim.name != null && !dad2.curCharacter.startsWith('gf') && !dad2.animation.curAnim.name.startsWith("sing") && !dad2.stunned)
			{
				dad2.dance();
			}

		switch (curStage)
		{
			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:BGSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1, [curLight]);

					phillyCityLights.members[curLight].visible = true;
					phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}

		// if (curBeat == 511 && curSong.toLowerCase() == 'pussy')
		// 	{
		// 		defaultCamZoom = 1.6;
		// 		camGame.zoom = 1.6;
		// 	}
		// if (curBeat == 526 && curSong.toLowerCase() == 'pussy')
		// 	{
		// 		defaultCamZoom = 0.86;
		// 		camGame.zoom = 0.86;
		// 	}

		if (curBeat == 322 && curSong.toLowerCase() == 'cray cray')
			{
				FlxTween.cancelTweensOf(camHUD);
				FlxTween.cancelTweensOf(camcontrol);
				//FlxG.sound.play(Paths.sound('vine-boom'));
				FlxTween.tween(camHUD, {alpha: 0}, 0.6);
				FlxTween.tween(camcontrol, {alpha: 0}, 0.6);
			}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat);//DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	public static var othersCodeName:String = 'otherAchievements';
	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String {

		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		var achievementsToCheck:Array<String> = achievesToCheck;
		if (achievementsToCheck == null) {
			achievementsToCheck = [];
			for (i in 0...Achievements.achievementsStuff.length) {
				achievementsToCheck.push(Achievements.achievementsStuff[i][2]);
			}
			achievementsToCheck.push(othersCodeName);
		}

		for (i in 0...achievementsToCheck.length) {
			var achievementName:String = achievementsToCheck[i];
			var unlock:Bool = false;

			if (achievementName == othersCodeName) {
				if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
				{
					var weekName:String = WeekData.getWeekFileName();

					for (json in Achievements.loadedAchievements) {
						if (json.unlocksAfter == weekName && !Achievements.isAchievementUnlocked(json.icon) && !json.customGoal) unlock = true;
						achievementName = json.icon;
					}

					for (k in 0...Achievements.achievementsStuff.length) {
						var unlockPoint:String = Achievements.achievementsStuff[k][3];
						if (unlockPoint != null) {
							if (unlockPoint == weekName && !unlock && !Achievements.isAchievementUnlocked(Achievements.achievementsStuff[k][2])) unlock = true;
							achievementName = Achievements.achievementsStuff[k][2];
						}
					}
				}
			}

			for (json in Achievements.loadedAchievements) { //Requires jsons for call
				var ret:Dynamic = callOnLuas('onCheckForAchievement', [json.icon]); //Set custom goals

				//IDK, like
				// if getProperty('misses') > 10 and leName == 'lmao_skill_issue' then return Function_Continue end

				if (ret == FunkinLua.Function_Continue && !Achievements.isAchievementUnlocked(json.icon) && json.customGoal && !unlock) {
					unlock = true;
					achievementName = json.icon;
				}
			}

			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && !unlock) {
				switch(achievementName)
				{
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing /*&& !ClientPrefs.imagesPersist*/) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}
			}

			if(unlock) {
				Achievements.unlockAchievement(achievementName);
				return achievementName;
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
