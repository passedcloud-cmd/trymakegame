extends Area2D
## 가시벌과 보스가 쏘는 침 구슬이에요. 곧게 날아가다가 벽이나 기사에 닿으면 터져요.

## 날아가는 방향과 빠르기 (쏘는 쪽에서 정해줘요)
var velocity := Vector2.ZERO
var life := 4.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if Dialogue.is_busy():
		return
	position += velocity * delta
	life -= delta
	$Sprite2D.frame = int(life * 10.0) % 2
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(1, global_position.x)
	pop()


func pop() -> void:
	Effects.burst(get_parent(), global_position, Color(1, 0.6, 0.3), 5, 50.0, 0.2)
	queue_free()
