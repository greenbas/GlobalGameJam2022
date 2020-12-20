extends Sprite
class_name ScreenObject

var scene
var data
var canvas
#var ia : Interactable

func _init(d):
	data = d
	scene = Game.sceneNode
	canvas = scene.get_node("Objects")
	name = data.ID
	#ia = Interactable.new()
	#ia.setData(Game.ENTITY.OBJ)

func drawMe():
	# Image
	visible = (visible and data.Visible == "1")
	var zoom = float(data.Zoom) / 100
	scale = Vector2(zoom, zoom)
	texture = Game.getTexture(data.Image_Path, data.Image_Filename, data.Image_Extension)
	rotation = deg2rad(float(data.Rotation))
	flip_h = (data.Flip_H == "1")
	flip_v = (data.Flip_V == "1")
	# Positioning
	var oldpos = position
	centered = false # We offset so that "position" is the position of the base
	var base_offset = Vector2(int(data.Base_X), int(data.Base_Y))
	var xpos = scene.WIDTH * float(data.Screen_X) / 100
	var ypos = scene.HEIGHT * float(data.Screen_Y) / 100
	position = Vector2(xpos, ypos)
	var frameSize = Vector2(texture.get_size().x / hframes, texture.get_size().y)
	offset = -(frameSize * base_offset / 100)
	z_index = round(position.y)

# Movement
#var goalPath = []
#var goalPosn = DONT_MOVE
#var speed = 175
#var velocity = Vector2(0, 0)

#func setGoal():
#	if goalPath.size() > 0:
#		goalPosn = goalPath.pop_front()
#		scene.get_node("BaseTest").position = goalPosn
#	else:
#		goalPosn = DONT_MOVE
		#Game.update(Game.ENTITY.CHAR, ["ID"], [sprite.name], "Scene_X", posn.x)
		#Game.update(Game.ENTITY.CHAR, ["ID"], [sprite.name], "Scene_Y", posn.y)
		#Game.update(Game.ENTITY.CHAR, ["ID"], [sprite.name], ["Scene_X", "Scene_Y"], [posn.x, posn.y])

#func _process(delta):
#	# To prevent jitter, we have a "close enough" check
#	if abs(position.x - goalPosn.x) < 4 and abs(position.y - goalPosn.y) < 4:
#		var prevAngle = get_angle_to(goalPosn)
#		position = goalPosn
#		setGoal()
#		if goalPosn == DONT_MOVE:
#			beginAnim(data["Idle_" + getDir(prevAngle)])
#	elif goalPosn != DONT_MOVE:
#		var angle = get_angle_to(goalPosn)
#		beginAnim(data[getDir(angle)])
#		velocity.x = cos(angle)
#		velocity.y = sin(angle)
#		position += velocity * speed * delta
