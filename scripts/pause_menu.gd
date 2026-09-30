extends CanvasLayer
## ESC를 누르면 뜨는 일시 정지 창이에요.
## 계속하기 / 타이틀 화면으로 / 게임 종료 중에서 골라요.
## 창이 떠 있는 동안에는 게임 전체가 멈춰요. (get_tree().paused)

const TITLE_SCENE := "res://scenes/title.tscn"

@onready var menu: VBoxContainer = $Root/Panel/Menu

var options: Array[String] = []
var index := 0


func _ready() -> void:
	# 게임이 멈춰 있어도 이 창은 움직여야 해요.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") and not visible:
		return

	if not visible:
		if can_pause():
			open()
			get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause"):
		close()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		index = wrapi(index + (-1 if event.is_action_pressed("ui_up") else 1), 0, options.size())
		Sound.play("cursor", 0.0, 1.0, 0.0)
		build_menu()
	elif event.is_action_pressed("interact"):
		choose(options[index])


# 타이틀 화면이나 맵을 옮기는 중에는 멈출 수 없어요.
func can_pause() -> bool:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == TITLE_SCENE:
		return false
	return not (Dialogue.cutscene and not Dialogue.is_open)


func open() -> void:
	options = ["계속하기", "타이틀 화면으로"]
	# 웹 브라우저에서는 게임이 스스로 창을 닫을 수 없어서 "게임 종료"를 숨겨요.
	if not OS.has_feature("web"):
		options.append("게임 종료")
	index = 0
	build_menu()
	show()
	get_tree().paused = true
	Sound.play("select", 0.0, 0.8, 0.0)


func close() -> void:
	hide()
	get_tree().paused = false
	Sound.play("cursor", 0.0, 1.0, 0.0)


func choose(option: String) -> void:
	match option:
		"계속하기":
			close()
		"타이틀 화면으로":
			GameState.save_game()
			hide()
			get_tree().paused = false
			Sound.play("select", 0.0, 1.0, 0.0)
			Transition.go(TITLE_SCENE, "")
		"게임 종료":
			GameState.save_game()
			get_tree().quit()


func build_menu() -> void:
	for child in menu.get_children():
		child.queue_free()
	for i in options.size():
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = ("▶ " if i == index else "  ") + options[i]
		label.add_theme_color_override("font_color", Color(1, 0.88, 0.45) if i == index else Color(0.85, 0.87, 1.0))
		menu.add_child(label)
