extends CanvasLayer
## 엔딩 화면이에요. 별 세 개를 모두 돌려보내면 나와요.

var can_close := false


func _ready() -> void:
	Dialogue.cutscene = true
	Sound.play_music("ending", 2.0)
	$Root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property($Root, "modulate:a", 1.0, 1.5)
	tween.tween_interval(1.5)
	tween.tween_callback(func(): can_close = true; $Root/Hint.show())


func _unhandled_input(event: InputEvent) -> void:
	if can_close and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		can_close = false
		GameState.flags["ending_seen"] = true
		Sound.play_music("village", 2.0)
		var tween := create_tween()
		tween.tween_property($Root, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): Dialogue.cutscene = false; queue_free())
