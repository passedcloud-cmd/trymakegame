extends Area2D
## 떨어진 별: 코랄이 주우면 새 능력을 얻어요.

## 몇 번째 별인지 (1, 2, 3)
@export var star_number: int = 1
## 주웠을 때 나오는 대사
@export var pickup_lines: Array[String] = []

var time := 0.0


func _ready() -> void:
	# 이미 주운 별이면 사라져요.
	if GameState.flags.get("star%d_found" % star_number, false):
		queue_free()
		return
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# 둥실둥실 떠 있고, 반짝반짝해요.
	time += delta
	$Sprite2D.position.y = round(sin(time * 2.5) * 2.0) - 4
	$Sprite2D.frame = int(time * 3.0) % 2


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.flags["star%d_found" % star_number] = true
	if star_number == 1:
		GameState.flags["has_dash"] = true
	set_deferred("monitoring", false)
	hide()
	Dialogue.start("★ 별", pickup_lines)
	await Dialogue.finished
	queue_free()
