extends Sprite
class_name ScreenObject

var scene
var data
var canvas

func _init(d):
	data = d
	scene = Game.sceneNode
	canvas = scene.get_node("Objects")
	name = data.ID

func reset():
	pass # This is called sometimes

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
	centered = false # We offset so that "position" is the position of the base
	var base_offset = Vector2(int(data.Base_X), int(data.Base_Y))
	var xpos = scene.WIDTH * float(data.Screen_X) / 100
	var ypos = scene.HEIGHT * float(data.Screen_Y) / 100
	position = Vector2(xpos, ypos)
	var frameSize = Vector2(texture.get_size().x / hframes, texture.get_size().y)
	offset = -(frameSize * base_offset / 100)
	z_index = int(round(position.y))

static func getWalkPoint(obj): # Could be object or character
	var posn = obj.position
	var offsetPerc = Vector2(float(obj.data.Walk_Point_X), float(obj.data.Walk_Point_Y))
	posn += obj.texture.size * offsetPerc / Vector2(100.0, 100.0)
	return posn
