extends CanvasLayer
## 장면(맵)을 바꿀 때 화면을 까맣게 덮었다가 다시 밝히는 효과예요.
## 사용 예: Transition.go("res://scenes/cave.tscn", "Entrance")

@onready var fade: ColorRect = $Fade


## scene_path 맵으로 이동해서, 이름이 spawn_name인 출발 지점에 코랄을 세워요.
func go(scene_path: String, spawn_name: String) -> void:
	Dialogue.cutscene = true
	Sound.play("whoosh", 0.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.35)
	await tween.finished

	GameState.next_spawn = spawn_name
	get_tree().change_scene_to_file(scene_path)
	# 새 맵이 준비될 때까지 잠깐 기다려요.
	await get_tree().process_frame
	await get_tree().process_frame
	GameState.save_game()

	tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.35)
	await tween.finished
	# 화면이 다 밝아진 뒤에 움직일 수 있어요.
	Dialogue.cutscene = false
