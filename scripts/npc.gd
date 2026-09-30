extends StaticBody2D
## 말을 걸 수 있는 NPC예요.
## 코랄이 가까이 오면 머리 위에 말풍선이 뜨고, Z(또는 스페이스, 엔터)를 누르면 대화해요.

## 대화창에 나올 이름
@export var npc_name: String = "NPC"
## 대사 목록. 한 칸이 대화창 한 장이에요.
@export var lines: Array[String] = []
## 몇 초마다 눈을 깜빡일지 정해요. (그림이 2칸 이상일 때만)
@export var blink_interval: float = 3.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var talk_icon: Sprite2D = $TalkIcon

var player_nearby := false
var time := 0.0


func _ready() -> void:
	talk_icon.hide()
	$TalkArea.body_entered.connect(_on_body_entered)
	$TalkArea.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	time += delta

	# 말풍선은 코랄이 가까이 있고, 대화 중이 아닐 때만 보여요. 위아래로 살짝 흔들려요.
	talk_icon.visible = player_nearby and not Dialogue.is_open
	talk_icon.position.y = -16 + round(sin(time * 4.0))

	# 가끔 눈을 깜빡여요.
	if sprite.hframes >= 2:
		sprite.frame = 1 if fmod(time, blink_interval) > blink_interval - 0.15 else 0


func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and not Dialogue.is_open and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		Dialogue.start(npc_name, lines)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
