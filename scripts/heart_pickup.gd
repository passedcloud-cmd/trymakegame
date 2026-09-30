extends Area2D
## 빛나는 버섯: 먹으면 최대 체력이 하트 1칸 늘어요. (한 번만)

## 대화창 이름표에 나올 이름
@export var speaker: String = "빛나는 버섯"
@export var pickup_lines: Array[String] = []

var time := 0.0


func _ready() -> void:
	if GameState.flags.get(flag_key(), false):
		queue_free()
		return
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	time += delta
	$Sprite2D.position.y = round(sin(time * 2.0) * 1.5) - 4


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.flags[flag_key()] = true
	GameState.bonus_hearts += 1
	body.increase_max_hp(1)
	set_deferred("monitoring", false)
	hide()
	Dialogue.start(speaker, pickup_lines)
	await Dialogue.finished
	queue_free()


func flag_key() -> String:
	return "heart_%s_%d_%d" % [get_tree().current_scene.name, int(position.x), int(position.y)]
