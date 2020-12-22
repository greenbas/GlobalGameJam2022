
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




// --------------- Clearing ------------------------------------------------

var numSticks = 0;
var numFRooms = 8;
//                    /- start
//  |---|---|---|---|---|---|---|---|
//  | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
//  |---|---|---|---|---|---|---|---|
//  |      sticks       |         \- first lost (reset to 5)



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
