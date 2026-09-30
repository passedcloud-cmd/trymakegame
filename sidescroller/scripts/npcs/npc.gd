class_name NPC
extends Area2D
## 말을 걸 수 있는 NPC예요.
## 기사가 가까이 오면 머리 위에 말풍선이 뜨고, ↑ 키를 누르면 대화해요.
## 특별한 행동을 하는 NPC는 이 스크립트를 이어받아서(extends NPC) talk()만 새로 쓰면 돼요.

## 대화창에 나올 이름
@export var npc_name: String = "NPC"
## 대사 목록. 한 칸이 대화창 한 장이에요.
@export var lines: Array[String] = []
## 몇 초마다 눈을 깜빡일지 정해요. (그림이 2칸일 때)
@export var blink_interval: float = 3.0
## 0보다 크면 눈 깜빡임 대신 그림 칸을 1초에 이만큼씩 넘겨요. (문처럼 계속 움직이는 것)
@export var animate_fps: float = 0.0
## 말풍선 높이 (발끝에서 위로 몇 픽셀)
@export var icon_height: float = 32.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var talk_icon: Sprite2D = $TalkIcon

var player_nearby := false
var time := 0.0


func _ready() -> void:
	add_to_group("npc")
	talk_icon.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	time = randf() * 3.0


func _process(delta: float) -> void:
	time += delta

	# 말풍선은 기사가 가까이 있고, 대화 중이 아닐 때만 보여요. 위아래로 살짝 흔들려요.
	talk_icon.visible = is_talk_target() and not Dialogue.is_busy()
	talk_icon.position.y = -icon_height + round(sin(time * 4.0))

	if animate_fps > 0.0:
		sprite.frame = int(time * animate_fps) % sprite.hframes
	elif sprite.hframes >= 2:
		sprite.frame = 1 if fmod(time, blink_interval) > blink_interval - 0.15 else 0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") and is_talk_target() and not Dialogue.is_busy():
		var player := get_player()
		if player.is_on_floor():
			get_viewport().set_input_as_handled()
			talk()


## 기사 근처에 NPC가 여럿 있으면 가장 가까운 NPC 하나만 대화 상대가 돼요.
func is_talk_target() -> bool:
	if not player_nearby:
		return false
	var player := get_player()
	if player == null or player.is_dead:
		return false
	var my_distance := global_position.distance_to(player.global_position)
	for other in get_tree().get_nodes_in_group("npc"):
		if other != self and other.player_nearby \
				and other.global_position.distance_to(player.global_position) < my_distance:
			return false
	return true


## 말을 걸었을 때 하는 일이에요. 기본은 lines에 적힌 대사를 보여줘요.
func talk() -> void:
	Dialogue.start(npc_name, lines)


func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
