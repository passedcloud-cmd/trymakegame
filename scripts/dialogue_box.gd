extends CanvasLayer
## 화면 아래에 뜨는 대화창이에요.
## 게임 어디서든 Dialogue.start("이름", ["첫 번째 대사", "두 번째 대사"])로 열 수 있어요.

## 대화가 모두 끝나면 알려주는 신호예요.
signal finished

## 글자가 1초에 몇 개씩 나타날지 정해요.
@export var chars_per_second: float = 30.0

@onready var name_label: Label = $NamePanel/NameLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var next_arrow: Label = $Panel/NextArrow

## 대화창이 열려 있는지 알려줘요. (열려 있으면 코랄이 못 움직여요)
var is_open := false

var lines: Array = []
var line_index := 0
var shown_chars := 0.0
var arrow_time := 0.0


func _ready() -> void:
	hide()


## 대화를 시작해요. speaker는 말하는 캐릭터 이름, new_lines는 대사 목록이에요.
func start(speaker: String, new_lines: Array) -> void:
	if new_lines.is_empty():
		return
	lines = new_lines
	line_index = 0
	name_label.text = speaker
	is_open = true
	show()
	show_line()


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
		arrow_time += delta
		next_arrow.visible = int(arrow_time * 2.0) % 2 == 0


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()

	if is_typing():
		# 글자가 나오는 중에 누르면 한 번에 다 보여줘요.
		text_label.visible_characters = text_label.get_total_character_count()
		return

	line_index += 1
	if line_index < lines.size():
		show_line()
	else:
		close()


func close() -> void:
	is_open = false
	hide()
	finished.emit()
