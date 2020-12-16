extends TextureButton

func _pressed():
	var p = get_parent()
	for g in range(0, p.get_child_count()):
		if p.get_child(g) == self:
			p.selectGame(g)
