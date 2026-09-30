extends Area2D
## 도토리: 코랄이 닿으면 주워요.

var time := 0.0


func _ready() -> void:
	# 이미 주운 도토리면 사라져요. (코랄이 쓰러졌다 깨어나도 다시 생기지 않게)
	if GameState.flags.get(pickup_key(), false):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	time = randf() * TAU


func _process(delta: float) -> void:
	# 둥실둥실 떠 있어요.
	time += delta
	$Sprite2D.position.y = round(sin(time * 3.0) * 1.5)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.acorns += 1
		GameState.flags[pickup_key()] = true
		queue_free()


# 도토리마다 다른 이름표 (맵 안의 위치로 구분해요)
func pickup_key() -> String:
	return "acorn_%d_%d" % [int(position.x), int(position.y)]
