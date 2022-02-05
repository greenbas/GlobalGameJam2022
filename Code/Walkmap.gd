extends TextureRect

var data
var scene

func lock():
	scene = get_parent()
	data = texture.get_data()
	data.lock()

func getColour(posn):
	if posn.x < 0 or posn.y < 0: return "#000000"
	if posn.x >= scene.WIDTH or posn.y >= scene.HEIGHT: return "#000000"
	if posn.x > data.get_width() or posn.y > data.get_height(): return "#000000"
	var colour = data.get_pixelv(posn).to_html(false)
	return "#" + colour
func isWalkable(posn):
	if posn.x < 0 or posn.y < 0: return false
	if posn.x >= sceneW or posn.y >= sceneH: return false
	return getColour(posn) != "#000000"

func _input(event):
	if Game.allGood():
		if Game.actionsAllowed():
			var posn = get_viewport().get_mouse_position()
			if event is InputEventMouseButton and event.pressed and not event.is_echo():
				if scene.scriptManager.inDialogue():
					scene.scriptManager.endDialogue()
				else:
					if event.button_index == BUTTON_LEFT:
						scene.triggerClick(posn)
					else:
						scene.triggerWalk(posn)
			elif event is InputEventMouse:
				scene.triggerHover(posn)
			else:
				Game.menu.checkInput(event)

# Movement
var astar : AStar2D
var sceneW = 1280
var sceneH = 720
var GRID_SIZE = 20.0#64.0
var OFFSET = GRID_SIZE / 2

func tryWalking(sprite, posn, retry=false):
	var found = false
	while !found && posn.y < sceneH:
		sprite.goalPath = findPath(sprite.position, posn)
		# If retry = true, it's probably because we're trying to walk to something,
		# and it's really easy to accidentally put that point above the walkmap
		if !retry or sprite.goalPath.size() > 0:
			found = true
		else:
			posn.y += GRID_SIZE
	if (found):
		Game.menu.clearMenu()
		sprite.setGoal()

func findPath(orig : Vector2, dest : Vector2):
	var path = []
	var ptOrig = pseudoToPtID(realToPseudo(orig))
	var ptDest = pseudoToPtID(realToPseudo(dest))
	if astar.has_point(ptDest):
		path = Array(astar.get_point_path(ptOrig, ptDest))
		# This gets us to the closest pt.  Assuming we found a path at all,
		# we want to go precisely to the point clicked.  And we would prefer
		# not to go to the closest point THEN the actual position because 
		# sometimes that means doubling back.  Similar with the first point.
		# So replace the first and last points with the real positions.
		path.pop_front()
		path.push_front(orig)
		path.pop_back()
		path.push_back(dest)
	Game.verboseMessage(Game.CAT.PATH, "Path from %s to %s = %s" % [ptOrig, ptDest, path])
	return path

func _draw():
	if Game.allGood() and Game.ready():
		recalcNodes()
		update()

func recalcNodes():
	# Loops through the scene and marks nodes.
	Game.debugMessage(Game.CAT.PATH, "Calculating pathfinding nodes")
	# We have to recalc all nodes after this point on the map anyway, so let's just start fresh
	astar = AStar2D.new()
	for j in range (0, sceneH / GRID_SIZE):
		for i in range (0, sceneW / GRID_SIZE):
			var pseudoPosn = Vector2(i, j)# * GRID_SIZE, j * GRID_SIZE)
			var realPosn = pseudoToReal(pseudoPosn)
			var ptID = pseudoToPtID(pseudoPosn)
			if ptID >= 0:
				astar.add_point(ptID, realPosn, 1.0)
				draw_circle(realPosn, 3, Color.black)
				draw_circle(realPosn, 2, Color.red)
				# Don't forget to connect it to previous nodes, including diagonals
				testAndConnect(ptID, realPosn, pseudoPosn + Vector2(-1,  0)) # Left
				testAndConnect(ptID, realPosn, pseudoPosn + Vector2( 0, -1)) # Above
				testAndConnect(ptID, realPosn, pseudoPosn + Vector2(-1, -1)) # Left Diagonal
				testAndConnect(ptID, realPosn, pseudoPosn + Vector2( 1, -1)) # Right Diagonal
	Game.verboseMessage(Game.CAT.PATH, "Calculation complete")

# Apparently we can't connect points based on posn (x, y) but only on ID, so instead
# of using the provided function get_available_point_id() I'm going to create one
# based on X, Y and a translation algorithm.
# To make them simpler I will also have a grid of "pseudo" points which start at (0, 0)
# and always go up by 1, these convert back and forth to a real position based on GRID_SIZE
func ptIDToPseudo(pointID):
	return Vector2(pointID % int(sceneW / GRID_SIZE), pointID / int(sceneW / GRID_SIZE))
func pseudoToPtID(pt):
	if !isWalkable(pseudoToReal(pt)): return -1 # Otherwise we try to convert realPosn back and get bad data bc modulus
	return sceneW / GRID_SIZE * round(pt.y) + round(pt.x)
func pseudoToReal(pt):
	return (pt * GRID_SIZE) + Vector2(OFFSET, OFFSET)
func realToPseudo(posn):
	return (posn - Vector2(OFFSET, OFFSET)) / GRID_SIZE



func testAndConnect(pt1, real1, pseudo2):
	# We assume that we know pt1 exists, because we just added it
	var pt2 = pseudoToPtID(pseudo2)
	if astar.has_point(pt2):
		astar.connect_points(pt1, pt2)
		# For debugging only
		var real2 = pseudoToReal(pseudo2)
		draw_line(real1, real2, Color.rebeccapurple)
