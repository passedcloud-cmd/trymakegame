extends CanvasLayer
## 화면 왼쪽 위에 코랄의 체력을 하트로 보여줘요.

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

@onready var hearts: HBoxContainer = $Hearts


func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(update_hearts)
		update_hearts(player.hp, player.max_hp)


func update_hearts(hp: int, max_hp: int) -> void:
	# 하트를 전부 지우고 체력만큼 다시 그려요.
	for child in hearts.get_children():
		child.queue_free()
	for i in max_hp:
		var heart := TextureRect.new()
		heart.texture = heart_full if i < hp else heart_empty
		hearts.add_child(heart)
