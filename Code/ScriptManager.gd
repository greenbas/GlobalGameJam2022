extends Node
class_name ScriptManager

var script_commands = {} # For each id, full list of commands in the script
var rgxInventory
var rgxStrings
var eval

# Knowing the playables will help us deal with scripts using DEFAULT
func attachScripts():
	# General init since it's apparently not happening in _ready
	rgxInventory = RegEx.new()
	rgxInventory.compile("Inventory.\\w+")
	rgxStrings = RegEx.new()
	# https://stackoverflow.com/questions/38512896/java-regex-match-words-that-arent-numbers
	rgxStrings.compile("((?![-+]?[0-9]*\\.?[0-9])\\w+\\b)")
	eval = Expression.new()
	var objgroups = Game.dictByID(Game.listOf(Game.ENTITY.OBJGROUP))
	# Actually attaching scripts
	for script in Game.dictByID(Game.entityByID(Game.ENTITY.SCRIPT)).values():
		# I know that this will already be unique in the end, but I'm not sure that without the
		# check it will only call commandsForID once per ID, & that could really kill load time.
		if !script_commands.has(script.ID):
			if objgroups.has(script.Target_ObjGroup):
				for o in Game.listWhere(Game.ENTITY.OBJ, ["Group"], [script.Target_ObjGroup]):
					var repl = "-" + script.Target_ObjGroup
					var with = "-" + o.ID
					addCommandsForID(script.ID.replace(repl, with), script.ID)
			else:
				addCommandsForID(script.ID, script.ID)

func hasScript(cmd):
	return script_commands.has(cmd)

# Takes an ID and returns an array containing all script records matching the ID
# In order not to be doing this constantly, the result will be saved.
func addCommandsForID(forID : String, whereID : String):
	var list = Game.listWhere(Game.ENTITY.SCRIPT, ["ID", "Deactivate"], [whereID, "0"], false)
	for cmd in list:
		if cmd.Character_ID == "DEFAULT":
			for p in Game.playables:
				var repl = "DEFAULT"
				var with = p.ID
				var newCmd = cmd.duplicate()
				newCmd.ID = forID.replace(repl + "-", with + "-")
				newCmd.Character_ID = newCmd.Character_ID.replace(repl, with)
				newCmd.Dialogue_Speaker = newCmd.Dialogue_Speaker.replace(repl, with)
				Game.verboseMessage("Script", "Adding " + newCmd.ID)
				cmdAppend(newCmd.ID, newCmd)
		else:
			cmdAppend(forID, cmd)

func cmdAppend(forID : String, cmd):
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

signal diag_timer

const SPLITTER = "~,~" # Do each comparison and update each value in one record
const MULTI = "~&~"    # Updating multiple records at once
# If you wanted to update a character only if they were in a certain scene,
# Filter_Column = "ID~,~Scene_ID" Filter_Value = "lindsay~,~campfire"
# Now if you wanted to do that for lindsay AND johnny:
# Filter_Column = "ID~,~Scene_ID" Filter_Value = "lindsay~,~campfire~&~johnny~,~campfire"

# Takes an array of commands and moves through them, executing
func run(commands):
	Game.disableActions()
	for cmd in commands:
		var todo = true;
		if (!Util.isnull(cmd.If_Expression)):
			var expr = cmd.If_Expression
			todo = parseExpr(expr, adjustExpr(expr)) # May throw errors
		if Game.allGood() and todo:
			if (!Util.isnull(cmd.Call_Script)):
				Game.debugMessage("Script", "Running " + cmd.Call_Script)
				var funcName = cmd.Call_Script
				#if (!script_functions.has(funcName)):
				#	script_functions[funcName] = commandsForID(funcName)
				#run(script_functions[funcName])
				run(script_commands[funcName])
			elif (!Util.isnull(cmd.Dialogue_Line)):
				Game.verboseMessage("Script", "Dialogue: " + cmd.Dialogue_Line)
				var speaker = cmd.Dialogue_Speaker
				if (!characters.has(speaker)):
					characters[speaker] = Game.entityWhere(Game.ENTITY.CHAR, ["ID"], [speaker], false)
				var label = Game.sceneNode.get_node("Dialogue/Text")
				var s = characters[speaker]
				label.text = cmd.Dialogue_Line
				var font = Game.getFont(s.Font_Path, s.Font_File, s.Font_Extension)
				font.size = int(s.Font_Size)
				label.set("custom_fonts/font", font)
				label.set("custom_colors/font_color", s.Colour)
				var seconds = float(cmd.Dialogue_Duration) / 100.0 # 2.0 * float
				#FIXME Just for testing
				if cmd.ID == "intro": seconds *= 0.1
				#Game.thread = 
				yield(Game.wait(seconds), "timeout")
				label.text = ""
				#yield(Game.wait(seconds), "diag_timer")
			elif (!Util.isnull(cmd.Set_Column)):
				var tab = cmd.Set_Tab.to_lower()
				var col = cmd.Set_Column.split(SPLITTER)
				var val = cmd.Set_Value.split(SPLITTER)
				for v in range(0, val.size()):
					if val[v] == "DEFAULT":
						val[v] = cmd.Character_ID#Game.sceneNode.currChar.data.ID
					if tab == Game.ENTITY_NAME[Game.ENTITY.VAR]: # Could depend on existing value(s)
						val[v] = str(parseExpr(v, adjustExpr(v)))
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
					Game.debugMessage("Script", "%s: Setting %s to %s where %s=%s" % [tab, col, val, fcol, fval])
					Game.update(tab, fcol, fval, col, val)
				
				# And actually update the view for the user
				if cmd.Refresh == "1":
					if tab == Game.ENTITY_NAME[Game.ENTITY.SCENE] or tab == Game.ENTITY_NAME[Game.ENTITY.CHAR] or tab == Game.ENTITY_NAME[Game.ENTITY.OBJECTS]:
						Game.sceneNode.refreshScene()
				#if tab == Game.ENTITY_NAME[Game.ENTITY.SCRIPT]:
				#	Game.sceneNode.attachScripts()
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
	# Everything left over must be a number or a string.
	# We need to be careful to compare numbers as numbers and strings as strings...
	# But once only, we don't want sticks==sticks to become ""sticks""==""sticks""
	var strings = {}
	for m in rgxStrings.search_all(expr):
		var item = m.get_string()
		strings[item] = item
	for s in strings:
		expr = expr.replace(s, "\"" + s + "\"")
	return expr

# Take the original expression so we can produce better error strings
func parseExpr(expr, adjusted):
	var result
	var error = eval.parse(adjusted, [])
	if error != OK:
		Game.reportError("Script", "Error parsing expression %s (%s): %s" % [expr, adjusted, eval.get_error_text()])
	else:
		result = eval.execute([], self, true)
		if eval.has_execute_failed():
			Game.reportError("Script", "Execution failed on expression %s (%s)" % [expr, adjusted])
	return result


#func triggerAction(posn):
#	print("Trigger action ", [posn, myType])
	#if myType == Game.ENTITY
	#var sprite = all_chars[currChar.ID]
	#walkmap.tryWalking(sprite, posn)
