
	else if (queenState == 3)
	{
		{
			if (src == cLEgo) Display("I don't want to make her think of her mom again.  Besides, she's right.");
			if (src == cJEgo) Display("Let's not have that conversation again.  We know what we have to do.");
			if (src == cSEgo) Display("Let's just get out of here as quickly as we can.");
		}
	}
}

function goToHouse() // Needs to be schedulable
{
		loadRoom("house");
		Narrate("I go no further.  I cannot even stay here for long.");
		Narrate("I will return when you come back out.");
		stopCutscene();
}
Screen_X~,~Screen_Y	Characters	5~,~85		johnny
Screen_X~,~Screen_Y	Characters	5~,~95		sarah
Screen_X~,~Screen_Y	Characters	5~,~91		lindsay




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
