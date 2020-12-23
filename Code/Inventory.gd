extends Node
class_name Inventory

var inv = {}

func _init(playables, list):
	for p in playables:
		inv[p.ID] = {}
	for i in list.values():
		addItem(i.Character, i.Object_Group, int(i.Quantity))

func addItem(c, i, q=1):
	if !inv[c].has(i): inv[c][i] = 0
	inv[c][i] += q

func removeItem(c, i, q=1):
	inv[c][i] -= q
	if inv[c][i] < 0: inv[c][i] = 0

func numItem(c, i):
	if !inv[c].has(i): return 0
	return inv[c][i]

# Update the entity
func updateEntity():
	var e = Game.entityByID(Game.ENTITY.INV)
	e = {}
	var count = 0
	for p in Game.playables:
		for i in inv[p.ID]:
			e[count] = { "Object_Group": i, "Character": p.ID, "Quantity": numItem(p.ID, i) }
			count += 1
	Game.entities[Game.ENTITY_NAME[Game.ENTITY.INV]] = e

# Returns a numbered array of inventory for a character.
# Used in displaying the inventory menu.
func getInvByLoc(c):
	var arr = []
	for i in inv[c]:
		arr.push_back(i)
	return arr

func getInvData(c, i):
	var objgroups = Game.dictByID(Game.listOf(Game.ENTITY.OBJGROUP))
	if objgroups.has(i):
		return Game.entityWhere(Game.ENTITY.OBJGROUP, ["ID"], [i])
	else:
		return Game.entityWhere(Game.ENTITY.OBJ, ["ID"], [i])
	
