import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;

using StringTools;

class RemoveDataSubState extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;
    var canUpdateChoice:Bool = true;
	public function new()
	{
		super();

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var text:Alphabet = new Alphabet(0, 180, "Clear all game progress?", true);
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
        text.scrollFactor.set();
		add(text);

		yesText = new Alphabet(0, text.y + 150, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
        yesText.scrollFactor.set();
		add(yesText);
		noText = new Alphabet(0, text.y + 150, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
        noText.scrollFactor.set();
		add(noText);
		addVirtualPad(LEFT_RIGHT, A_B);
		
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		bg.alpha += elapsed * 1.5;
		if(bg.alpha > 0.6) bg.alpha = 0.6;

		for (i in 0...alphabetArray.length) {
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}
        if (canUpdateChoice){
		if(controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			onYes = !onYes;
			updateOptions();
		}
		if(controls.BACK) {
            canUpdateChoice = false;
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
            MainMenuState.isReseting = false;
			close();
		} else if(controls.ACCEPT) {
			if(onYes) {
                canUpdateChoice = false;
                StoryMenuState.weekCompleted.set(WeekData.weeksList[1], false);

                FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
                StoryMenuState.weekCompleted.set(WeekData.weeksList[2], false);

                FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
                // RESET EVERY WEEK SCORE NOOOO
                Highscore.resetWeek(WeekData.weeksList[1], 0);
                Highscore.resetWeek(WeekData.weeksList[1], 1);
                Highscore.resetWeek(WeekData.weeksList[1], 2);

                Highscore.resetWeek(WeekData.weeksList[2], 2);
				// reset every song score
				Highscore.resetSong('pip', 0);
				Highscore.resetSong('pip', 1);
				Highscore.resetSong('pip', 2);

				Highscore.resetSong('fuck', 0);
				Highscore.resetSong('fuck', 1);
				Highscore.resetSong('fuck', 2);

				Highscore.resetSong('cray cray', 0);
				Highscore.resetSong('cray cray', 1);
				Highscore.resetSong('cray cray', 2);

				Highscore.resetSong('pussy', 0);
				Highscore.resetSong('pussy', 1);
				Highscore.resetSong('pussy', 2);

                // no more trophy as well
                FlxG.save.data.PipModWeekCompleted = null;
                FlxG.save.data.PipModFC = null;
                FlxG.save.data.PussyModWeekCompleted = null;
				// haha fc go brrrr
				FlxG.save.data.PipModFCedPip = false;
				FlxG.save.data.PipModFCedFuck = false;
				FlxG.save.data.PipModFCedCray = false;

				FlxG.save.flush();

                trace('all ur data was cleared');

                }
                canUpdateChoice = false;

                //FlxG.sound.play(Paths.sound('cancelMenu'), 1);
                            
                FlxG.sound.play(Paths.sound('confirmMenu', 'preload'));
                FlxTween.tween(FlxG.camera, {zoom:1.05}, 1.3, {ease: FlxEase.quadOut, type: BACKWARD});
                new FlxTimer().start(1.2, function(fuckingtmr:FlxTimer) {
            
                    if(onYes) {
					TitleState.initialized = false;
					TitleState.closedState = false;
					FlxG.sound.music.fadeOut(0.3);
					FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);                    
				}
                    else
                    {
                        MainMenuState.isReseting = false;
                        close();
                    }
                });
		}
    }
		super.update(elapsed);
	}

	function updateOptions() {
        if (canUpdateChoice){
		    var scales:Array<Float> = [0.75, 1];
            var alphas:Array<Float> = [0.6, 1.25];
            var confirmInt:Int = onYes ? 1 : 0;

            yesText.alpha = alphas[confirmInt];
            yesText.scale.set(scales[confirmInt], scales[confirmInt]);
            noText.alpha = alphas[1 - confirmInt];
            noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
        }
	}
}