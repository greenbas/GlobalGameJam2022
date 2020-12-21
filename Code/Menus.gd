extends Control
class_name Menu
# TODO
# https://www.reddit.com/r/godot/comments/8i88sh/changing_the_inputmap_via_code/dyqlemj/

var scene
var actionMenu : ActionMenu
var actionList
var screensList = {}
var screenItems = {}
#var screenMenu : ScreenMenu
#var screenItem

func loadData(s):
	scene = s
	actionMenu = ActionMenu.new()
	for e in Game.entityByID(Game.ENTITY.MENU).values():
		if !screensList.has(e.ID):
			var menu = ScreenMenu.new(e)
			screensList[e.ID] = menu
			menu.updateMe(scene)
	#self.connect("ui_dialogue", self, "accept_event")

#func _on_ui_dialogue():
#	openScreen(Game.entityWhere(Game.ENTITY.MENU, ["ID"], ["portrait"]))

# Main defined menus e.g. inventory and save games
func _input(event):
	checkInput(event)
func checkInput(event): # Why can't this be _input like the others?
	for e in Game.entityByID(Game.ENTITY.MENU).values():
		if event.is_action_pressed(e.Signal):
			if state == STATES.MENU_SCREEN:
				state = STATES.BASE
				clearMenu(scene)
			else:
				openScreen(e)
	if event.is_action_pressed("ui_quicksave"):
		Game.saveGameToFile("quick")
	elif event.is_action_pressed("ui_quickload"):
		Game.loadGameFromSave("quick")

func openScreen(e):
	var typeBack = -1
	var typeMain = -1
	match e.Type:
		"dialogue":
			typeBack = ScreenItem.TYPES.PORTRAIT_BACK
			typeMain = ScreenItem.TYPES.PORTRAIT_MAIN
		"inventory":
			typeBack = ScreenItem.TYPES.INV_BACK
			typeMain = ScreenItem.TYPES.INV_MAIN
	if typeMain > -1:
		state = STATES.MENU_SCREEN
		scene.drawItems("*", [screensList[e.ID].data], scene.all_menus, MENUS.SCREEN)
		var sItem = scene.all_menus[e.ID]
		sItem.updateMe(scene)
		var backArray = []
		var slotArray = []
		for j in range(0, e.Rows):
			for i in range(0, e.Columns):
				var pad_id = Util.padNum(i, '0', 2) + "_" + Util.padNum(j, '0', 2)
				# Each item has a backing (e.g. "inventory_slot.png")
				var back_id = e.ID + "_back_" + pad_id
				if !screenItems.has(back_id):
					screenItems[back_id] = ScreenItem.new(typeBack, back_id, e.duplicate())
				backArray.push_back(screenItems[back_id].data)
				screenItems[back_id].updateMe(scene, i, j)
				# And a foreground image (e.g. "stick.png")
				var slot_id = e.ID + "_slot_" + pad_id
				if !screenItems.has(slot_id):
					screenItems[slot_id] = ScreenItem.new(typeMain, slot_id, e.duplicate())
				slotArray.push_back(screenItems[slot_id].data)
				screenItems[slot_id].updateMe(scene, i, j)
		scene.drawItems("*", backArray, scene.all_menus, MENUS.SCREEN_ITEM)
		scene.drawItems("*", slotArray, scene.all_menus, MENUS.SCREEN_ITEM)

	#scene.drawItems("*", actionList, scene.all_menus, MENUS.WHEEL_ITEM)
	

# Handle clicks
enum STATES { BASE = 0, ON_ACTIONS, CHAR_MOVING, MENU_SCREEN }
enum MENUS { WHEEL = 80, WHEEL_ITEM, SCREEN, SCREEN_ITEM, SCREEN_INV }
var state = STATES.BASE

var actingObj
var actingChar
var actingAction

func triggerClick(character, posn, obj):
	# TODO: I will want to check configuation for how the menus / interaction should
	# be set up, via action wheel or other menu.  But for now, it's this way.
	match state:
		STATES.BASE:
			state = STATES.ON_ACTIONS
			actingObj = obj
			if obj.Tab == Game.ENTITY.ACTION:
				clearMenu(scene)
			else:
				# Draw the action wheel
				scene.drawItems("*", [actionMenu.data], scene.all_menus, MENUS.WHEEL)
				actionMenu = scene.all_menus[actionMenu.data.ID]
				actionMenu.updateMe(posn, character)
				var onType = "On_" + Game.ENTITY_NAME[obj.Tab].capitalize()
				actionList = Game.listWhere(Game.ENTITY.ACTION, ["Allowed", onType], ["1", "1"])
				scene.drawItems("*", actionList, scene.all_menus, MENUS.WHEEL_ITEM)
				for a in actionList:
					var aItem = scene.all_menus[a.ID]
					aItem.updateMe(actionMenu)
		STATES.ON_ACTIONS:
			clearMenu(scene)
			if scene.all_menus.has(obj.ID):
				state = STATES.CHAR_MOVING
				actingChar = character
				actingAction = obj
				if obj.Walk_First == "1":
					state = STATES.CHAR_MOVING
					Game.disableActions()
					scene.walkmap.tryWalking(scene.getCurrentSprite(), posn)
				else:
					triggerDestination()
			else:
				state = STATES.BASE
				triggerClick(character, posn, obj)

func triggerDestination():
	if state == STATES.CHAR_MOVING:
		var scriptID = actingChar.ID + "-" + actingAction.ID + "-" + actingObj.ID
		state = STATES.BASE
		Game.debugMessage(Game.CAT.SCRIPT, "Resuming " + scriptID)
		if scene.scriptManager.hasScript(scriptID):
			scene.scriptManager.run(scene.scriptManager.script_commands[scriptID], actingObj)
		actingObj = null
		actingAction = null
		actingChar = null
		Game.enableActions()
		#foundObj.triggerAction(posn)
		#else: self.triggerAction(posn)

func clearMenu(scene):
	state = STATES.BASE
	for a in scene.all_menus.values():
		a.visible = false

class MenuData:
	extends Sprite
	var data
	var canvas
	func _init(id, d):
		data = d
		data.ID = id
		data.Scene_ID = "*"
		canvas = Game.sceneNode.get_node("Menu")
		z_index = 2000
	func drawMe():
		pass
# The action wheel and its items are very different from menu items defined in menus.csv
class ActionMenu:
	extends MenuData
	func _init().("action_menu", {}):
		z_index += 100
	func updateMe(posn, c):
		data.Actionable = "1" # Click to cancel
		data.Walk_First = "0"
		data.Label = ""
		position = posn
		texture = Game.getTexture(c.Action_Wheel_Path, c.Action_Wheel_Filename, c.Action_Wheel_Extension)
class ActionItem:
	extends MenuData
	func _init(d).(d.ID, d):
		z_index += 101
	func updateMe(wheel):
		data.Actionable = "1"
		texture = Game.getTexture(data.Action_Path, data.Action_Filename, data.Action_Extension)
		# Display radially from the center of the ActionMenu
		var dist = (wheel.texture.get_width() / 2) * int(data.Distance_From_Center) / 100
		var angle = deg2rad(float(data.Radial_Position))
		var offset = dist * Vector2(cos(angle), -sin(angle))
		position = wheel.position + offset
# However, each of these can be treated more or less the same.
class ScreenMenu:
	extends MenuData
	func _init(d).(d.ID, d):
		data.Actionable = "0"
		z_index += 150
	func updateMe(scene):
		centered = false # We offset so that "position" is the position of the base
		texture = Game.getTexture(data.Menu_Path, data.Menu_Filename, data.Menu_Extension)
		offset = -texture.size * Vector2(float(data.Base_X), float(data.Base_Y)) / 100.0
		var xpos = scene.WIDTH * float(data.Screen_X) / 100.0
		var ypos = scene.HEIGHT * float(data.Screen_Y) / 100.0
		position = Vector2(xpos, ypos)
class ScreenItem:
	extends MenuData
	enum TYPES { INV_BACK = 0, INV_MAIN, SAVE_BACK, SAVE_MAIN, PORTRAIT_BACK, PORTRAIT_MAIN }
	var type
	func _init(t, id, d).(id, d):
		type = t
		data.Actionable = "0"
		z_index += 151
	func updateMe(scene, slot_i, slot_j):
		var found = false
		match type:
			TYPES.INV_BACK:
				found = true
				texture = Game.getTexture(data.Slot_Path, data.Slot_Filename_Inactive, data.Slot_Extension)
			TYPES.INV_MAIN:
				var inv = Game.inventory.getInvByLoc(scene.currChar.ID)
				var loc = slot_j * int(data.Columns) + slot_i
				if inv.size() > loc:
					found = true
					texture = Game.getTexture(Game.getImageFile(inv[loc]))
			TYPES.PORTRAIT_MAIN:
				found = true
				var emo = Game.speakerEmotion
				texture = Game.getTexture(emo.Image_Path, emo.Image_Filename, emo.Image_Extension)
				scene.get_node("Dialogue/Text").margin_left = texture.size.x - position.x/2
		if found:
			var start_x = scene.WIDTH * float(data.Slot_Start_X) / 100.0
			var start_y = scene.HEIGHT * float(data.Slot_Start_Y) / 100.0
			position = Vector2(start_x + texture.size.x * slot_i, start_y + texture.size.y * slot_j)
