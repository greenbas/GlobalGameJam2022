extends Node
class_name Scene

var WIDTH
var HEIGHT
var scriptManager

var walkmap
#var all_scenes = {} # Unique list of scenes in the game
var all_chars = {} # List of Characters (extends sprite) that we've encountered so far
var all_objs = {}
var all_menus = {}
var currChar # Just the data, we can get_node & .new(data) from there
var currScene # ditto

func _ready():
	Game.sceneLoaded(self)

func prepScene():
	if Game.allGood():
		scriptManager = preload("ScriptManager.gd").new()
		scriptManager.attachScripts()
		refreshScene(true)
		Game.menu = Menu.new()
		Game.menu.loadData(self)
		refreshScene()
	else: # FIXME: This won't work if the various _draw and _inputs don't check Game.allGood
		  # So before release, test again by opening any of the csvs and making sure it quits.
		Game.reportError("Setup", "Unrecoverable error.  Quitting.")
		get_tree().quit()

# RefreshScene can cause scripts to run, which may need the Dialogue Menu.
# But the dialogue menu needs the size of the screen, which requires the background loaded.
# So there's a one-time call to this function to get the background loaded.
func refreshScene(justBG=false):
	# Determine the current scene based on where the current character is
	currChar = getCurrentCharacter()
	if Game.allGood():
		currScene = getCurrentScene(currChar)
		if Game.allGood():
			loadScene(currScene, justBG)

func getCurrentScene(character):
	return Game.entityWhere(Game.ENTITY.SCENE, ["ID"], [character.Scene_ID])

func loadScene(scene, justBG=false):
	$Background.texture = Game.getTexture(scene.Background_Path, scene.Background_Filename, scene.Background_Extension)
	WIDTH = $Background.texture.get_width()
	HEIGHT = $Background.texture.get_height()
	walkmap = $Walkmap
	walkmap.texture = Game.getTexture(scene.Walkmap_Path, scene.Walkmap_Filename, scene.Walkmap_Extension)
	walkmap.lock() # So we can read the colours of the pixels
	
	if !justBG:
		# Load the background and foreground
		Game.setCursor(currChar.Cursor_Path, currChar.Cursor_Filename, currChar.Cursor_Extension)
		#walkmap.recalcNodes()
		$Foreground.texture = Game.getTexture(scene.Foreground_Path, scene.Foreground_Filename, scene.Foreground_Extension)
		
		# Unload characters not currently in the scene
		#var removeNodes = []
		for i in range(0, $Characters.get_child_count()):
			var node = $Characters.get_child(i)
			node.visible = (all_chars[node.name].data.Scene_ID == scene.ID)
		for i in range(0, $Objects.get_child_count()):
			var node = $Objects.get_child(i)
			node.visible = (all_objs[node.name].data.Scene_ID == scene.ID)
		#	if currChar.Scene_ID != scene.ID: # Pro: Animations don't go forever.  Cons: ?
		#		removeNodes.append(node)
		#for node in removeNodes: # Do after so we're not changing the list we're iterating over
		#	$Characters.remove_child(node)
		
		# Load or update all characters and objects in the scene
		drawItems(scene.ID, Game.listOf(Game.ENTITY.CHAR).values(), all_chars, Game.ENTITY.CHAR)
		drawItems(scene.ID, Game.listOf(Game.ENTITY.OBJ).values(), all_objs, Game.ENTITY.OBJ)
		#emit_signal("draw")

func drawItems(sceneID, list, arr, oType):
	for i in list:
		if i.Scene_ID == sceneID or i.Scene_ID == "*":
			var sprite
			if arr.has(i.ID):
				sprite = arr[i.ID]
				sprite.visible = true #shouldn't need this
			else:
				match oType:
					Game.ENTITY.CHAR:
						sprite = Character.new(i)
					Game.ENTITY.OBJ:
						sprite = ScreenObject.new(i)
					Menu.MENUS.WHEEL:
						sprite = Menu.ActionMenu.new()
					Menu.MENUS.WHEEL_ITEM:
						sprite = Menu.ActionItem.new(i)
					Menu.MENUS.SCREEN: # This way is probably better
						sprite = Game.menu.screensList[i.ID]
					Menu.MENUS.SCREEN_ITEM:
						sprite = Game.menu.screenItems[i.ID]
					Menu.MENUS.SCREEN_INV:
						sprite = Game.menu.screenInv[i.ID]
				arr[i.ID] = sprite
				sprite.canvas.add_child(sprite) # or this
			sprite.drawMe()
			#var canvas = sprite.canvas
			#if !canvas.has_node(i.ID):
			#	canvas.add_child(sprite)

func _input(event):
	if event.is_action_pressed("ui_playable_next"):
		cycleChar(1)
	if event.is_action_pressed("ui_playable_prev"):
		cycleChar(-1)

func moveToChar(moveTo):
	cycleChar(0, moveTo)
func cycleChar(moveBy, moveTo=0):
	var curr = Game.playables.find(currChar)
	if moveBy == 0:
		curr = moveTo
	else:
		curr = (curr + moveBy) % Game.playables.size()
	currChar = Game.playables[curr]
	Game.updateByID(Game.ENTITY.CHAR, ["ID"], [currChar.ID], ["Current"], ["1"])
	refreshScene()

func onCharacterMove(character : Character):
	#character.Screen_X = posn.x # Only need to update at destination OR on new area, I think
	#character.Screen_Y = posn.y
	# Get the colour of the current position of the sprite's base
	var currColour = walkmap.getColour(character.position)
	if character.lastColour != currColour:
		character.lastColour = currColour
		triggerCharacterMove(currColour, character)


# As a type of interactable, Scenes may trigger scripts when:
# The user hovers over a coloured area on the walkmap
# A character enters (or begins the scene in) a coloured area of the walkmap
# A character performs any action on the screen itself

func triggerCharacterMove(colour, character):
	Game.verboseMessage("Pathing", "Character has entered area " + colour)
	# If there is a script associated with this movement, trigger it
	var scriptID = character.data.ID + "-" + currScene.ID + "-" + colour
	#scriptManager.run(scriptID)
	if scriptManager.hasScript(scriptID):
		scriptManager.run(scriptManager.script_commands[scriptID])

func getCurrentCharacter():
	return Game.entityWhere(Game.ENTITY.CHAR, ["Current"], ["1"])

func getCurrentSprite():
	var character : Character
	character = all_chars[currChar.ID]
	return character

func triggerClick(posn):
	# Find the clicked item - character, object, menu
	# Menu is the highest order.  Fall through to the scene
	var foundObj = findClicked(posn, all_menus)
	if !foundObj:
		var c = findClicked(posn, all_chars)
		var o = findClicked(posn, all_objs)
		if !c: foundObj = o
		elif !o: foundObj = c
		elif o.z_index > c.z_index: foundObj = o
		else: foundObj = c
	if !foundObj: foundObj = currScene
	else: foundObj = foundObj.data # We need the data to be equivalent with scene
	# But if try to grab it earlier we get null exceptions
	Game.menu.triggerClick(currChar, posn, foundObj)

func findClicked(posn, arr):
	# Loop through everything to check if it has the point and has actions
	# Return the clicked object with the highest Z-index
	var foundObj
	var foundZ = -1
	for i in arr.values():
		if i.visible and i.data.Actionable == "1":
			if Util.clickSolid(i, posn):
				if i.z_index > foundZ: foundObj = i
	return foundObj
	

func triggerWalk(posn):
	Game.debugMessage("Action", "Clicked screen (colour: %s, position: %s" % [posn, walkmap.getColour(posn)])
	var sprite = all_chars[currChar.ID]
	walkmap.tryWalking(sprite, posn)

func triggerHover(colour):
	# Update hover text
	# Debugging
	#print("New area! ", colour)
	pass
