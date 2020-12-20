extends GridContainer

var template
enum DATA { NAME = 0, NUM_SAVES, LAST_PLAYED }
var list = []

func _ready():
	Game.varPrep()
	list = Data.getFileList("Games/")
	template = get_node("Button")
	if list.size() == 1:
		Game.debugMessage("Load", "Found one game (%s), loading" % list[0])
		Game.gamePicked(list[0])
	else:
		Game.debugMessage("Load", "Found games: " + str(list))
	reload()

func reload():
	Game.debugMessage("Load", "Loading game list, size=" + str(list.size()))
	# First child is the invisible template; clear everything else and then start copying it
	while get_child_count() > 1:
		remove_child(get_child(1))
	for i in range(0, 12):
		if i < list.size():
			var t = template.duplicate()
			var game = list[i]
			# Icon
			var icon = t.get_node("GameData/IconMargin/GameIcon")
			icon.texture = Data.getTexture("Games/", game, "/icon.png")
			icon.texture.size = Vector2(96, 96)
			# Various info about the game data
			var infolist = t.get_node("GameData/InfoList")
			var saves = Data.getFileList("Saves/" + game)
			dataLabel(infolist, DATA.NAME, game)
			dataLabel(infolist, DATA.NUM_SAVES, "Saves: " + str(saves.size()))
			# Last played date takes a bit of doing
			var lastPlayed = 0
			var strLP = "-"
			for s in range(0, saves.size()):
				var folderPlayed = Data.getFileAccessTime("Saves/" + game + "/" + saves[s] + "/data/characters.csv")
				if folderPlayed > lastPlayed: lastPlayed = folderPlayed
			if lastPlayed > 0:
				strLP = Util.getStringDate(lastPlayed)
			dataLabel(infolist, DATA.LAST_PLAYED, "Last played: " + strLP)
			t.visible = true
			add_child(t)
	#get_parent().
	emit_signal("draw")

func dataLabel(infolist, posn, data):
	var lbl = infolist.get_child(0).duplicate()
	if posn == DATA.NAME: lbl.add_color_override("font_color", Color("#e3c000"))
	lbl.text = str(data)
	lbl.rect_min_size = Vector2(200, 16)
	lbl.set_size(Vector2(200, 16))
	infolist.add_child(lbl)
	#print("Item ", [posn, data])

func selectGame(g):
	Game.gamePicked(list[g-1])
