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
		if e.Always_On == "1":
			openScreen(e)

#func _on_ui_dialogue():
#	openScreen(Game.entityWhere(Game.ENTITY.MENU, ["ID"], ["portrait"]))

# Main defined menus e.g. inventory and save games
func _input(event):
	checkInput(event)
func checkInput(event): # Why can't this be _input like the others?
	for e in Game.entityByID(Game.ENTITY.MENU).values():
		if event.is_action_pressed(e.Signal):
			match e.Type:
				"inventory":
					if invOpen:
						invOpen = false
						clearMenu()
					else:
						openScreen(e)
				_:
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
			typeBack = ScreenItem.TYPES.DIALOGUE_BACK
			typeMain = ScreenItem.TYPES.DIALOGUE_MAIN
		"portrait":
			typeBack = ScreenItem.TYPES.PORTRAIT_BACK
			typeMain = ScreenItem.TYPES.PORTRAIT_MAIN
		"inventory":
			typeBack = ScreenItem.TYPES.INV_BACK
			typeMain = ScreenItem.TYPES.INV_MAIN
			invOpen = true
	if typeMain > -1:
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
enum STATES { BASE = 0, ON_ACTIONS, CHAR_MOVING, CHOOSE_SECOND }
enum MENUS { WHEEL = 80, WHEEL_ITEM, SCREEN, SCREEN_ITEM } #, SCREEN_INV }
var state = STATES.BASE
var invOpen = false

var actingObj
var actingChar
var actingAction
var secondObj

func triggerClick(character, posn, obj):
	# TODO: I will want to check configuation for how the menus / interaction should
	# be set up, via action wheel or other menu.  But for now, it's this way.
	if Game.dbgr.mode == Game.dbgr.MODES.PLAY:
		if state == STATES.CHOOSE_SECOND:
			secondObj = obj
			doThing()
		elif state == STATES.BASE:
			actingObj = obj
			state = STATES.ON_ACTIONS
			if obj.data.Tab == Game.ENTITY.INV:
				obj = obj.data.Item
				obj.Tab = Game.ENTITY.INV
				drawActionWheel(character, posn, obj)
			else:
				drawActionWheel(character, posn, obj.data)
		elif state == STATES.ON_ACTIONS:
			clearMenu([MENUS.WHEEL, MENUS.WHEEL_ITEM])
			if scene.all_menus.has(obj.data.ID):
				actingChar = character
				actingAction = obj
				state = STATES.CHAR_MOVING
				if obj.data.Needs_Second == "1":
					state = STATES.CHOOSE_SECOND
				else:
					doThing()
			else:
				state = STATES.BASE
				triggerClick(character, posn, obj)

func doThing():
	var actingObjID
	if scene.all_menus.has(actingObj.data.ID):
		actingObjID = actingObj.data.Item.ID
	else:
		actingObjID = actingObj.data.ID
	var scriptID = actingChar.ID + "-" + actingAction.data.ID + "-" + actingObjID
	if secondObj:
		if scene.all_menus.has(secondObj.data.ID):
			secondObj = secondObj.data.Item
		scriptID += "-" + secondObj.data.ID
		secondObj = null
	Game.debugMessage(Game.CAT.SCRIPT, "Resuming " + scriptID)
	if scene.scriptManager.hasScript(scriptID):
		scene.scriptManager.run(scene.scriptManager.script_commands[scriptID], actingObj)
	actingObj = null
	actingAction = null
	actingChar = null
	Game.enableActions()
	state = STATES.BASE
	#foundObj.triggerAction(posn)
	#else: self.triggerAction(posn)

func clearMenu(clearTypes = []):
	for a in scene.all_menus.values():
		if clearTypes.has(a.menu) or len(clearTypes) == 0:
			if a.data.Always_On != "1":
				a.visible = false

func refreshMenu(refreshTypes = []):
	for e in Game.entityByID(Game.ENTITY.MENU).values():
		if refreshTypes.has(e.Type) or len(refreshTypes) == 0:
			openScreen(e)

func drawActionWheel(character, posn, obj):
	# Draw the action wheel
	scene.drawItems("*", [actionMenu.data], scene.all_menus, MENUS.WHEEL)
	actionMenu = scene.all_menus[actionMenu.data.ID]
	actionMenu.updateMe(posn, character)
	var onType = "On_" + Game.getTabName(obj.Tab)
	var myList = Game.listWhere(Game.ENTITY.ACTION, ["Character", onType], [character.ID, "1"], true, false)
	var defaultList = Game.listWhere(Game.ENTITY.ACTION, ["Character", onType], ["DEFAULT", "1"], true, false)
	actionList = Data.filter(Game.mergeDicts(myList, defaultList, true), ["Allowed"], ["1"], true, true)
	if len(actionList) == 0:
		Game.reportError(Game.CAT.LOAD, "No allowed %s actions exist for %s" % [onType, character.ID])
	else:
		# Don't display actions which lack a connected script
		# TODO: Display, but with a red border?  Sometimes we just want nothing, e.g. "take window"
		var filteredList = []
		for a in actionList:
			if Game.sceneNode.scriptManager.hasScript(character.ID + "-" + a.ID + "-" + obj.ID):
				filteredList.push_back(a)
		actionList = filteredList
	scene.drawItems("*", actionList, scene.all_menus, MENUS.WHEEL_ITEM)
	for a in actionList:
		var aItem = scene.all_menus[a.ID]
		aItem.updateMe(actionMenu)

class MenuData:
	extends Sprite
	var data
	var canvas
	var menu
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
		menu = MENUS.WHEEL
		z_index += 150
	func updateMe(posn, c):
		data.Actionable = "1" # Click to cancel
		data.Always_On = "0" # TODO: From spreadsheet
		data.Type = "actionwheel"
		data.Walk_First = "0"
		data.Needs_Second = "0"
		data.Label = ""
		texture = Game.getTexture(c.Action_Wheel_Path, c.Action_Wheel_Filename, c.Action_Wheel_Extension)
		# Position is mouse click, unless mouse click is too close to an edge
		position = posn
		var closeTL = texture.get_size() / 2
		var closeBR = Vector2(Game.sceneNode.WIDTH, Game.sceneNode.HEIGHT) - closeTL
		if position.x < closeTL.x: position.x = closeTL.x
		elif position.x > closeBR.x: position.x = closeBR.x
		if position.y < closeTL.y: position.y = closeTL.y
		elif position.y > closeBR.y: position.y = closeBR.y
class ActionItem:
	extends MenuData
	func _init(d).(d.ID, d):
		z_index += 151
		menu = MENUS.WHEEL_ITEM
	func updateMe(wheel):
		data.Actionable = "1"
		data.Always_On = "0" # TODO: From spreadsheet
		data.Type = "actionwheel"
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
		menu = MENUS.SCREEN
		data.Actionable = "0"
		z_index += 100
		# Dialogue goes over inventory
		if data.Type == "dialogue": z_index += 20
		if data.Type == "portrait": z_index += 25
	func updateMe(scene):
		centered = false # We offset so that "position" is the position of the base
		texture = Game.getTexture(data.Menu_Path, data.Menu_Filename, data.Menu_Extension)
		offset = -texture.size * Vector2(float(data.Base_X), float(data.Base_Y)) / 100.0
		var xpos = scene.WIDTH * float(data.Screen_X) / 100.0
		var ypos = scene.HEIGHT * float(data.Screen_Y) / 100.0
		position = Vector2(xpos, ypos)
class ScreenItem:
	extends MenuData
	enum TYPES { INV_BACK = 0, INV_MAIN, SAVE_BACK, SAVE_MAIN, PORTRAIT_BACK, PORTRAIT_MAIN,
		DIALOGUE_BACK, DIALOGUE_MAIN }
	var type
	func _init(t, id, d).(id, d):
		menu = MENUS.SCREEN_ITEM
		type = t
		z_index += 101
		# Dialogue goes over inventory
		if data.Type == "dialogue": z_index += 20
		if data.Type == "portrait": z_index += 25
		data.Actionable = "0" # Will be overwritten later for many types
	func updateMe(scene, slot_i, slot_j):
		var found = false
		var diag_text : Label = scene.get_node("Dialogue/Text")
		var start_x = scene.WIDTH * float(data.Slot_Start_X) / 100.0
		var start_y = scene.HEIGHT * float(data.Slot_Start_Y) / 100.0
		var size_x = float(data.Slot_Size_X) * scene.WIDTH / 100.0
		var size_y = float(data.Slot_Size_Y) * scene.HEIGHT / 100.0
		match type:
			TYPES.INV_BACK:
				found = true
				texture = Game.getTexture(data.Slot_Path, data.Slot_Filename_Inactive, data.Slot_Extension)
				var inv = Game.inventory.getInvByLoc(scene.currChar.ID)
				var loc = slot_j * int(data.Columns) + slot_i
				if inv.size() > loc:
					data.Actionable = "1"
					data.Item = Game.inventory.getInvData(inv[loc])
					data.Label = data.Item.Label
					data.Tab = Game.ENTITY.INV
			TYPES.INV_MAIN:
				var inv = Game.inventory.getInvByLoc(scene.currChar.ID)
				var loc = slot_j * int(data.Columns) + slot_i
				if inv.size() > loc:
					found = true
					texture = Game.getTexture(Game.getImageFile(inv[loc]))
				else:
					texture = null
			TYPES.DIALOGUE_MAIN:
				found = true
				var emo = Game.speakerEmotion
				var left = float(emo.Shift_Dialogue_X) * scene.WIDTH / 100.0
				var top = float(emo.Shift_Dialogue_Y) / 100.0
				diag_text.set_size(Vector2(size_x - left, size_y - top))
				diag_text.set_position(Vector2(start_x + left, start_y + top))
				texture = Game.getTexture(data.Slot_Path, data.Slot_Filename_Inactive, data.Slot_Extension)
			TYPES.PORTRAIT_MAIN:
				found = true
				var emo = Game.speakerEmotion
				texture = Game.getTexture(emo.Image_Path, emo.Image_Filename, emo.Image_Extension)
		if found:
			position = Vector2(start_x + size_x * slot_i, start_y + size_y * slot_j)
		
		# Portrait (or other) label
		var d = scene.get_node("Dialogue")
		while d.get_child_count() > 2:
			d.remove_child(d.get_child(2))
		if data.Show_Labels == "1":
			#print("true")
			# Clone the dialogue text, it will be the correct font etc
			var label_text : Label = diag_text.duplicate()
			label_text.visible = true
			#var lbl_x = start_x + float(data.Label_Offset_X) * 100.0 / float(data.Slot_Size_X)
			#var lbl_y = start_y + float(data.Label_Offset_Y) * 100.0 / float(data.Slot_Size_Y)
			#var lbl_offset = -label_text.get_size() * Vector2(float(data.Label_Base_X), float(data.Label_Base_Y)) / 100.0
			#label_text.set_position(Vector2(lbl_x, lbl_y) + lbl_offset)
			#label_text.set_position(Vector2(100, 100))
			label_text.text = "aaa"
			d.add_child(label_text)
			d.emit_signal("draw")
