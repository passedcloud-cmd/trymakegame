extends Area2D
## 도토리: 코랄이 닿으면 주워요.

var time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	time = randf() * TAU


func _process(delta: float) -> void:
	# 둥실둥실 떠 있어요.
	time += delta
	$Sprite2D.position.y = round(sin(time * 3.0) * 1.5)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.acorns += 1
		queue_free()
