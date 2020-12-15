extends Node
var sceneNode : Node
var menu : Menu
var inventory : Inventory
var allowActions = true
var debugger : Debugger

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

# ===== Game State ======================================================

# I could just define dicts directly, e.g. "var scenes = {}".
# But if I do it this way, then I can retrieve the entity name for error reporting
# and it may be useful for other reasons down the road.
# So, we have a dictionary of dictionaries.  Use the string as the index for easier debugging.
enum ENTITY { SCRIPT = 0, VAR, ACTION, CHAR, SCENE, OBJGROUP, OBJ, INV, EMOTIONS, ANIM, MENU }
const MENU = 99
const ENTITY_NAME = { ENTITY.SCRIPT: "script", ENTITY.VAR: "variables", ENTITY.ACTION: "actions",
	ENTITY.CHAR: "characters", ENTITY.SCENE: "scenes", ENTITY.OBJGROUP: "objgroups",
	ENTITY.OBJ: "objects", ENTITY.INV: "inventory", ENTITY.EMOTIONS: "emotions",
	ENTITY.ANIM: "animations", ENTITY.MENU: "menus" }
var entities = {}
var idlist = {}

static func loadGame(scene):
	Game.debugger = Debugger.new()
	Game.sceneNode = scene
	var folder = Game.gamepath + Game.currgame + "/exports/"
	for type in range(0, len(ENTITY)):
		var dict = Game.loadDict(folder, ENTITY_NAME[type])
		if allGood():
			Game.entities[ENTITY_NAME[type]] = dict
			var ids = {}
			for e in dict.values():
				e.Tab = type # We're going to want this later
				ids[e] = e.ID # As a rule of dicts, each ID will only be entered once
			Game.idlist[type] = ids
	if allGood():
		Game.playables = Game.listWhere(Game.ENTITY.CHAR, ["Playable"], ["1"])
		Game.inventory = Inventory.new(Game.playables, entityByID(Game.ENTITY.INV))
		Game.setEvents()

#static func getScripts(): # Special.  And this is very long...
#	return Game.entities[Game.ENTITY_NAME[Game.ENTITY.SCRIPT]].values()

#var thread
static func wait(seconds):
	return Game.sceneNode.get_tree().create_timer(seconds)
#static func cont():
#	print("continuing")
#	#if (!Util.isnull(Game.thread)):
#	#	print("yes, really")
#	Game.thread.resume()

func disableActions():
	#Game.allowActions = false
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass
func enableActions():
	Game.allowActions = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
func actionsAllowed():
	return Game.allowActions

# ===== Setup ===========================================================

var gamepath = "Games/"
var savepath = "Saves/"
var currgame = "Lake of Reflection"
var playables = {} # Playable characters, since there should be actions for each

func _ready():
	currgame = "Lake of Reflection"

# ===== Errors / Debugging ==============================================

static func reportError(c, s):     Game.debugger.reportError(c, s)
static func reportWarning(c, s):   Game.debugger.reportWarning(c, s)
static func verboseMessage(c, s):  Game.debugger.verboseMessage(c, s)
static func debugMessage(c, s):    Game.debugger.debugMessage(c, s)
static func allGood():     return  Game.debugger.allGood()

# ===== Objects =========================================================

static func loadDict(folder, tab):
	var dict = Data.fillProps(folder, tab)
	return dict

static func getImage(folder, file, ext):
	return Data.getImage(Game.gamepath + Game.currgame + "/" + folder, file, ext)

static func getTexture(folder, file="", ext=""):
	return Data.getTexture(Game.gamepath + Game.currgame + "/" + folder, file, ext)

static func getFont(folder, file, ext):
	return Data.getFont(Game.gamepath + Game.currgame + "/" + folder, file, ext)

static func setCursor(folder, file, ext):
	var cursor = getTexture(folder, file, ext)
	Input.set_custom_mouse_cursor(cursor)

static func getImageFile(id):
	# Checks whether the object is in a group, and returns the appropriate image
	var obj = Game.entityWhere(Game.ENTITY.OBJ, ["ID"], [id], true, false)
	if len(obj) > 0:
		return obj.Inventory_Path + obj.Inventory_Filename + obj.Inventory_Extension
	else:
		var objg = Game.entityWhere(Game.ENTITY.OBJGROUP, ["ID"], [id])
		return objg.Inventory_Path + objg.Inventory_Filename + objg.Inventory_Extension

# This internal-only function does the filter and then returns ONE item, or
# a LIST of items.  Use the access functions below for better readability.
static func filter(e, prop, value, multi, dict, err):
	var res = {} # Only one of these two will be returned
	var arr = [] # Unless multi is false, in which case neither will be
	for row in Game.entities[ENTITY_NAME[e]].values():
		var matches = true
		for i in range(0, len(prop)):
			if Util.isnull(row[prop[i]]) and Util.isnull(value[i]):
				pass # Two nulls are equal
			elif row[prop[i]] != value[i]:
				matches = false
		if (matches):
			if (!multi): return row
			res[row.ID] = row
			arr.append(row)
	if err and Util.isnull(res):
		var s = ""
		var n = ENTITY_NAME[e]
		if n.right(len(n)-1) != "s": s = "s" # Just grammatical perfectionism... sorry
		Game.reportError("Data", "No %s%s exist with property %s = %s" % [ENTITY_NAME[e], s, prop, value])
	if (dict): return res.values()
	else: return arr

# Updates all matching rows; similar to filter, but allows it would be very
# confusing to try to combine these functions.  Nothing good could come of that
static func updateByID(e, fprop, fvalue, uprop, uvalue, err=true):
	update(Game.ENTITY_NAME[e], fprop, fvalue, uprop, uvalue, err)
static func update(e, fprop, fvalue, uprop, uvalue, err=true):
	# We can pass multiple variables with separators.  Let's do some validation:
	if len(fprop) != len(fvalue):
		reportError("Script", "If more than one Set_Column, you must have a matching number of Set_Values (split by ~).")
	if len(uprop) != len(uvalue):
		reportError("Script", "If more than one Filter_Column, you must have a matching number of Filter_values (split by ~).")
	if Game.allGood():
		var updatedRows = 0
		# Now check for matching rows
		for row in Game.entities[e].values():
			var matches = true
			var checkCurrent = false
			for i in range(0, len(fprop)):
				# We always update all records for Current, just only one of them will be 1
				if uprop[i] == "Current" and uvalue[i] == "1":
					checkCurrent = true
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
			Game.reportError("Script", "No %s%s exist with property %s = %s" % [e, s, fprop, fvalue])

# ===== Signals =========================================================

#var ui_dialogue : InputEventAction
var dialogueMenu
var speaker
var speakerEmotion
func setEvents():
	dialogueMenu = Game.entityWhere(Game.ENTITY.MENU, ["Type"], ["dialogue"])
#	ui_dialogue = InputEventAction.new()
#	ui_dialogue.action = "ui_dialogue"
#	ui_dialogue.pressed = true
func beginSpeaking(c, e):
	speaker = c
	speakerEmotion = Game.entityWhere(Game.ENTITY.EMOTIONS, ["Character", "ID"], [c.ID, e])
	menu.openScreen(dialogueMenu)
	#Input.parse_input_event(ui_dialogue)
func endSpeaking():
	#Input.parse_input_event(ui_dialogue)
	menu.clearMenu(sceneNode)
	

func sendSignal(s):
	emit_signal(s)
