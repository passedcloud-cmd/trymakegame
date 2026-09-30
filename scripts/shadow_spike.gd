extends Node2D
## 그림자 가시: 먼저 경고 동그라미가 나타나고, 잠시 뒤 가시가 솟아올라요.

## 경고 동그라미가 보이는 시간 (초)
@export var warning_time: float = 0.8
## 가시가 솟아 있는 시간 (초)
@export var active_time: float = 0.35
## 이 거리(픽셀) 안에 있으면 가시에 찔려요.
@export var hit_radius: float = 11.0

var time := 0.0


func _ready() -> void:
	add_to_group("boss_attack")
	$Sprite2D.frame = 0


func _physics_process(delta: float) -> void:
	if Dialogue.is_busy():
		return
	time += delta
	if time < warning_time:
		# 경고 동그라미가 깜빡여요.
		$Sprite2D.modulate.a = 0.5 + 0.5 * sin(time * 20.0)
		return
	$Sprite2D.frame = 1
	$Sprite2D.modulate.a = 1.0
	if time < warning_time + active_time:
		var player := get_tree().get_first_node_in_group("player")
		# 코랄의 발 위치로 거리를 재요.
		if player and (player.global_position + Vector2(0, 4)).distance_to(global_position) < hit_radius:
			player.take_damage(1, global_position)
	else:
		queue_free()
