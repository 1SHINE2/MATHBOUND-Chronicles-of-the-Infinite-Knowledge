extends Node
## Lightweight procedural audio placeholder manager.
## Can be swapped with real AudioStream assets later without changing game code.

var sfx_volume: float = 0.8
var music_volume: float = 0.45
var audio_enabled: bool = true

var _sfx_player: AudioStreamPlayer
var _generator: AudioStreamGenerator

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_player = AudioStreamPlayer.new()
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 22050.0
	_generator.buffer_length = 0.25
	_sfx_player.stream = _generator
	add_child(_sfx_player)

func set_volumes(sfx_pct: float, music_pct: float) -> void:
	sfx_volume = clampf(sfx_pct / 100.0, 0.0, 1.0)
	music_volume = clampf(music_pct / 100.0, 0.0, 1.0)

func play_tone(freq_hz: float, duration_sec: float = 0.08, volume_scale: float = 0.25) -> void:
	if not audio_enabled or sfx_volume <= 0.01:
		return
	if not _sfx_player.playing:
		_sfx_player.play()
	var playback := _sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := int(_generator.mix_rate * clampf(duration_sec, 0.02, 0.22))
	var avail := mini(frames, playback.get_frames_available())
	var phase := 0.0
	var increment := freq_hz / _generator.mix_rate
	var amp := sfx_volume * volume_scale
	for i in range(avail):
		var env := 1.0 - (float(i) / float(maxi(avail, 1)))
		var sample := sin(phase * TAU) * amp * env
		playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + increment, 1.0)

func play_ui_click() -> void:
	play_tone(580.0, 0.05, 0.2)

func play_sigil_place() -> void:
	play_tone(740.0, 0.07, 0.25)

func play_dialogue_chirp() -> void:
	play_tone(480.0 + randf() * 140.0, 0.035, 0.15)

func play_spell_cast() -> void:
	play_tone(660.0, 0.14, 0.3)

func play_puzzle_success() -> void:
	play_tone(880.0, 0.18, 0.35)

func play_error() -> void:
	play_tone(210.0, 0.14, 0.3)

func play_attack() -> void:
	play_tone(340.0, 0.08, 0.28)

func play_archive_unlock() -> void:
	play_tone(960.0, 0.16, 0.3)
