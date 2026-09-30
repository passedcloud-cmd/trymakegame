extends Area2D
## 보스가 벽에 부딪히면 천장에서 떨어지는 돌이에요.
## 떨어지기 전에 바닥에 빨간 표시가 깜빡여요. 표시를 보고 피해요!

## 바닥 높이 (표시를 그릴 곳)
var floor_y := 0.0
## 떨어지기 전에 기다리는 시간 (초)
var delay := 0.6
var fall_speed := 0.0

@onready var marker: Sprite2D = $Marker


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	marker.global_position = Vector2(global_position.x, floor_y - 1)
	monitoring = false


func _physics_process(delta: float) -> void:
	if Dialogue.is_busy():
		return
	if delay > 0.0:
		delay -= delta
		marker.visible = int(delay * 12.0) % 2 == 0
		$Sprite2D.position.x = randf_range(-1, 1)
		if delay <= 0.0:
			monitoring = true
		return
	marker.visible = true
	fall_speed = minf(fall_speed + 900.0 * delta, 400.0)
	position.y += fall_speed * delta
	marker.global_position.y = floor_y - 1


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(1, global_position.x)
	elif body.is_in_group("enemy"):
		return
	Sound.play("land", 2.0, 0.6)
	Effects.burst(get_parent(), global_position, Color(0.6, 0.55, 0.5), 8, 80.0)
	queue_free()
