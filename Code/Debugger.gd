extends Control
class_name Debugger

enum MODES { PLAY = 0, DEBUG }
var mode = MODES.PLAY

func _init():
	verbosity = LEVELS.MESSAGE

func _input(event):
	if event.is_action_pressed("ui_debug_mode"):
		toggleDebug()

func toggleDebug():
	mode += 1
	mode = mode % MODES.size()
	
	match mode:
		MODES.PLAY:
			debugSettings(false, LEVELS.WARNING)
		MODES.DEBUG:
			debugSettings(true, LEVELS.VERBOSE)

func debugSettings(debugMovement : bool, v):
	verbosity = v
	var alpha =  int(debugMovement) * 0.5
	Game.sceneNode.walkmap.modulate = Color(1,1,1, alpha)
	pass


# ===== Errors / Log ====================================================

var error = null
var debugLog = []
var verbosity
enum LEVELS { UNRECOVERABLE, ERROR, WARNING, MESSAGE, VERBOSE }
const PREFIX = { LEVELS.UNRECOVERABLE: "!!! ERROR !!! ", LEVELS.ERROR: "!!! ERROR !!! ",
	LEVELS.WARNING: " ! warning !  ", LEVELS.MESSAGE: "              ",
	LEVELS.VERBOSE: "              "}
func reportError(cat, s):
	error = s
	logMessage(cat, s, LEVELS.ERROR)
func reportWarning(cat, s):
	logMessage(cat, s, LEVELS.WARNING)
func debugMessage(cat, s):
	logMessage(cat, s, LEVELS.MESSAGE)
func verboseMessage(cat, s):
	logMessage(cat, s, LEVELS.VERBOSE)

func logMessage(cat, s, level = LEVELS.MESSAGE):
	debugLog.push_back(LogData.new(cat, s, level))
	if level <= verbosity:
		print(Util.pad(cat, ' ', 8, false) + PREFIX[level] + s)

func allGood():
	return Util.isnull(error)

class LogData:
	extends Node
	var date : Dictionary
	var level : int
	var category : String # Completely arbitrary
	var message : String
	func _init(cat, s, l):
		date = OS.get_time()
		level = l
		category = cat
		message = s
