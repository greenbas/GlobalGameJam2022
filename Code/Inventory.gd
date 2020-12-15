extends Node
class_name Inventory

var inv = {}

func _init(playables, list):
	for p in playables:
		inv[p.ID] = {}
	for i in list:
		addItem(i.Character, i.Object_Group, i.Quantity)

func addItem(c, i, q=1):
	if !inv[c].has(i): inv[c][i] = 0
	inv[c][i] += q

func removeItem(c, i, q=1):
	inv[c][i] -= q
	if inv[c][i] < 0: inv[c][i] = 0

func numItem(c, i):
	if !inv[c].has(i): return 0
	return inv[c][i]

func getInvByLoc(c):
	var arr = []
	for i in inv[c]:
		arr.push_back(i)
	return arr