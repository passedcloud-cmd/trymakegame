extends Node2D
## 엔딩 화면이에요. 글자가 아래에서 위로 천천히 올라가요.
## 다 올라가거나 Z를 누르면 마을로 돌아가요.

@onready var credits: Label = $UI/Credits

var time := 0.0
var leaving := false


func _ready() -> void:
	Sound.play_music("ending")
	credits.text = credits.text.replace("{shards}", str(GameState.shards)) \
		.replace("{sword}", str(GameState.sword_level)) \
		.replace("{hp}", str(GameState.max_hp()))
	credits.position.y = 180.0


func _process(delta: float) -> void:
	time += delta
	credits.position.y -= 14.0 * delta
	if credits.position.y < -credits.size.y - 10.0:
		leave()


func _unhandled_input(event: InputEvent) -> void:
	if time > 2.0 and event.is_action_pressed("confirm"):
		leave()


func leave() -> void:
	if leaving:
		return
	leaving = true
	Transition.go(GameState.VILLAGE_SCENE)
