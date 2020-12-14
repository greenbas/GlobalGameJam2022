var cLEgo = 0;
var cJEgo = 1;
var cSEgo = 2;
// Func Names	cJEgo = johnny, etc
//		Interact = handle, Look = look, etc
// CtrlF	player -> active



// ===== PREPARATION ==============================================================================

// Players
var NARRATOR = 3;
var plName = { 0 : "pl_lindsay", 1 : "pl_johnny", 2: "pl_sarah" };
var plColour = { 0: "#ba0", 1: "#e44", 2: "#739", 3: "white" }
var plFSize = { 0: 25, 1: 20, 2: 25, 3: 25 }
// Interactions
var vcName = { 0 : "look", 1 : "handle", 2: "take", 3: "talk" };
var vcDesc = { 0 : "Look at ", 1 : "Interact with ", 2: "Take ", 3: "Talk to " };
// Rooms
var rName = { 0: "intro", 1 : "clearing", 2 : "house", 3: "hallway" };
var rImg = { 0 : "intro", 1: "forest_clearing", 2 : "forest_house", 3: "hallway" };
// Inventory
var invItems = { 0 : "stick" }; // Possible items

function general_init()
{
	//currRoom = 1;
}


// ===== PLAYERS ==================================================================================

function johnny_handle()
{
	if (active == cLEgo) Display("He's my brother!");
	if (active == cSEgo) Display("Not right now.");
	if (active == cJEgo) Display("Not here.");
}
function sarah_handle()
{
	if (active == cLEgo) Display("You'd like that, wouldn't you?");
	if (active == cSEgo) Display("Nah.");
	if (active == cJEgo) Display("Not here.");
}
function lindsay_handle()
{
	if (active == cLEgo) Display("Nice try.");
	if (active == cSEgo) Display("She's my friend.");
	if (active == cJEgo) Display("Ew.");
}

function johnny_look()
{
	if (active == cLEgo) Display("My brother, Johnny.");
	if (active == cSEgo) Display("Lindsay's brother.  I'm... kind of dating him.");
	if (active == cJEgo) Display("Me!  Aren't I gorgeous?");
}

function lindsay_look()
{
	if (active == cJEgo) Display("Little sis.");
	if (active == cSEgo) Display("My best friend, Lindsay.");
	if (active == cLEgo) Display("That would be me.");
}

function sarah_look()
{
	if (active == cJEgo) Display("Lindsay's hot friend, and recently, my girlfriend: Sarah.");
	if (active == cLEgo) Display("My good friend Sarah.");
	if (active == cSEgo) Display("That's me.");
}
// FIXME: It would be fun to have some Talk dialogues between the players.
// Maybe some randomization on it, or have it depend where you are in the game.

function johnny_talk()  { players_talk(cJEgo, active); }
function lindsay_talk() { players_talk(cLEgo, active); }
function sarah_talk()   { players_talk(cSEgo, active); }

var timesTalked = 0;
function players_talk(src, dest)
{
	if (!lost)
	{
		Display("Let's get the firewood and get back.");
		if (src == cLEgo) Display("I want to finish my story.");
	}
	else if (queenState <= 2)
	{
		SayAsID(cSEgo, "This is the way we came, right?");
		SayAsID(cJEgo, "Yeah, it is.");
		SayAsID(cLEgo, "It doesn't make any sense.  We went in a straight line.");
		SayAsID(cJEgo, "We must have gotten turned around.");
		SayAsID(cLEgo, "I guess so?");
	}
	else if (queenState == 3)
	{
		if (timesTalked == 0)
		{
			SayAsID(cLEgo, "You know we can't trust her.  It.");
			SayAsID(cJEgo, "I don't think we have any choice.");
			SayAsID(cLEgo, "We stumbled into this world, surely if we walk around enough, we can stumble back?");
			SayAsID(cSEgo, "I don't want to be in this forest for hours, never mind days.");
			SayAsID(cSEgo, "And we took the same path out as in.  It's already clear that we've missed it at least once.");
			SayAsID(cJEgo, "And we've wandered around enough that we have no *idea* where to start looking.");
			SayAsID(cLEgo, "But she may have brought us here herself.");
			SayAsID(cJEgo, "I don't think that changes anything, Lindsay.");
			SayAsID(cSEgo, "I need to get back home in case there's a call about my mom.");
			SayAsID(cLEgo, "... yeah.");
			SayAsID(cJEgo, "She'll be OK.");
			SayAsID(cSEgo, "... sure.");
			SayAsID(cLEgo, "So we're doing it, huh?");
			SayAsID(cJEgo, "I really don't think we have any choice.");
			timesTalked = 1;
		}
		else
		{
			if (src == cLEgo) Display("I don't want to make her think of her mom again.  Besides, she's right.");
			if (src == cJEgo) Display("Let's not have that conversation again.  We know what we have to do.");
			if (src == cSEgo) Display("Let's just get out of here as quickly as we can.");
		}
	}
}



// ===== ITEMS ON PLAYERS =========================================================================

function use_stick(oid)
{
	// To prove this can be done (I''ll need it later):
	//SayAs(oid, "All right, give it here.");
	//removeFromInventory("stick");
	//addToInventory("stick", /*ID*/);
	if (isPlayer(oid))	Display("Or just let " + oid + " get the next one.");
	if (oid == "something_odd") Display("Still doesn't quite reach.  Sorry.");

}



// ===== NPCs =====================================================================================

var queenState = 0;
var queenX = 640;
var queenY = 370;

function something_odd_describe() { return "strange object"; }

function something_odd_look()
{
	if (queenState <= 2)
	{
		Display("There's something... white - and moving - deeper into the forest.");
		Display("The trees are too thick to go over there, though.");
	}
	else
	{
		Display("It claims to be a faerie.  I'm hardly in a position to disagree.");
	}
}

function something_odd_take()
{
	something_odd_handle();
}

function something_odd_talk()
{
	if (queenState <= 2)
	{
		Display("Hello!", 2000);
		Display("Is anyone there?!?", 4000);
		Display("... Guess not.");
	}
	else
	{
		startCutscene();
		Display("All right, we've agreed.  We'll go to this house for you.");
		Narrate("So be it.  Follow me.");
		// FIXME: moving
		doAfterStuff("goToHouse");
	}
}
function goToHouse() // Needs to be schedulable
{
		loadRoom("house");
		Narrate("I go no further.  I cannot even stay here for long.");
		Narrate("I will return when you come back out.");
		stopCutscene();
}

function something_odd_handle()
{
	if (active == cSEgo)
	{
		var queen = obj(main, "something_odd");
		if (queenState == 1) // Drawn
		{
			queenState++;
			startCutscene();
			Display("It's just too far awa-");
			// At this point, queenX and queenY are top-right, let''s translate them and THEN move
			queenX = getPlayerPos(queen)[0] - 10;
			queenY = getPlayerPos(queen)[1] + 20;
			walkToXY(queenX, queenY, queen);
			Display("Well, that's ... very odd.", 2500);
			Display("My fingers just tingled,", 2000)
			Display("and it almost felt as though... never mind.");
			stopCutscene();
		}
		else if (queenState == 2)
		{
			startCutscene();
			Display("There it goes again.  My fingers are tingling.  And...");
			queenState++;
			//queenX = getPlayerPos(player(cSEgo))[0];
			//queenY = getPlayerPos(player(cSEgo))[1] - 100;
			//walkToXY(queenX, queenY, queen);
			Display("...oh my.");
			// FIXME Queen to follow? and insert explanation
			//cFaerieQueen.FollowCharacter(cSEgo, 20, 0);
			//cFaerieQueen.z = 100;
			Narrate("Human.  You must stop this at once.");
			Narrate("(( Long cutscene ))");
			stopCutscene();
		}
		else if (queenState > 2)
		{
			Display("I don't know what she might do if I did that again.");
		}
	}
	else
	{
		if (queenState > 2)
		{
			Display("That just doesn't seem like a good idea.");
		}
		else
		{
			Display("My arms just aren't long enough,", 2500);
			Display("and the trees get too thick to go much closer.");
		}
	}
}




// ===== ROOMS ====================================================================================

function intro_init()
{
	var animList = {};
	animList = addAnimation(animList, "burn", 400, 217, 0, 0, 8);
	scheduleSprite(main, 0, 0, "campfire", path + //_
		"images/objects/campfire_sprite.png", OBJECT, animList, "burn", false);
}
var fireanim = false;
var fire;
function intro_loaded()
{
	fire = obj(main, "campfire");
	startCutscene();
	scaleObj(fire, 0.1, 1);
	centerObj(fire);
	// Text while the screen is black
	SayAsID(cLEgo, "Ten years ago,");
	SayAsID(cLEgo, "on a night just like this one,");
	SayAsID(cLEgo, "there were three youths who went camping together...");
	doAfterStuff("doIntroPart2");
}
function doIntroPart2()
{
	// Bring in the campfire
	fire.show();
	fireanim = true;
	// Move it closer
	walkToXY(getScreenW()/2, 350, fire, -1);
	doAfterStuff("doIntroPart3");
}
function doIntroPart3()
{
	SayAsID(cLEgo, "Little did they know");
	SayAsID(cLEgo, "that they were embarking on a journey");
	SayAsID(cLEgo, "that would change their world!");
	doAfterStuff("doIntroPart4");
}
function doIntroPart4()
{
	// And closer again
	walkToXY(getScreenW()/2, 600, fire, -1);
	//Wait();
	doAfterStuff("doIntroPart5");
}
function doIntroPart5()
{
	// And then bring in the characters
	$.each(plName, function(k, plID)
	{
		obj(main, plID).show();
		obj(main, plID).setAnimation("sit");
	});
	obj(main, "pl_lindsay").setPosition(550, 150);
	obj(main, "pl_sarah").setPosition(100, 125);
	obj(main, "pl_johnny").setPosition(475, 75);
	obj(main, "pl_johnny").attrs.scale.x = -obj(main, "pl_johnny").attrs.scale.x;
	//Wait();
	doAfterStuff("doIntroPart6");
}
function doIntroPart6()
{
	fireanim = false;
	SayAsID(cJEgo, "<laughs>");
	SayAsID(cSEgo, "Can you make it any more obvious that this is about us?");
	SayAsID(cLEgo, "Sure!  It was a girl named Lindsay, and her brother, and her best friend.");
	SayAsID(cJEgo, "Let me guess, and the brother and the friend were dating each other?");
	SayAsID(cLEgo, "God no, that would be too awful.");
	SayAsID(cSEgo, "Right, because it bothers you *so much*.");
	SayAsID(cLEgo, "I can't even sleep at night.");
	SayAsID(cJEgo, "Aw... we're not THAT loud, are we?");
	SayAsID(cSEgo, "Johnny!");
	SayAsID(cJEgo, "Awww, she knows it was a joke.");
	SayAsID(cSEgo, "Don't joke about things like that.");
	SayAsID(cJEgo, "<mumbles> Sorry...");
	SayAsID(cLEgo, "So... can I get back to my story?");
	SayAsID(cSEgo, "Maybe we should stock up on firewood first - we're getting a little low.");
	SayAsID(cJEgo, "Good idea, it's almost too dark to do it already.");
	SayAsID(cLEgo, "Fine.  I'd barely gotten started anyway.  <mock glare>");
	doAfterStuff("endIntro");
}
function endIntro()
{
	stopCutscene();
	loadRoom("clearing");
}

// --------------- Clearing ------------------------------------------------

var numSticks = 0;
var numFRooms = 8;
//                    /- start
//  |---|---|---|---|---|---|---|---|
//  | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
//  |---|---|---|---|---|---|---|---|
//  |      sticks       |         \- first lost (reset to 5)

var startFRoom = 3;
var currFRoom = startFRoom;
var maxSticks = 12; // The number I let them collect
var lost = false;

function cl_descr() { return "Forest"; }
function clearing_describe() { return cl_descr(); }
/*function clearing00_describe() { return cl_descr(); }
function clearing01_describe() { return cl_descr(); }
function clearing02_describe() { return cl_descr(); }
function clearing03_describe() { return cl_descr(); }
function clearing04_describe() { return cl_descr(); }
function clearing05_describe() { return cl_descr(); }
function clearing06_describe() { return cl_descr(); }
function clearing07_describe() { return cl_descr(); }*/

function clearing_look() { clearing_look_general(); }
/*function clearing00_look() { clearing_look_general(); }
function clearing01_look() { clearing_look_general(); }
function clearing02_look() { clearing_look_general(); }
function clearing03_look() { clearing_look_general(); }
function clearing04_look() { clearing_look_general(); }
function clearing05_look() { clearing_look_general(); }
function clearing06_look() { clearing_look_general(); }
function clearing07_look() { clearing_look_general(); }*/

function clearing_look_general()
{
	if (!lost)
	{
		Display("A bit gloomy, but otherwise nice enough.");
	}
	else
	{
		Display("It's looking gloomier than it was earlier.")
	}
}

function clearing_init() { clearing_init_general(); }
/*function clearing00_init() { clearing_init_general(); }
function clearing01_init() { clearing_init_general(); }
function clearing02_init() { clearing_init_general(); }
function clearing03_init() { clearing_init_general(); }
function clearing04_init() { clearing_init_general(); }
function clearing05_init() { clearing_init_general(); }
function clearing06_init() { clearing_init_general(); }
function clearing07_init() { clearing_init_general(); }*/

function clearing_init_general()
{
	if (currFRoom == 3)	{ loadStick("01", 2); loadStick("02", 3);			}
	if (currFRoom == 4)	{ loadStick("03", 2); loadStick("04", 4);			}
	if (currFRoom == 5)	{ loadStick("05", 1); loadStick("06", 3); loadStick("07", 4);	}
	if (currFRoom == 6)	{ loadStick("08", 2); loadStick("09", 4);			}
	if (currFRoom == 7)	{ loadStick("10", 1); loadStick("11", 2); loadStick("12", 3);	}
	load_decoration("go_left0" + currFRoom, "go_left", 0, 0);
	load_decoration("go_right0" + currFRoom, "go_right", 818, 0);
	if (lost && currFRoom == 7)
	{
		var animList = {};
		animList = addAnimation(animList, "fly", 45, 30, 0, 0, 9);
		scheduleSprite(main, queenX, queenY, "something_odd", path + //_
			"images/characters/faeries/queen_sprite.png", OBJECT, animList, "fly");
		scheduleDraw(main, 594, 345, "unreachable_forest", path + //_
			"images/objects/hiding_trees.png", OBJECT + 1);
		if (queenState == 0) queenState++;
	}
}

function left_descr() { return "Go Further"; }
function right_descr() { return "Go Back"; }
function left00_describe()	{ return left_descr(); }
function left01_describe()	{ return left_descr(); }
function left02_describe()	{ return left_descr(); }
function left03_describe()	{ return left_descr(); }
function left04_describe()	{ return left_descr(); }
function left05_describe()	{ return left_descr(); }
function left06_describe()	{ return left_descr(); }
function left07_describe()	{ return left_descr(); }
function right00_describe()	{ return right_descr(); }
function right01_describe()	{ return right_descr(); }
function right02_describe()	{ return right_descr(); }
function right03_describe()	{ return right_descr(); }
function right04_describe()	{ return right_descr(); }
function right05_describe()	{ return right_descr(); }
function right06_describe()	{ return right_descr(); }
function right07_describe()	{ return right_descr(); }

function go_left00_click()	{ moveClearing(1); }
function go_left01_click()	{ moveClearing(1); }
function go_left02_click()	{ moveClearing(1); }
function go_left03_click()	{ moveClearing(1); }
function go_left04_click()	{ moveClearing(1); }
function go_left05_click()	{ moveClearing(1); }
function go_left06_click()	{ moveClearing(1); }
function go_left07_click()
{
	if (numSticks < maxSticks)
	{
		var some = "some";
		if (numSticks > 0) some = "some more";
		Display("We don't need to go that far.", 2000);
		Display("Let's just collect " + some + " of the", 2500);
		Display("dead branches we've already seen.", 2500);
	}
	else
	{
		if (lost) moveClearing(1);
		else Display("It's getting dark and we have plenty of firewood.  Let's go back.");
	}
}
function go_right00_click()	{ moveClearing(-1); }
function go_right01_click()
{
	moveClearing(-1);
	if (!lost)
	{
		Display("That's really odd.", 1500);
		Display("We should be back by now.", 2500);
		lost = true;
		fixLost();
	}
}
function go_right02_click()	{ moveClearing(-1); }
function go_right03_click()
{
	if (numSticks < maxSticks)
	{
		Display("Let's get a little more firewood before we head back.")
	}
	else moveClearing(-1);
}
function go_right04_click()	{ moveClearing(-1); }
function go_right05_click()	{ moveClearing(-1); }
function go_right06_click()	{ moveClearing(-1); }
function go_right07_click()	{ moveClearing(-1); }

function moveClearing(dir)
{
	currFRoom += dir;
	fixLost();
	loadRoom("clearing");
	//clearOldRoom();
	//clearing_init_general();
}
function fixLost()
{
	if (lost)
	{
		// Ensure that they wander forever between rooms Start and Max
		if (currFRoom >= numFRooms) currFRoom -= 5;
		if (currFRoom < startFRoom) currFRoom += 5;
	}
}

function loadStick(n, preset)
{
	var x = 0;	var y = 0;
	if (preset == 1) { x = 113; y = 583; }
	if (preset == 2) { x = 227; y = 491; }
	if (preset == 3) { x = 436; y = 525; }
	if (preset == 4) { x = 596; y = 608; }
	load_obj("stick" + n, "stick", x, y);
}


function st_descr() { return "Stick"; }
function stick01_describe() { return st_descr(); }
function stick02_describe() { return st_descr(); }
function stick03_describe() { return st_descr(); }
function stick04_describe() { return st_descr(); }
function stick05_describe() { return st_descr(); }
function stick06_describe() { return st_descr(); }
function stick07_describe() { return st_descr(); }
function stick08_describe() { return st_descr(); }
function stick09_describe() { return st_descr(); }
function stick10_describe() { return st_descr(); }
function stick11_describe() { return st_descr(); }
function stick12_describe() { return st_descr(); }

function stick01_take() { pickUpStick("01"); }
function stick02_take() { pickUpStick("02"); }
function stick03_take() { pickUpStick("03"); }
function stick04_take() { pickUpStick("04"); }
function stick05_take() { pickUpStick("05"); }
function stick06_take() { pickUpStick("06"); }
function stick07_take() { pickUpStick("07"); }
function stick08_take() { pickUpStick("08"); }
function stick09_take() { pickUpStick("09"); }
function stick10_take() { pickUpStick("10"); }
function stick11_take() { pickUpStick("11"); }
function stick12_take() { pickUpStick("12"); }

function stick01_look()	{ lookAtStick("01"); }
function stick02_look()	{ lookAtStick("02"); }
function stick03_look()	{ lookAtStick("03"); }
function stick04_look()	{ lookAtStick("04"); }
function stick05_look()	{ lookAtStick("05"); }
function stick06_look()	{ lookAtStick("06"); }
function stick07_look()	{ lookAtStick("07"); }
function stick08_look()	{ lookAtStick("08"); }
function stick09_look()	{ lookAtStick("09"); }
function stick10_look()	{ lookAtStick("10"); }
function stick11_look()	{ lookAtStick("11"); }
function stick12_look()	{ lookAtStick("12"); }


function lookAtStick(st)
{
	Display("It looks perfect for firewood.");
}
function pickUpStick(st)
{
	if (numSticks < maxSticks)
	{
		if (countInventory("stick") < 5)
		{
			clearOffMain("stick" + st);
			markAsTaken("stick"+st);
			addToInventory("stick");
			numSticks++;
		}
		else
		{
			if (active == cLEgo)
			{
				Display("I'm already holding plenty.", 2000);
				Display("Let the others carry their share.", 2500);
				Narrate("Roll or click the mouse wheel, or press Q or E, to switch characters.");
			}
			else if (active == cJEgo)
			{
				Display("Ehh, all these sticks are pretty awkward.", 2500);
				Display("The girls won't mind helping.", 2500);
				Narrate("Remember, use Q or E or the mouse wheel to switch characters.");
			}
			else if (active == cSEgo)
			{
				Display("Surely I shouldn't have to hold so many of these myself.", 3500);
				Narrate("Remember, use Q or E or the mouse wheel to switch characters.");
			}
			Narrate("Some puzzles in this game will need the right person at the right time.");
		}
	}
	if (numSticks == maxSticks) // NOT else
	{
		Display("That's probably enough.  Let's go back.");
	}
}

// --------------- House ------------------------------------------------

function house_init()
{
	load_decoration("house", "house_house", 0, 0);
	load_decoration("front_door", "house_frontdoor", 0, 0);
	load_decoration("a_hole", "house_treehole", 0, 0);
	load_decoration("front_window", "house_window", 0, 0);
}

var goneIn = false;
function house_look()
{
	Display("It's kind of creepy - the only civilization for miles.");
}
function front_door_look()
{
	Display("The only door leading into the house.");
	Display("As far as I can tell, it's not rigged to explode upon opening.  Or anything else like that.");
}
function front_door_handle()
{
	if (!goneIn) Display("Here goes nothing.");
	loadRoom("hallway");
	goneIn = true;
}
function front_window_look()
{
	Display("Oddly, the only window.  It's a pretty small house.");
	Display("Inside, it seems to be a normal-looking bedroom.  A dresser, a rug... the bed is even made.");
}
function a_hole_look()
{
	Display("It's too dark to see anything.");
}
function a_hole_handle()
{
	Display("Sorry, I can't feel anything inside.");
}

// ===== Mechanical ===============================================================================

function extraAnimations()
{
	var changed = false;
	if (lost && currFRoom == 7)
	{
		if (queenState == 3) // Flittering around
		{
			// FIXME: Check if queen is in animObj
			/*if (!animating) // If the player is walking, this will interfere
			{
				queenX = getPlayerPos(player(cSEgo))[0];
				queenY = getPlayerPos(player(cSEgo))[1] - 100;
				// FIXME: Now add a random number between X (-20, 20) and Y (-5, 5)
				walkToXY(queenX, queenY, obj(main, "something_odd"));
			}*/
		}
	}
	if (fireanim)
	{
		scaleObj(fire, 0.1, 1);
		centerObj(fire);
	}
	return changed;
}


function extraSaving()
{
	saveVar("currFRoom", currFRoom);
	saveVar("lost", lost);
	saveVar("queenX", queenX);
	saveVar("queenY", queenY);
	saveVar("queenState", queenState);
}

function extraLoading()
{
	currFRoom = loadInt("currFRoom");
	lost = loadBool("lost");
	queenX = loadInt("queenX");
	queenY = loadInt("queenY");
	queenState = loadInt("queenState");
	//if (queenState > 0) obj(main, "queen").setPosition(queenX, queenY);
	numSticks = countInventory("stick", cLEgo) + //_
				countInventory("stick", cJEgo) + //_
				countInventory("stick", cSEgo);
}


var int_done = 0;