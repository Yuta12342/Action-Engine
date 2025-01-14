package;

import haxe.Timer;
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
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import flixel.animation.FlxAnimationController;
import animateatlas.AtlasFrameMaker;
import flixel.tweens.misc.NumTween;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import Conductor.Rating;
import Note;
import archipelago.ArchPopup;
import lime.app.Application;
import openfl.filters.ColorMatrixFilter;
import openfl.filters.BlurFilter;
import flixel.util.FlxDestroyUtil;
import lime.media.openal.AL;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler;
#else import vlc.MP4Handler as VideoHandler; #end
#end
using StringTools;

typedef PatternResult =
{
	pattern:Array<Int>,
	repetitions:Int,
	start:Int,
	end:Int,
	patternLength:Int
}

class PlayState extends MusicBeatState
{
	// Chart Modifier and Trap/Randomizer Variables!
	var prevNoteData:Int = -1;
	var initialNoteData:Int = -1;
	var caseExecutionCount:Int = FlxG.random.int(-50, 50);
	var currentModifier:Int = -1;
	var trap:String = 'None';
	var resistMode:Bool = false;

	public static var commands:Array<String> = [];
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var maxHealth:Float = 2;
	public var startHealth:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;

	public var healthBar:FlxBar;

	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;

	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public static var mania:Int = 0;
	public static var EKMode:Null<Bool> = true;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var chartModifier:String = 'Normal';
	public var convertMania:Int = ClientPrefs.getGameplaySetting('convertMania', 3);

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camUnderTop:FlxCamera;
	public var camSpellPrompts:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;

	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

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

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

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

	public var defaultCamZoom:Float = 1.05;
	public var defaultHudCamZoom:Float = 1.0;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;

	public var luaArray:Array<FunkinLua> = [];

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	private var debugKeysDodge:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	public var activeItems:Array<Int> = [0, 0, 0, 0]; // Shield, Curse, MHP, Traps
	public var archMode:Bool = false;
	public var itemAmount:Int = 0;
	public var midSwitched:Bool = false;

	var resistGroup:FlxTypedGroup<FlxSprite>;

	public var resistBarBar:FlxSprite;
	public var resistBarBG:FlxSprite;
	public var resistBar:FlxSprite;

	public var currentBarPorcent:Float = 0;
	public var heightBar:Float = 0;
	public var songStarted:Bool = false;
	public var curResist:Float = 0;
	public var curHorny:Float = 0;

	public static var effectiveScrollSpeed:Float;
	public static var effectiveDownScroll:Bool;

	public var vocals:FlxSound;
	public var inst:FlxSound;

	var effectsActive:Map<String, Int> = new Map<String, Int>();

	var effectTimer:FlxTimer = new FlxTimer();
	var randoTimer:FlxTimer = new FlxTimer();

	public static var xWiggle:Array<Float> = [0, 0, 0, 0];
	public static var yWiggle:Array<Float> = [0, 0, 0, 0];

	var xWiggleTween:Array<NumTween> = [null, null, null, null];
	var yWiggleTween:Array<NumTween> = [null, null, null, null];

	public var severInputs:Array<Bool> = new Array<Bool>();


	var drainHealth:Bool = false;

	var drunkTween:NumTween = null;

	var lagOn:Bool = false;

	var addedMP4s:Array<VideoHandlerMP4> = [];

	var flashbangTimer:FlxTimer = new FlxTimer();

	var errorMessages:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	var noiseSound:FlxSound = new FlxSound();

	var camAngle:Float = 0;

	var dmgMultiplier:Float = 1;

	var delayOffset:Float = 0;
	var volumeMultiplier:Float = 1;

	var frozenInput:Int = 0;

	public static var notePositions:Array<Int> = [0, 1, 2, 3];

	var blurEffect:MosaicEffect = new MosaicEffect();

	public static var validWords:Array<String> = [];

	var spellPrompts:Array<SpellPrompt> = [];

	public static var controlButtons:Array<String> = [];

	private var camNotes:FlxCamera;

	var terminateStep:Int = -1;
	var terminateMessage:FlxSprite = new FlxSprite();
	var terminateSound:FlxSound = new FlxSound();
	var terminateTimestamps:Array<TerminateTimestamp> = new Array<TerminateTimestamp>();
	var terminateCooldown:Bool = false;

	var shieldSprite:FlxSprite = new FlxSprite();
	private var invulnCount:Int = 0;
	var filters:Array<BitmapFilter> = [];
	var filtersGame:Array<BitmapFilter> = [];
	var filtersHUD:Array<BitmapFilter> = [];
	var filterMap:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}>;
	var picked:Int = 0;

	var effectArray:Array<String> = [
		'colorblind', 'blur', 'lag', 'mine', 'warning', 'heal', 'spin', 'songslower', 'songfaster', 'scrollswitch', 'scrollfaster', 'scrollslower', 'rainbow',
		'cover', 'ghost', 'flashbang', 'nostrum', 'jackspam', 'spam', 'sever', 'shake', 'poison', 'dizzy', 'noise', 'flip', 'invuln',
		'desync', 'mute', 'ice', 'randomize', 'fakeheal', 'spell', 'terminate', 'lowpass', 'songSwitch'
	];
	var curEffect:Int = 0;

	public static var ogScroll:Bool = ClientPrefs.downScroll;

	var allNotes:Array<Int> = [];

	public var lowFilterAmount:Float = 1;
	public var vocalLowFilterAmount:Float = 1;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	function generateGibberish(length:Int, exclude:String):String
	{
		var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
		var result:String = "";

		// Remove excluded characters from the alphabet
		for (i in 0...exclude.length)
		{
			alphabet = StringTools.replace(alphabet, exclude.charAt(i), "");
		}

		// Generate the gibberish string
		for (i in 0...length)
		{
			var randomIndex:Int = Math.floor(Math.random() * alphabet.length);
			result += alphabet.charAt(randomIndex);
		}

		return result;
	}

	override public function create()
	{
		if (FlxG.save.data.closeDuringOverRide == null) FlxG.save.data.closeDuringOverRide = false;
		if (FlxG.save.data.manualOverride == null) FlxG.save.data.manualOverride = false;
		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		lastDifficultyName = CoolUtil.difficulties[curDifficulty];
		if (chartModifier == '4K Only' && mania != 3)
		{
			mania = 3;
		}
		if (ClientPrefs.getGameplaySetting('archMode', false))
		{
			if (FlxG.save.data.activeItems != null)
				activeItems = FlxG.save.data.activeItems;
			if (FlxG.save.data.activeItems == null)
			{
				activeItems[3] = FlxG.random.int(0, 9);
				activeItems[2] = Std.int(maxHealth);
			}
		}

		if (Main.args[0] == 'editorMode')
		{
			chartingMode = true;
		}
		// trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();

		resetChatData();

		effectiveScrollSpeed = 1;
		effectiveDownScroll = ClientPrefs.downScroll;
		notePositions = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];

		blurEffect.setStrength(0, 0);

		var wordList:Array<String> = [];
		var nonoLetters:String = "";

		function addNonoLetters(keyBind:String) {
			var keys:Null<Array<FlxKey>> = ClientPrefs.keyBinds.get(keyBind);
			if (keys != null) {
				for (key in keys) {
					var keyName:String = InputFormatter.getKeyName(key);
					if (keyName.length == 1 && keyName != "-") {
						nonoLetters += keyName.toLowerCase();
					}
				}
			}
		}

		addNonoLetters('note_left');
		addNonoLetters('note_down');
		addNonoLetters('note_up');
		addNonoLetters('note_right');
		addNonoLetters('reset');

		trace(nonoLetters);
		if (FileSystem.exists(Paths.txt("words")))
		{
			var content:String = sys.io.File.getContent(Paths.txt("words"));
			wordList = content.toLowerCase().split("\n");
		}
		wordList.push(SONG.song);
		trace(wordList.length + " words loaded");
		trace(wordList);
		validWords.resize(0);
		for (word in wordList)
		{
			var containsNonoLetter:Bool = false;
			var nonoLettersArray:Array<String> = nonoLetters.split("");

			for (nonoLetter in nonoLettersArray)
			{
				if (word.contains(nonoLetter))
				{
					containsNonoLetter = true;
					break;
				}
			}

			if (!containsNonoLetter)
			{
				validWords.push(word.toLowerCase());
			}
		}

		if (validWords.length <= 0)
		{
			trace("wtf no valid words");
			var numWords:Int = 10; // Number of words to generate

			validWords = [for (i in 0...numWords) generateGibberish(5, nonoLetters)];
		}
		trace(validWords.length + " words accepted");
		trace(validWords);
		controlButtons.resize(0);
		for (thing in [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')).toString(),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')).toString(),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')).toString(),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')).toString(),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('reset')).toString(),
			"LEFT",
			"RIGHT",
			"UP",
			"DOWN",
			"SEVEN",
			"EIGHT",
			"NINE"
		])
		{
			controlButtons.push(StringTools.trim(thing).toLowerCase());
		}
		// FlxG.sound.cache("assets/music/" + SONG.song + "_Inst" + TitleState.soundExt);
		// FlxG.sound.cache("assets/music/" + SONG.song + "_Voices" + TitleState.soundExt);

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		debugKeysDodge = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('dodge'));
		PauseSubState.songName = null; // Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		keysArray = EKData.Keybinds.fill();

		// Ratings
		ratingsData.push(new Rating('sick')); // default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		chartModifier = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');
		archMode = (ClientPrefs.getGameplaySetting('archMode', false) && !FlxG.save.data.manualOverride);
		itemAmount = ClientPrefs.getGameplaySetting('itemAmount', 69);

		if (archMode)
		{
			if (FlxG.save.data.activeItems == null)
			{
				if (activeItems[3] != 0)
				{
					switch activeItems[3]
					{
						case 1:
							chartModifier = 'Flip';
						case 2:
							chartModifier = 'Random';
						case 3:
							chartModifier = 'Stairs';
						case 4:
							chartModifier = 'Wave';
						case 5:
							chartModifier = 'SpeedRando';
						case 6:
							chartModifier = 'Amalgam';
						case 7:
							chartModifier = 'Trills';
						case 8:
							chartModifier = "SpeedUp";
						case 9:
							if (SONG.mania == 3)
							{
								chartModifier = "ManiaConverter";
								convertMania = FlxG.random.int(4, Note.maxMania);
							}
							else
							{
								chartModifier = "4K Only";
							}
					}
				}
				if (chartModifier == "ManiaConverter")
				{
					ArchPopup.startPopupCustom("convertMania value is:", "" + convertMania + "", 'Color');
				}

				ArchPopup.startPopupCustom('You Got an Item!', "Chart Modifier Trap (" + chartModifier + ")", 'Color');
			}
			maxHealth = activeItems[2];
		}

		filterMap = [
			"Grayscale" => {
				var matrix:Array<Float> = [
					0.5, 0.5, 0.5, 0, 0,
					0.5, 0.5, 0.5, 0, 0,
					0.5, 0.5, 0.5, 0, 0,
					  0,   0,   0, 1, 0,
				];

				{filter: new ColorMatrixFilter(matrix)}
			},
			"BlurLittle" => {
				filter: new BlurFilter()
			}
		];

		terminateSound = new FlxSound().loadEmbedded(Paths.sound('beep'));
		FlxG.sound.list.add(terminateSound);

		terminateMessage.visible = false;
		add(terminateMessage);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camNotes = new FlxCamera();
		camOther = new FlxCamera();
		camUnderTop = new FlxCamera();
		camSpellPrompts = new FlxCamera();
		camNotes.bgColor.alpha = 0;
		camUnderTop.bgColor.alpha = 0;
		camSpellPrompts.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		camNotes.setFilters(filters);
		camNotes.filtersEnabled = true;

		camGame.setFilters(filtersGame);
		camGame.filtersEnabled = true;

		camHUD.setFilters(filtersHUD);
		camHUD.filtersEnabled = true;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camNotes, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camUnderTop, false);
		FlxG.cameras.add(camSpellPrompts, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		errorMessages.cameras = [camUnderTop];
		add(errorMessages);

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		if (chartModifier == "4K Only")
		{
			mania = 3;
		}
		else if (chartModifier == "ManiaConverter")
		{
			mania = convertMania;
		}
		else
		{
			mania = SONG.mania;
		}
		if (mania < Note.minMania || mania > Note.maxMania)
			mania = Note.defaultMania;

		EKMode = SONG.EKSkin;
		if (mania != Note.defaultMania)
		{
			EKMode = true;
		}
		else
			EKMode = false;
		if (EKMode == null)
		{
			EKMode = true;
		}

		for (i in 0...mania + 1) {
			severInputs.push(false);
		}

		trace("song keys: " + (mania + 1) + " / mania value: " + mania);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray[mania].length)
		{
			keysPressed.push(false);
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		var s_termination = "s";
		if (mania == 0)
			s_termination = "";
		storyDifficultyText = " (" + CoolUtil.difficulties[storyDifficulty] + ", " + (mania + 1) + " key" + s_termination + ")";

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

		curStage = SONG.stage;
		// trace('stage is: ' + curStage);
		if (SONG.stage == null || SONG.stage.length < 1)
		{
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
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
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

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': // Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if (!ClientPrefs.lowQuality)
				{
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
				dadbattleSmokes = new FlxSpriteGroup(); // troll'd

			case 'spooky': // Week 2
				if (!ClientPrefs.lowQuality)
				{
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				}
				else
				{
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				// PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

			case 'philly': // Week 3
				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if (!ClientPrefs.lowQuality)
				{
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

			case 'limo': // Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if (!ClientPrefs.lowQuality)
				{
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
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					// PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					// PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': // Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if (!ClientPrefs.lowQuality)
				{
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
				precacheList.set('Lights_Shut_off', 'sound');

			case 'mallEvil': // Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': // Week 6 - Senpai, Roses
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
				if (!ClientPrefs.lowQuality)
				{
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

				if (!ClientPrefs.lowQuality)
				{
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

				if (!ClientPrefs.lowQuality)
				{
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': // Week 6 - Thorns
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
				if (!ClientPrefs.lowQuality)
				{
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
				}
				else
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'tank': // Week 7 - Ugh, Guns, Stress
				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if (!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins', -200, 0, .35, .35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if (!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
		}

		switch (Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); // Needed for blammed lights

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);

		switch (curStage)
		{
			case 'spooky':
				add(halloweenWhite);
			case 'tank':
				add(foregroundSprites);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}

		if (doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}

			switch (Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);

			if (gfVersion == 'pico-speaker')
			{
				if (!ClientPrefs.lowQuality)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if (FlxG.random.bool(16))
						{
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
				}
			}
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		add(shieldSprite);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		switch (curStage)
		{
			case 'limo':
				resetFastCar();
				addBehindGF(fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); // nice
				addBehindDad(evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); // Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		if (effectiveDownScroll)
			strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 570).makeGraphic(FlxG.width, 10);
		else
			strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);

		if (ClientPrefs.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if (ClientPrefs.downScroll)
			timeTxt.y = FlxG.height - 44;

		if (ClientPrefs.timeBarType == 'Song Name')
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
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if (ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		if (archMode)
		{
			itemAmount = FlxG.random.int(1, ClientPrefs.getGameplaySetting('itemAmount', 69));
			trace('Max Items = ' + ClientPrefs.getGameplaySetting('itemAmount', 69));
			trace('itemAmount:' + itemAmount);
		}

		// startCountdown();

		generateSong(SONG.song);

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
		moveCameraSection();

		resistGroup = new FlxTypedGroup<FlxSprite>();
		resistBar = new FlxSprite(FlxG.width - 100, 60).loadGraphic(Paths.image('healthBar2'));
		resistBar.scale.set(1.8, 1.1);
		resistBar.cameras = [camHUD];
		resistGroup.add(resistBar);

		resistBarBG = new FlxSprite(resistBar.x, resistBar.y).loadGraphic(Paths.image('healthBarg'));
		resistBarBG.cameras = [camHUD];
		resistBarBG.scale.set(1.6, 1.07);
		resistGroup.add(resistBarBG);

		resistBarBar = new FlxSprite(resistBar.x, resistBar.y);
		resistBarBar.makeGraphic(Std.int(resistBarBG.width / 1.1), Std.int(resistBar.height), 0xffeda6c4);
		resistBarBar.cameras = [camHUD];
		resistGroup.add(resistBarBar);
		trace("Initial BarBar: " + (resistBarBar.x + resistBarBar.y));

		add(resistGroup);
		resistBarBG.screenCenter();
		resistBarBG.x = resistBar.x + 5;
		resistBarBar.screenCenter();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = effectiveDownScroll ? FlxG.height * 0.1 : FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if (ClientPrefs.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, maxHealth);
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

		scoreTxt = new FlxText(0, (effectiveDownScroll ? FlxG.height * 0.1 - 72 : healthBarBG.y + 36), FlxG.width, "", 20);
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
		if (ClientPrefs.downScroll)
		{
			botplayTxt.y = timeBarBG.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camNotes];
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

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
			if (OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_events/' + event + '.lua');
			if (OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0,
				Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) +
					'/')); // using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					camNotes.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							camNotes.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if (gf != null)
						gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					camNotes.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
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
						camNotes.visible = true;
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
					if (daSong == 'roses')
						FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro();

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			trace('Start at: ' + FlxG.save.data.songPos);
			trace('Starting the song at: ' + startOnTime);
			if (daSong != 'tutorial') 
			{
				startCountdownSwitch(FlxG.save.data.songPos);
				FlxG.save.data.songPos = null;
			}
			else startCountdown();
		}
		RecalculateRating();

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0)
			precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null)
		{
			precacheList.set(PauseSubState.songName, 'music');
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + storyDifficultyText, iconP2.getCharacter());
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		callOnLuas('onCreatePost', []);

		super.create();

		if (curStage.startsWith('school'))
		{
			shieldSprite.loadGraphic(Paths.image("pixelUI/shield"));
			shieldSprite.alpha = 0.85;
			shieldSprite.setGraphicSize(Std.int(shieldSprite.width * daPixelZoom));
			shieldSprite.updateHitbox();
			shieldSprite.antialiasing = false;
		}
		else
		{
			shieldSprite.loadGraphic(Paths.image("shield"));
			shieldSprite.alpha = 0.85;
			shieldSprite.scale.x = shieldSprite.scale.y = 0.8;
			shieldSprite.updateHitbox();
		}
		shieldSprite.visible = false;

		cacheCountdown();
		cachePopUpScore();

		for (key => type in precacheList)
		{
			// trace('Key $key is type $type');
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		Paths.clearUnusedMemory();

		CustomFadeTransition.nextCamera = camOther;

		/*if (FlxG.save.data.manualOverride && FlxG.save.data.closeDuringOverRide)
		{
			//playBackRate = 1;
			PlayState.storyWeek = 0;
			Paths.currentModDirectory = '';
			var diffStr:String = WeekData.getCurrentWeek().difficulties;
			if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

			if(diffStr != null && diffStr.length > 0)
			{
				var diffs:Array<String> = diffStr.split(',');
				var i:Int = diffs.length - 1;
				while (i > 0)
				{
					if(diffs[i] != null)
					{
						diffs[i] = diffs[i].trim();
						if(diffs[i].length < 1) diffs.remove(diffs[i]);
					}
					--i;
				}

				if(diffs.length > 0 && diffs[0].length > 0)
				{
					CoolUtil.difficulties = diffs;
				}
			}
			if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
			{
				curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
			}
			else
			{
				curDifficulty = 0;
			}

			var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
			//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
			if(newPos > -1)
			{
				curDifficulty = newPos;
			}
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
			PlayState.SONG = Song.loadFromJson(Highscore.formatSong('tutorial', curDifficulty), Paths.formatToSongPath('tutorial'));
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			FlxG.save.data.manualOverride = false;
			FlxG.save.data.closeDuringOverRide = false;
			FlxG.save.flush();
			justOverRide = true;
			MusicBeatState.resetState();
		}*/
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if (!ClientPrefs.shaders)
			return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if (!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if (!ClientPrefs.shaders)
			return false;

		if (runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if (FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else
					frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else
					vert = null;

				if (found)
				{
					runtimeShaders.set(name, [frag, vert]);
					// trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if (generatedMusic)
		{
			if (vocals != null)
				vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		trace('Anim speed: ' + FlxAnimationController.globalSpeed);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor)
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34)
		{
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors()
	{
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
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
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if (Assets.exists(luaFile))
		{
			doPush = true;
		}
		#end

		if (doPush)
		{
			for (script in luaArray)
			{
				if (script.scriptName == luaFile)
					return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		if (variables.exists(tag))
			return variables.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:VideoHandlerMP4 = new VideoHandlerMP4();
		video.cameras = [camHUD];
		video.playMP4(filepath, null, false, true);
		video.finishCallback = function()
		{
			addedMP4s.remove(video);
			remove(video);
			startAndEnd();
			return;
		}
		add(video);
		addedMP4s.push(video);
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				endSong();
			}
			else
			{
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
				camNotes.visible = false;
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
										camNotes.visible = true;
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

	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		camNotes.visible = false;
		// inCutscene = true; //this would stop the camera movement, oops

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			camNotes.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch (songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if (name == 'dieBitch') // Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if (name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public static var startOnTime:Float = 0;

	public var camMovement:Float = 40;
	public var velocity:Float = 1;
	public var campointx:Float = 0;
	public var campointy:Float = 0;
	public var camlockx:Float = 0;
	public var camlocky:Float = 0;
	public var camlock:Bool = false;
	public var bfturn:Bool = false;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage)
			introAlts = introAssets.get('pixel');

		for (asset in introAlts)
			Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function updateLuaDefaultPos()
	{
		for (i in 0...playerStrums.length)
		{
			setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
			setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
		}
		for (i in 0...opponentStrums.length)
		{
			setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
			setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			// if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
		}
	}

	public function startCountdown():Void
	{
		if (archMode)
		{
			trace("Checking for missing Items...");

			if (stuck)
			{
				if (PlayState.SONG.player1.toLowerCase().contains('zenetta') || PlayState.SONG.player2.toLowerCase().contains('zenetta') || PlayState.SONG.gfVersion.toLowerCase().contains('zenetta'))
				{
					itemAmount = 69;
					trace("RESISTANCE OVERRIDE!");
				}
				stuck = false;

				// Check if there are any suitable mustPress notes available
				if (unspawnNotes.filter(function(note:Note):Bool
				{
					return note.mustPress && !note.isSustainNote && !note.isCheck && !note.ignoreNote;
				}).length == 0)
				{
					trace('No suitable notes found. Stopping current Generation...');
					trace('Waiting for Song Generator...');
				}
				else
				{
					while (did < itemAmount && !stuck)
					{
						var foundOne:Bool = false;

						for (i in 0...unspawnNotes.length)
						{
							if (did >= itemAmount)
							{
								break; // exit the loop if the required number of notes are created
							}

							if (unspawnNotes[i].mustPress
								&& !unspawnNotes[i].isSustainNote
								&& FlxG.random.bool(1)
								&& !unspawnNotes[i].isCheck
								&& !unspawnNotes[i].ignoreNote
								&& unspawnNotes.filter(function(note:Note):Bool
								{
									return note.mustPress && !note.isSustainNote && !note.isCheck && !note.ignoreNote;
								}).length != 0)
							{
								unspawnNotes[i].isCheck = true;
								did++;
								foundOne = true;
								Sys.print('\rGenerating Checks: ' + did + '/' + itemAmount);
							}
							else if (unspawnNotes.filter(function(note:Note):Bool
							{
								return note.mustPress && !note.isSustainNote && !note.isCheck && !note.ignoreNote;
							}).length == 0)
							{
								Sys.println('');
								trace('Stuck!');
								stuck = true;
								// Additional handling for when it gets stuck
							}
						}

						// Check if there are no more mustPress notes that are not sustain notes, not isCheck, and not ignoreNote
						if (stuck)
						{
							Sys.println('');
							trace('No more suitable notes found. Stopping current Generation...');
							trace('Waiting for Song Generator...');
							break; // exit the loop if no more suitable notes are found
						}
					}
				}
			}
			Sys.println('');
			trace("Note Generation complete.");

			if (did == 0)
			{
				Sys.println('');
				trace("No notes...? Impossible song detected! Fixing this blunder.");
				check = itemAmount;
				ArchPopup.startPopupCustom('You Found A Check!', check + '/' + itemAmount, 'Color');
				trace('Got: ' + check + '/' + itemAmount);
				ArchPopup.startPopupCustom('Error Found', 'No Items could be spawned as there are no Notes.', 'Color');
			}

			for (i in 0...unspawnNotes.length)
			{
				if (unspawnNotes[i].isCheck && unspawnNotes[i].noteType != 'Check Note')
				{
					trace('Making extra note noticable as Check...');
					unspawnNotes[i].colorSwap.hue = 40;
					unspawnNotes[i].colorSwap.saturation = 50;
					unspawnNotes[i].colorSwap.brightness = 50;
				}
				var checkedNoteIndices = new Array<Int>();

				for (note in unspawnNotes)
				{
					if (note.isCheck && !checkedNoteIndices.contains(note.noteIndex))
					{
						checkedNoteIndices.push(note.noteIndex);

						for (i in 0...unspawnNotes.length)
						{
							if (unspawnNotes[i].isSustainNote && unspawnNotes[i].noteIndex == note.noteIndex)
							{
								unspawnNotes[i].colorSwap.hue = 40;
								unspawnNotes[i].colorSwap.saturation = 50;
								unspawnNotes[i].colorSwap.brightness = 50;

								// Print progress and note being changed on a single line
								// Sys.print('\rProgress: ' + (i + 1) + '/' + unspawnNotes.length + ', Changing note: ' + unspawnNotes[i].noteIndex);
							}
						}
					}
				}
			}
			Sys.println('');
			trace("Generation complete.");

			trace('Starting Countdown...');
		}
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		if (ret != FunkinLua.Function_Stop)
		{
			if (skipCountdown || startOnTime > 0)
				skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			updateLuaDefaultPos();

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (startOnTime < 0)
				startOnTime = 0;

			if (startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null
					&& tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
					&& gf.animation.curAnim != null
					&& !gf.animation.curAnim.name.startsWith("sing")
					&& !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0
					&& boyfriend.animation.curAnim != null
					&& !boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0
					&& dad.animation.curAnim != null
					&& !dad.animation.curAnim.name.startsWith('sing')
					&& !dad.stunned)
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if (isPixelStage)
				{
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if (curStage == 'mall')
				{
					if (!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.cameras = [camHUD];
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						insert(members.indexOf(notes), countdownReady);
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
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						insert(members.indexOf(notes), countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
						//doEffect("spell");
						if (chartModifier == "Amalgam")
						{
							var previousPlaybackRate = playbackRate;
							playbackRate = 0;
							var randomDuration = Math.random() * 10;
							var playbackRateObj = {value: playbackRate}; // Create an object with a "value" property
							FlxTween.tween(playbackRateObj, {value: previousPlaybackRate}, randomDuration, {
								onUpdate: function(twn:FlxTween)
								{
									set_playbackRate(playbackRateObj.value); // Update playbackRate using set_playbackRate
								},
								onComplete: function(twn:FlxTween)
								{
									set_playbackRate(playbackRateObj.value); // Update playbackRate using set_playbackRate
								}
							});
						}
				}

				notes.forEachAlive(function(note:Note)
				{
					if (ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if (ClientPrefs.middleScroll && !note.mustPress)
						{
							note.alpha *= 0.35;
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function startCountdownSwitch(songPos:Float):Void
	{
		startOnTime = songPos;
		if (archMode)
		{
			trace("Checking for missing Items...");

			if (stuck)
			{
				if (PlayState.SONG.song.toLowerCase().contains('resistance') || PlayState.SONG.song.toLowerCase() == 'resistalovania')
				{
					itemAmount = 69;
					trace("RESISTANCE OVERRIDE!");
				}
				stuck = false;

				// Check if there are any suitable mustPress notes available
				if (unspawnNotes.filter(function(note:Note):Bool
				{
					return note.mustPress && !note.isSustainNote && !note.isCheck && !note.ignoreNote;
				}).length == 0)
				{
					trace('No suitable notes found. Stopping current Generation...');
					trace('Waiting for Song Generator...');
				}
				else
				{
					while (did < itemAmount && !stuck)
					{
						var foundOne:Bool = false;

						for (i in 0...unspawnNotes.length)
						{
							if (did >= itemAmount)
							{
								break; // exit the loop if the required number of notes are created
							}

							if (unspawnNotes[i].mustPress
								&& !unspawnNotes[i].isSustainNote
								&& FlxG.random.bool(1)
								&& !unspawnNotes[i].isCheck
								&& !unspawnNotes[i].ignoreNote
								&& unspawnNotes.filter(function(note:Note):Bool
								{
									return note.mustPress && !note.isSustainNote && !note.isCheck && !note.ignoreNote;
								}).length != 0)
							{
								unspawnNotes[i].isCheck = true;
								did++;
								foundOne = true;
								Sys.print('\rGenerating Checks: ' + did + '/' + itemAmount);
							}
							else if (unspawnNotes.filter(function(note:Note):Bool
							{
								return note.mustPress && !note.isSustainNote && !note.isCheck && !note.ignoreNote;
							}).length == 0)
							{
								Sys.println('');
								trace('Stuck!');
								stuck = true;
								// Additional handling for when it gets stuck
							}
						}

						// Check if there are no more mustPress notes that are not sustain notes, not isCheck, and not ignoreNote
						if (stuck)
						{
							Sys.println('');
							trace('No more suitable notes found. Stopping current Generation...');
							trace('Waiting for Song Generator...');
							break; // exit the loop if no more suitable notes are found
						}
					}
				}
			}
			Sys.println('');
			trace("Note Generation complete.");

			if (did == 0)
			{
				Sys.println('');
				trace("No notes...? Impossible song detected! Fixing this blunder.");
				check = itemAmount;
				ArchPopup.startPopupCustom('You Found A Check!', check + '/' + itemAmount, 'Color');
				trace('Got: ' + check + '/' + itemAmount);
				ArchPopup.startPopupCustom('Error Found', 'No Items could be spawned as there are no Notes.', 'Color');
			}

			for (i in 0...unspawnNotes.length)
			{
				if (unspawnNotes[i].isCheck && unspawnNotes[i].noteType != 'Check Note')
				{
					trace('Making extra note noticable as Check...');
					unspawnNotes[i].colorSwap.hue = 40;
					unspawnNotes[i].colorSwap.saturation = 50;
					unspawnNotes[i].colorSwap.brightness = 50;
				}
				var checkedNoteIndices = new Array<Int>();

				for (note in unspawnNotes)
				{
					if (note.isCheck && !checkedNoteIndices.contains(note.noteIndex))
					{
						checkedNoteIndices.push(note.noteIndex);

						for (i in 0...unspawnNotes.length)
						{
							if (unspawnNotes[i].isSustainNote && unspawnNotes[i].noteIndex == note.noteIndex)
							{
								unspawnNotes[i].colorSwap.hue = 40;
								unspawnNotes[i].colorSwap.saturation = 50;
								unspawnNotes[i].colorSwap.brightness = 50;

								// Print progress and note being changed on a single line
								// Sys.print('\rProgress: ' + (i + 1) + '/' + unspawnNotes.length + ', Changing note: ' + unspawnNotes[i].noteIndex);
							}
						}
					}
				}
			}
			Sys.println('');
			trace("Generation complete.");

			trace('Starting Countdown...');
		}
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		if (ret != FunkinLua.Function_Stop)
		{
			if (skipCountdown || startOnTime > 0)
				skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			updateLuaDefaultPos();

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (startOnTime < 0)
				startOnTime = 0;

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null
					&& tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
					&& gf.animation.curAnim != null
					&& !gf.animation.curAnim.name.startsWith("sing")
					&& !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0
					&& boyfriend.animation.curAnim != null
					&& !boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0
					&& dad.animation.curAnim != null
					&& !dad.animation.curAnim.name.startsWith('sing')
					&& !dad.stunned)
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if (isPixelStage)
				{
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if (curStage == 'mall')
				{
					if (!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.cameras = [camHUD];
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						insert(members.indexOf(notes), countdownReady);
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
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						insert(members.indexOf(notes), countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
						if (startOnTime > 0)
						{
							clearNotesBefore(startOnTime);
							setSongTime(startOnTime - 350);
							return;
						}
						else if (skipCountdown)
						{
							setSongTime(0);
							return;
						}	
					//doEffect("spell");
						if (chartModifier == "Amalgam")
						{
							var previousPlaybackRate = playbackRate;
							playbackRate = 0;
							var randomDuration = Math.random() * 10;
							var playbackRateObj = {value: playbackRate}; // Create an object with a "value" property
							FlxTween.tween(playbackRateObj, {value: previousPlaybackRate}, randomDuration, {
								onUpdate: function(twn:FlxTween)
								{
									set_playbackRate(playbackRateObj.value); // Update playbackRate using set_playbackRate
								},
								onComplete: function(twn:FlxTween)
								{
									set_playbackRate(playbackRateObj.value); // Update playbackRate using set_playbackRate
								}
							});
						}
				}

				notes.forEachAlive(function(note:Note)
				{
					if (ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if (ClientPrefs.middleScroll && !note.mustPress)
						{
							note.alpha *= 0.35;
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		scoreTxt.text = 'Score: '
			+ songScore
			+ ' | Misses: '
			+ songMisses
			+ ' | Rating: '
			+ ratingName
			+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');

		if (ClientPrefs.scoreZoom && !miss && !cpuControlled)
		{
			if (scoreTxtTween != null)
			{
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					scoreTxtTween = null;
				}
			});
		}
		callOnLuas('onUpdateScore', [miss]);
		if (archMode)
		{
			scoreTxt.text += ' | Checks: ' + check + '/' + did;
			if (did != itemAmount)
			{
				scoreTxt.text += ' (T: ' + itemAmount + ')';
			}
		}
		if (resistMode)
		{
			scoreTxt.text += ' | Amount of Resistance Left: ' + Highscore.floorDecimal(curResist, 3) + '%';
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue()
	{
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue()
	{
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

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if (startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		else startOnTime = 0;

		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		switch (curStage)
		{
			case 'tank':
				if (!ClientPrefs.lowQuality)
					tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}

		effectTimer.start(5, function(timer)
		{
			if (paused)
				return;
			if (startingSong)
				return;
			if (endingSong)
				return;
			readChatData();
		}, 0);

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + storyDifficultyText, iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
		songStarted = true;
		if (archMode)
		{
			randoTimer.start(FlxG.random.float(5, 10), function(tmr:FlxTimer)
			{
				if (curEffect <= 37) doEffect(effectArray[curEffect]);
				else if (curEffect >= 37 && archMode)
				{
					switch (curEffect)
					{
						case 38:
							activeItems[0] += 1;
							ArchPopup.startPopupCustom('You Got an Item!', '+1 Shield ( ' + activeItems[0] + ' Left)', 'Color');
						case 39:
							activeItems[1] = 1;
							ArchPopup.startPopupCustom('You Got an Item!', "Blue Ball's Curse", 'Color');
						case 40:
							activeItems[2] += 1;
							ArchPopup.startPopupCustom('You Got an Item!', "Max HP Up!", 'Color');
					}
				}
				tmr.reset(FlxG.random.float(5, 10));
			});
		}
		new FlxTimer().start(FlxG.sound.music.length + 2, function(_)
		{
			endSong();
			trace('FORCE END');
		});
	}

	function findRepeatingPatterns(notePositions:Array<Int>):Array<PatternResult>
	{
		var results:Array<PatternResult> = [];

		for (patternLength in 0...notePositions.length)
		{
			var currentPattern:Array<Int> = notePositions.slice(0, patternLength);
			var repetitions:Int = countPatternRepetitions(notePositions, currentPattern);

			if (repetitions > 1)
			{
				var result:PatternResult = {
					pattern: currentPattern,
					repetitions: repetitions,
					start: Std.int(notePositions.indexOf(currentPattern[0])),
					patternLength: currentPattern.length,
					end: Std.int(notePositions.indexOf(currentPattern[0])) + (currentPattern.length * repetitions) - 1
				};
				results.push(result);
			}
		}

		return results;
	}

	function countPatternRepetitions(notePositions:Array<Int>, pattern:Array<Int>):Int
	{
		if (pattern.length == 0)
		{
			trace("Pattern is empty");
			return 0;
		}

		var repetitions:Int = 0;
		var i:Int = 0;

		while (i < notePositions.length)
		{
			var currentIndex:Int = i % pattern.length;
			if (notePositions[i] != pattern[currentIndex])
			{
				i += pattern.length - currentIndex; // Skip to the next potential pattern start
				continue;
			}

			if (currentIndex == pattern.length - 1)
			{
				repetitions++;
			}

			i++;
		}

		return repetitions;
	}

	function modifyNoteData(noteData:Int, playerNote:Bool):Int
	{
		var initNoteData:Int = noteData;
		var gottaHitNote:Bool = playerNote;
		var daNoteData:Int = initNoteData;
		switch (chartModifier)
		{
			case "Random":
				daNoteData = FlxG.random.int(0, mania);
			case "RandomBasic":
				var randomDirection:Int;
				do
				{
					randomDirection = FlxG.random.int(0, mania);
				}
				while (randomDirection == prevNoteData && mania > 1);
				prevNoteData = randomDirection;
				daNoteData = randomDirection;
			case "RandomComplex":
				var thisNoteData = daNoteData;
				if (initialNoteData == -1)
				{
					initialNoteData = daNoteData;
					daNoteData = FlxG.random.int(0, mania);
				}
				else
				{
					var newNoteData:Int;
					do
					{
						newNoteData = FlxG.random.int(0, mania);
					}
					while (newNoteData == prevNoteData && mania > 1);
					if (thisNoteData == initialNoteData)
					{
						daNoteData = prevNoteData;
					}
					else
					{
						daNoteData = newNoteData;
					}
				}
				prevNoteData = daNoteData;
				initialNoteData = thisNoteData;
			case "Flip":
				if (gottaHitNote)
				{
					daNoteData = mania - Std.int(initNoteData % Note.ammo[mania]);
				}
			case "Pain":
				daNoteData = daNoteData - Std.int(initNoteData % Note.ammo[mania]);
			case "4K Only":
				daNoteData = getNumberFromAnims(daNoteData, SONG.mania);
			case "ManiaConverter":
				if (SONG.mania != 3)
				{
					daNoteData = getNumberFromAnims(daNoteData, 3);
				}
				daNoteData = getNumberFromAnims(daNoteData, SONG.mania);
			case "Stairs":
				daNoteData = stair % Note.ammo[mania];
				stair++;
			case "Wave":
				// Sketchie... WHY?!
				var ammoFromFortnite:Int = Note.ammo[mania];
				var luigiSex:Int = (ammoFromFortnite * 2 - 2);
				var marioSex:Int = stair++ % luigiSex;
				if (marioSex < ammoFromFortnite)
				{
					daNoteData = marioSex;
				}
				else
				{
					daNoteData = luigiSex - marioSex;
				}
			case "Trills":
				var ammoFromFortnite:Int = Note.ammo[mania];
				var luigiSex:Int = (ammoFromFortnite * 2 - 2);
				var marioSex:Int;
				do
				{
					marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
					if (marioSex < ammoFromFortnite)
					{
						daNoteData = marioSex;
					}
					else
					{
						daNoteData = luigiSex - marioSex;
					}
				}
				while (daNoteData == prevNoteData && mania > 1);
				prevNoteData = daNoteData;
			case "Ew":
				// I hate that I used Sketchie's variables as a base for this... ;-;
				var ammoFromFortnite:Int = Note.ammo[mania];
				var luigiSex:Int = (ammoFromFortnite * 2 - 2);
				var marioSex:Int = stair++ % luigiSex;
				var noteIndex:Int = Std.int(marioSex / 2);
				var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
				daNoteData = noteIndex + noteDirection;
				// If the note index is out of range, wrap it around
				if (daNoteData < 0)
				{
					daNoteData = 1;
				}
				else if (daNoteData >= ammoFromFortnite)
				{
					daNoteData = ammoFromFortnite - 2;
				}
			case "Death":
				var ammoFromFortnite:Int = Note.ammo[mania];
				var luigiSex:Int = (ammoFromFortnite * 4 - 4);
				var marioSex:Int = stair++ % luigiSex;
				var step:Int = Std.int(luigiSex / 3);

				if (marioSex < ammoFromFortnite)
				{
					daNoteData = marioSex % step;
				}
				else if (marioSex < ammoFromFortnite * 2)
				{
					daNoteData = (marioSex - ammoFromFortnite) % step + step;
				}
				else if (marioSex < ammoFromFortnite * 3)
				{
					daNoteData = (marioSex - ammoFromFortnite * 2) % step + step * 2;
				}
				else
				{
					daNoteData = (marioSex - ammoFromFortnite * 3) % step + step * 3;
				}
			case "What":
				switch (stair % (2 * Note.ammo[mania]))
				{
					case 0:
					case 1:
					case 2:
					case 3:
					case 4:
						daNoteData = stair % Note.ammo[mania];
					default:
						daNoteData = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
				}
				stair++;
			case "Amalgam":
				{
					var modifierNames:Array<String> = [
						"Random", "RandomBasic", "RandomComplex", "Flip", "Pain", "Stairs", "Wave", "Huh", "Ew", "What", "Jack Wave", "SpeedRando", "Trills"
					];

					if (caseExecutionCount <= 0)
					{
						currentModifier = FlxG.random.int(-1, (modifierNames.length - 1)); // Randomly select a case from 0 to 9
						caseExecutionCount = FlxG.random.int(1, 51); // Randomly select a number from 1 to 50
						trace("Active Modifier: " + modifierNames[currentModifier] + ", Notes to edit: " + caseExecutionCount);
					}
					// trace('Notes remaining: ' + caseExecutionCount);
					caseExecutionCount--;
					switch (currentModifier)
					{
						case 0: // "Random"
							daNoteData = FlxG.random.int(0, mania);
						case 1: // "RandomBasic"
							var randomDirection:Int;
							do
							{
								randomDirection = FlxG.random.int(0, mania);
							}
							while (randomDirection == prevNoteData && mania > 1);
							prevNoteData = randomDirection;
							daNoteData = randomDirection;
						case 2: // "RandomComplex"
							var thisNoteData = daNoteData;
							if (initialNoteData == -1)
							{
								initialNoteData = daNoteData;
								daNoteData = FlxG.random.int(0, mania);
							}
							else
							{
								var newNoteData:Int;
								do
								{
									newNoteData = FlxG.random.int(0, mania);
								}
								while (newNoteData == prevNoteData && mania > 1);
								if (thisNoteData == initialNoteData)
								{
									daNoteData = prevNoteData;
								}
								else
								{
									daNoteData = newNoteData;
								}
							}
							prevNoteData = daNoteData;
							initialNoteData = thisNoteData;
						case 3: // "Flip"
							if (gottaHitNote)
							{
								daNoteData = mania - Std.int(initNoteData % Note.ammo[mania]);
							}
						case 4: // "Pain"
							daNoteData = daNoteData - Std.int(initNoteData % Note.ammo[mania]);
						case 5: // "Stairs"
							daNoteData = stair % Note.ammo[mania];
							stair++;
						case 6: // "Wave"
							// Sketchie... WHY?!
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 2 - 2);
							var marioSex:Int = stair++ % luigiSex;
							if (marioSex < ammoFromFortnite)
							{
								daNoteData = marioSex;
							}
							else
							{
								daNoteData = luigiSex - marioSex;
							}
						case 7: // "Huh"
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 4 - 4);
							var marioSex:Int = stair++ % luigiSex;
							var step:Int = Std.int(luigiSex / 3);
							var waveIndex:Int = Std.int(marioSex / step);
							var waveDirection:Int = waveIndex % 2 == 0 ? 1 : -1;
							var waveRepeat:Int = Std.int(waveIndex / 2);
							var repeatStep:Int = marioSex % step;
							if (repeatStep < waveRepeat)
							{
								daNoteData = waveIndex * step + waveDirection * repeatStep;
							}
							else
							{
								daNoteData = waveIndex * step + waveDirection * (waveRepeat * 2 - repeatStep);
							}
							if (daNoteData < 0)
							{
								daNoteData = 0;
							}
							else if (daNoteData >= ammoFromFortnite)
							{
								daNoteData = ammoFromFortnite - 1;
							}
						case 8: // "Ew"
							// I hate that I used Sketchie's variables as a base for this... ;-;
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 2 - 2);
							var marioSex:Int = stair++ % luigiSex;
							var noteIndex:Int = Std.int(marioSex / 2);
							var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
							daNoteData = noteIndex + noteDirection;
							// If the note index is out of range, wrap it around
							if (daNoteData < 0)
							{
								daNoteData = 1;
							}
							else if (daNoteData >= ammoFromFortnite)
							{
								daNoteData = ammoFromFortnite - 2;
							}
						case 9: // "What"
							switch (stair % (2 * Note.ammo[mania]))
							{
								case 0:
								case 1:
								case 2:
								case 3:
								case 4:
									daNoteData = stair % Note.ammo[mania];
								default:
									daNoteData = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
							}
							stair++;
						case 10: // Jack Wave
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 2 - 2);
							var marioSex:Int = Std.int((stair++ % (luigiSex * 4)) / 4);
							if (marioSex < ammoFromFortnite)
							{
								daNoteData = marioSex;
							}
							else
							{
								daNoteData = luigiSex - marioSex;
							}
						case 11: // SpeedRando
						// Handled by SpeedRando Code below!
						case 12: // Trills
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 2 - 2);
							var marioSex:Int;
							do
							{
								marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
								if (marioSex < ammoFromFortnite)
								{
									daNoteData = marioSex;
								}
								else
								{
									daNoteData = luigiSex - marioSex;
								}
							}
							while (daNoteData == prevNoteData && mania > 1);
							prevNoteData = daNoteData;
						default:
							// Default case (optional)
					}
				}
		}
		return daNoteData;
	}

	public static function getNumberFromAnims(note:Int, mania:Int):Int
	{
		var animMap:Map<String, Int> = new Map<String, Int>();
		animMap.set("LEFT", 0);
		animMap.set("DOWN", 1);
		animMap.set("UP", 2);
		animMap.set("RIGHT", 3);

		var anims:Array<String> = EKData.keysShit.get(mania).get("anims");
		var animKeys:Array<String> = [
			for (key in animMap.keys())
				if (key == "LEFT") "RIGHT" else if (key == "RIGHT") "LEFT" else key
		];

		if (mania > 3)
		{
			var anim = animKeys[note];
			var matchingIndices:Array<Int> = [];
			if (note < animKeys.length)
			{
				for (i in 0...anims.length)
				{
					if (anims[i] == anim)
					{
						matchingIndices.push(i);
					}
				}
				if (matchingIndices.length > 0)
				{
					var randomIndex = Std.int(Math.random() * matchingIndices.length);
					return matchingIndices[randomIndex];
				}
				else
				{
					var randomIndex = Std.int(Math.random() * anims.length);
					return randomIndex;
				}
			}
			else
			{
				if (matchingIndices.length > 0)
				{
					var randomIndex = Std.int(Math.random() * matchingIndices.length);
					return matchingIndices[randomIndex];
				}
				else
				{
					var randomIndex = Std.int(Math.random() * anims.length);
					return randomIndex;
				}
			}
		}
		else
		{ // mania == 3
			var anim = anims[note];
			if (note < anims.length)
			{
				if (animMap.exists(anim))
				{
					return animMap.get(anim);
				}
				else
				{
					throw 'No matching animation found';
				}
			}
			else
			{
				return animMap.get(anim);
			}
		}
	}

	public static function getNumberFromAnimsSpecial(note:Int, mania:Int):Int
	{
		var animMap:Map<String, Int> = new Map<String, Int>();
		animMap.set("LEFT", 0);
		animMap.set("DOWN", 1);
		animMap.set("UP", 2);
		animMap.set("RIGHT", 3);

		var anims:Array<String> = EKData.keysShit.get(mania).get("anims");
		var animKeys:Array<String> = [
			for (key in animMap.keys())
				if (key == "LEFT") "RIGHT" else if (key == "RIGHT") "LEFT" else key
		];

		if (note < animKeys.length)
		{
			var anim = animKeys[note];
			var matchingIndices:Array<Int> = [];
			for (i in 0...anims.length)
			{
				if (anims[i] == anim)
				{
					matchingIndices.push(i);
				}
			}
			if (matchingIndices.length > 0)
			{
				var randomIndex = Std.int(Math.random() * matchingIndices.length);
				return matchingIndices[randomIndex];
			}
			else
			{
				var randomIndex = Std.int(Math.random() * anims.length);
				return randomIndex;
			}
		}
		else
		{
			throw 'Note value is out of range';
		}
	}

	var debugNum:Int = 0;
	var stair:Int = 0;
	var noteIndex:Int = -1;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch (songSpeedType)
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
		{
			try
			{
				if (songData.needsVoices) vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			}
			catch (error:Dynamic)
			{
				trace("Error loading vocals:", error);
				Application.current.window.alert("Error: Expected Vocals, but none were found! \n" + error, "Sound Error");
				vocals = new FlxSound();
			}
		}
		else
		{
			vocals = new FlxSound();
		}

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		{
		#else
		if (OpenFlAssets.exists(file))
		{
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset + SONG.offset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		/*
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if (ClientPrefs.getGameplaySetting('generatorType', 'Chart') == "Time")
				{
					section.sectionNotes.sort(function(a:Array<Float>, b:Array<Float>):Int
					{
						return Std.int(a[0] - b[0]);
					});

				}
				// add here
				if (songNotes.length >= 4 && !Std.isOfType(songNotes[3], String) || songNotes[3] == null)
				{
					if (Std.isOfType(songNotes[2], String))
					{
						songNotes[3] = songNotes[2];
					}
				}
			}
		}
	 */

		function findPatterns(noteData:Array<Int>):Array<PatternResult>
		{
			var notePositions:Array<Int> = noteData;
			var patternResults:Array<PatternResult> = findRepeatingPatterns(notePositions);

			if (patternResults.length > 0)
			{
				for (result in patternResults)
				{
					trace("Pattern found: " + result.pattern);
					trace("Starts at: " + result.start);
					trace("Ends at: " + result.end);
					trace("Number of repetitions: " + result.repetitions);
					trace("------");
				}
			}
			else
			{
				trace("No repeating patterns found.");
			}

			return patternResults;
		}

		// if (chartModifier == 'RandomPatterned')
		// {
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				allNotes.push(songNotes[1]);
				// trace("Notes: " + allNotes);
			}
		}
		var patterns:Array<PatternResult> = findPatterns(allNotes);
		// }
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int;
				if (chartModifier != "4K Only" && chartModifier != "ManiaConverter")
				{
					daNoteData = Std.int(songNotes[1] % Note.ammo[mania]);
				}
				else
				{
					daNoteData = Std.int(songNotes[1] % Note.ammo[SONG.mania]);
				}
				var gottaHitNote:Bool = section.mustHitSection;
				if (chartModifier != "4K Only" && chartModifier != "ManiaConverter")
				{
					if (songNotes[1] > (Note.ammo[mania] - 1))
					{
						gottaHitNote = !section.mustHitSection;
					}
				}
				else
				{
					if (songNotes[1] > (Note.ammo[SONG.mania] - 1))
					{
						gottaHitNote = !section.mustHitSection;
					}
				}
				if (ClientPrefs.getGameplaySetting('generatorType', 'Chart') != "Time")
				{
					switch (chartModifier)
					{
						case "Random":
							daNoteData = FlxG.random.int(0, mania);
						case "RandomBasic":
							var randomDirection:Int;
							do
							{
								randomDirection = FlxG.random.int(0, mania);
							}
							while (randomDirection == prevNoteData && mania > 1);
							prevNoteData = randomDirection;
							daNoteData = randomDirection;
						case "RandomComplex":
							var thisNoteData = daNoteData;
							if (initialNoteData == -1)
							{
								initialNoteData = daNoteData;
								daNoteData = FlxG.random.int(0, mania);
							}
							else
							{
								var newNoteData:Int;
								do
								{
									newNoteData = FlxG.random.int(0, mania);
								}
								while (newNoteData == prevNoteData && mania > 1);
								if (thisNoteData == initialNoteData)
								{
									daNoteData = prevNoteData;
								}
								else
								{
									daNoteData = newNoteData;
								}
							}
							prevNoteData = daNoteData;
							initialNoteData = thisNoteData;
						case "Flip":
							if (gottaHitNote)
							{
								daNoteData = mania - Std.int(songNotes[1] % Note.ammo[mania]);
							}
						case "Pain":
							daNoteData = daNoteData - Std.int(songNotes[1] % Note.ammo[mania]);
						case "4K Only":
							daNoteData = getNumberFromAnims(daNoteData, SONG.mania);
						case "ManiaConverter":
							daNoteData = getNumberFromAnims(daNoteData, mania);
						case "Stairs":
							daNoteData = stair % Note.ammo[mania];
							stair++;
						case "Wave":
							// Sketchie... WHY?!
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 2 - 2);
							var marioSex:Int = stair++ % luigiSex;
							if (marioSex < ammoFromFortnite)
							{
								daNoteData = marioSex;
							}
							else
							{
								daNoteData = luigiSex - marioSex;
							}
						case "Trills":
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 2 - 2);
							var marioSex:Int;
							do
							{
								marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
								if (marioSex < ammoFromFortnite)
								{
									daNoteData = marioSex;
								}
								else
								{
									daNoteData = luigiSex - marioSex;
								}
							}
							while (daNoteData == prevNoteData && mania > 1);
							prevNoteData = daNoteData;
						case "Ew":
							// I hate that I used Sketchie's variables as a base for this... ;-;
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 2 - 2);
							var marioSex:Int = stair++ % luigiSex;
							var noteIndex:Int = Std.int(marioSex / 2);
							var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
							daNoteData = noteIndex + noteDirection;
							// If the note index is out of range, wrap it around
							if (daNoteData < 0)
							{
								daNoteData = 1;
							}
							else if (daNoteData >= ammoFromFortnite)
							{
								daNoteData = ammoFromFortnite - 2;
							}
						case "Death":
							var ammoFromFortnite:Int = Note.ammo[mania];
							var luigiSex:Int = (ammoFromFortnite * 4 - 4);
							var marioSex:Int = stair++ % luigiSex;
							var step:Int = Std.int(luigiSex / 3);

							if (marioSex < ammoFromFortnite)
							{
								daNoteData = marioSex % step;
							}
							else if (marioSex < ammoFromFortnite * 2)
							{
								daNoteData = (marioSex - ammoFromFortnite) % step + step;
							}
							else if (marioSex < ammoFromFortnite * 3)
							{
								daNoteData = (marioSex - ammoFromFortnite * 2) % step + step * 2;
							}
							else
							{
								daNoteData = (marioSex - ammoFromFortnite * 3) % step + step * 3;
							}
						case "What":
							switch (stair % (2 * Note.ammo[mania]))
							{
								case 0:
								case 1:
								case 2:
								case 3:
								case 4:
									daNoteData = stair % Note.ammo[mania];
								default:
									daNoteData = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
							}
							stair++;
						case "Amalgam":
							{
								var modifierNames:Array<String> = [
									"Random", "RandomBasic", "RandomComplex", "Flip", "Pain", "Stairs", "Wave", "Huh", "Ew", "What", "Jack Wave", "SpeedRando",
									"Trills"
								];

								if (caseExecutionCount <= 0)
								{
									currentModifier = FlxG.random.int(-1, (modifierNames.length - 1)); // Randomly select a case from 0 to 9
									caseExecutionCount = FlxG.random.int(1, 51); // Randomly select a number from 1 to 50
									trace("Active Modifier: " + modifierNames[currentModifier] + ", Notes to edit: " + caseExecutionCount);
								}
								// trace('Notes remaining: ' + caseExecutionCount);
								caseExecutionCount--;
								switch (currentModifier)
								{
									case 0: // "Random"
										daNoteData = FlxG.random.int(0, mania);
									case 1: // "RandomBasic"
										var randomDirection:Int;
										do
										{
											randomDirection = FlxG.random.int(0, mania);
										}
										while (randomDirection == prevNoteData && mania > 1);
										prevNoteData = randomDirection;
										daNoteData = randomDirection;
									case 2: // "RandomComplex"
										var thisNoteData = daNoteData;
										if (initialNoteData == -1)
										{
											initialNoteData = daNoteData;
											daNoteData = FlxG.random.int(0, mania);
										}
										else
										{
											var newNoteData:Int;
											do
											{
												newNoteData = FlxG.random.int(0, mania);
											}
											while (newNoteData == prevNoteData && mania > 1);
											if (thisNoteData == initialNoteData)
											{
												daNoteData = prevNoteData;
											}
											else
											{
												daNoteData = newNoteData;
											}
										}
										prevNoteData = daNoteData;
										initialNoteData = thisNoteData;
									case 3: // "Flip"
										if (gottaHitNote)
										{
											daNoteData = mania - Std.int(songNotes[1] % Note.ammo[mania]);
										}
									case 4: // "Pain"
										daNoteData = daNoteData - Std.int(songNotes[1] % Note.ammo[mania]);
									case 5: // "Stairs"
										daNoteData = stair % Note.ammo[mania];
										stair++;
									case 6: // "Wave"
										// Sketchie... WHY?!
										var ammoFromFortnite:Int = Note.ammo[mania];
										var luigiSex:Int = (ammoFromFortnite * 2 - 2);
										var marioSex:Int = stair++ % luigiSex;
										if (marioSex < ammoFromFortnite)
										{
											daNoteData = marioSex;
										}
										else
										{
											daNoteData = luigiSex - marioSex;
										}
									case 7: // "Huh"
										var ammoFromFortnite:Int = Note.ammo[mania];
										var luigiSex:Int = (ammoFromFortnite * 4 - 4);
										var marioSex:Int = stair++ % luigiSex;
										var step:Int = Std.int(luigiSex / 3);
										var waveIndex:Int = Std.int(marioSex / step);
										var waveDirection:Int = waveIndex % 2 == 0 ? 1 : -1;
										var waveRepeat:Int = Std.int(waveIndex / 2);
										var repeatStep:Int = marioSex % step;
										if (repeatStep < waveRepeat)
										{
											daNoteData = waveIndex * step + waveDirection * repeatStep;
										}
										else
										{
											daNoteData = waveIndex * step + waveDirection * (waveRepeat * 2 - repeatStep);
										}
										if (daNoteData < 0)
										{
											daNoteData = 0;
										}
										else if (daNoteData >= ammoFromFortnite)
										{
											daNoteData = ammoFromFortnite - 1;
										}
									case 8: // "Ew"
										// I hate that I used Sketchie's variables as a base for this... ;-;
										var ammoFromFortnite:Int = Note.ammo[mania];
										var luigiSex:Int = (ammoFromFortnite * 2 - 2);
										var marioSex:Int = stair++ % luigiSex;
										var noteIndex:Int = Std.int(marioSex / 2);
										var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
										daNoteData = noteIndex + noteDirection;
										// If the note index is out of range, wrap it around
										if (daNoteData < 0)
										{
											daNoteData = 1;
										}
										else if (daNoteData >= ammoFromFortnite)
										{
											daNoteData = ammoFromFortnite - 2;
										}
									case 9: // "What"
										switch (stair % (2 * Note.ammo[mania]))
										{
											case 0:
											case 1:
											case 2:
											case 3:
											case 4:
												daNoteData = stair % Note.ammo[mania];
											default:
												daNoteData = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
										}
										stair++;
									case 10: // Jack Wave
										var ammoFromFortnite:Int = Note.ammo[mania];
										var luigiSex:Int = (ammoFromFortnite * 2 - 2);
										var marioSex:Int = Std.int((stair++ % (luigiSex * 4)) / 4);
										if (marioSex < ammoFromFortnite)
										{
											daNoteData = marioSex;
										}
										else
										{
											daNoteData = luigiSex - marioSex;
										}
									case 11: // SpeedRando
									// Handled by SpeedRando Code below!
									case 12: // Trills
										var ammoFromFortnite:Int = Note.ammo[mania];
										var luigiSex:Int = (ammoFromFortnite * 2 - 2);
										var marioSex:Int;
										do
										{
											marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
											if (marioSex < ammoFromFortnite)
											{
												daNoteData = marioSex;
											}
											else
											{
												daNoteData = luigiSex - marioSex;
											}
										}
										while (daNoteData == prevNoteData && mania > 1);
										prevNoteData = daNoteData;
									default:
										// Default case (optional)
								}
							}
					}
				}
				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
				swagNote.noteType = songNotes[3];
				swagNote.noteIndex = noteIndex++;
				if (chartModifier == 'Amalgam' && currentModifier == 11)
				{
					swagNote.multSpeed = FlxG.random.float(0.1, 2);
				}
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;
				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				var floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime
							+ (Conductor.stepCrochet * susNote)
							+ (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed + swagNote.multSpeed, 2)),
							daNoteData, oldNote, true);

						sustainNote.prevNote = swagNote;
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.noteIndex = swagNote.noteIndex;
						if (chartModifier == 'Amalgam' && currentModifier == 11)
						{
							sustainNote.multSpeed = swagNote.multSpeed;
						}
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
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
				else if (ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType))
				{
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];

				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset + SONG.offset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};

				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}
		// trace(unspawnNotes.length);
		// playerCounter += 1;
		unspawnNotes.sort(sortByShit);
		timeModifierGeneratorInit();
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
		if (chartModifier == 'SpeedRando')
		{
			var curNotes:Array<Note> = [];
			var allowBrokenSustains = Math.random() < 0.2;

			trace('Broken Sustains?: ' + allowBrokenSustains);
			for (i in 0...unspawnNotes.length)
			{
				if (unspawnNotes[i] != null)
				{ // Null check
					if (unspawnNotes[i].mustPress)
					{
						if (!unspawnNotes[i].isSustainNote)
						{
							unspawnNotes[i].multSpeed = FlxG.random.float(0.1, 2);
							curNotes[unspawnNotes[i].noteData] = unspawnNotes[i];
						}
						else
						{
							if (curNotes[unspawnNotes[i].noteData] != null)
							{
								unspawnNotes[i].multSpeed = curNotes[unspawnNotes[i].noteData].multSpeed;
							}
						}
					}
					if (!unspawnNotes[i].mustPress)
					{
						if (!unspawnNotes[i].isSustainNote)
						{
							unspawnNotes[i].multSpeed = FlxG.random.float(0.1, 2);
							curNotes[unspawnNotes[i].noteData] = unspawnNotes[i];
						}
						else
						{
							if (curNotes[unspawnNotes[i].noteData] != null)
							{
								unspawnNotes[i].multSpeed = curNotes[unspawnNotes[i].noteData].multSpeed;
							}
						}
					}
				}
				if (!allowBrokenSustains)
				{
					if (unspawnNotes[i] != null)
					{
						if (unspawnNotes[i].isSustainNote)
						{
							for (note in unspawnNotes)
							{
								if (note != null && !note.isSustainNote && note.noteIndex == unspawnNotes[i].noteIndex)
								{
									unspawnNotes[i].multSpeed = note.multSpeed;
									break;
								}
							}
						}
					}
				}
			}
		}
		if (chartModifier == "SpeedUp")
		{
			var scaryMode:Bool = Math.random() < 0.5;

			var endSpeed:Float = Math.random() < 0.9 ? Math.random() * 10 : Math.random() * 2 - 1;
			var startSpeed:Float;
			if (endSpeed == 1)
			{
				// If endSpeed is exactly 1, startSpeed is a random float between -0.1 and 0.1
				startSpeed = Math.random() < 0.5 ? Math.random() * 0.1 : -Math.random() * 0.1;
			}
			else if (endSpeed > 1)
			{
				startSpeed = Math.random() * 1.1 - 0.1;
			}
			else
			{
				startSpeed = Math.random() * 1;
			}
			var speedMultiplier:Float = 0;
			var currentMultiplier:Float = 0;
			if (scaryMode)
			{
				speedMultiplier = (endSpeed - startSpeed) / unspawnNotes.length;
			}
			else
			{
				var nonSustainNotes = unspawnNotes.filter(function(note) return !note.isSustainNote);
				speedMultiplier = (endSpeed - startSpeed) / nonSustainNotes.length;
			}
			trace("startSpeed: " + startSpeed);
			trace("endSpeed: " + endSpeed);
			trace("speedMultiplier: " + speedMultiplier);
			trace("currentMultiplier: " + currentMultiplier);
			trace("scaryMode: " + scaryMode);
			trace("noteIndex: " + noteIndex);
			for (i in 0...unspawnNotes.length)
			{
				if (unspawnNotes[i] != null)
				{
					if (scaryMode)
					{
						currentMultiplier += speedMultiplier;
						var noteIndex = unspawnNotes[i].noteIndex;
						var multSpeed = unspawnNotes[i].multSpeed;
						var newMultSpeed = currentMultiplier;
						unspawnNotes[i].multSpeed = newMultSpeed;
					}
					else if (!scaryMode && !unspawnNotes[i].isSustainNote)
					{
						currentMultiplier += speedMultiplier;
						var noteIndex = unspawnNotes[i].noteIndex;
						var multSpeed = unspawnNotes[i].multSpeed;
						var newMultSpeed = currentMultiplier;

						unspawnNotes[i].multSpeed = newMultSpeed;
					}
				}
			}
			if (!scaryMode)
			{
				for (i in 0...unspawnNotes.length)
				{
					if (unspawnNotes[i] != null)
					{
						if (unspawnNotes[i].isSustainNote)
						{
							for (note in unspawnNotes)
							{
								if (note != null && !note.isSustainNote && note.noteIndex == unspawnNotes[i].noteIndex)
								{
									unspawnNotes[i].multSpeed = note.multSpeed;
									break;
								}
							}
						}
					}
				}
			}
		}
		trace("Generating Checks...");
		if (archMode)
		{
			if (PlayState.SONG.player1.toLowerCase().contains('zenetta') || PlayState.SONG.player2.toLowerCase().contains('zenetta') || PlayState.SONG.gfVersion.toLowerCase().contains('zenetta'))
			{
				itemAmount = 69;
				trace("RESISTANCE OVERRIDE!"); // what are the chances
			}
			// Check if there are any mustPress notes available
			if (unspawnNotes.filter(function(note:Note):Bool
			{
				return note.mustPress && note.noteType == '' && !note.isSustainNote;
			}).length == 0)

			{
				trace('No mustPress notes found. Pausing Note Generation...');
				trace('Waiting for Note Scripts...');
			}
			else
			{
				while (did < itemAmount && !stuck)
				{
					var foundOne:Bool = false;

					for (i in 0...unspawnNotes.length)
					{
						if (did >= itemAmount)
						{
							break; // exit the loop if the required number of notes are created
						}
						if (unspawnNotes[i].mustPress
							&& unspawnNotes[i].noteType == ''
							&& !unspawnNotes[i].isSustainNote
							&& FlxG.random.bool(1)
							&& unspawnNotes.filter(function(note:Note):Bool
							{
								return note.mustPress && note.noteType == '' && !note.isSustainNote;
							}).length != 0)

						{
							unspawnNotes[i].isCheck = true;
							unspawnNotes[i].noteType = 'Check Note';
							did++;
							foundOne = true;
							Sys.print('\rGenerating Checks: ' + did + '/' + itemAmount);
						}
						else if (unspawnNotes.filter(function(note:Note):Bool
						{
							return note.mustPress && note.noteType == '' && !note.isSustainNote;
						}).length == 0)
						{
							Sys.println('');
							trace('Stuck!');
							stuck = true;
							// Additional handling for when it gets stuck
						}
					}
					// Check if there are no more mustPress notes of type '' and not isSustainNote
					if (stuck)
					{
						Sys.println('');
						trace('No more mustPress notes of type \'\' found. Pausing Note Generation...');
						trace('Waiting for Note Scripts...');
						break; // exit the loop if no more mustPress notes of type '' are found
					}
				}
			}
		}
		for (i in 0...unspawnNotes.length)
		{
			if (unspawnNotes[i].noteType == 'Hurt Note') unspawnNotes[i].reloadNote('HURT');
		}
		Sys.println('');
	}

	public var did:Int = 0;
	public var stuck:Bool = false;

	function timeModifierGeneratorInit():Void
	{
		if (ClientPrefs.getGameplaySetting('generatorType', 'Chart') == 'Time')
		{
			var newUnspawnNotes:Array<Note> = []; // create a new array
			for (section in SONG.notes)
			{
				for (songNotes in section.sectionNotes)
				{
					var gottaHitNote:Bool = section.mustHitSection;
					if (chartModifier != "4K Only" && chartModifier != "ManiaConverter")
					{
						if (songNotes[1] > (Note.ammo[mania] - 1))
						{
							gottaHitNote = !section.mustHitSection;
						}
					}
					else
					{
						if (songNotes[1] > (Note.ammo[SONG.mania] - 1))
						{
							gottaHitNote = !section.mustHitSection;
						}
					}
					for (i in 0...unspawnNotes.length)
					{
						if (!unspawnNotes[i].isSustainNote)
						{
							var modifiedNoteData = modifyNoteData(unspawnNotes[i].noteData, unspawnNotes[i].mustPress);
							var newNote = new Note(unspawnNotes[i].strumTime, unspawnNotes[i].noteData); // create a new Note object with the data of the original note
							newNote.mustPress = gottaHitNote;
							newNote.sustainLength = songNotes[2];
							newNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
							newNote.noteType = songNotes[3];
							newNote.noteIndex = noteIndex++;
							if (chartModifier == 'Amalgam' && currentModifier == 11)
							{
								newNote.multSpeed = FlxG.random.float(0.1, 2);
							}
							if (!Std.isOfType(songNotes[3], String))
								newNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
							newNote.scrollFactor.set();
							newNote.noteData = modifiedNoteData; // modify the noteData of the new note
							newUnspawnNotes.push(newNote); // push the new note into the new array
						}
					}

					for (i in 0...unspawnNotes.length)
					{
						if (unspawnNotes[i].isSustainNote)
						{
							var noteIndex = unspawnNotes[i].noteIndex;
							for (j in 0...newUnspawnNotes.length) // iterate over the new array
							{
								if (!newUnspawnNotes[j].isSustainNote && newUnspawnNotes[j].noteIndex == noteIndex)
								{
									var newNote = new Note(unspawnNotes[i].strumTime,
										unspawnNotes[i].noteData); // create a new Note object with the data of the original note
									newNote.mustPress = gottaHitNote;
									newNote.sustainLength = songNotes[2];
									newNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
									newNote.noteType = songNotes[3];
									newNote.noteIndex = noteIndex++;
									if (chartModifier == 'Amalgam' && currentModifier == 11)
									{
										newNote.multSpeed = FlxG.random.float(0.1, 2);
									}
									if (!Std.isOfType(songNotes[3], String))
										newNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
									newNote.scrollFactor.set();
									newNote.noteData = newUnspawnNotes[j].noteData; // modify the noteData of the new note
									newUnspawnNotes.push(newNote); // push the new note into the new array
									break;
								}
							}
						}
					}
				}
			}

			unspawnNotes = newUnspawnNotes; // replace the unspawnNotes array with the new array
		}
		for (i in 0...unspawnNotes.length)
		{
			unspawnNotes[i].reloadNote();
		}
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);

			case 'Philly Glow':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5,
					FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); // This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if (!ClientPrefs.flashing)
					phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('philly/particle', 'image'); // precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}

		if (!eventPushedMap.exists(event.event))
		{
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if (returnedValue != 0)
		{
			return returnedValue;
		}

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; // for lua

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...Note.ammo[mania])
		{
			var twnDuration:Float = 4 / mania;
			var twnStart:Float = 0.5 + ((0.8 / mania) * i);
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if (!ClientPrefs.opponentStrums)
					targetAlpha = 0;
				else if (ClientPrefs.middleScroll)
					targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween && mania > 1)
			{
				// babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, twnDuration, {ease: FlxEase.circOut, startDelay: twnStart});
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
				if (ClientPrefs.middleScroll)
				{
					var separator:Int = Note.separator[mania];

					babyArrow.x += 310;
					if (i > separator)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();

			if (ClientPrefs.showKeybindsOnStart && player == 1)
			{
				for (j in 0...keysArray[mania][i].length)
				{
					var daKeyTxt:FlxText = new FlxText(babyArrow.x, babyArrow.y - 10, 0, InputFormatter.getKeyName(keysArray[mania][i][j]), 32);
					daKeyTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					daKeyTxt.borderSize = 1.25;
					daKeyTxt.alpha = 0;
					daKeyTxt.size = 32 - mania; // essentially if i ever add 0k!?!?
					daKeyTxt.x = babyArrow.x + (babyArrow.width / 2);
					daKeyTxt.x -= daKeyTxt.width / 2;
					add(daKeyTxt);
					daKeyTxt.cameras = [camHUD];
					var textY:Float = (j == 0 ? babyArrow.y - 32 : ((babyArrow.y - 32) + babyArrow.height) - daKeyTxt.height);
					daKeyTxt.y = textY;

					if (mania > 1 && !skipArrowStartTween)
					{
						FlxTween.tween(daKeyTxt, {y: textY + 32, alpha: 1}, twnDuration, {ease: FlxEase.circOut, startDelay: twnStart});
					}
					else
					{
						daKeyTxt.y += 16;
						daKeyTxt.alpha = 1;
					}
					new FlxTimer().start(Conductor.crochet * 0.001 * 12, function(_)
					{
						FlxTween.tween(daKeyTxt, {y: daKeyTxt.y + 32, alpha: 0}, twnDuration, {
							ease: FlxEase.circIn,
							startDelay: twnStart,
							onComplete: function(t)
							{
								remove(daKeyTxt);
							}
						});
					});
				}
			}
		}
	}

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var defaultWidth:Float = 0;
	var defaultHeight:Float = 0;
	function updateNote(note:Note)
	{
		var tMania:Int = mania + 1;
		var noteData:Int = note.noteData;

		note.scale.set(1, 1);
		note.updateHitbox();

		/*
		if (!isPixelStage) {
			note.setGraphicSize(Std.int(note.width * Note.noteScales[mania]));
			note.updateHitbox();
		} else {
			note.setGraphicSize(Std.int(note.width * daPixelZoom * (Note.noteScales[mania] + 0.3)));
			note.updateHitbox();
		}
		*/

		// Like reloadNote()
		defaultWidth = 157;
		defaultHeight = 154;
		var lastScaleY:Float = note.scale.y;
		if (EKMode) {
			if (isPixelStage) {
				note.setGraphicSize(Std.int(note.width * PlayState.daPixelZoom * Note.pixelScales[mania]));
				if(note.isSustainNote) {
					note.offsetX += lastNoteOffsetXForPixelAutoAdjusting;
					lastNoteOffsetXForPixelAutoAdjusting = (note.width - 7) * (PlayState.daPixelZoom / 2);
					note.offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
				}
			} else {
				// Like loadNoteAnims()

				if (!note.isSustainNote) {
					note.setGraphicSize(Std.int(defaultWidth * Note.scales[mania]));
				} else {
					note.setGraphicSize(Std.int(defaultWidth * Note.scales[mania]), Std.int(defaultHeight * Note.scales[0]));
				}
				note.updateHitbox();
			}
		}
		else
		{
			if (isPixelStage) {
				note.setGraphicSize(Std.int(note.width * PlayState.daPixelZoom));
				if(note.isSustainNote) {
					note.offsetX += lastNoteOffsetXForPixelAutoAdjusting;
					lastNoteOffsetXForPixelAutoAdjusting = (note.width - 7) * (PlayState.daPixelZoom / 2);
					note.offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
	
					/*if(animName != null && !animName.endsWith('end'))
					{
						lastScaleY /= lastNoteScaleToo;
						lastNoteScaleToo = (6 / height);
						lastScaleY *= lastNoteScaleToo;
					}*/
				}
			} else {
				// Like loadNoteAnims()

				note.setGraphicSize(Std.int(note.width * 0.7));
				note.updateHitbox();
			}
		}

		//if (note.isSustainNote) {note.scale.y = lastScaleY;}
		note.updateHitbox();

		// Like new()

		var prevNote:Note = note.prevNote;
		
		if (note.isSustainNote && prevNote != null) {
			
			note.offsetX += note.width / 2;

			if (EKMode) {
				note.animation.play(Note.keysShit.get(mania).get('letters')[noteData] + ' tail');
			} else {
				note.animation.play(Note.colArray[noteData % 4] + 'holdend');
			}

			note.updateHitbox();

			note.offsetX -= note.width / 2;

			if (PlayState.isPixelStage)
				note.offsetX += 30 * Note.pixelScales[mania];

			if (note != null && prevNote != null && prevNote.isSustainNote && prevNote.animation != null) { // haxe flixel
				if (EKMode) {
					prevNote.animation.play(Note.keysShit.get(mania).get('letters')[prevNote.noteData] + ' hold');}
				else {
					prevNote.animation.play(Note.colArray[prevNote.noteData % 4] + 'hold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

				if(PlayState.isPixelStage) { ///Y E  A H
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / prevNote.height); //Auto adjust note size
				}

				prevNote.updateHitbox();
				//trace(prevNote.scale.y);
			}

			if(PlayState.isPixelStage) {
				note.scale.y *= PlayState.daPixelZoom;
				note.updateHitbox();
			}
			
			if (isPixelStage){
				prevNote.scale.y *= daPixelZoom * (Note.pixelScales[mania]); //Fuck urself
				prevNote.updateHitbox();
			}
		} else if (!note.isSustainNote && noteData > - 1 && noteData < tMania) {
			if (note.changeAnim) {
				var animToPlay:String = '';

				animToPlay = Note.keysShit.get(mania).get('letters')[noteData % tMania];
				
				note.animation.play(animToPlay);
			}
		} else if(!note.isSustainNote) {
			note.earlyHitMult = 1;
		}

		// Like set_noteType()

		note.applyManiaChange(); //yep

		if (note.changeColSwap) {
			var hsvNumThing = Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData % tMania]);
			var colSwap = note.colorSwap;

			colSwap.hue = ClientPrefs.arrowHSV[hsvNumThing][0] / 360;
			colSwap.saturation = ClientPrefs.arrowHSV[hsvNumThing][1] / 100;
			colSwap.brightness = ClientPrefs.arrowHSV[hsvNumThing][2] / 100;
		}
	}

	public function changeMania(newValue:Int, skipStrumFadeOut:Bool = false)
	{
		if (chartModifier == '4K Only' || chartModifier == 'maniaConverter')
			return;
		// Set EKMode based on newValue
		EKMode = newValue != 3;
		// funny dissapear transitions
		// while new strums appear
		var daOldMania = mania;

		mania = newValue;
		skipArrowStartTween = skipStrumFadeOut;
		if (!skipStrumFadeOut) {
			for (i in 0...strumLineNotes.members.length) {
				var oldStrum:FlxSprite = strumLineNotes.members[i].clone();
				oldStrum.x = strumLineNotes.members[i].x;
				oldStrum.y = strumLineNotes.members[i].y;
				oldStrum.alpha = strumLineNotes.members[i].alpha;
				oldStrum.scrollFactor.set();
				oldStrum.cameras = [camHUD];
				oldStrum.setGraphicSize(Std.int(oldStrum.width * Note.scales[daOldMania]));
				oldStrum.updateHitbox();
				add(oldStrum);
	
				FlxTween.tween(oldStrum, {alpha: 0}, 0.3, {onComplete: function(_) {
					remove(oldStrum);
				}});
			}
		}

		playerStrums.clear();
		opponentStrums.clear();
		strumLineNotes.clear();
		setOnLuas('mania', mania);

		EKMode = SONG.EKSkin;
		if (mania != Note.defaultMania)
		{
			EKMode = true;
		}
		else
			EKMode = false;
		if (EKMode == null)
		{
			EKMode = true;
		}

		notes.forEachAlive(function(note:Note)
		{
			updateNote(note);
		});

		for (noteI in 0...unspawnNotes.length)
		{
			var note:Note = unspawnNotes[noteI];
			updateNote(note);
		}

		callOnLuas('onChangeMania', [mania, daOldMania]);

		generateStaticArrows(0);
		generateStaticArrows(1);
		updateLuaDefaultPos();
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

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if (carTimer != null)
				carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = false;
			}
			for (timer in modchartTimers)
			{
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

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if (carTimer != null)
				carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = true;
			}
			for (timer in modchartTimers)
			{
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ storyDifficultyText, iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset
					- SONG.offset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + storyDifficultyText, iconP2.getCharacter());
			}
			#end
		}
		setBoyfriendInvuln(1 / 60);
		resumeMP4s();
		noiseSound.resume();
		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused && !Crashed)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ storyDifficultyText, iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset
					- SONG.offset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + storyDifficultyText, iconP2.getCharacter());
			}
		}
		#end
		resumeMP4s();
		noiseSound.resume();
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused && !Crashed)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + storyDifficultyText, iconP2.getCharacter());
		}
		#end

		pauseMP4s();
		noiseSound.pause();
		super.onFocusLost();
	}

	override public function switchTo(nextState:FlxState):Bool
	{
		if (vocals != null)
			vocals.pause();
		pauseMP4s();

		if (xWiggle != null && yWiggle != null && xWiggleTween != null && yWiggleTween != null)
		{
			xWiggle = [0, 0, 0, 0];
			yWiggle = [0, 0, 0, 0];
			for (i in [xWiggleTween, yWiggleTween])
			{
				for (j in i)
				{
					if (j != null && j.active)
						j.cancel();
				}
			}
		}

		if (drunkTween != null && drunkTween.active)
		{
			drunkTween.cancel();
		}

		if (effectTimer != null && effectTimer.active)
			effectTimer.cancel();
		if (randoTimer != null && randoTimer.active)
			randoTimer.cancel();

		return super.switchTo(nextState);
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time + delayOffset;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	function commandSend(command:String)
	{
		if (paused)
		{
			return;
		}
		if (endingSong)
		{
			return;
		}
		try
		{
			callOnLuas('onStreamCommand', [command]);
			trace("Command sent: " + command);
		}
		catch (e:Dynamic)
		{
			trace("Error calling Lua function: " + e);
		}
		commands.remove(command);
	}

	function readChatData()
	{
		if (commands.length == 0)
			return;

		var choose = commands[Std.random(commands.length)];
		trace(choose);
		commandSend(choose);
	}

	function resetChatData()
	{
		commands = [];
	}

	var oldRate:Int = 60;
	var noIcon:Bool = false;

	function doEffect(effect:String)
	{
		if (paused)
			return;
		if (endingSong)
			return;

		var ttl:Float = 0;
		var onEnd:(Void->Void) = null;
		var alwaysEnd:Bool = false;
		var playSound:String = "";
		var playSoundVol:Float = 1;
		// trace(effect);
		switch (effect)
		{
			case 'colorblind':
				filters.push(filterMap.get("Grayscale").filter);
				filtersGame.push(filterMap.get("Grayscale").filter);
				playSound = "colorblind";
				playSoundVol = 0.8;
				ttl = 16;
				onEnd = function()
				{
					filters.remove(filterMap.get("Grayscale").filter);
					filtersGame.remove(filterMap.get("Grayscale").filter);
				}
				noIcon = false;
			case 'blur':
				if (effectsActive[effect] == null || effectsActive[effect] <= 0)
				{
					filtersGame.push(filterMap.get("BlurLittle").filter);
					if (curStage.startsWith('school'))
						blurEffect.setStrength(2, 2);
					else
						blurEffect.setStrength(32, 32);
					strumLineNotes.forEach(function(sprite)
					{
						sprite.shader = blurEffect.shader;
					});
					for (daNote in unspawnNotes)
					{
						if (daNote == null)
							continue;
						if (daNote.strumTime >= Conductor.songPosition)
							daNote.shader = blurEffect.shader;
					}
					for (daNote in notes)
					{
						if (daNote == null)
							continue;
						else
							daNote.shader = blurEffect.shader;
					}
					boyfriend.shader = blurEffect.shader;
					dad.shader = blurEffect.shader;
					if (gf != null) gf.shader = blurEffect.shader;
				}
				noIcon = false;
				playSound = "blur";
				playSoundVol = 0.7;
				ttl = 12;
				onEnd = function()
				{
					strumLineNotes.forEach(function(sprite)
					{
						sprite.shader = null;
					});
					for (daNote in unspawnNotes)
					{
						if (daNote == null)
							continue;
						if (daNote.strumTime >= Conductor.songPosition)
							daNote.shader = null;
					}
					for (daNote in notes)
					{
						if (daNote == null)
							continue;
						else
							daNote.shader = null;
					}
					boyfriend.shader = null;
					dad.shader = null;
					if(gf != null) gf.shader = null;
					blurEffect.setStrength(0, 0);
					filtersGame.remove(filterMap.get("BlurLittle").filter);
				}
			case 'lag':
				noIcon = false;
				lagOn = true;
				playSound = "lag";
				playSoundVol = 0.7;
				ttl = 12;
				onEnd = function()
				{
					lagOn = false;
				}
			case 'mine':
				noIcon = true;
				var startPoint:Int = FlxG.random.int(5, 9);
				var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
				var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
				addNote(1, startPoint, startPoint);
				addNote(1, nextPoint, nextPoint);
				addNote(1, lastPoint, lastPoint);
			case 'warning':
				noIcon = true;
				var startPoint:Int = FlxG.random.int(5, 9);
				var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
				var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
				addNote(2, startPoint, startPoint, -1);
				addNote(2, nextPoint, nextPoint, -1);
				addNote(2, lastPoint, lastPoint, -1);
			case 'heal':
				noIcon = true;
				addNote(3, 5, 9);
			case 'spin':
				noIcon = false;
				for (daNote in unspawnNotes)
				{
					if (daNote == null)
						continue;
					if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote)
						daNote.spinAmount = (FlxG.random.bool() ? 1 : -1) * FlxG.random.float(333 * 0.8, 333 * 1.15);
				}
				for (daNote in notes)
				{
					if (daNote == null)
						continue;
					if (!daNote.isSustainNote)
						daNote.spinAmount = (FlxG.random.bool() ? 1 : -1) * FlxG.random.float(333 * 0.8, 333 * 1.15);
				}
				playSound = "spin";
				ttl = 15;
				onEnd = function()
				{
					for (daNote in unspawnNotes)
					{
						if (daNote == null)
							continue;
						if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote)
						{
							daNote.spinAmount = 0;
							daNote.angle = 0;
						}
					}
					for (daNote in notes)
					{
						if (daNote == null)
							continue;
						if (!daNote.isSustainNote)
						{
							daNote.spinAmount = 0;
							daNote.angle = 0;
						}
					}
				}
			case 'songslower':
				noIcon = false;
				var desiredChangeAmount:Float = FlxG.random.float(0.1, 0.9);
				var changeAmount = playbackRate - Math.max(playbackRate - desiredChangeAmount, 0.2);
				set_playbackRate(playbackRate - changeAmount);
				playbackRate - changeAmount;
				trace(playbackRate);
				playSound = "songslower";
				ttl = 15;
				alwaysEnd = true;
				onEnd = function()
				{
					set_playbackRate(playbackRate + changeAmount);
					playbackRate + changeAmount;
				};
			case 'songfaster':
				noIcon = false;
				var changeAmount:Float = FlxG.random.float(0.1, 0.9);
				set_playbackRate(playbackRate + changeAmount);
				playbackRate + changeAmount;
				playSound = "songfaster";
				ttl = 15;
				alwaysEnd = true;
				onEnd = function()
				{
					set_playbackRate(playbackRate - changeAmount);
					playbackRate - changeAmount;
				};
			case 'scrollswitch':
				noIcon = false;
				effectiveDownScroll = !effectiveDownScroll;
				for (daNote in unspawnNotes)
				{
					if (daNote == null)
						continue;
					daNote.updateFlip();
				}
				for (daNote in notes)
				{
					if (daNote == null)
						continue;
					daNote.updateFlip();
				}
				playSound = "scrollswitch";
				updateScrollUI();
			case 'scrollfaster':
				noIcon = false;
				var changeAmount:Float = FlxG.random.float(1.1, 3);
				effectiveScrollSpeed += changeAmount;
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
				playSound = "scrollfaster";
				ttl = 20;
				alwaysEnd = true;
				onEnd = function() {
					effectiveScrollSpeed -= changeAmount;
					songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
				}
			case 'scrollslower':
				noIcon = false;
				var changeAmount:Float = FlxG.random.float(0.1, 0.9);
				effectiveScrollSpeed -= changeAmount;
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
				playSound = "scrollslower";
				ttl = 20;
				alwaysEnd = true;
				onEnd = function() {
					effectiveScrollSpeed += changeAmount;
					songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
				}
			case 'rainbow':
				noIcon = false;
				for (daNote in unspawnNotes)
				{
					if (daNote == null)
						continue;
					if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote)
						daNote.setColorTransform(1, 1, 1, 1, FlxG.random.int(-255, 255), FlxG.random.int(-255, 255), FlxG.random.int(-255, 255));
					else if (daNote.strumTime >= Conductor.songPosition && daNote.isSustainNote)
						daNote.setColorTransform(1, 1, 1, 1, Std.int(daNote.prevNote.colorTransform.redOffset),
							Std.int(daNote.prevNote.colorTransform.greenOffset), Std.int(daNote.prevNote.colorTransform.blueOffset));
				}
				for (daNote in notes)
				{
					if (daNote == null)
						continue;
					daNote.setColorTransform(1, 1, 1, 1, FlxG.random.int(-255, 255), FlxG.random.int(-255, 255), FlxG.random.int(-255, 255));
				}
				playSound = "rainbow";
				playSoundVol = 0.5;
				ttl = 20;
				onEnd = function()
				{
					for (daNote in unspawnNotes)
					{
						if (daNote == null)
							continue;
						if (daNote.strumTime >= Conductor.songPosition)
							daNote.setColorTransform();
					}
					for (daNote in notes)
					{
						if (daNote == null)
							continue;
						daNote.setColorTransform();
					}
				};
			case 'cover':
				noIcon = false;
				var errorMessage = new FlxSprite();
				var random = FlxG.random.int(0, 13);
				var randomPosition:Bool = true;

				switch (random)
				{
					case 0:
						errorMessage.loadGraphic(Paths.image("zzzzzzzz"));
						errorMessage.scale.x = errorMessage.scale.y = 0.5;
						errorMessage.updateHitbox();
						playSound = "bell";
						playSoundVol = 0.6;
					case 1:
						errorMessage.loadGraphic(Paths.image("scam"));
						playSound = 'scam';
					case 2:
						errorMessage.loadGraphic(Paths.image("funnyskeletonman"));
						playSound = 'doot';
						errorMessage.scale.x = errorMessage.scale.y = 0.8;
					case 3:
						errorMessage.loadGraphic(Paths.image("error"));
						playSound = 'error';
						errorMessage.scale.x = errorMessage.scale.y = 0.8;
						errorMessage.antialiasing = true;
						errorMessage.updateHitbox();
					case 4:
						errorMessage.loadGraphic(Paths.image("nopunch"));
						playSound = 'nopunch';
						errorMessage.scale.x = errorMessage.scale.y = 0.8;
						errorMessage.antialiasing = true;
						errorMessage.updateHitbox();
					case 5:
						errorMessage.loadGraphic(Paths.image("banana"), true, 397, 750);
						errorMessage.animation.add("dance", [0, 1, 2, 3, 4, 5, 6, 7, 8], 9, true);
						errorMessage.animation.play("dance");
						playSound = 'banana';
						playSoundVol = 0.5;
						errorMessage.scale.x = errorMessage.scale.y = 0.5;
					case 6:
						errorMessage = new VideoHandlerMP4();
						cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('mark'), null, false, false).setDimensions(378, 362);
						addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
						errorMessages.add(errorMessage);
					case 7:
						randomPosition = false;
						errorMessage = new VideoHandlerMP4();
						cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('fireworks'), null, false, false).setDimensions(1280, 720);
						addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
						errorMessages.add(errorMessage);
						errorMessage.x = errorMessage.y = 0;
						errorMessage.blend = ADD;
						playSound = 'firework';
					case 8:
						randomPosition = false;
						errorMessage = new VideoHandlerMP4();
						cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('spiral'), null, false, false).setDimensions(1280, 720);
						addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
						errorMessages.add(errorMessage);
						errorMessage.x = errorMessage.y = 0;
						errorMessage.blend = ADD;
						playSound = 'spiral';
					case 9:
						randomPosition = false;
						errorMessage = new VideoHandlerMP4();
						cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('thingy'), null, false, false).setDimensions(1280, 720);
						addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
						errorMessages.add(errorMessage);
						errorMessage.x = errorMessage.y = 0;
						errorMessage.blend = ADD;
						playSound = 'thingy';
					case 10:
						randomPosition = false;
						errorMessage = new VideoHandlerMP4();
						cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('light'), null, false, false).setDimensions(1280, 720);
						addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
						errorMessages.add(errorMessage);
						errorMessage.x = errorMessage.y = 0;
						errorMessage.blend = ADD;
						playSound = 'light';
					case 11:
						randomPosition = false;
						errorMessage = new VideoHandlerMP4();
						cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('snow'), null, false, false).setDimensions(1280, 720);
						addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
						errorMessages.add(errorMessage);
						errorMessage.x = errorMessage.y = 0;
						errorMessage.blend = ADD;
						playSound = 'snow';
						playSoundVol = 0.6;
					case 12:
						randomPosition = false;
						errorMessage = new VideoHandlerMP4();
						cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('spiral2'), null, false, false).setDimensions(1280, 720);
						addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
						errorMessages.add(errorMessage);
						errorMessage.x = errorMessage.y = 0;
						errorMessage.blend = ADD;
						playSound = 'spiral';
					case 13:
						randomPosition = false;
						errorMessage = new VideoHandlerMP4();
						cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('wheel'), null, false, false).setDimensions(1280, 720);
						addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
						errorMessages.add(errorMessage);
						errorMessage.x = errorMessage.y = 0;
						errorMessage.blend = ADD;
						playSound = 'wheel';
				}

				if (randomPosition)
				{
					var position = FlxG.random.int(0, 4);
					switch (position)
					{
						case 0:
							errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
							errorMessage.screenCenter(Y);
							errorMessages.add(errorMessage);
						case 1:
							errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
							errorMessage.y = (effectiveDownScroll ? FlxG.height - errorMessage.height : 0);
							errorMessages.add(errorMessage);
						case 2:
							errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
							errorMessage.y = (effectiveDownScroll ? 0 : FlxG.height - errorMessage.height);
							errorMessages.add(errorMessage);
						case 3:
							errorMessage.screenCenter(XY);
							errorMessages.add(errorMessage);
						case 4:
							errorMessage.x = 0;
							errorMessage.y = 0;
							FlxTween.circularMotion(errorMessage, FlxG.width / 2 - errorMessage.width / 2, FlxG.height / 2 - errorMessage.height / 2,
								errorMessage.width / 2, 0, true, 6, true, {
									onStart: function(_)
									{
										errorMessages.add(errorMessage);
									},
									type: LOOPING
								});
					}
				}

				ttl = 12;
				alwaysEnd = true;
				onEnd = function()
				{
					errorMessage.kill();
					errorMessages.remove(errorMessage);
					FlxDestroyUtil.destroy(errorMessage);
				}

			/*case 'mixup':
				noIcon = false;
				mixUp();
				playSound = "mixup";
				ttl = 7;
				onEnd = function()
				{
					mixUp(true);
				}*/
			case 'ghost':
				noIcon = false;
				for (daNote in unspawnNotes)
				{
					if (daNote == null)
						continue;
					if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote)
						daNote.doGhost();
					else if (daNote.strumTime >= Conductor.songPosition && daNote.isSustainNote)
						daNote.doGhost(daNote.prevNote.ghostSpeed, daNote.prevNote.ghostSine);
				}
				for (daNote in notes)
				{
					if (daNote == null)
						continue;
					if (!daNote.isSustainNote)
						daNote.doGhost();
					else if (daNote.isSustainNote)
						daNote.doGhost(daNote.prevNote.ghostSpeed, daNote.prevNote.ghostSine);
				}
				playSound = "ghost";
				playSoundVol = 0.5;
				ttl = 15;
				onEnd = function()
				{
					for (daNote in unspawnNotes)
					{
						if (daNote == null)
							continue;
						if (daNote.strumTime >= Conductor.songPosition)
							daNote.undoGhost();
					}
					for (daNote in notes)
					{
						if (daNote == null)
							continue;
						daNote.undoGhost();
					}
				};
			/*case 'wiggle':
				noIcon = false;
				xWiggle = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
				yWiggle = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
				for (i in [xWiggleTween, yWiggleTween])
				{
					for (j in i)
					{
						if (j != null && j.active)
							j.cancel();
					}
				}

				var xFrom:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
				var xTo:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
				var yFrom:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
				var yTo:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
				var xTime:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
				var yTime:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
				var disableX = false;
				var disableY = false;
				var random = FlxG.random.int(0, mania);
				switch (random)
				{
					case 0:
						var ranTime = FlxG.random.float(0.3, 0.9);
						var ranMove = FlxG.random.float(25, 50);
						for (i in 0...xFrom.length)
							xFrom[i] = -ranMove;
						for (i in 0...xTo.length)
							xTo[i] = ranMove;
						for (i in 0...xTime.length)
							xTime[i] = ranTime;
						disableY = true;
					case 1:
						var ranTime = FlxG.random.float(0.3, 0.9);
						var ranMove = FlxG.random.float(25, 50);
						for (i in 0...yFrom.length)
							yFrom[i] = -ranMove;
						for (i in 0...yTo.length)
							yTo[i] = ranMove;
						for (i in 0...yTime.length)
							yTime[i] = ranTime;
						disableX = true;
					case 2:
						var ranTime = FlxG.random.float(0.3, 0.9);
						var ranMove = FlxG.random.float(25, 50);
						for (i in 0...xFrom.length)
							xFrom[i] = -ranMove;
						for (i in 0...xTo.length)
							xTo[i] = ranMove;
						for (i in 0...xTime.length)
							xTime[i] = ranTime;
						for (i in 0...yFrom.length)
							yFrom[i] = -ranMove * (i % 2 == 0 ? 1 : -1);
						for (i in 0...yTo.length)
							yTo[i] = ranMove * (i % 2 == 0 ? 1 : -1);
						for (i in 0...yTime.length)
							yTime[i] = ranTime;
					case 3:
						var ranTime = FlxG.random.float(0.3, 0.9);
						var ranMove = FlxG.random.float(25, 50);
						for (i in 0...xFrom.length)
							xFrom[i] = -ranMove * (i % 2 == 0 ? -1 : 1);
						for (i in 0...xTo.length)
							xTo[i] = ranMove * (i % 2 == 0 ? -1 : 1);
						for (i in 0...xTime.length)
							xTime[i] = ranTime;
						for (i in 0...yFrom.length)
							yFrom[i] = -ranMove;
						for (i in 0...yTo.length)
							yTo[i] = ranMove;
						for (i in 0...yTime.length)
							yTime[i] = ranTime;
					case 4:
						var ranTime = FlxG.random.float(0.3, 0.9);
						var ranMove = FlxG.random.float(25, 50);
						for (i in 0...xFrom.length)
							xFrom[i] = -ranMove * (i % 2 == 0 ? -1 : 1);
						for (i in 0...xTo.length)
							xTo[i] = ranMove * (i % 2 == 0 ? -1 : 1);
						for (i in 0...xTime.length)
							xTime[i] = ranTime;
						for (i in 0...yFrom.length)
							yFrom[i] = -ranMove * (i % 2 == 0 ? 1 : -1);
						for (i in 0...yTo.length)
							yTo[i] = ranMove * (i % 2 == 0 ? 1 : -1);
						for (i in 0...yTime.length)
							yTime[i] = ranTime;
					case 5:
						var ranTime = FlxG.random.float(0.3, 0.9);
						var ranMoveX = FlxG.random.float(25, 50);
						var ranMoveY = FlxG.random.float(25, 50);
						for (i in 0...xFrom.length)
							xFrom[i] = -ranMoveX * (i % 2 == 0 ? -1 : 1);
						for (i in 0...xTo.length)
							xTo[i] = ranMoveX * (i % 2 == 0 ? -1 : 1);
						for (i in 0...xTime.length)
							xTime[i] = ranTime;
						for (i in 0...yFrom.length)
							yFrom[i] = -ranMoveY;
						for (i in 0...yTo.length)
							yTo[i] = ranMoveY;
						for (i in 0...yTime.length)
							yTime[i] = ranTime;
					case 6:
						var ranTime = FlxG.random.float(0.3, 0.9);
						for (i in 0...xFrom.length)
							xFrom[i] = -FlxG.random.float(25, 50) * (i % 2 == 0 ? -1 : 1);
						for (i in 0...xTo.length)
							xTo[i] = FlxG.random.float(25, 50) * (i % 2 == 0 ? -1 : 1);
						for (i in 0...xTime.length)
							xTime[i] = ranTime;
						for (i in 0...yFrom.length)
							yFrom[i] = -FlxG.random.float(25, 50) * (i % 2 == 0 ? 1 : -1);
						for (i in 0...yTo.length)
							yTo[i] = FlxG.random.float(25, 50) * (i % 2 == 0 ? 1 : -1);
						for (i in 0...yTime.length)
							yTime[i] = ranTime;
					case 7:
						var ranTime = FlxG.random.float(0.3, 0.9);
						for (i in 0...xFrom.length)
							xFrom[i] = FlxG.random.float(25, 50) * (FlxG.random.bool() ? 1 : -1);
						for (i in 0...xTo.length)
							xTo[i] = FlxG.random.float(25, 50) * (FlxG.random.bool() ? 1 : -1);
						for (i in 0...xTime.length)
							xTime[i] = ranTime;
						for (i in 0...yFrom.length)
							yFrom[i] = -FlxG.random.float(25, 50) * (FlxG.random.bool() ? 1 : -1);
						for (i in 0...yTo.length)
							yTo[i] = FlxG.random.float(25, 50) * (FlxG.random.bool() ? 1 : -1);
						for (i in 0...yTime.length)
							yTime[i] = ranTime;
				}

				for (i in 0...xWiggleTween.length)
				{
					if (!disableX)
					{
						xWiggleTween[i] = FlxTween.num(xFrom[i], xTo[i], xTime[i], {
							onUpdate: function(tween)
							{
								xWiggle[i] = cast(tween, NumTween).value;
							},
							type: PINGPONG
						});
					}
					if (!disableY)
					{
						yWiggleTween[i] = FlxTween.num(yFrom[i], yTo[i], yTime[i], {
							onUpdate: function(tween)
							{
								yWiggle[i] = cast(tween, NumTween).value;
							},
							type: PINGPONG
						});
					}
				}

				playSound = "wiggle";

				ttl = 20;
				onEnd = function()
				{
					xWiggle = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
					yWiggle = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

					for (i in [xWiggleTween, yWiggleTween])
					{
						for (j in i)
						{
							if (j != null && j.active)
								j.cancel();
						}
					}
				}*/
			case 'flashbang':
				noIcon = true;
				playSound = "bang";
				if (flashbangTimer != null && flashbangTimer.active)
					flashbangTimer.cancel();
				var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
				whiteScreen.scrollFactor.set();
				whiteScreen.cameras = [camUnderTop];
				add(whiteScreen);
				flashbangTimer.start(0.4, function(timer)
				{
					camUnderTop.flash(FlxColor.WHITE, 7, null, true);
					remove(whiteScreen);
					FlxG.sound.play(Paths.sound('ringing'), 0.4);
				});

			case 'nostrum':
				noIcon = false;
				for (i in 0...playerStrums.length)
					playerStrums.members[i].visible = false;
				playSound = "nostrum";
				ttl = 13;
				onEnd = function()
				{
					for (i in 0...playerStrums.length)
						playerStrums.members[i].visible = true;
				}
			case 'jackspam':
				noIcon = true;
				var startingPoint = FlxG.random.int(5, 9);
				var endingPoint = FlxG.random.int(startingPoint + 6, startingPoint + 12);
				var dataPicked = FlxG.random.int(0, mania);
				for (i in startingPoint...endingPoint)
				{
					addNote(0, i, i, dataPicked);
				}
			case 'spam':
				noIcon = true;
				var startingPoint = FlxG.random.int(5, 9);
				var endingPoint = FlxG.random.int(startingPoint + 5, startingPoint + 10);
				for (i in startingPoint...endingPoint)
				{
					addNote(0, i, i);
				}
			case 'sever':
				noIcon = false;
				var chooseFrom:Array<Int> = [];
				for (i in 0...severInputs.length)
				{
					if (!severInputs[i])
						chooseFrom.push(i);
				}
				if (chooseFrom.length <= 0)
					picked = FlxG.random.int(0, 3);
				else
					picked = chooseFrom[FlxG.random.int(0, chooseFrom.length - 1)];
				playerStrums.members[picked].alpha = 0;
				severInputs[picked] = true;

				var okayden:Array<Int> = [];
				for (i in 0...64)
				{
					okayden.push(i);
				}
				var explosion = new FlxSprite().loadGraphic(Paths.image("explosion"), true, 256, 256);
				explosion.animation.add("boom", okayden, 60, false);
				explosion.animation.finishCallback = function(name)
				{
					explosion.visible = false;
					explosion.kill();
					remove(explosion);
					FlxDestroyUtil.destroy(explosion);
				};
				explosion.cameras = [camHUD];
				explosion.x = playerStrums.members[picked].x + playerStrums.members[picked].width / 2 - explosion.width / 2;
				explosion.y = playerStrums.members[picked].y + playerStrums.members[picked].height / 2 - explosion.height / 2;
				explosion.animation.play("boom", true);
				add(explosion);

				playSound = "sever";
				ttl = 6;
				alwaysEnd = true;
				onEnd = function()
				{
					playerStrums.members[picked].alpha = 1;
					severInputs[picked] = false;
				}
			case 'shake':
				noIcon = false;
				playSound = "shake";
				playSoundVol = 0.5;
				camHUD.shake(FlxG.random.float(0.03, 0.06), 9, null, true);
				camNotes.shake(FlxG.random.float(0.03, 0.06), 9, null, true);
			case 'poison':
				noIcon = false;
				drainHealth = true;
				playSound = "poison";
				playSoundVol = 0.6;
				ttl = 5;
				boyfriend.color = 0xf003fc;
				onEnd = function()
				{
					drainHealth = false;
					boyfriend.color = 0xffffff;
				}
			case 'dizzy':
				noIcon = false;
				if (effectsActive[effect] == null || effectsActive[effect] <= 0)
				{
					if (drunkTween != null && drunkTween.active)
					{
						drunkTween.cancel();
						FlxDestroyUtil.destroy(drunkTween);
					}
					drunkTween = FlxTween.num(0, 24, FlxG.random.float(1.2, 1.4), {
						onUpdate: function(tween)
						{
							camNotes.angle = (tween.executions % 4 > 1 ? 1 : -1) * cast(tween, NumTween).value + camAngle;
							camHUD.angle = (tween.executions % 4 > 1 ? 1 : -1) * cast(tween, NumTween).value + camAngle;
							camGame.angle = (tween.executions % 4 > 1 ? -1 : 1) * cast(tween, NumTween).value / 2 + camAngle;
						},
						type: PINGPONG
					});
				}

				playSound = "dizzy";
				ttl = 8;
				onEnd = function()
				{
					if (drunkTween != null && drunkTween.active)
					{
						drunkTween.cancel();
						FlxDestroyUtil.destroy(drunkTween);
					}
					camNotes.angle = camAngle;
					camHUD.angle = camAngle;
					camGame.angle = camAngle;
				}
			case 'noise':
				noIcon = false;
				var noisysound:String = "";
				var noisysoundVol:Float = 1.0;
				switch (FlxG.random.int(0, 9))
				{
					case 0:
						noisysound = "dialup";
						noisysoundVol = 0.5;
					case 1:
						noisysound = "crowd";
						noisysoundVol = 0.3;
					case 2:
						noisysound = "airhorn";
						noisysoundVol = 0.6;
					case 3:
						noisysound = "copter";
						noisysoundVol = 0.5;
					case 4:
						noisysound = "magicmissile";
						noisysoundVol = 0.9;
					case 5:
						noisysound = "ping";
						noisysoundVol = 1.0;
					case 6:
						noisysound = "call";
						noisysoundVol = 1.0;
					case 7:
						noisysound = "knock";
						noisysoundVol = 1.0;
					case 8:
						noisysound = "fuse";
						noisysoundVol = 0.7;
					case 9:
						noisysound = "hallway";
						noisysoundVol = 0.9;
				}
				noiseSound.stop();
				noiseSound.loadEmbedded(Paths.sound(noisysound));
				noiseSound.volume = noisysoundVol;
				noiseSound.play(true);

			case 'flip':
				noIcon = false;
				playSound = "flip";
				ttl = 5;
				camAngle = 180;
				camNotes.angle = camAngle;
				camHUD.angle = camAngle;
				camGame.angle = camAngle;
				onEnd = function()
				{
					camAngle = 0;
					camNotes.angle = camAngle;
					camHUD.angle = camAngle;
					camGame.angle = camAngle;
				}
			case 'invuln':
				noIcon = false;
				playSound = "invuln";
				playSoundVol = 0.5;
				ttl = 5;
				if (boyfriend.curCharacter.contains("pixel"))
				{
					shieldSprite.x = boyfriend.x + boyfriend.width / 2 - shieldSprite.width / 2 - 150;
					shieldSprite.y = boyfriend.y + boyfriend.height / 2 - shieldSprite.height / 2 - 150;
				}
				else
				{
					shieldSprite.x = boyfriend.x + boyfriend.width / 2 - shieldSprite.width / 2;
					shieldSprite.y = boyfriend.y + boyfriend.height / 2 - shieldSprite.height / 2;
				}
				shieldSprite.visible = true;
				dmgMultiplier = 0;
				onEnd = function()
				{
					shieldSprite.visible = false;
					dmgMultiplier = 1.0;
				}

			case 'desync':
				noIcon = true;
				playSound = "delay";
				delayOffset = FlxG.random.int(Std.int(Conductor.stepCrochet), Std.int(Conductor.stepCrochet) * 3);
				FlxG.sound.music.time -= delayOffset;
				resyncVocals();

				ttl = 8;
				onEnd = function()
				{
					FlxG.sound.music.time += delayOffset;
					delayOffset = 0;
				}

			case 'mute':
				noIcon = true;
				playSound = "delay";
				if (FlxG.random.bool(15)) 
				{
					FlxG.sound.music.volume = 0;
				}
				else 
				{
					volumeMultiplier = 0;
					vocals.volume = 0;
				}
				ttl = 8;
				onEnd = function()
				{
					FlxG.sound.music.volume = 1;
					volumeMultiplier = 1;
				}

			case 'ice':
				noIcon = true;
				var startPoint:Int = FlxG.random.int(5, 9);
				var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
				var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
				addNote(4, startPoint, startPoint, -1);
				addNote(4, nextPoint, nextPoint, -1);
				addNote(4, lastPoint, lastPoint, -1);

			case 'randomize':
				noIcon = false;
				var available:Array<Int> = [];
				for (i in 0...mania+1) {
					available.push(i);
					trace("available: " + available);
				}
				FlxG.random.shuffle(available);
				switch (available)
				{
					case [0, 1, 2, 3]:
						available = [3, 2, 1, 0];
					default:
				}

				for (daNote in unspawnNotes)
				{
					if (daNote == null)
						continue;
					if (daNote.strumTime >= Conductor.songPosition)
					{
						daNote.noteData = available[daNote.noteData];
					}
				}
				for (daNote in notes)
				{
					if (daNote == null)
						continue;
					else
					{
						daNote.noteData = available[daNote.noteData];
					}
				}

				playSound = "randomize";
				playSoundVol = 0.7;
				ttl = 10;
				onEnd = function()
				{
					for (daNote in unspawnNotes)
					{
						if (daNote == null)
							continue;
						if (daNote.strumTime >= Conductor.songPosition)
						{
							daNote.noteData = daNote.trueNoteData;
						}
					}
					for (daNote in notes)
					{
						if (daNote == null)
							continue;
						else
						{
							daNote.noteData = daNote.trueNoteData;
						}
					}
				}

			case 'fakeheal':
				noIcon = true;
				addNote(5, 5, 9);

			case 'spell':
				noIcon = false;
				var spellThing = new SpellPrompt();
				spellPrompts.push(spellThing);
				playSound = "spell";
				playSoundVol = 0.66;

			case 'terminate':
				noIcon = true;
				terminateStep = 3;

			case 'lowpass':
				noIcon = true;
				if (FlxG.random.bool(40)) 
				{
					lowFilterAmount = .0134;
					filtersGame.push(filterMap.get("BlurLittle").filter);
					blurEffect.setStrength(32, 32);
				
				}
				else 
				{
					vocalLowFilterAmount = .0134;
					filtersHUD.push(filterMap.get("BlurLittle").filter);
					filters.push(filterMap.get("BlurLittle").filter);
					blurEffect.setStrength(32, 32);
				}
				playSound = "delay";
				playSoundVol = 0.6;
				ttl = 10;
				onEnd = function()
				{
					blurEffect.setStrength(0, 0);
					filtersHUD.remove(filterMap.get("BlurLittle").filter);
					filtersGame.remove(filterMap.get("BlurLittle").filter);
					filters.remove(filterMap.get("BlurLittle").filter);
					lowFilterAmount = 1;
					vocalLowFilterAmount = 1;
				}

			case 'songSwitch':
				//save everything first
				if (FlxG.save.data.manualOverride != null && FlxG.save.data.manualOverride == false) 
					FlxG.save.data.manualOverride = true;
				else if (FlxG.save.data.manualOverride != null && FlxG.save.data.manualOverride == true) 
					FlxG.save.data.manualOverride = false;

				trace('MANUAL OVERRIDE: ' + FlxG.save.data.manualOverride);

				if (FlxG.save.data.manualOverride)
				{
					FlxG.save.data.storyWeek = PlayState.storyWeek;
					FlxG.save.data.currentModDirectory = Paths.currentModDirectory;
					FlxG.save.data.difficulties = CoolUtil.difficulties; // just in case
					FlxG.save.data.SONG = PlayState.SONG;
					FlxG.save.data.storyDifficulty = PlayState.storyDifficulty;
					FlxG.save.data.songPos = Conductor.songPosition;
					FlxG.save.flush();
				}

				//Then make a hostile takeover
				if (FlxG.save.data.manualOverride)
				{
					//playBackRate = 1;
					PlayState.storyWeek = 0;
					Paths.currentModDirectory = '';
					var diffStr:String = WeekData.getCurrentWeek().difficulties;
					if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5
		
					if(diffStr != null && diffStr.length > 0)
					{
						var diffs:Array<String> = diffStr.split(',');
						var i:Int = diffs.length - 1;
						while (i > 0)
						{
							if(diffs[i] != null)
							{
								diffs[i] = diffs[i].trim();
								if(diffs[i].length < 1) diffs.remove(diffs[i]);
							}
							--i;
						}
		
						if(diffs.length > 0 && diffs[0].length > 0)
						{
							CoolUtil.difficulties = diffs;
						}
					}
					if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
					{
						curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
					}
					else
					{
						curDifficulty = 0;
					}
		
					var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
					//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
					if(newPos > -1)
					{
						curDifficulty = newPos;
					}
					CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
					PlayState.SONG = Song.loadFromJson(Highscore.formatSong('tutorial', curDifficulty), Paths.formatToSongPath('tutorial'));
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = curDifficulty;
					FlxG.save.flush();
				}
				MusicBeatState.resetState();

			default:
				return;
		}

		effectsActive[effect] = (effectsActive[effect] == null ? 0 : effectsActive[effect] + 1);

		if (playSound != "")
		{
			FlxG.sound.play(Paths.sound(playSound), playSoundVol);
		}

		new FlxTimer().start(ttl, function(tmr:FlxTimer)
		{
			effectsActive[effect]--;
			if (effectsActive[effect] < 0)
				effectsActive[effect] = 0;

			if (onEnd != null && (effectsActive[effect] <= 0 || alwaysEnd))
				onEnd();

			FlxDestroyUtil.destroy(tmr);
		});

		if (!noIcon)
		{
			if (lagOn)
			{
				var icon = new FlxSprite().loadGraphic(Paths.image("effectIcons/" + effect));
				icon.cameras = [camOther];
				icon.screenCenter(X);
				icon.y = (effectiveDownScroll ? FlxG.height - icon.height - 10 : 10);
				add(icon);
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					icon.kill();
					remove(icon);
					FlxDestroyUtil.destroy(icon);
					FlxDestroyUtil.destroy(tmr);
				});
			}
			else
			{
				var icon = new FlxSprite().loadGraphic(Paths.image("effectIcons/" + effect));
				icon.cameras = [camOther];
				icon.screenCenter(X);
				icon.y = (effectiveDownScroll ? FlxG.height - icon.frameHeight - 10 : 10);
				icon.scale.x = icon.scale.y = 0.5;
				icon.updateHitbox();
				FlxTween.tween(icon, {"scale.x": 1, "scale.y": 1}, 0.1, {
					onUpdate: function(tween)
					{
						icon.updateHitbox();
						icon.screenCenter(X);
						icon.y = (effectiveDownScroll ? FlxG.height - icon.frameHeight - 10 : 10);
					}
				});
				add(icon);
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					icon.kill();
					remove(icon);
					FlxDestroyUtil.destroy(icon);
					FlxDestroyUtil.destroy(tmr);
				});
			}
		}

		resetChatData();
	}

	function addNote(type:Int = 0, min:Int = 0, max:Int = 0, ?specificData:Int)
	{
		if (startingSong)
			return;
		var pickSteps = FlxG.random.int(min, max);
		var pickTime = Conductor.songPosition + pickSteps * Conductor.stepCrochet;
		var pickData:Int = 0;

		if (SONG.notes.length <= Math.floor((curStep + pickSteps + 1) / 16))
			return;

		if (SONG.notes[Math.floor((curStep + pickSteps + 1) / 16)] == null)
			return;

		if (specificData == null)
		{
			if (SONG.notes[Math.floor((curStep + pickSteps + 1) / 16)].mustHitSection)
			{
				pickData = FlxG.random.int(0, mania);
			}
			else
			{
				// pickData = FlxG.random.int(4, 7);
				pickData = FlxG.random.int(0, mania);
			}
		}
		else if (specificData == -1)
		{
			var chooseFrom:Array<Int> = [];
			for (i in 0...severInputs.length)
			{
				if (!severInputs[i])
					chooseFrom.push(i);
			}

			if (chooseFrom.length <= 0)
				pickData = FlxG.random.int(0, mania);
			else
				pickData = chooseFrom[FlxG.random.int(0, chooseFrom.length - 1)];
		}
		else
		{
			if (SONG.notes[Math.floor((curStep + pickSteps + 1) / 16)].mustHitSection)
			{
				pickData = specificData % Note.ammo[mania];
			}
			else
			{
				// pickData = specificData % 4 + 4;
				pickData = specificData % Note.ammo[mania];
			}
		}
		var swagNote:Note = new Note(pickTime, pickData);
		switch (type)
		{
			case 1:
				swagNote.noteType = 'Mine Note';
				swagNote.reloadNote('minenote');
				swagNote.isMine = true;
				swagNote.ignoreNote = true;
				swagNote.specialNote = true;
			case 2:
				swagNote.noteType = 'Warning Note';
				swagNote.reloadNote('warningnote');
				swagNote.isAlert = true;
				swagNote.specialNote = true;
			case 3:
				swagNote.noteType = 'Heal Note';
				swagNote.reloadNote('healnote');
				swagNote.isHeal = true;
				swagNote.specialNote = true;
			case 4:
				swagNote.noteType = 'Ice Note';
				swagNote.reloadNote('icenote');
				swagNote.isFreeze = true;
				swagNote.ignoreNote = true;
				swagNote.specialNote = true;
			case 5:
				swagNote.noteType = 'Fake Heal Note';
				swagNote.reloadNote('fakehealnote');
				swagNote.isFakeHeal = true;
				swagNote.ignoreNote = true;
				swagNote.specialNote = true;
			default:
				swagNote.ignoreNote = false;
				swagNote.specialNote = false;
		}
		swagNote.mustPress = true;
		if (chartModifier == "SpeedRando")
			{swagNote.multSpeed = FlxG.random.float(0.1, 2);}
		if (chartModifier == "SpeedUp")
			{}
		swagNote.x += FlxG.width / 2;
		unspawnNotes.push(swagNote);
		unspawnNotes.sort(sortByShit);
	}

	function updateScrollUI()
	{
		ClientPrefs.downScroll = effectiveDownScroll;
		timeTxt.y = (effectiveDownScroll ? FlxG.height - 44 : 19);
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBar.y = timeBarBG.y + 4;
		strumLine.y = (effectiveDownScroll ? 570 : 30);
		healthBarBG.y = (effectiveDownScroll ? FlxG.height * 0.1 : FlxG.height * 0.875);
		healthBar.y = healthBarBG.y + 4;
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		strumLineNotes.forEach(function(sprite)
		{
			sprite.y = strumLine.y;
			sprite.downScroll = ClientPrefs.downScroll;
		});
		scoreTxt.y = (effectiveDownScroll ? FlxG.height * 0.1 - 72 : FlxG.height * 0.9 + 36);
	}

	var strumTweens:Array<FlxTween> = new Array<FlxTween>();

	function mixUp(reset:Bool = false)
	{
		var available = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
		if (!reset)
		{
			FlxG.random.shuffle(available);
			switch (available)
			{
				case [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]:
					available = [17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0];
				default:
			}
		}

		notePositions = available;

		for (i in 0...playerStrums.length)
		{
			if (strumTweens[i] != null && strumTweens[i].active)
				strumTweens[i].cancel();
			strumTweens[i] = FlxTween.tween(playerStrums.members[i], {x: 50 + Note.swagWidth * notePositions[i] + 50 + (FlxG.width / 2)}, 0.25);
		}
		for (daNote in unspawnNotes)
		{
			if (daNote == null)
				continue;
			if (daNote.strumTime >= Conductor.songPosition && daNote.mustPress)
			{
				daNote.swapPositions();
			}
		}
		for (daNote in notes)
		{
			if (daNote == null)
				continue;
			if (daNote.mustPress)
			{
				daNote.swapPositions();
			}
		}
	}

	function updateResist(elasped:Float):Void
	{
		if (!resistMode)
		{
			resistGroup.visible = false;
			return;
		}
		resistGroup.visible = true;
		if (currentBarPorcent == 0)
		{
			resistBarBar.setGraphicSize(Math.ceil(resistBarBG.width / 1.6 * resistBarBG.scale.x), 1);
		}
		else
		{
			resistBarBar.setGraphicSize(Math.ceil(resistBarBG.width / 1.6 * resistBarBG.scale.x), Math.ceil(resistBarBG.height / 0.99 * currentBarPorcent));
		}
		resistBarBar.x = resistBar.x;
		resistBarBar.y = resistBar.y + resistBarBG.height - resistBarBar.height;
		dadGroup.x = Math.ceil(resistBarBG.width / 1.2 * currentBarPorcent);

		if (currentBarPorcent > 1)
		{
			currentBarPorcent = 1;
		}
		if (currentBarPorcent <= 0)
		{
			currentBarPorcent = 0.01;
			resistBarBar.setGraphicSize(Math.ceil(resistBarBG.width / 1.8 * resistBarBG.scale.x), 1);
			resistBarBar.visible = false;
		}
		else
		{
			resistBarBar.visible = true;
		}
		var updateFactor:Float = elasped * FlxG.updateFramerate / 60; // Calculate the update factor based on elapsed time and actual FPS

		if (currentBarPorcent == 1)
		{
			// health -= (0.0051 * updateFactor);
		}
		curResist = 100 - Math.ceil((currentBarPorcent * 1000) / 10);

		if (health >= 1)
		{
			curHorny = -0;
		}
		else
		{
			curHorny = Math.ceil((health - 1) * 100);
		}

		// Update the score
		updateScore();
	}

	public var Crashed:Bool;
	var isFrozen:Bool = false;

	override public function update(elapsed:Float)
	{
		#if cpp			
		if(FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			@:privateAccess
			{
				var af = lime.media.openal.AL.createFilter(); // create AudioFilter
				lime.media.openal.AL.filteri( af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS ); // set filter type
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAIN, 1 ); // set gain
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAINHF, lowFilterAmount ); // set gainhf
				lime.media.openal.AL.sourcei( FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
				//lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.HIGHPASS_GAIN, 0);
			}
		}
		if(vocals != null && vocals.playing)
		{
			@:privateAccess
			{
				var af = lime.media.openal.AL.createFilter(); // create AudioFilter
				lime.media.openal.AL.filteri( af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS ); // set filter type
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAIN, 1 ); // set gain
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAINHF, vocalLowFilterAmount ); // set gainhf
				lime.media.openal.AL.sourcei( vocals._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
				//lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.HIGHPASS_GAIN, 0);
			}
		}
		#end
		
		if (Crashed)
		{
			FlxG.switchState(new MainMenuState());
			Crashed = false;
		}

		if (SONG.speed < 0) SONG.speed = 0;

		camNotes.zoom = camHUD.zoom;

		curEffect = FlxG.random.int(0, 40);

		if (songPercent == 1 && (notes.length <= 0 || unspawnNotes.length <= 0) || songStarted && !FlxG.sound.music.playing) endSong(); //FOR THE LOVE OF GOD JUST END THE GOD DANG SONG

		//trace(songPercent);

		if (isFrozen) boyfriend.stunned = true;

		if (notes != null)
		{
			notes.forEachAlive(function(note:Note)
			{
				if (severInputs[picked] == true && note.noteData == picked)
					note.blockHit = true;
				else
					note.blockHit = false;
			});
		}

		for (i in 0...unspawnNotes.length)
		{
			if (unspawnNotes[i].noteData == picked)
				unspawnNotes[i].blockHit = true;
		}

		if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}

		/*if (FlxG.keys.justPressed.H)
		{
			doEffect('songSwitch');
		}

		if (FlxG.keys.justPressed.F)
		{
			doEffect('lowpass');
		}*/

		if (chartModifier == '4K Only' && mania != 3)
		{
			changeMania(3);
		}
		if (archMode)
		{
			if (!endingSong)
				FlxG.save.data.activeItems = activeItems;

			for (i in activeItems)
				if (i == 0)
					FlxG.save.data.activeItems = null;

			/*if (FlxG.keys.justPressed.F)
			{
				switch (FlxG.random.int(0, 2))
				{
					case 0:
						activeItems[0] += 1;
						ArchPopup.startPopupCustom('You Got an Item!', '+1 Shield ( ' + activeItems[0] + ' Left)', 'Color');
					case 1:
						activeItems[1] = 1;
						ArchPopup.startPopupCustom('You Got an Item!', "Blue Ball's Curse", 'Color');
					case 2:
						activeItems[2] += 1;
						ArchPopup.startPopupCustom('You Got an Item!', "Max HP Up!", 'Color');
					case 3:
						keybindSwitch('SAND');
						ArchPopup.startPopupCustom('You Got an Item!', "Keybind Switch (S A N D)", 'Color');
				}
			}*/

			if (activeItems[0] > 0 && health <= 0)
			{
				health = 1;
				activeItems[0]--;
				ArchPopup.startPopupCustom('You Used A Shield!', '-1 Shield ( ' + activeItems[0] + ' Left)', 'Color');
			}

			if (activeItems[1] == 1)
			{
				activeItems[1] = 0;
				health = 0;
				doDeathCheck(true, true);
			}
		}

		callOnLuas('onUpdate', [elapsed]);

		readChatData();

		updateResist(elapsed);

		if (ClientPrefs.camMovement && !PlayState.isPixelStage)
		{
			if (camlock)
			{
				camFollow.x = camlockx;
				camFollow.y = camlocky;
			}
		}

		switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if (!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished)
				{
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
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if (phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length - 1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if (particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if (!ClientPrefs.lowQuality)
				{
					grpLimoParticles.forEach(function(spr:BGSprite)
					{
						if (spr.animation.curAnim.finished)
						{
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch (limoKillingState)
					{
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length)
							{
								if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170)
								{
									switch (i)
									{
										case 0 | 3:
											if (i == 0)
												FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4,
												['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4,
												['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4,
												['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'],
												false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} // Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if (limoMetalPole.x > FlxG.width * 2)
							{
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x > FlxG.width * 1.5)
							{
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if (limoSpeed < 1000)
								limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x < -275)
							{
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if (Math.round(bgLimo.x) == -150)
							{
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if (limoKillingState > 2)
					{
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length)
						{
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if (heyTimer > 0)
				{
					heyTimer -= elapsed;
					if (heyTimer <= 0)
					{
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		for (i in 0...opponentStrums.length)
			additionalOffset(opponentStrums.members[i], i);

		for (i in 0...playerStrums.length)
			additionalOffset(playerStrums.members[i], i);

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if (!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);
			if (ret != FunkinLua.Function_Stop)
			{
				openPauseMenu();
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			+ (150 * iconP1.scale.x - 150) / 2
			- iconOffset;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (150 * iconP2.scale.x) / 2
			- iconOffset * 2;

		if (health > maxHealth)
			health = maxHealth;

		if (health < 0)
			health = 0;

		switch (iconP1.type)
		{
			case SINGLE:
				iconP1.animation.curAnim.curFrame = 0;
			case WINNING:
				iconP1.animation.curAnim.curFrame = (healthBar.percent > 80 ? 2 : (healthBar.percent < 20 ? 1 : 0));
			default:
				iconP1.animation.curAnim.curFrame = (healthBar.percent < 20 ? 1 : 0);
		}

		switch (iconP2.type)
		{
			case SINGLE:
				iconP2.animation.curAnim.curFrame = 0;
			case WINNING:
				iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
			default:
				iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : 0);
		}

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
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

				if (updateTime)
				{
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset - SONG.offset;
					if (curTime < 0)
						curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if (ClientPrefs.timeBarType == 'Time Elapsed')
						songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0)
						secondsTotal = 0;

					if (ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camNotes.zoom = FlxMath.lerp(1, camNotes.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;
				callOnLuas('onSpawnNote', [
					notes.members.indexOf(dunceNote),
					dunceNote.noteData,
					dunceNote.noteType,
					dunceNote.isSustainNote
				]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic && !inCutscene)
		{
			if (!cpuControlled)
			{
				keyShit();
			}
			else if (boyfriend.animation.curAnim != null
				&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				// boyfriend.animation.curAnim.finish();
			}

			if (startedCountdown)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if (!daNote.mustPress)
						strumGroup = opponentStrums;

					if (strumGroup.members[daNote.noteData] == null)
						daNote.noteData = mania; // crash prevention ig?

					var strumX:Float = strumGroup.members[daNote.noteData].x;
					var strumY:Float = strumGroup.members[daNote.noteData].y;
					var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
					var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
					var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
					var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;

					if (strumScroll || effectiveDownScroll) // Downscroll
					{
						// daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
						daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
					}
					else // Upscroll
					{
						// daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
						daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
					}

					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;

					if (daNote.copyAlpha && !severInputs[daNote.noteData])
						daNote.alpha = strumAlpha;

					if (daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

					var shouldMove = false;
					if (!lagOn || (lagOn && curStep % 2 == 0))
						shouldMove = true;

					if (daNote.copyY && shouldMove)
					{
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

						// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if (strumScroll && daNote.isSustainNote)
						{
							if (daNote.animation.curAnim.name.endsWith('tail'))
							{
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
								if (PlayState.isPixelStage)
								{
									daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
								}
								else
								{
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

					if (!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit && !daNote.ignoreNote)
					{
						if (daNote.isSustainNote)
						{
							if (daNote.canBeHit)
							{
								goodNoteHit(daNote);
							}
						}
						else if (daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote)
						{
							goodNoteHit(daNote);
						}
					}

					var center:Float = strumY + Note.swagWidth / 2;
					if (strumGroup.members[daNote.noteData].sustainReduce
						&& daNote.isSustainNote
						&& (daNote.mustPress || !daNote.ignoreNote)
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						if (strumScroll)
						{
							if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
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
						if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
						{
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
			else
			{
				notes.forEachAlive(function(daNote:Note)
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}
		checkEventNote();

		
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}

		if (drainHealth)
		{
			health = Math.max(0.0000000001, health - (FlxG.elapsed * 0.425 * dmgMultiplier));
		}

		for (i in 0...spellPrompts.length)
		{
			if (spellPrompts[i] == null)
			{
				continue;
			}
			else if (spellPrompts[i].ttl <= 0)
			{
				health -= 0.5 * dmgMultiplier;
				FlxG.sound.play(Paths.sound('spellfail'));
				camSpellPrompts.flash(FlxColor.RED, 1, null, true);
				spellPrompts[i].kill();
				FlxDestroyUtil.destroy(spellPrompts[i]);
				remove(spellPrompts[i]);
				spellPrompts.remove(spellPrompts[i]);
			}
			else if (!spellPrompts[i].alive)
			{
				remove(spellPrompts[i]);
				FlxDestroyUtil.destroy(spellPrompts[i]);
			}
		}

		for (timestamp in terminateTimestamps)
		{
			if (timestamp == null || !timestamp.alive)
				continue;

			if (timestamp.tooLate)
			{
				if (!timestamp.didLatePenalty)
				{
					timestamp.didLatePenalty = true;
					var healthToTake = health / 3 * dmgMultiplier;
					health -= healthToTake;
					boyfriend.playAnim('hit', true);
					FlxG.sound.play(Paths.sound('theshoe'));
					timestamp.kill();
					terminateTimestamps.resize(0);

					var theShoe = new FlxSprite();
					theShoe.loadGraphic(Paths.image("theshoe"));
					theShoe.x = boyfriend.x + boyfriend.width / 2 - theShoe.width / 2;
					theShoe.y = -FlxG.height / defaultCamZoom;
					add(theShoe);
					FlxTween.tween(theShoe, {y: boyfriend.y + boyfriend.height - theShoe.height}, 0.2, {
						onComplete: function(tween)
						{
							if (tween.executions >= 2)
							{
								theShoe.kill();
								FlxDestroyUtil.destroy(theShoe);
								tween.cancel();
								FlxDestroyUtil.destroy(tween);
							}
						},
						type: PINGPONG
					});
				}
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		pauseMP4s();
		noiseSound.pause();

		// 1 / 1000 chance for Gitaroo Man easter egg
		/*if (FlxG.random.bool(0.1))
		{
			// gitaroo man easter egg
			cancelMusicFadeTween();
			MusicBeatState.switchState(new GitarooPause());
		}
		else { */
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		// }

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + storyDifficultyText, iconP2.getCharacter());
		#end
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

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false, instaKill:Bool = false)
	{
		if (archMode && activeItems[0] <= 0)
		{
			if ((((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead) || instaKill)
			{
				ClientPrefs.downScroll = ogScroll;
				if (effectTimer != null && effectTimer.active)
					effectTimer.cancel();
				if (randoTimer != null && randoTimer.active)
					randoTimer.cancel();
				pauseMP4s();
				noiseSound.pause();
				var ret:Dynamic = callOnLuas('onGameOver', [], false);
				if (ret != FunkinLua.Function_Stop)
				{
					boyfriend.stunned = true;
					deathCounter++;

					paused = true;

					vocals.stop();
					FlxG.sound.music.stop();

					persistentUpdate = false;
					persistentDraw = false;
					for (tween in modchartTweens)
					{
						tween.active = true;
					}
					for (timer in modchartTimers)
					{
						timer.active = true;
					}
					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0],
						boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

					// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

					#if desktop
					// Game Over doesn't get his own variable because it's only used here
					DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + storyDifficultyText, iconP2.getCharacter());
					#end
					isDead = true;
					return true;
				}
			}
		}
		else if (!archMode)
		{
			if ((((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead) || instaKill)
			{
				ClientPrefs.downScroll = ogScroll;
				var ret:Dynamic = callOnLuas('onGameOver', [], false);
				if (ret != FunkinLua.Function_Stop)
				{
					boyfriend.stunned = true;
					deathCounter++;

					paused = true;

					vocals.stop();
					FlxG.sound.music.stop();

					persistentUpdate = false;
					persistentDraw = false;
					for (tween in modchartTweens)
					{
						tween.active = true;
					}
					for (timer in modchartTimers)
					{
						timer.active = true;
					}
					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0],
						boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

					// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

					#if desktop
					// Game Over doesn't get his own variable because it's only used here
					DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + storyDifficultyText, iconP2.getCharacter());
					#end
					isDead = true;
					return true;
				}
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Dadbattle Spotlight':
				var val:Null<Int> = Std.parseInt(value1);
				if (val == null)
					val = 0;

				switch (Std.parseInt(value1))
				{
					case 1, 2, 3: // enable and target dad
						if (val == 1) // enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if (val > 2)
							who = boyfriend;
						// 2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer)
						{
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {
							onComplete: function(twn:FlxTween)
							{
								dadbattleSmokes.visible = false;
							}
						});
				}

			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if (curStage == 'mall')
					{
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1)
					value = 1;
				gfSpeed = value;

			case 'Philly Glow':
				var lightId:Int = Std.parseInt(value1);
				if (Math.isNaN(lightId))
					lightId = 0;

				var doFlash:Void->Void = function()
				{
					var color:FlxColor = FlxColor.WHITE;
					if (!ClientPrefs.flashing)
						color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch (lightId)
				{
					case 0:
						if (phillyGlowGradient.visible)
						{
							doFlash();
							if (ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
								camNotes.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: // turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if (!phillyGlowGradient.visible)
						{
							doFlash();
							if (ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
								camNotes.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if (ClientPrefs.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if (!ClientPrefs.flashing)
							charColor.saturation *= 0.5;
						else
							charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if (!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400
										+ width * i
										+ FlxG.random.float(-width / 5, width / 5),
										phillyGlowGradient.originalY
										+ 200
										+ (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
					camNotes.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if (curStage == 'schoolEvil' && !ClientPrefs.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2))
							val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if (camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if (Math.isNaN(val1))
						val1 = 0;
					if (Math.isNaN(val2))
						val2 = 0;

					isCameraOnForcedPos = false;
					if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
					{
						camFollow.x = val1;
						camFollow.y = val2;
						isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}
			case 'Change Mania':
				var newMania:Int = 0;
				var skipTween:Bool = value2.toLowerCase().trim() == "true" ? true : false;

				newMania = Std.parseInt(value1);
				if (Math.isNaN(newMania) && newMania < 0 && newMania > 9)
					newMania = 0;
				changeMania(newMania, skipTween);
			
			case 'Change Mania (Special)':
				var newMania:Int = 0;
				var skipTween:Bool = value2 == "true" ? true : false;
				var prevNote1:Note = null;
				var prevNote2:Note = null;

				if (value1.toLowerCase().trim() == "random") {
					newMania = FlxG.random.int(0, 8);
				} else {
					newMania = Std.parseInt(value1);
				}
				if (Math.isNaN(newMania) && newMania < 0 && newMania > 9)
					newMania = 0;
				notes.forEach(function(daNote:Note)
				{
					daNote.noteData = getNumberFromAnims(daNote.noteData, newMania);
				});
				for (i in 0...unspawnNotes.length)
				{
					if (unspawnNotes[i].mustPress)
					{
						if (!unspawnNotes[i].isSustainNote)
						{
							unspawnNotes[i].noteData = getNumberFromAnims(unspawnNotes[i].noteData, newMania);
							prevNote1 = unspawnNotes[i];
						}
						else if (prevNote1 != null && unspawnNotes[i].isSustainNote) unspawnNotes[i].noteData = prevNote1.noteData;
					}
					if (!unspawnNotes[i].mustPress)
					{
						if (!unspawnNotes[i].isSustainNote)
						{
							unspawnNotes[i].noteData = getNumberFromAnims(unspawnNotes[i].noteData, newMania);
							prevNote2 = unspawnNotes[i];
						}
						else if (prevNote2 != null && unspawnNotes[i].isSustainNote) unspawnNotes[i].noteData = prevNote2.noteData;
					}
				}
				changeMania(newMania, skipTween);

			case 'Change Character':
				var charType:Int = 0;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
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
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf && gf != null)
								{
									gf.visible = true;
								}
							}
							else if (gf != null)
							{
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'BG Freaks Expression':
				if (bgGirls != null)
					bgGirls.swapDanceType();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if (killMe.length > 1)
				{
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length - 1], value2);
				}
				else
				{
					FunkinLua.setVarInArray(this, value1, value2);
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection():Void
	{
		if (SONG.notes[curSection] == null)
			return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			if (ClientPrefs.camMovement && !PlayState.isPixelStage)
			{
				campointx = camFollow.x;
				campointy = camFollow.y;
				bfturn = false;
				camlock = false;
				cameraSpeed = 1;
			}
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			if (ClientPrefs.camMovement && !PlayState.isPixelStage)
			{
				campointx = camFollow.x;
				campointy = camFollow.y;
				bfturn = true;
				camlock = false;
				cameraSpeed = 1;
			}
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn()
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset + SONG.offset / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	public var transitioning = false;
	public var justOverRide = false;

	public function endSong():Void
	{
		
		if (effectTimer != null && effectTimer.active)
			effectTimer.cancel();

		ClientPrefs.downScroll = ogScroll;
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			}

			if (doDeathCheck())
			{
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
		if (achievementObj != null)
		{
			return;
		}
		else
		{
			var achieve:String = checkForAchievement([
				'week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss', 'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad', 'ur_good', 'hype',
				'two_keys', 'toastie', 'debugger'
			]);

			if (achieve != null)
			{
				startAchievement(achieve);
				return;
			}
		}
		#end

		if (check == did)
		{
			FreeplayState.giveSong = true;
		}

		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			playbackRate = 1;

			if (FlxG.save.data.manualOverride)
			{
				trace('Switch Back');
				PlayState.storyWeek = FlxG.save.data.storyWeek;
				Paths.currentModDirectory = FlxG.save.data.currentModDirectory;
				var diffStr:String = WeekData.getCurrentWeek().difficulties;
				if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

				if(diffStr != null && diffStr.length > 0)
				{
					var diffs:Array<String> = diffStr.split(',');
					var i:Int = diffs.length - 1;
					while (i > 0)
					{
						if(diffs[i] != null)
						{
							diffs[i] = diffs[i].trim();
							if(diffs[i].length < 1) diffs.remove(diffs[i]);
						}
						--i;
					}

					if(diffs.length > 0 && diffs[0].length > 0)
					{
						CoolUtil.difficulties = diffs;
					}
				}
				if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
				{
					curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
				}
				else
				{
					curDifficulty = 0;
				}

				var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
				//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
				if(newPos > -1)
				{
					curDifficulty = newPos;
				}
				CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
				PlayState.SONG = FlxG.save.data.SONG;
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = FlxG.save.data.storyDifficulty;
				FlxG.save.data.manualOverride = false;
				FlxG.save.flush();
				FlxG.resetState();
				return;
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if (FlxTransitionableState.skipNextTransIn)
					{
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
					{
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
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

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
						camNotes.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if (winterHorrorlandNext)
					{
						new FlxTimer().start(1.5, function(tmr:FlxTimer)
						{
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					}
					else
					{
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if (FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;

	function startAchievement(achieve:String)
	{
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}

	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene)
		{
			endSong();
		}
	}
	#end

	public function KillNotes()
	{
		while (notes.length > 0)
		{
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
	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "combo" + pixelShitPart2);

		for (i in 0...10)
		{
			Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
		}
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		// trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1 * volumeMultiplier;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled)
			daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if (daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if (!practiceMode && !cpuControlled)
		{
			songScore += score;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);

		if (!ClientPrefs.comboStacking)
		{
			if (lastRating != null)
				lastRating.kill();
			lastRating = rating;
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (!ClientPrefs.comboStacking)
		{
			if (lastCombo != null)
				lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

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

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.hideHud;

			// if (combo >= 10 || combo == 0)
			if (showComboNum)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if (numScore.x > xThing)
				xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		/*
		trace(combo);
		trace(seperatedScore);
	 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				// var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true
						&& daNote.canBeHit
						&& daNote.mustPress
						&& !daNote.tooLate
						&& !daNote.wasGoodHit
						&& !daNote.isSustainNote
						&& !daNote.blockHit)
					{
						if (daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							// notesDatas.push(daNote.noteData);
							canMiss = ClientPrefs.antimash;
						}
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else
				{
					callOnLuas('onGhostTap', [key]);
					if (canMiss)
					{
						noteMissPress(key);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		// trace('pressed: ' + controlArray);
	}

	/**
	This needs to have two different keybinds since that's how ninjamuffin wanted it like bruh.

	yeah this is like 10X better than what it was before lmao
**/
	var TemporaryKeys:Map<String, Map<String, Array<FlxKey>>> = [
		"dfjk" => [
			'note_left' => [D, D],
			'note_down' => [F, F],
			'note_up' => [J, J],
			'note_right' => [K, K]
		],
		// ... other keybind configurations ...
	];

	var switched:Bool = false;

	function keybindSwitch(keybind:String = 'normal'):Void
	{
		switched = true;

		// Function to create keybinds dynamically
		function createKeybinds(bindString:String):Map<String, Array<FlxKey>>
		{
			var keybinds:Map<String, Array<FlxKey>> = new Map<String, Array<FlxKey>>();
			var keys:Array<FlxKey> = [];

			var keyNames:Array<String> = ['left', 'down', 'up', 'right'];

			for (i in 0...bindString.length)
			{
				var keyChar:String = bindString.charAt(i).toUpperCase();
				var key:FlxKey = FlxKey.fromString(keyChar);

				keys.push(key);
				keybinds.set('note_' + keyNames[i], [key, key]); // Modify as needed
			}
			trace(keybinds);
			return keybinds;
		}

		function switchKeys(newBinds:String):Void
		{
			var bindsTable:Array<String> = newBinds.split("");
			midSwitched = true;
			changeMania(mania);

			keysArray = [];
			ClientPrefs.keyBinds = createKeybinds(newBinds);
			keysArray = [
				(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left'))),
				(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down'))),
				(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up'))),
				(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')))
			];
		}

		// Switch based on the provided keybind
		switchKeys(keybind);

		ClientPrefs.reloadControls();
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}

			callOnLuas('onKeyRelease', [key]);
		}
		// trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray[mania].length)
			{
				for (j in 0...keysArray[mania][i].length)
				{
					if (key == keysArray[mania][i][j])
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
		for (i in 0...keysArray[mania].length)
		{
			for (j in 0...keysArray[mania][i].length)
			{
				if (FlxG.keys.checkStatus(keysArray[mania][i][j], PRESSED))
					return true;
			}
		}

		return false;
	}

	private function dataKeyIsPressed(data:Int):Bool
	{
		for (i in 0...keysArray[mania][data].length)
		{
			if (FlxG.keys.checkStatus(keysArray[mania][data][i], PRESSED))
				return true;
		}

		return false;
	}

	private function keyShit():Void
	{
		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			if ((FlxG.keys.anyJustPressed(debugKeysDodge) && terminateTimestamps.length > 0 && !terminateCooldown) || cpuControlled)
			{
				boyfriend.playAnim('dodge', true);
				terminateCooldown = true;

				for (i in 0...terminateTimestamps.length)
				{
					if (!terminateTimestamps[i].alive || terminateTimestamps[i] == null)
						continue;

					if (terminateTimestamps[i].alive && terminateTimestamps[i].canBeHit)
					{
						terminateTimestamps[i].wasGoodHit = true;
						terminateTimestamps[i].kill();
						terminateTimestamps.resize(0);
					}
				}

				new FlxTimer().start(Conductor.stepCrochet * 2 / 1000, function(tmr)
				{
					terminateCooldown = false;
					FlxDestroyUtil.destroy(tmr);
				});
			}

			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true
					&& daNote.isSustainNote
					&& dataKeyIsPressed(daNote.noteData % Note.ammo[mania])
					&& daNote.canBeHit
					&& daNote.mustPress
					&& !daNote.tooLate
					&& !daNote.wasGoodHit
					&& !daNote.blockHit)
				{
					goodNoteHit(daNote);
				}
			});
		

			if (keysArePressed() && !endingSong)
			{
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null)
				{
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.animation.curAnim != null
				&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				// boyfriend.animation.curAnim.finish();
			}
		}
	}

	function additionalOffset(spr:StrumNote, i:Int)
	{
		spr.offset.x += xWiggle[spr.ID % 4];
		spr.offset.y += yWiggle[spr.ID % 4];
	}

	function noteMiss(daNote:Note, ?playAudio:Bool = true, ?skipInvCheck:Bool = false, isAlert:Bool = false):Void
	{	
		// You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		if (!boyfriend.invuln)
		{
			combo = 0;

			health -= daNote.missHealth * healthLoss * dmgMultiplier;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (playAudio)
			{
				FlxG.sound.play(Paths.sound('missnote' + FlxG.random.int(1, 3)), FlxG.random.float(0.1, 0.2));
			}

			// For testing purposes
			// trace(daNote.missHealth);
			songMisses++;
			vocals.volume = 0;
			if (!practiceMode)
				songScore -= 10;

			totalPlayed++;
			RecalculateRating(true);

			var char:Character = boyfriend;
			if (daNote.gfNote)
			{
				char = gf;
			}

			if (daNote.isAlert)
			{
				health -= daNote.missHealth * healthLoss * 2;
				FlxG.sound.play(Paths.sound('warning'));
				var fist:FlxSprite = new FlxSprite().loadGraphic("assets/images/thepunch.png");
				fist.x = FlxG.width / camGame.zoom;
				fist.y = char.y + char.height / 2 - fist.height / 2;
				add(fist);
				FlxTween.tween(fist, {x: char.x + char.frameWidth / 2}, 0.1, {
					onComplete: function(tween)
					{
						if (tween.executions >= 2)
						{
							fist.kill();
							FlxDestroyUtil.destroy(fist);
							tween.cancel();
							FlxDestroyUtil.destroy(tween);
						}
					},
					type: PINGPONG
				});
			}

			if (daNote.isAlert)
			{
				char.playAnim('hit', true);
			}
			else if (char != null && !daNote.noMissAnimation && char.hasMissAnimations)
			{
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[daNote.noteData] + 'miss' + daNote.animSuffix;
				char.playAnim(animToPlay, true);
			}

			callOnLuas('noteMiss', [
				notes.members.indexOf(daNote),
				daNote.noteData,
				daNote.noteType,
				daNote.isSustainNote
			]);

			if (daNote.noteType == '' && currentBarPorcent < 1)
				currentBarPorcent += 0.053;
		}
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.ghostTapping)
			return; // fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss * dmgMultiplier;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if (!practiceMode)
				songScore -= 10;
			if (!endingSong)
			{
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			setBoyfriendInvuln(4 / 60);
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
		});*/

			if (boyfriend.hasMissAnimations)
			{
				boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
			}
			vocals.volume = 0;
		}
		callOnLuas('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
				{
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData] + altAnim;
			if (note.gfNote)
			{
				char = gf;
			}

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}
		var char:Character = dad;
		var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
		if (note.noteType == 'GF Duet')
		{
			gf.playAnim(animToPlay + note.animSuffix, true);
			gf.holdTimer = 0;
			dad.playAnim(animToPlay + note.animSuffix, true);
			dad.holdTimer = 0;
		}

		if (SONG.needsVoices)
			vocals.volume = 1 * volumeMultiplier;

		var time:Float = 0.15;
		if (note.isSustainNote && !(note.animation.curAnim.name.endsWith('tail') || note.animation.curAnim.name.endsWith('end')))
		{
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}

		if (currentBarPorcent < 1)
			currentBarPorcent += 0.0030;
	}

	public var check:Int = 0;

	function goodNoteHit(note:Note):Void
	{
		if (note.specialNote)
		{
			specialNoteHit(note);
			return;
		}
		if (archMode)
		{
			if (note.isCheck)
			{
				check++;
				if (ClientPrefs.notePopup)
					ArchPopup.startPopupCustom('You Found A Check!', check + '/' + itemAmount, 'Color'); // test
				trace('Got: ' + check + '/' + itemAmount);
				updateScore();
			}
		}
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss))
				return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}

				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'Hurt Note': // Hurt note
							if (boyfriend.animation.getByName('hurt') != null)
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
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
				if (combo > 9999)
					combo = 9999;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			if (!note.noAnimation)
			{
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];

				if (note.gfNote)
				{
					if (gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;
				}
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
				if (note.noteType == 'GF Duet')
				{
					gf.playAnim(animToPlay + note.animSuffix, true);
					gf.holdTimer = 0;
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;
				}

				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !(note.animation.curAnim.name.endsWith('tail') || note.animation.curAnim.name.endsWith('end')))
				{
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
			}
			else
			{
				var spr = playerStrums.members[note.noteData];
				if (spr != null)
				{
					spr.playAnim('confirm', true);
				}
			}
			note.wasGoodHit = true;
			vocals.volume = 1 * volumeMultiplier;

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				if (currentBarPorcent < 1)
				{
					currentBarPorcent -= 0.0120;
				}
			}
			else
			{
				if (currentBarPorcent < 1)
				{
					currentBarPorcent -= 0.0001;
				}
			}
			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function specialNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (note.isMine || note.isFakeHeal)
			{
				songMisses++;
				health -= FlxG.random.float(0.25, 0.5) * dmgMultiplier;
				if (note.isMine)
					FlxG.sound.play(Paths.sound('mine'));
				else if (note.isFakeHeal)
					FlxG.sound.play(Paths.sound('fakeheal'));
				var nope:FlxSprite = new FlxSprite(0, 0);
				nope.loadGraphic(Paths.image("cross"));
				nope.setGraphicSize(Std.int(nope.width * 4));
				nope.angle = 45;
				nope.updateHitbox();
				nope.alpha = 0.8;
				nope.cameras = [camNotes];

				playerStrums.forEach(function(spr:FlxSprite)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						nope.x = (spr.x + spr.width / 2) - nope.width / 2;
						nope.y = (spr.y + spr.height / 2) - nope.height / 2;
					}
				});

				add(nope);

				FlxTween.tween(nope, {alpha: 0}, 1, {
					onComplete: function(tween)
					{
						nope.kill();
						remove(nope);
						nope.destroy();
					}
				});
			}
			else if (note.isFreeze)
			{
				songMisses++;
				FlxG.sound.play(Paths.sound('freeze'));
				frozenInput++;
				playerStrums.forEach(function(sprite)
				{
					sprite.color = 0x0073b5;
					isFrozen = true;
				});
				new FlxTimer().start(2, function(timer)
				{
					frozenInput--;
					if (frozenInput <= 0)
					{
						playerStrums.forEach(function(sprite)
						{
							sprite.color = 0xffffff;
							isFrozen = false;
							boyfriend.stunned = false;
						});
					}
					FlxDestroyUtil.destroy(timer);
				});
			}
			else if (note.isAlert)
			{
				FlxG.sound.play(Paths.sound('dodge'));
				boyfriend.playAnim('dodge', true);
			}
			else if (note.isHeal)
			{
				health += FlxG.random.float(0.3, 0.6);
				FlxG.sound.play(Paths.sound('heal'));
				boyfriend.playAnim('hey', true);
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !(note.animation.curAnim.name.endsWith('tail') || note.animation.curAnim.name.endsWith('end')))
				{
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
			}
			else
			{
				var spr = playerStrums.members[note.noteData];
				if (spr != null)
				{
					spr.playAnim('confirm', true);
				}
			}

			note.wasGoodHit = true;
			vocals.volume = 1 * volumeMultiplier;

			if (!note.isSustainNote)
			{
				note.kill();
			}

			popUpScore(note);
		}
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;

		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			hue = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][0] / 360;
			sat = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][1] / 100;
			brt = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][2] / 100;
			if (note != null)
			{
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
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
		// trace('Car drive');
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
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
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
		if (gf != null)
		{
			gf.danced = false; // Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
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
		if (!ClientPrefs.lowQuality)
			halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared'))
		{
			boyfriend.playAnim('scared', true);
		}

		if (gf != null && gf.animOffsets.exists('scared'))
		{
			gf.playAnim('scared', true);
		}

		if (ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
			camNotes.zoom += 0.03;

			if (!camZooming)
			{ // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.flashing)
		{
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if (!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo')
		{
			if (limoKillingState < 1)
			{
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
				if (achieve != null)
				{
					startAchievement(achieve);
				}
				else
				{
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if (curStage == 'limo')
		{
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

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if (!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	function pauseMP4s()
	{
		for (i in 0...addedMP4s.length)
		{
			if (addedMP4s[i] == null)
				continue;
			if (addedMP4s[i].vlcBitmap == null)
				continue;
			if (!addedMP4s[i].vlcBitmap.isPlaying)
				continue;
			addedMP4s[i].pause();
		}
	}

	function resumeMP4s()
	{
		if (paused)
			return;

		for (i in 0...addedMP4s.length)
		{
			if (addedMP4s[i] == null)
				continue;
			if (addedMP4s[i].vlcBitmap == null)
				continue;
			if (addedMP4s[i].vlcBitmap.isPlaying)
				continue;
			addedMP4s[i].resume();
		}
	}

	override function destroy()
	{
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		#if hscript
		if (FunkinLua.hscript != null)
			FunkinLua.hscript = null;
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;

		FlxDestroyUtil.destroyArray(xWiggleTween);
		FlxDestroyUtil.destroyArray(yWiggleTween);

		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate) + delayOffset
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate) + delayOffset))
		{
			resyncVocals();
		}

		if (curStep == lastStepHit)
		{
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

		if (curBeat % 8 == 8)
		{
			readChatData();
		}
		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null
			&& curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& gf.animation.curAnim != null
			&& !gf.animation.curAnim.name.startsWith("sing")
			&& !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.animation.curAnim.name.startsWith('sing')
			&& !dad.stunned)
		{
			dad.dance();
		}

		switch (curStage)
		{
			case 'tank':
				if (!ClientPrefs.lowQuality)
					tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});

			case 'school':
				if (!ClientPrefs.lowQuality)
				{
					bgGirls.dance();
				}

			case 'mall':
				if (!ClientPrefs.lowQuality)
				{
					upperBoppers.dance(true);
				}

				if (heyTimer <= 0)
					bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if (!ClientPrefs.lowQuality)
				{
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
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
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

		switch (terminateStep)
		{
			case 3:
				var terminate = new TerminateTimestamp(Math.floor(Conductor.songPosition / Conductor.crochet) * Conductor.crochet + Conductor.crochet * 3);
				add(terminate);
				terminateTimestamps.push(terminate);
				terminateStep--;
			case 2 | 1 | 0:
				terminateMessage.loadGraphic(Paths.image("terminate" + terminateStep));
				terminateMessage.screenCenter(XY);
				terminateMessage.cameras = [camOther];
				terminateMessage.visible = true;
				if (terminateStep > 0)
				{
					terminateSound.volume = 0.6;
					terminateSound.play(true);
				}
				else if (terminateStep == 0)
				{
					FlxG.sound.play(Paths.sound('beep2'), 0.85);
				}
				terminateStep--;
			case -1:
				terminateMessage.visible = false;
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); // DAWGG?????
		callOnLuas('onBeatHit', []);

		if (currentBarPorcent < 1)
			currentBarPorcent += 0.010;
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
				camNotes.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}

		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if (ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;

			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == FunkinLua.Function_Continue;
			if (!bool && ret != 0)
			{
				returnVal = cast ret;
			}
		}
		#end
		// trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = strumLineNotes.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	function setBoyfriendInvuln(time:Float = 5 / 60)
	{
		invulnCount++;
		var invulnCheck = invulnCount;

		boyfriend.invuln = true;

		new FlxTimer().start(time, function(tmr:FlxTimer)
		{
			if (invulnCount == invulnCheck)
			{
				boyfriend.invuln = false;
			}
		});
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating(badHit:Bool = false)
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0)
				ratingFC = "SFC";
			if (goods > 0)
				ratingFC = "GFC";
			if (bads > 0 || shits > 0)
				ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10)
				ratingFC = "SDCB";
			else if (songMisses >= 10)
				ratingFC = "Clear";
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if (chartingMode)
			return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length)
		{
			var achievementName:String = achievesToCheck[i];
			if (!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled)
			{
				var unlock:Bool = false;

				if (achievementName.contains(WeekData.getWeekFileName())
					&& achievementName.endsWith('nomiss')) // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss";
				{
					if (isStoryMode
						&& campaignMisses + songMisses < 1
						&& CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1
						&& !changedDifficulty
						&& !usedPractice)
						unlock = true;
				}
				switch (achievementName)
				{
					case 'ur_bad':
						if (ratingPercent < 0.2 && !practiceMode)
						{
							unlock = true;
						}
					case 'ur_good':
						if (ratingPercent >= 1 && !usedPractice)
						{
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if (Achievements.henchmenDeath >= 100)
						{
							unlock = true;
						}
					case 'oversinging':
						if (boyfriend.holdTimer >= 10 && !usedPractice)
						{
							unlock = true;
						}
					case 'hype':
						if (!boyfriendIdled && !usedPractice)
						{
							unlock = true;
						}
					case 'two_keys':
						if (!usedPractice)
						{
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length)
							{
								if (keysPressed[j])
									howManyPresses++;
							}

							if (howManyPresses <= 2)
							{
								unlock = true;
							}
						}
					case 'toastie':
						if (/*ClientPrefs.framerate <= 60 &&*/ !ClientPrefs.shaders && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing)
						{
							unlock = true;
						}
					case 'debugger':
						if (Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice)
						{
							unlock = true;
						}
				}

				if (unlock)
				{
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
} class TerminateTimestamp extends FlxObject
{
	public var strumTime:Float = 0;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var tooLate:Bool = false;
	public var didLatePenalty:Bool = false;

	public function new(_strumTime:Float)
	{
		super();
		strumTime = _strumTime;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		canBeHit = (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
			&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset);

		if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
			tooLate = true;
	}
}
