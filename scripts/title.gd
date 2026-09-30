extends Control
## 타이틀 화면: 이어하기 / 처음부터 / 조작법을 골라요.

const FIRST_MAP := "res://scenes/main.tscn"
const SHOOTING_STAR := preload("res://assets/title/shooting_star.png")

@onready var menu: VBoxContainer = $Menu
@onready var controls_panel: Panel = $ControlsPanel
@onready var confirm_label: Label = $Confirm
@onready var coral: Sprite2D = $Coral

var options: Array[String] = []
var index := 0
var waiting_confirm := false   # "정말 처음부터?"를 묻는 중
var started := false
var time := 0.0
var next_shooting_star := 1.0


func _ready() -> void:
	Sound.play_music("village")
	controls_panel.hide()
	confirm_label.hide()
	if GameState.has_save():
		options.append("이어하기")
	options.append_array(["처음부터", "조작법"])
	build_menu()


func build_menu() -> void:
	for child in menu.get_children():
		child.queue_free()
	for i in options.size():
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = ("▶ " if i == index else "  ") + options[i]
		label.add_theme_color_override("font_color", Color(1, 0.88, 0.45) if i == index else Color(0.78, 0.8, 0.95))
		label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.14))
		label.add_theme_constant_override("outline_size", 3)
		menu.add_child(label)


func _process(delta: float) -> void:
	time += delta
	# 코랄이 숨 쉬듯 살짝 들썩이고, 가끔 꼬리를 흔들어요.
	coral.position.y = 128 + (1 if int(time * 1.5) % 2 == 0 else 0)
	# 가끔 별똥별이 떨어져요.
	next_shooting_star -= delta
	if next_shooting_star <= 0.0:
		next_shooting_star = randf_range(1.5, 3.5)
		spawn_shooting_star()


func spawn_shooting_star() -> void:
	var star := Sprite2D.new()
	star.texture = SHOOTING_STAR
	var start := Vector2(randf_range(40, 300), randf_range(4, 50))
	var direction := Vector2(-1, 0.45).normalized()
	star.position = start
	star.rotation = direction.angle() + PI  # 꼬리가 뒤쪽으로 오게
	star.modulate.a = 0.0
	$Sky.add_child(star)
	var tween := star.create_tween().set_parallel()
	tween.tween_property(star, "position", start + direction * 90.0, 0.8)
	tween.tween_property(star, "modulate:a", 1.0, 0.15)
	tween.tween_property(star, "modulate:a", 0.0, 0.4).set_delay(0.4)
	tween.chain().tween_callback(star.queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if started:
		return

	# 조작법 창이 열려 있으면 아무 키나 누르면 닫혀요.
	if controls_panel.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("ui_cancel"):
			controls_panel.hide()
			Sound.play("cursor", 0.0, 1.0, 0.0)
			get_viewport().set_input_as_handled()
		return

	# "정말 처음부터 시작할까요?" 대답 기다리기
	if waiting_confirm:
		if event.is_action_pressed("interact"):
			GameState.delete_save()
			start_new_game()
		elif event.is_action_pressed("attack") or event.is_action_pressed("ui_cancel"):
			waiting_confirm = false
			confirm_label.hide()
			menu.show()
			Sound.play("cursor", 0.0, 1.0, 0.0)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		index = wrapi(index + (-1 if event.is_action_pressed("ui_up") else 1), 0, options.size())
		Sound.play("cursor", 0.0, 1.0, 0.0)
		build_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		choose(options[index])


func choose(option: String) -> void:
	match option:
		"이어하기":
			var save := GameState.load_game()
			if save.is_empty():
				start_new_game()
				return
			start(save.scene, save.spawn)
		"처음부터":
			if GameState.has_save():
				# 저장된 기록이 있으면 한 번 더 물어봐요.
				waiting_confirm = true
				menu.hide()
				confirm_label.show()
				Sound.play("cursor", 0.0, 1.0, 0.0)
			else:
				start_new_game()
		"조작법":
			controls_panel.show()
			Sound.play("select", 0.0, 1.0, 0.0)


func start_new_game() -> void:
	GameState.reset()
	start(FIRST_MAP, "")


func start(scene_path: String, spawn: String) -> void:
	started = true
	Sound.play("select", 0.0, 1.0, 0.0)
	Transition.go(scene_path, spawn)
