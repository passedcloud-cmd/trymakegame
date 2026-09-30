extends Node2D
## 타이틀 화면이에요. 이어하기 / 처음부터 / 조작법 중에서 골라요.

@onready var menu: VBoxContainer = $UI/Menu
@onready var controls: Control = $UI/Controls
@onready var knight: Sprite2D = $Knight
@onready var hint: Label = $UI/Hint

var options: Array[String] = []
var index := 0
var mode := "main"   # main: 첫 메뉴, confirm: 처음부터 할지 확인, controls: 조작법 보기
var time := 0.0


func _ready() -> void:
	Sound.play_music("village")
	controls.hide()
	show_main()


func _process(delta: float) -> void:
	time += delta
	knight.frame = int(time * 2.0) % 2


func show_main() -> void:
	mode = "main"
	options = []
	if GameState.has_save():
		options.append("이어하기")
	options.append_array(["처음부터", "조작법"])
	index = 0
	build_menu()


func _unhandled_input(event: InputEvent) -> void:
	if Transition.busy:
		return
	if mode == "controls":
		if event.is_action_pressed("confirm") or event.is_action_pressed("pause"):
			Sound.play("cursor", 0.0, 1.0, 0.0)
			controls.hide()
			menu.show()
			hint.text = "↑↓ 고르기   Z 결정"
			show_main()
		return

	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		index = wrapi(index + (-1 if event.is_action_pressed("move_up") else 1), 0, options.size())
		Sound.play("cursor", 0.0, 1.0, 0.0)
		build_menu()
	elif event.is_action_pressed("confirm"):
		Sound.play("select", 0.0, 1.0, 0.0)
		choose(options[index])


func choose(option: String) -> void:
	match option:
		"이어하기":
			GameState.load_game()
			Transition.go(GameState.VILLAGE_SCENE)
		"처음부터":
			if GameState.has_save():
				# 저장 기록이 있으면 한 번 더 물어봐요.
				mode = "confirm"
				options = ["네, 처음부터 할래요", "아니요"]
				index = 1
				build_menu()
			else:
				start_new_game()
		"네, 처음부터 할래요":
			start_new_game()
		"아니요":
			show_main()
		"조작법":
			mode = "controls"
			menu.hide()
			hint.text = "Z 돌아가기"
			controls.show()


func start_new_game() -> void:
	GameState.new_game()
	Transition.go(GameState.VILLAGE_SCENE)


func build_menu() -> void:
	for child in menu.get_children():
		child.queue_free()
	if mode == "confirm":
		var warn := Label.new()
		warn.text = "저장 기록이 지워져요. 괜찮아요?"
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warn.add_theme_color_override("font_color", Color(1, 0.7, 0.7))
		menu.add_child(warn)
	for i in options.size():
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = ("▶ " if i == index else "  ") + options[i]
		label.add_theme_color_override("font_color", Color(1, 0.88, 0.45) if i == index else Color(0.92, 0.94, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0.05, 0.05, 0.1))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		menu.add_child(label)
