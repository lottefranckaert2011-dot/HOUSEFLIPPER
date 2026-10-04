extends Node
## Plays sound effects and the background music loop.

const SOUNDS := [
	"pop", "cash", "error", "scrub", "paint", "place", "complete", "click", "rip", "whoosh"
]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _next := 0
var _cooldown := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, "Master")
	for s in SOUNDS:
		var path := "res://assets/audio/%s.wav" % s
		if ResourceLoader.exists(path):
			_streams[s] = load(path)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	if ResourceLoader.exists("res://assets/audio/music.wav"):
		var m: AudioStreamWAV = load("res://assets/audio/music.wav")
		m.loop_mode = AudioStreamWAV.LOOP_FORWARD
		m.loop_end = m.get_length() * m.mix_rate
		_music.stream = m
	Game.settings_changed.connect(_apply_volume)
	_apply_volume()


func play(sound: String, pitch_jitter := 0.08, volume_db := 0.0) -> void:
	if not _streams.has(sound):
		return
	var now := Time.get_ticks_msec()
	if now - int(_cooldown.get(sound, 0)) < 40:
		return
	_cooldown[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db
	p.play()


func start_music() -> void:
	if _music.stream and not _music.playing:
		_music.play()


func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(0, muted)


func _apply_volume() -> void:
	_set_bus("Music", Game.settings["music"] * 0.55)
	_set_bus("SFX", Game.settings["sfx"])


func _set_bus(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)
