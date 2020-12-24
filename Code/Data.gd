extends Node

static func fillProps(folder, tab):
	var file = File.new()
	var dict
	var path = folder + tab + ".csv"
	if file.open(path, file.READ) == OK:
		Game.verboseMessage(Game.CAT.FILE, "Found tab " + tab)
		dict = Data.parseCSV(file)
	else:
		Game.reportError(Game.CAT.FILE, "Error reading file %s" % path)
	file.close()
	return dict

static func parseCSV(file):
	var props = []
	var defaults = []
	file.seek(0)
	var list = {}
	while !file.eof_reached(): 
		var line = file.get_csv_line()
#		for p in range(0, line.size()):
#			if line[p] == "\"":
#				line[p] = ""
		if len(props) == 0:
			props = line
		elif len(defaults) == 0 and line[0] == "DEFAULT":
			defaults = line
		elif len(line) >= len(props):
			var dict = {}
			for i in range(0, props.size()):
				dict[props[i]] = Util.nvl(line[i], defaults[i])
			list[list.size()] = dict
	return list

static func saveCSV(fhead, fdata, filename, dict):
	Game.debugMessage(Game.CAT.SAVE, "Saving file: %s" % [fdata + filename])
	var dir = Directory.new()
	dir.make_dir_recursive(fdata)
	var file = File.new()
	var count = 0
	if file.open(fdata + filename, file.WRITE) == OK:
		var hdr = File.new()
		if hdr.open(fhead + filename, file.READ) == OK:
			var colIDs = hdr.get_csv_line()
			file.store_line(colIDs.join(","))
			var defaults = hdr.get_csv_line()
			file.store_line(defaults.join(","))
			count += 2
		for row in dict.keys():
			var dataRow : PoolStringArray = []
			for col in dict[row].keys():
				var cell = dict[row][col]
				if cell:
					 cell = "\"" + str(cell) + "\""
				dataRow.push_back(cell)
			file.store_line(dataRow.join(","))
			count += 1
		file.close()
	Game.verboseMessage(Game.CAT.SAVE, "Wrote %s lines" % [count])
		

static func getImage(folder, file, ext):
	var img = Image.new()
	var fname = folder + file + ext
	var f = File.new()
	if f.open(fname, f.READ) == OK:
		img.load(fname)
	else:
		Game.reportError(Game.CAT.FILE, "Error reading image file " + fname)
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
	# Report error
	var f = File.new()
	if f.open(fname, f.READ) == OK:
		font.font_data = load(fname)
	else:
		Game.reportWarning(Game.CAT.FILE, "Error reading font file " + fname)
	return font

# https://github.com/godotengine/godot/issues/17748
static func getAudio(folder, file, ext):
	var fname = folder + file + ext
	var stream = AudioStreamOGGVorbis.new()
	var afile = File.new()
	if afile.open(fname, File.READ) == OK:
		var bytes = afile.get_buffer(afile.get_len())
		stream.data = bytes
	else:
		Game.reportWarning(Game.CAT.FILE, "Error reading sound file " + fname)
	afile.close()
	return stream

# http://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func getFileList(path):
	var list = []
	var dir = Directory.new()
	if dir.dir_exists(path):
		dir.open(path)
		dir.list_dir_begin()
		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with(".") and not file.begins_with("_") and dir.current_is_dir():
				list.append(file)
		dir.list_dir_end()
	return list

func getFileAccessTime(fname):
	var file = File.new()
	file.open(fname, file.READ)
	return file.get_modified_time(fname)
