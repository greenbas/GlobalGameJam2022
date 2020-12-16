extends Node

static func fillProps(folder, tab):
	var file = File.new()
	var dict
	var path = folder + tab + ".csv"
	if file.open(path, file.READ) == OK:
		Game.verboseMessage("File", "Found tab " + tab)
		dict = Data.parseCSV(file)
	else:
		Game.reportError("File", "Error reading file %s" % path)
	file.close()
	return dict

static func parseCSV(file):
	var props = []
	var defaults = []
	file.seek(0)
	var list = {}
	while !file.eof_reached(): 
		var line = file.get_csv_line()
		if len(props) == 0:
			props = line
		elif len(defaults) == 0 and line[0] == "DEFAULT":
			defaults = line
		elif len(line) == len(props):
			var dict = {}
			for i in range(0, props.size()):
				dict[props[i]] = Util.nvl(line[i], defaults[i])
			list[list.size()] = dict
	return list

#static func getCSVLine(lineOrig : String):
#	# I've been using the built-in "file.get_csv_line()" but I
#	# just discovered that it doesn't support quotes or even
#	# multi-character delimiters.  So I'll write my own.
#	print ("Line ", lineOrig.substr(1, -2))
#	return lineOrig.substr(1, -2).split(""",""", false)
#	# Or not.  Never mind, it was just already open elsewhere...
#		var line = getCSVLine(file.get_line())

static func getImage(folder, file, ext):
	var img = Image.new()
	var fname = folder + file + ext
	var f = File.new()
	if f.open(fname, f.READ) == OK:
		img.load(fname)
	else:
		Game.debugMessage("File", "Error reading image file " + fname)
	f.close()
	return img

# https://godotengine.org/qa/30210/how-do-load-resource-works
static func getTexture(folder, file, ext):
	var img = Data.getImage(folder, file, ext)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex

static func getFont(folder, file, ext):
	var fname = folder + file + ext
	var font = DynamicFont.new()
	font.font_data = load(fname)
	return font


# http://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func getGamesList():
	var list = []
	var dir = Directory.new()
	dir.open("Games/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and not file.begins_with("_") and dir.current_is_dir():
			list.append(file)
	dir.list_dir_end()
	return list
