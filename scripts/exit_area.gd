extends Area2D
## 코랄이 닿으면 다른 맵으로 이동하는 출구예요.

## 이동할 맵 (장면 파일)
@export_file("*.tscn") var target_scene: String = ""
## 이동한 맵에서 코랄이 설 출발 지점 이름
@export var target_spawn: String = ""

var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if used or not body.is_in_group("player"):
		return
	used = true
	Transition.go(target_scene, target_spawn)
