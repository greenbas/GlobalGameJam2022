extends AudioStreamPlayer

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS

var currMusicFile : String
func playSceneMusic(data):
	var newMusicFile = data.Audio_Path + data.Audio_Filename + data.Audio_Extension
	if newMusicFile != currMusicFile:
		currMusicFile = newMusicFile
		stream = Game.getAudio(data.Audio_Path, data.Audio_Filename, data.Audio_Extension)
		stop()
		play()
	volume_db = float(data.Audio_Volume_Db)

