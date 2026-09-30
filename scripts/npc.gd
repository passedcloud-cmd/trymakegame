class_name NPC
extends StaticBody2D
## 말을 걸 수 있는 NPC예요.
## 코랄이 가까이 오면 머리 위에 말풍선이 뜨고, Z(또는 스페이스, 엔터)를 누르면 대화해요.
## 특별한 행동을 하는 NPC는 이 스크립트를 이어받아서(extends NPC) talk()만 새로 쓰면 돼요.

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
	add_to_group("npc")
	talk_icon.hide()
	$TalkArea.body_entered.connect(_on_body_entered)
	$TalkArea.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	time += delta

	# 말풍선은 코랄이 가까이 있고, 대화 중이 아닐 때만 보여요. 위아래로 살짝 흔들려요.
	talk_icon.visible = is_talk_target() and not Dialogue.is_busy()
	talk_icon.position.y = -16 + round(sin(time * 4.0))

	# 가끔 눈을 깜빡여요.
	if sprite.hframes >= 2:
		sprite.frame = 1 if fmod(time, blink_interval) > blink_interval - 0.15 else 0


func _unhandled_input(event: InputEvent) -> void:
	if is_talk_target() and not Dialogue.is_busy() and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		talk()


## 코랄 근처에 NPC가 여럿 있으면 가장 가까운 NPC 하나만 대화 상대가 돼요.
func is_talk_target() -> bool:
	if not player_nearby:
		return false
	var player_pos: Vector2 = get_player().global_position
	var my_distance := global_position.distance_to(player_pos)
	for other in get_tree().get_nodes_in_group("npc"):
		if other != self and other.player_nearby \
				and other.global_position.distance_to(player_pos) < my_distance:
			return false
	return true


## 말을 걸었을 때 하는 일이에요. 기본은 lines에 적힌 대사를 보여줘요.
func talk() -> void:
	Dialogue.start(npc_name, lines)


## 코랄을 찾아줘요.
func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
