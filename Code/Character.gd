extends Sprite
class_name Character

var DONT_MOVE = Vector2(-1, -1)

var scene
var canvas
var data
#var ia : Interactable

func _init(d):
	data = d
	scene = Game.sceneNode
	canvas = scene.get_node("Characters")
	name = data.ID
	speed = DEFAULT_SPEED * float(data.Walk_Speed) / 100.0
	#ia = Interactable.new()
	#ia.setData(Game.ENTITY.CHAR)
	initAnim()
	return self

func drawMe():
	# Image (texture is part of animation)
	visible = (visible and data.Visible == "1")
	var zoom = float(data.Zoom) / 100
	scale = Vector2(zoom, zoom)
	# Animation
	beginAnim(data.Animation_Current)
	# Positioning
	var oldpos = position
	centered = false # We offset so that "position" is the position of the base
	var base_offset = Vector2(float(data.Base_X), float(data.Base_Y))
	var xpos = float(scene.WIDTH) * float(data.Screen_X) / 100.0
	var ypos = float(scene.HEIGHT) * float(data.Screen_Y) / 100.0
	position = Vector2(xpos, ypos)
	var frameSize = Vector2(texture.get_size().x / hframes, texture.get_size().y)
	offset = -(frameSize * base_offset / 100)
	z_index = round(position.y)
	if visible and position != oldpos:
		scene.onCharacterMove(self)

# Movement
var goalPath = []
var goalPosn = DONT_MOVE
var DEFAULT_SPEED : float = 175.0
var speed = DEFAULT_SPEED
var velocity = Vector2(0, 0)
var lastColour = ""

func updatePosn(dictToo=false):
	data.Screen_X = str(position.x * 100.0 / scene.WIDTH) + "%"
	data.Screen_Y = str(position.y * 100.0 / scene.HEIGHT) + "%"
	scene.all_chars[data.ID] = self
	if dictToo:
		Game.updateByID(Game.ENTITY.CHAR, ["ID"], [data.ID], ["Screen_X", "Screen_Y"], [data.Screen_X, data.Screen_Y])

#func getSpriteBase():
#	var base_in_sprite = Vector2(int(data.Base_X), int(data.Base_Y))
#	var base_on_screen = position + (texture.get_size() * scale * (base_in_sprite - BASE_OFFSET) / 100)
#	scene.get_node("BaseTest").position = base_on_screen # FIXME: For testing only
#	return base_on_screen

#func getSpriteCenter(base_on_screen):
#	var base_in_sprite = Vector2(int(data.Base_X), int(data.Base_Y)) # Base within the sprite
#	var center = base_on_screen - (texture.get_size() * scale * (base_in_sprite - BASE_OFFSET) / 100)
#	return Vector2(round(center.x), round(center.y))

func setGoal():
	if goalPath.size() > 0:
		goalPosn = goalPath.pop_front()
		scene.get_node("Walkmap/BaseTest").position = goalPosn
	else:
		goalPosn = DONT_MOVE
		Game.menu.triggerDestination()
		#Game.update(Game.ENTITY.CHAR, ["ID"], [sprite.name], "Scene_X", posn.x)
		#Game.update(Game.ENTITY.CHAR, ["ID"], [sprite.name], "Scene_Y", posn.y)
		#Game.update(Game.ENTITY.CHAR, ["ID"], [sprite.name], ["Scene_X", "Scene_Y"], [posn.x, posn.y])

func _process(delta):
	# To prevent jitter, we have a "close enough" check
	var closeEnough = 4 * ceil(Game.dbgr.getFF())
	if abs(position.x - goalPosn.x) < closeEnough and abs(position.y - goalPosn.y) < closeEnough:
		var prevAngle = get_angle_to(goalPosn)
		position = goalPosn
		z_index = round(position.y)
		updatePosn(goalPosn == DONT_MOVE)
		setGoal()
		scene.onCharacterMove(self)
		if goalPosn == DONT_MOVE:
			beginAnim(data["Idle_" + getDir(prevAngle)])
			Game.menu.triggerDestination()
	elif goalPosn != DONT_MOVE:
		var angle = get_angle_to(goalPosn)
		beginAnim(data[getDir(angle)])
		velocity.x = cos(angle)
		velocity.y = sin(angle)
		position += velocity * speed * delta * Game.dbgr.getFF()
		z_index = round(position.y)

# Animation
var aTimer
var all_anims = {}

func initAnim(): # Once only
	aTimer = Timer.new()
	aTimer.one_shot = false
	aTimer.connect("timeout", self, "animateSprite")
	scene.add_child(aTimer)

func beginAnim(animID):
	var animation
	if all_anims.has(animID):
		animation = all_anims[animID]
	else:
		animation = Game.entityWhere(Game.ENTITY.ANIM, ["Character", "Name"], [data.ID, animID])
		all_anims[animID] = animation
	texture = Game.getTexture(animation.Path, animation.Filename, animation.Extension)
	hframes = int(animation.Frames)
	if aTimer.is_stopped():
		aTimer.start(float(animation.Frame_Duration))
		#aTimer.wait_time = Game.dbgr.getFF() # not working

func animateSprite():
	frame = (frame + 1) % hframes
	
func getDir(angle):
	# This function returns a compass direction given a heading.  It is
	# intended to be used with the animations which follow format "N",
	# "NE" etc if moving or "Idle_N", "Idle_NE" etc if standing still.
	var dir = ""
	#print("%s <= %s and %s < %s" % [-5*PI/6, angle, angle, -1*PI/6])
	if -5*PI/6  <= angle and angle < -1*PI/6:
		dir += "N"
	elif PI/6 <= angle and angle < 5*PI/6:
		dir += "S"
	#print(" %s < %s or %s > %s" % [ angle, -2*PI/3, angle, 2*PI/3])
	if -PI/3 <= angle and angle < PI/3: dir += "E"
	elif angle < -2*PI/3 or angle > 2*PI/3: dir += "W"
	return dir
	
