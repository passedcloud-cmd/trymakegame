extends Area2D
## 그림자 곰이 쏘는 그림자 구슬이에요. 코랄에게 닿으면 하트 1칸이 줄어요.

var velocity := Vector2.ZERO
var life := 5.0


func _ready() -> void:
	add_to_group("boss_attack")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if Dialogue.is_busy():
		return
	position += velocity * delta
	rotation += delta * 6.0
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		return  # 곰이나 슬라임은 그냥 지나가요.
	if body.is_in_group("player"):
		body.take_damage(1, global_position)
	queue_free()  # 벽에 부딪혀도 사라져요.
