extends CanvasLayer
## 장면(맵)을 바꿀 때 화면을 까맣게 덮었다가 다시 밝히는 효과예요.
## 사용 예: Transition.go("res://scenes/village.tscn")

@onready var fade: ColorRect = $Fade

## 지금 장면을 바꾸는 중이면 true
var busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## scene_path 장면으로 이동해요.
func go(scene_path: String) -> void:
	if busy:
		return
	busy = true
	Dialogue.cutscene = true
	Sound.play("whoosh", 0.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.35)
	await tween.finished

	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	# 새 장면이 준비될 때까지 잠깐 기다려요.
	await get_tree().process_frame
	await get_tree().process_frame

	tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.35)
	await tween.finished
	# 화면이 다 밝아진 뒤에 움직일 수 있어요.
	Dialogue.cutscene = false
	busy = false


## 지금 장면을 처음부터 다시 해요. (쓰러졌을 때)
func restart() -> void:
	go(get_tree().current_scene.scene_file_path)
