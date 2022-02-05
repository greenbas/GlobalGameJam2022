extends Node
class_name ScriptManager

var script_commands = {} # For each id, full list of commands in the script
var rgxInventory
var rgxStrings
var eval

func _init():
	Game.sceneNode.connect("char_destination", self, "charAtDestination")
	mode = MODES.READY
	rgxInventory = RegEx.new()
	rgxInventory.compile("Inventory.\\w+")
	rgxStrings = RegEx.new()
	# https://stackoverflow.com/questions/38512896/java-regex-match-words-that-arent-numbers
	rgxStrings.compile("((?![-+]?[0-9]*\\.?[0-9])\\w+\\b)")
	eval = Expression.new()
	var actionable = Game.listWhere(Game.ENTITY.OBJ, ["Actionable"], ["1"])
	for a in actionable:
		obj_list[a.ID] = a.ID

func attachScripts():
	var objgroups = Game.dictByID(Game.listOf(Game.ENTITY.OBJGROUP))
	# Actually attaching scripts
	for script in Game.dictByID(Game.entityByID(Game.ENTITY.SCRIPT)).values():
		if objgroups.has(script.Target_ObjGroup):
			# If the script is set to an object ID, create a script for each Unique ID
			for o in Game.listWhere(Game.ENTITY.OBJ, ["Group"], [script.Target_ObjGroup]):
				var repl = "-" + script.Target_ObjGroup
				var with = "-" + o.ID
				addCommandsForID(script.ID.replace(repl, with), script.ID)
		#else: # Including objgroups in this, as you can also use from inventory
		addCommandsForID(script.ID, script.ID)

func transferScripts():
	# When we unload a scene on loading a game, we need to create a new
	# script manager object.  But we don't need to redo all the work
	# involved in attaching the scripts.
	return script_commands

func hasScript(cmd):
	if script_commands.has(cmd): return true
	# For actions requiring a second target, "hasScript" should return true when
	# asked if, e.g. "johnny-use-sheet" exists because no second target will have
	# been selected yet when we are asked this.
	var dash = cmd.find("-") + 1
	#var mid = cmd.substr(dash, cmd.find_last("-") - dash)
	var mid = cmd.substr(dash, cmd.find("-", dash) - dash)
	var action = Game.entityWhere(Game.ENTITY.ACTION, ["ID"], [mid], true, false)
	if action:
		if action.Needs_Second == "1":
			for c in script_commands:
				if c.match(cmd + "-*"): return true
	return false

# Takes an ID and returns an array containing all script records matching the ID
# In order not to be doing this constantly, the result will be saved.
func addCommandsForID(forID : String, whereID : String):
	var list = Game.listWhere(Game.ENTITY.SCRIPT, ["ID", "Deactivate"], [whereID, "0"], false, false)
	for cmd in list:
		if cmd.Character_ID == "DEFAULT":
			for p in Game.playables:
				var repl = "DEFAULT"
				var with = p.ID
				var newCmd = cmd.duplicate()
				newCmd.ID = forID.replace(repl + "-", with + "-")
				newCmd.Character_ID = newCmd.Character_ID.replace(repl, with)
				newCmd.Dialogue_Speaker = newCmd.Dialogue_Speaker.replace(repl, with)
				Game.verboseMessage(Game.CAT.SCRIPT, "Adding " + newCmd.ID)
				cmdAppend(newCmd.ID, newCmd)
		else:
			cmdAppend(forID, cmd)

# For handling the OTHER keyword, we need to track handled objects for each prefix
# "OTHER" can only show up as the last word in any given command, e.g. johnny-look-OTHER
# We track everything we've handled for the rest of the phrase, "johnny-look"
var obj_list = {} # All actionable objects in the game
var unhandled_obj_for_prefix = {} # Key is everything before the last dash

func cmdAppend(forID : String, cmd):
	# Check for unhandled objects in case OTHER suffix is used (see variable comments for more info)
	var last_dash = cmd.ID.find_last("-")
	var suffix = cmd.ID.substr(last_dash + 1)
	var prefix = cmd.ID.trim_suffix("-" + suffix)
	var unhandled
	if unhandled_obj_for_prefix.has(prefix):
		unhandled = unhandled_obj_for_prefix[prefix]
	else:
		unhandled = obj_list.duplicate()
	unhandled.erase(suffix)
	unhandled_obj_for_prefix[prefix] = unhandled
	if suffix == "OTHER":
		# We assume this will only occur last of scripts for using this item
		for o in unhandled:
			var newCmd = cmd.duplicate()
			var repl = "OTHER"
			var with = o
			newCmd.ID = forID.replace("-" + repl, "-" + with)
			print(newCmd.ID)
			cmdAppend(newCmd.ID, newCmd)
	if !script_commands.has(forID):
		script_commands[forID] = []
	script_commands[forID].append(cmd)

#func checkForMissing(typeID, playables, entityID):
#	for a in Game.listOf(Game.ENTITY.ACTION).values():
#		# This gets a little tricky because in addition to the usual DEFAULT line, we can define
#		# a default for a particular action; e.g. if Sarah can use "pull" but nobody else can,
#		# then you'll see a pull/DEFAULT record and a pull/Sarah record.
#		var default = Game.entityWhere(Game.ENTITY.ACTION, ["ID", "Character"], [a.ID, "DEFAULT"])
#		for p in playables:
#			var thisChar = Game.entityWhere(Game.ENTITY.ACTION, ["ID", "Character"], [a.ID, p.ID], true, false)
#			var action = Util.nvl(thisChar, default)
#			match typeID:
#				Game.ENTITY.SCENE:
#					if (action.Allowed == "1" and action.On_Objects == "1"):
#						if (action.Script_Required == "1"):
#							var required = p.ID + "-" + a.ID + "-" + entityID
#							if !(script_ids[entityID].has(required) or script_ids[entityID].has("DEFAULT-" + a.ID + "-" + entityID)):
#								Game.reportWarning("No script has been defined for interaction " + required)

# Some commands are just calls to named scripts (e.g. "lindsay-look-johnny" may call
# "long_winded_speech" which is a sequence of commands not triggered directly by any actions,
# but can be called by any triggered action.  These will not be stored in any interactables,
# so the ScriptManager will handle them directly.  Track them as they come up: if we've
# encountered them before, run them; if not, save before running.
var script_functions = {}
var characters = {} # Track these the same way

#signal diag_timer

const SPLITTER = "~,~" # Do each comparison and update each value in one record
const MULTI = "~&~"    # Updating multiple records at once
# If you wanted to update a character only if they were in a certain scene,
# Filter_Column = "ID~,~Scene_ID" Filter_Value = "lindsay~,~campfire"
# Now if you wanted to do that for lindsay AND johnny:
# Filter_Column = "ID~,~Scene_ID" Filter_Value = "lindsay~,~campfire~&~johnny~,~campfire"

enum MODES { READY = 0, RUNNING, STOPPING }
var mode

#signal ui_dialogue()
# Takes an array of commands and moves through them, executing
func run(commands, actingObj=null):
	mode = MODES.RUNNING
	Game.disableActions()
	# I've discovered that I have to do this in two steps: evaluate conditions
	# for all commands, THEN run the ones that were true.  Otherwise changing
	# values can cause unexpected behaviours.
	var runcommands = []
	var todoElse = true
	for cmd in commands:
		var todo = true
		if (!Util.isnull(cmd.If_Expression)):
			var expr = cmd.If_Expression
			if expr == "ELSE":
				todo = todoElse
			else:
				todo = parseExpr(adjustExpr(expr)) # May throw errors
				todoElse = todoElse and !todo # Becomes false the moment we do something else
		if todo: runcommands.push_back(cmd)
	for cmd in runcommands:
		# We want to be able to stop this function mid-cutscene
		if !Game.allGood() or mode == MODES.STOPPING:
			break
		else:
			# Calc stuff!
			var refresh = false
			var targetType
			if (!Util.isnull(cmd.Call_Script)):
				Game.debugMessage(Game.CAT.SCRIPT, "Running " + cmd.Call_Script)
				var funcName = cmd.Call_Script
				run(script_commands[funcName])
				if mode != MODES.STOPPING:
					mode = MODES.RUNNING # because it gets set to READY after completing
			if cmd.Remove_Target == "1" or cmd.Add_To_Inventory == "1":
				# We need to identify the object being acted on
				if !Util.isnull(cmd.Target_Object):
					targetType = Game.ENTITY.OBJ
				elif !Util.isnull(cmd.Target_ObjGroup):
					targetType = Game.ENTITY.OBJ # It's the object that got clicked & will get removed
				elif !Util.isnull(cmd.Target_Character):
					targetType = Game.ENTITY.CHAR
			
			# Do stuff!
			if cmd.Walk_First == "1" and actingObj.data.Tab != Game.ENTITY.INV:
				var charID = Game.sceneNode.currChar.ID
				var sprite = Game.sceneNode.all_chars[charID]
				var dest =  ScreenObject.getWalkPoint(actingObj)
				Game.debugMessage(Game.CAT.SCRIPT, "Attempting to move %s to (%f.1, %f.1)" % [charID, dest.x, dest.y])
				Game.sceneNode.walkmap.tryWalking(sprite, dest, true)
				yield(self, "char_destination")
			if (!Util.isnull(cmd.Audio_Filename)):
				Game.sceneNode.playSound(cmd)
			if (!Util.isnull(cmd.Dialogue_Line)):
				Game.verboseMessage(Game.CAT.SCRIPT, "Dialogue: " + cmd.Dialogue_Line)
				var speaker = cmd.Dialogue_Speaker
				if speaker == "DEFAULT": speaker = cmd.Character_ID
				if (!characters.has(speaker)):
					characters[speaker] = Game.entityWhere(Game.ENTITY.CHAR, ["ID"], [speaker], false)
				var sp_label = Game.sceneNode.get_node("Dialogue/SpeakerLabel")
				var sp_text = Game.sceneNode.get_node("Dialogue/SpeakerText")
				var s = characters[speaker]
				Game.beginSpeaking(s, cmd.Dialogue_Emotion)
				sp_text.text = cmd.Dialogue_Line
				Game.sceneNode.setLabelFont(sp_text, s)
				if s.Label_Portrait == "1":
					var emo = Game.speakerEmotion
					if emo.Label == "DEFAULT":
						sp_label.text = s.Label
					else:
						sp_label.text = emo.Label
					Game.sceneNode.setLabelFont(sp_label, emo)
				var seconds = 2.5 * float(cmd.Dialogue_Duration) / 100.0 / Game.getFF()
				# Wait on a loop; the loop may be ended early from elsewhere
				# DO NOT PUT THIS INSIDE A FUNCTION
				dialOpen = true
				var waited = 0.0
				while dialOpen and waited < seconds: # dialOpen may be set to false outside this function
					yield(Game.wait(incr_size), "timeout")
					waited += incr_size
				dialOpen = false
				# Done wait loop
				sp_text.text = ""
				sp_label.text = ""
				Game.endSpeaking()
				#yield(Game.wait(seconds), "diag_timer")
			if (!Util.isnull(cmd.Set_Column)):
				var tab = cmd.Set_Tab.to_lower()
				var col = cmd.Set_Column.split(SPLITTER)
				var val = cmd.Set_Value.split(SPLITTER)
				for v in range(0, val.size()):
					if val[v] == "DEFAULT":
						val[v] = cmd.Character_ID
					else:
						val[v] = adjustExpr(val[v])
					if tab == Game.ENTITY_NAME[Game.ENTITY.VAR]: # Could depend on existing value(s)
						val[v] = str(parseExpr(val[v]))
				# Filter value is special in that it can contain the MULTI splitter too (see above)
				var fcol_all = cmd.Filter_Column.split(MULTI)
				var fval_all = cmd.Filter_Value.split(MULTI)
				if len(fcol_all) == 1 and len(fcol_all) < len(fval_all):
					while len(fcol_all) < len(fval_all):
						fcol_all.append(fcol_all[0])
				for i in range(0, len(fcol_all)):
					var fcol = fcol_all[i].split(SPLITTER)
					var fval = fval_all[i].split(SPLITTER)
					for v in range(0, fval.size()):
						if fval[v] == "DEFAULT":
							fval[v] = cmd.Character_ID
						if cmd.Animate_Move == "1":
							# We expect a Screen_X and Screen_Y, we will not update these the normal way
							if col[0] == "Screen_X" and col[1] == "Screen_Y":
								var x = float(Game.sceneNode.WIDTH) * float(val[0]) / 100.0
								var y = float(Game.sceneNode.HEIGHT) * float(val[1]) / 100.0
								Game.debugMessage(Game.CAT.SCRIPT, "Attempting to move %s to (%s, %s)" % [fval[v], x, y])
								col.remove(0) # first two of each
								col.remove(0)
								val.remove(0)
								val.remove(0)
								var sprite = Game.sceneNode.all_chars[fval[v]]
								Game.sceneNode.walkmap.tryWalking(sprite, Vector2(x, y))
								#while sprite.goal_path.size() > 0:
								#	yield(get_tree().create_timer(.25), "timeout")
								yield(self, "char_destination")
							else:
								Game.reportError(Game.CAT.SCRIPT, "Animate_Move requires Screen_X and Screen_Y as the first two values in Set_Column.")
					Game.debugMessage(Game.CAT.SCRIPT, "%s: Setting %s to %s where %s=%s" % [tab, col, val, fcol, fval])
					Game.update(tab, fcol, fval, col, val)
				# Refresh if necessary
				if cmd.Refresh == "1":
					if tab == Game.ENTITY_NAME[Game.ENTITY.SCENE]:
						refresh = true
						#Game.sceneNode.dirtyScene()
					elif tab == Game.ENTITY_NAME[Game.ENTITY.CHAR]:
						refresh = true
						#Game.sceneNode.dirtyChars()
					elif tab == Game.ENTITY_NAME[Game.ENTITY.OBJ]:
						refresh = true
						#Game.sceneNode.dirtyObjs()
					#if tab == Game.ENTITY_NAME[Game.ENTITY.ACTION]:
					#	Game.sceneNode.all_menus = {}
				
			# And some other housekeeping
			if !Util.isnull(cmd.Wait_Seconds):
				if cmd.Wait_Seconds != "0":
					if cmd.Wait_Seconds.left(1) == "D":
						var waitingForDest = int(cmd.Wait_Seconds) # int() discards the D
						while waitingForDest > 0:
							yield(self, "char_destination")
							waitingForDest -= 1
					else:
						yield(Game.wait(float(cmd.Wait_Seconds) / Game.dbgr.getFF()), "timeout")
			# We are acting on the target of this action (determined above)
			if cmd.Remove_Target == "1" and actingObj:
				Game.debugMessage(Game.CAT.SCRIPT, "Taking " + Game.ENTITY_NAME[targetType].rstrip("s") + " " + actingObj.data.ID)
				Game.updateByID(targetType, ["ID"], [actingObj.data.ID], ["Visible"], ["0"])
				refresh = true
			if !Util.isnull(cmd.Add_To_Inventory):
				Game.debugMessage(Game.CAT.SCRIPT, "Adding to inventory")
				for addItem in cmd.Add_To_Inventory.split("~,~"):
					Game.inventory.addItem(cmd.Character_ID, addItem)
				#FIXME: Game.menu.refreshMenu(["inventory"]) # but only if open
			if !Util.isnull(cmd.Del_From_Inventory):
				Game.debugMessage(Game.CAT.SCRIPT, "Removing from inventory")
				for delItem in cmd.Del_From_Inventory.split("~,~"):
					Game.inventory.removeItem(cmd.Dialogue_Speaker, delItem) # FIXME shouldn't be speaker...
				#FIXME: Game.menu.refreshMenu(["inventory"]) # but only if open
			if refresh: Game.sceneNode.refreshScene()
	mode = MODES.READY
	Game.enableActions()

func adjustExpr(e):
	var expr = str(e)
	# Handle inventory checks
	var c = Game.sceneNode.currChar.ID
	for m in rgxInventory.search_all(expr):
		var item = m.get_string()
		expr = expr.replace(item, Game.inventory.numItem(c, item.replace("Inventory.", "")))
	# Handle variables
	for v in Game.entityByID(Game.ENTITY.VAR).values():
		expr = expr.replace(v.ID, v.Value)
	Game.verboseMessage(Game.CAT.SCRIPT, "Adjusted expression %s to %s" % [e, expr])
	return expr

# Take the original expression so we can produce better error strings
func parseExpr(e):
	var expr = e
	# If it didn't already get adjusted, then it must be a number or a string.
	# We need to be careful to compare numbers as numbers and strings as strings...
	# But once only, we don't want sticks==sticks to become ""sticks""==""sticks""
	var strings = []
	for m in rgxStrings.search_all(str(expr)):
		var item = m.get_string()
		strings.push_back(item)
	var offset = 0
	for s in strings:
		expr = rgxStrings.sub(str(expr), "\"" + s + "\"", false, offset)
		offset += len(s) + 2
		
	var result
	var error = eval.parse(expr, [])
	if error != OK:
		Game.reportError(Game.CAT.SCRIPT, "Error parsing expression %s: %s" % [expr, eval.get_error_text()])
	else:
		result = eval.execute([], self, true)
		if eval.has_execute_failed():
			Game.reportError(Game.CAT.SCRIPT, "Execution failed on expression %s" % [expr])
		else:
			Game.debugMessage(Game.CAT.SCRIPT, "Expression parsed as %s" % [result])
	return result

# It seems that in order to yield on a signal, we need to refine it in scope
signal char_destination
func charAtDestination():
	emit_signal("char_destination")

var dialOpen = false
var incr_size = 0.1 # time in seconds between checking for dialOpen to be false
func inDialogue():
	return dialOpen
func endDialogue():
	dialOpen = false
