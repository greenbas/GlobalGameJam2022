extends Node
var sceneNode : Node
var menu : Menu
var inventory : Inventory
var allowActions = false
var dbgr : Debugger

# ===== Primary =========================================================

static func listOf(e): return Game.entities[Game.ENTITY_NAME[e]]

static func listWhere(e, prop, value, dict=true, err=true):
	return filter(e, prop, value, true, dict, err)

static func entityWhere(e, prop, value, dict=true, err=true):
	return filter(e, prop, value, false, dict, err)
	
static func entityByID(id): return Game.entities[Game.ENTITY_NAME[id]]
static func entityByName(name): return Game.entities[name]

static func dictByID(d):
	var dict = {}
	for o in d.values():
		dict[o.ID] = o
	return dict

static func getTabName(t):
	return Game.ENTITY_NAME[t].capitalize()

# ===== Game State ======================================================

# I could just define dicts directly, e.g. "var scenes = {}".
# But if I do it this way, then I can retrieve the entity name for error reporting
# and it may be useful for other reasons down the road.
# So, we have a dictionary of dictionaries.  Use the string as the index for easier debugging.
enum ENTITY { SCRIPT = 0, VAR, ACTION, CHAR, SCENE, OBJGROUP, OBJ, INV, EMOTIONS, ANIM, MENU, SAVE }
const MENU = 99
const ENTITY_NAME = { ENTITY.SCRIPT: "script", ENTITY.VAR: "variables", ENTITY.ACTION: "actions",
	ENTITY.CHAR: "characters", ENTITY.SCENE: "scenes", ENTITY.OBJGROUP: "objgroups",
	ENTITY.OBJ: "objects", ENTITY.INV: "inventory", ENTITY.EMOTIONS: "emotions",
	ENTITY.ANIM: "animations", ENTITY.MENU: "menus", ENTITY.SAVE: "save" }
var entities = {}
var idlist = {}

static func sceneLoaded(scene):
	Game.sceneNode = scene
	Game.dbgr = scene.get_node("DebugLayer/Debugger")
	scene.get_node("GameSelect/Background/MarginContainer/VBoxContainer/GamesList").loadGameList()

static func gamePicked(gameName):
	Game.currgame = gameName
	loadGameFromStart()

static func loadGameFromSave(fname):
	Game.sceneNode.unloadScene() # TODO: Loading from another save
	var folder = Game.savepath + Game.currgame + "/"
	var commands = Data.fillProps(folder, fname)
	for cmd in commands.values():
		var fcol = cmd.Filter_Column.split(ScriptManager.SPLITTER)
		var fval = cmd.Filter_Value.split(ScriptManager.SPLITTER)
		update(cmd.Set_Tab, fcol, fval, [cmd.Set_Column], [cmd.Set_Value], true)
	# And inventory, which is just easiest to keep separate
	var inv = ENTITY_NAME[ENTITY.INV]
	Game.entities[inv] = Game.loadDict(folder, fname + "-inv")
	Game.inventory = Inventory.new(Game.playables, entityByID(Game.ENTITY.INV))
	Game.sceneNode.refreshScene()

static func loadGameFromStart():
	var start = Game.gamepath + Game.currgame + "/data/"
	for type in range(0, len(ENTITY)):
		var dict = Game.loadDict(start, ENTITY_NAME[type])
		if allGood():
			Game.entities[ENTITY_NAME[type]] = dict
			var ids = {}
			for e in dict.values():
				e.Tab = type # We're going to want this later
				if type != Game.ENTITY.INV:
					ids[e] = e.ID # As a rule of dicts, each ID will only be entered once
				else:
					pass
			Game.idlist[type] = ids
	if allGood():
		Game.save = entityByID(Game.ENTITY.SAVE)
		saveCommand("Set_Tab", "Filter_Column", "Filter_Value", # These are ignored,
			"Set_Column", "Set_Value") # but there needs to be SOME header row
		Game.sceneNode.get_node("GameSelect").visible = false
		Game.playables = Game.listWhere(Game.ENTITY.CHAR, ["Playable"], ["1"])
		Game.inventory = Inventory.new(Game.playables, entityByID(Game.ENTITY.INV))
		Game.setEvents()
		Game.sceneNode.prepScene()
		Game.enableActions()

static func saveGameToFile(fname):
	Game.inventory.updateEntity()
	var fhead = Game.gamepath + Game.currgame + "/data/save.csv"
	var ihead = Game.gamepath + Game.currgame + "/data/save-inv.csv"
	var fdata = Game.savepath + Game.currgame + "/"
	Data.saveCSV(ihead, fdata, fname + "-inv.csv", Game.entityByID(Game.ENTITY.INV))
	Data.saveCSV(fhead, fdata, fname + ".csv", Game.save)

func getScreenSize():
	return Vector2(sceneNode.WIDTH, sceneNode.HEIGHT)

#static func getScripts(): # Special.  And this is very long...
#	return Game.entities[Game.ENTITY_NAME[Game.ENTITY.SCRIPT]].values()

func disableActions():
	Game.allowActions = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	#pass
func enableActions():
	Game.allowActions = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
func actionsAllowed():
	return Game.allowActions
	
func ready():
	return currgame != ""

# ===== Setup ===========================================================

var gamepath = "Games/"
var savepath = "Saves/"
var currgame = ""
var playables = {} # Playable characters, since there should be actions for each
var save # List of commands in this play-through

# ===== Errors / Debugging ==============================================

enum CAT { PATH = 0, SCRIPT, LOAD, ACTION, SAVE, FILE, DEBUG }
const category = { CAT.PATH: "Pathing", CAT.SCRIPT: "Script", CAT.LOAD: "Load",
	CAT.ACTION: "Action", CAT.SAVE: "Save", CAT.FILE: "File", CAT.DEBUG: "Debug" }

static func reportError(c, s):     Game.dbgr.reportError(c, s)
static func reportWarning(c, s):   Game.dbgr.reportWarning(c, s)
static func verboseMessage(c, s):  Game.dbgr.verboseMessage(c, s)
static func debugMessage(c, s):    Game.dbgr.debugMessage(c, s)
static func allGood():     return  Game.dbgr.allGood()
static func getFF():       return  Game.dbgr.getFF()

# ===== Objects =========================================================

static func loadDict(folder, tab):
	var dict = Data.fillProps(folder, tab)
	return dict

# Adds records or columns from d2 into d1
# Shallow version assumes (as would be the case for savegames) that d2 contains all of d1
# with some possible extras.  Deep version is O(n^2) (ie, slow for nontrivial dicts) but
# will completely merge two totally different dicts
static func mergeDicts(d1, d2, deep=false):
	var merged = {}
	var count = 0
	var checkID = ""
	var countID_1 = 0
	var countID_2 = 0
	for r2 in range(0, len(d2)):
		var row2 = d2[r2]
		# Does d1 have any records with this ID?
		# Only check the first time we encounter the ID!
		if checkID != row2.ID:
			checkID = row2.ID
			countID_1 = 0
			countID_2 = 1 # this row
			var stPos = r2
			if deep: stPos = 0
			for r1 in range(stPos, len(d1)):
				var row1 = d1[r1]
				# Add any row from d1 with a matching ID
				if row1.ID == checkID:
					countID_1 += 1
					# But also handle new columns
					for c2 in row2:
						if !row1.has(c2):
							row1[c2] = row2[c2]
					merged[count] = row1
					count += 1
				elif !deep and countID_1 > 0: break # We found them all, quit
		else:
			countID_2 += 1
		# We ONLY add from d2 if that ID did not exist previously
		if countID_2 > countID_1:
			merged[count] = row2
			count += 1
	return merged

static func getImage(folder, file, ext):
	return Data.getImage(Game.gamepath + Game.currgame + "/" + folder, file, ext)

static func getTexture(folder, file="", ext=""):
	return Data.getTexture(Game.gamepath + Game.currgame + "/" + folder, file, ext)

static func getFont(folder, file, ext):
	return Data.getFont(Game.gamepath + Game.currgame + "/" + folder, file, ext)

static func getAudio(folder, file, ext):
	return Data.getAudio(Game.gamepath + Game.currgame + "/" + folder, file, ext)

static func setCursor(c):
	var cursor = getTexture(c.Cursor_Path, c.Cursor_Filename, c.Cursor_Extension)
	var hotspot = Vector2(c.Cursor_Point_X, c.Cursor_Point_Y) * cursor.size / 100.0
	Input.set_custom_mouse_cursor(cursor, 0, hotspot)

static func getImageFile(id):
	# Checks whether the object is in a group, and returns the appropriate image
	var obj = Game.entityWhere(Game.ENTITY.OBJ, ["ID"], [id], true, false)
	if len(obj) > 0:
		return obj.Inventory_Path + obj.Inventory_Filename + obj.Inventory_Extension
	else:
		var objg = Game.entityWhere(Game.ENTITY.OBJGROUP, ["ID"], [id])
		return objg.Inventory_Path + objg.Inventory_Filename + objg.Inventory_Extension

# This internal-only function does the filter and then returns ONE item, or
# a LIST of items.  Use the access functions above for better readability.
static func filter(e, prop, value, multi, asDict, err):
	var d = Data.filter(Game.entities[ENTITY_NAME[e]], prop, value, multi, asDict)
	if err and len(d) == 0:
		var s = ""
		var n = ENTITY_NAME[e]
		if n.right(len(n)-1) != "s": s = "s" # Just grammatical perfectionism... sorry
		Game.reportError(Game.CAT.LOAD, "No %s%s exist with property %s = %s" % [ENTITY_NAME[e], s, prop, value])
	return d

# Updates all matching rows; similar to filter, but allows it would be very
# confusing to try to combine these functions.  Nothing good could come of that
static func updateByID(e, fprop, fvalue, uprop, uvalue, err=true):
	update(Game.ENTITY_NAME[e], fprop, fvalue, uprop, uvalue, err)
static func update(e, fprop, fvalue, uprop, uvalue, err=true):
	saveCommandArr(e, fprop, fvalue, uprop, uvalue)
	# We can pass multiple variables with separators.  Let's do some validation:
	if len(fprop) != len(fvalue):
		reportError(Game.CAT.SCRIPT, "If more than one Set_Column, you must have a matching number of Set_Values (split by ~).")
	if len(uprop) != len(uvalue):
		reportError(Game.CAT.SCRIPT, "If more than one Filter_Column, you must have a matching number of Filter_values (split by ~).")
	if Game.allGood():
		var updatedRows = 0
		# Now check for matching rows
		for row in Game.entities[e].values():
			var matches = true
			var checkCurrent = false
			for i in range(0, len(uprop)):
				# We always update all records for Current, just only one of them will be 1
				if uprop[i] == "Current" and str(uvalue[i]) == "1":
					checkCurrent = true
			for i in range(0, len(fprop)):
				if row[fprop[i]] != fvalue[i]:
					matches = false
			# And update all update-columns
			if (matches or checkCurrent):
				if matches: updatedRows += 1
				for i in range(0, len(uprop)):
					if matches:
						row[uprop[i]] = uvalue[i]
					else:
						if uprop[i] == "Current":
							row[uprop[i]] = "0"
		if err and updatedRows == 0:
			var s = ""
			if e.right(len(e)-1) != "s": s = "s" # Just grammatical perfectionism... sorry
			Game.reportError(Game.CAT.SCRIPT, "No %s%s exist with property %s = %s" % [e, s, fprop, fvalue])

# Every time we perform an update, we save it to the list of commands in this savegame
static func saveCommandArr(e, fprop, fvalue, uprop, uvalue):
	#for f in range(0, len(fprop)):
		for u in range(0, len(uprop)):
			saveCommand(e, PoolStringArray(fprop).join(ScriptManager.SPLITTER),
				PoolStringArray(fvalue).join(ScriptManager.SPLITTER), uprop[u], uvalue[u])
			#saveCommand(e, fprop[f], fvalue[f], uprop[u], uvalue[u])
	#saveCommand(e, fprop, fvalue, uprop, uvalue)
static func saveCommand(e, fprop, fvalue, uprop, uvalue):
	var cmd = { "Set_Tab": e, "Set_Column": uprop, "Set_Value": uvalue,
		"Filter_Column": fprop, "Filter_Value": fvalue }
	Game.save[len(Game.save)] = (cmd)

# ===== Signals =========================================================

#var thread
static func wait(seconds):
	return Game.sceneNode.get_tree().create_timer(seconds)
#static func killTimers():
#	Game.sceneNode.get_tree()
#static func cont():
#	print("continuing")
#	#if (!Util.isnull(Game.thread)):
#	#	print("yes, really")
#	Game.thread.resume()

var dialogueMenu
var dialoguePortrait
var speaker
var speakerEmotion
func setEvents():
	dialogueMenu = Game.entityWhere(Game.ENTITY.MENU, ["Type"], ["dialogue"])
	dialoguePortrait = Game.entityWhere(Game.ENTITY.MENU, ["Type"], ["portrait"])
#	ui_dialogue = InputEventAction.new()
#	ui_dialogue.action = "ui_dialogue"
#	ui_dialogue.pressed = true
func beginSpeaking(c, e):
	speaker = c
	speakerEmotion = Game.entityWhere(Game.ENTITY.EMOTIONS, ["Character", "ID"], [c.ID, e])
	menu.openScreen(dialogueMenu)
	menu.openScreen(dialoguePortrait)
	#Input.parse_input_event(ui_dialogue)
func endSpeaking():
	#Input.parse_input_event(ui_dialogue)
	menu.clearMenu()
	

func sendSignal(s):
	emit_signal(s)
