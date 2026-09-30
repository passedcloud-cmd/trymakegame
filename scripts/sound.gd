extends Node
## 효과음과 배경 음악을 틀어 주는 곳이에요. 게임 어디서든 쓸 수 있어요.
##   효과음:   Sound.play("swipe")
##   배경 음악: Sound.play_music("village")   (같은 곡이면 그대로 이어서 틀어요)
## M 키를 누르면 모든 소리를 끄고 켤 수 있어요.

## 효과음 크기 (dB). 0이 원래 크기, 숫자가 작을수록 조용해요.
@export var sfx_volume_db: float = -4.0
## 배경 음악 크기 (dB)
@export var music_volume_db: float = -9.0

const SFX_PATH := "res://assets/sounds/%s.wav"
const MUSIC_PATH := "res://assets/music/%s.wav"
## 동시에 날 수 있는 효과음 개수
const SFX_CHANNELS := 10

var sfx_players: Array[AudioStreamPlayer] = []
var music_players: Array[AudioStreamPlayer] = []
var current_music := ""
var active_music := 0
var cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_CHANNELS:
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)
	for i in 2:
		var player := AudioStreamPlayer.new()
		add_child(player)
		music_players.append(player)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))


func get_stream(path: String) -> AudioStream:
	if not cache.has(path):
		cache[path] = load(path) if ResourceLoader.exists(path) else null
	return cache[path]


## 효과음을 틀어요.
## pitch: 음 높이 (1 = 원래). variation: 매번 음 높이를 살짝 다르게 해서 덜 지루하게 해요.
func play(sound_name: String, volume_db := 0.0, pitch := 1.0, variation := 0.08) -> void:
	var stream := get_stream(SFX_PATH % sound_name)
	if stream == null:
		push_warning("효과음 파일이 없어요: " + sound_name)
		return
	# 쉬고 있는 스피커를 찾아요. 모두 바쁘면 가장 먼저 시작한 소리를 끊어요.
	var player: AudioStreamPlayer = sfx_players[0]
	for p in sfx_players:
		if not p.playing:
			player = p
			break
	sfx_players.erase(player)
	sfx_players.append(player)
	player.stream = stream
	player.volume_db = sfx_volume_db + volume_db
	player.pitch_scale = pitch * randf_range(1.0 - variation, 1.0 + variation)
	player.play()


## 배경 음악을 바꿔요. 앞의 곡은 천천히 작아지고 새 곡이 천천히 커져요.
## 빈 이름("")을 주면 음악을 꺼요.
func play_music(music_name: String, fade_time := 1.0) -> void:
	if music_name == current_music:
		return
	current_music = music_name

	var old_player := music_players[active_music]
	if old_player.playing:
		var fade_out := create_tween()
		fade_out.tween_property(old_player, "volume_db", -40.0, fade_time)
		fade_out.tween_callback(old_player.stop)

	if music_name == "":
		return
	var stream := get_stream(MUSIC_PATH % music_name)
	if stream == null:
		push_warning("음악 파일이 없어요: " + music_name)
		return
	active_music = 1 - active_music
	var new_player := music_players[active_music]
	new_player.stream = stream
	new_player.volume_db = -40.0
	new_player.play()
	create_tween().tween_property(new_player, "volume_db", music_volume_db, fade_time)


# 게임을 끌 때 모든 소리를 멈추고 정리해요.
func _exit_tree() -> void:
	for player in sfx_players + music_players:
		player.stop()
		player.stream = null
	cache.clear()
