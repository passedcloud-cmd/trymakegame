extends CanvasLayer
## 화면 아래에 뜨는 대화창이에요.
## 게임 어디서든 Dialogue.start("이름", ["첫 번째 대사", "두 번째 대사"])로 열 수 있어요.

## 대화가 모두 끝나면 알려주는 신호예요.
signal finished
## 선택지에서 고른 번호를 알려주는 신호예요. (0부터 세요)
signal choice_made(index: int)

## 글자가 1초에 몇 개씩 나타날지 정해요.
@export var chars_per_second: float = 30.0

@onready var name_panel: Panel = $NamePanel
@onready var name_label: Label = $NamePanel/NameLabel
@onready var choice_panel: Panel = $ChoicePanel
@onready var choice_label: Label = $ChoicePanel/ChoiceLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var next_arrow: Label = $Panel/NextArrow

## 대화창이 열려 있는지 알려줘요. (열려 있으면 코랄이 못 움직여요)
var is_open := false
## 연출(컷신) 중이면 true. 대화창이 닫혀 있어도 코랄과 몬스터가 멈춰요.
var cutscene := false

var lines: Array = []
var line_index := 0
var shown_chars := 0.0
var arrow_time := 0.0
var choices: Array = []
var choice_index := 0


## 대화나 연출 중이라 모두 멈춰야 하면 true를 돌려줘요.
func is_busy() -> bool:
	return is_open or cutscene


func _ready() -> void:
	hide()
	choice_panel.hide()


## 대화를 시작해요. speaker는 말하는 캐릭터 이름, new_lines는 대사 목록이에요.
func start(speaker: String, new_lines: Array) -> void:
	if new_lines.is_empty():
		return
	lines = new_lines
	line_index = 0
	choices = []
	name_label.text = speaker
	# 이름 길이에 맞춰 이름표 너비를 바꿔요.
	name_panel.size.x = text_width(name_label, speaker) + 12
	is_open = true
	show()
	show_line()


## 질문을 하고 선택지를 보여줘요. 고른 번호(0부터)를 돌려줘요.
## 사용 예: var answer = await Dialogue.ask("너구리", "살래?", ["응", "아니"])
func ask(speaker: String, question: String, options: Array) -> int:
	start(speaker, [question])
	choices = options
	choice_index = 0
	return await choice_made


func text_width(label: Label, text: String) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	return ceilf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)


# 선택지 창을 그려요. 지금 고른 줄 앞에 ▶ 표시가 붙어요.
func show_choices() -> void:
	var text_lines := []
	var widest := 0.0
	for i in choices.size():
		var line: String = ("▶ " if i == choice_index else "   ") + choices[i]
		text_lines.append(line)
		widest = maxf(widest, text_width(choice_label, "▶ " + choices[i]))
	choice_label.text = "\n".join(text_lines)

	var font := choice_label.get_theme_font("font")
	var line_height := font.get_height(choice_label.get_theme_font_size("font_size"))
	choice_panel.size = Vector2(widest + 16, line_height * choices.size() + 8)
	# 대화창 오른쪽 위에 붙여요.
	choice_panel.position = Vector2(312 - choice_panel.size.x, 129 - choice_panel.size.y)
	choice_panel.show()


# 지금 순서의 대사를 처음부터 한 글자씩 보여주기 시작해요.
func show_line() -> void:
	text_label.text = wrap_by_words(lines[line_index])
	shown_chars = 0.0
	text_label.visible_characters = 0
	next_arrow.hide()


# Godot은 한글을 글자 단위로 줄바꿈해서 "몬 / 스터"처럼 단어가 잘릴 수 있어요.
# 그래서 띄어쓰기 단위로 직접 줄을 나눠요.
func wrap_by_words(text: String) -> String:
	var font := text_label.get_theme_font("font")
	var font_size := text_label.get_theme_font_size("font_size")
	var max_width := text_label.size.x
	var result := ""
	var line := ""
	for word in text.split(" "):
		var candidate: String = word if line.is_empty() else line + " " + word
		var width := font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if width > max_width and not line.is_empty():
			result += line + "\n"
			line = word
		else:
			line = candidate
	return result + line


func is_typing() -> bool:
	return text_label.visible_characters < text_label.get_total_character_count()


func _process(delta: float) -> void:
	if not is_open:
		return

	if is_typing():
		# 타자 치듯 글자를 조금씩 늘려요.
		shown_chars += chars_per_second * delta
		text_label.visible_characters = int(shown_chars)
	else:
		# 다 나오면 ▼ 표시를 깜빡여서 "다음"을 알려줘요.
		if not choices.is_empty():
			# 선택지가 있으면 ▼ 대신 선택지 창을 보여줘요.
			if not choice_panel.visible:
				show_choices()
			return
		arrow_time += delta
		next_arrow.visible = int(arrow_time * 2.0) % 2 == 0


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	# 선택지 창이 떠 있으면 위/아래로 고르고, Z로 결정해요.
	if choice_panel.visible:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			var step := -1 if event.is_action_pressed("ui_up") else 1
			choice_index = wrapi(choice_index + step, 0, choices.size())
			show_choices()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			var picked := choice_index
			choices = []
			choice_panel.hide()
			close()
			choice_made.emit(picked)
		return

	if not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()

	if is_typing():
		# 글자가 나오는 중에 누르면 한 번에 다 보여줘요.
		text_label.visible_characters = text_label.get_total_character_count()
		return

	# 선택지가 남아 있으면 넘기지 않고 선택지를 보여줘요.
	if not choices.is_empty():
		show_choices()
		return

	line_index += 1
	if line_index < lines.size():
		show_line()
	else:
		close()


func close() -> void:
	is_open = false
	choice_panel.hide()
	hide()
	finished.emit()
