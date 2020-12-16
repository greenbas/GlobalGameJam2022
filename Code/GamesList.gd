extends GridContainer

var template
enum DATA { NAME = 0, NUM_SAVES, LAST_PLAYED }
var list = []

func _ready():
	Game.debugger = Debugger.new()
	list = Data.getGamesList()
	template = get_node("GameData")
	if list.size() == 1:
		Game.debugMessage("Load", "Found one game (%s), loading" % list[0])
		Game.gamePicked(list[0])
	else:
		Game.debugMessage("Load", "Found games: " + str(list))
	reload()

func reload():
	print("Reloading game list, size=", list.size())
	# First child is the invisible template; clear everything else and then start copying it
	while get_child_count() > 1:
		remove_child(get_child(1))
	for i in range(0, 12):
		if i < list.size():
			#print("Has item ", i)
			var t = template.duplicate()
			var game = list[i]
			var btn = t.get_node("GameIcon")
			btn.texture = Data.getTexture("Games/", game, "/icon.png")
			btn.texture.size = Vector2(128, 128)
			#t.icon = Data.getImage("Games/", game, "/icon.ico")
			var infolist = t.get_node("InfoList")
			dataLabel(infolist, DATA.NAME, game)
#			dupLabel(t, TEMPLATE.HAB, task.assignedHab)
#			dupLabel(t, TEMPLATE.TILE, "(" + str(task.posn.x) + ", " + str(task.posn.y) + ")")
#			var itName = ""
#			if !Data.isnull(task.item):
#				var obj = Data.getObj(task.item)
#				itName = obj.name
#			dupLabel(t, TEMPLATE.ITEM, itName)
#			dupLabel(t, TEMPLATE.UID, task.uid)
			t.visible = true
			add_child(t)
	#get_parent().
	emit_signal("draw")

func dataLabel(infolist, posn, data):
	var lbl = infolist.get_child(posn)
	lbl.text = str(data)
	infolist.add_child(lbl)
	#print("Item ", [posn, data])
	
