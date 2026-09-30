extends NPC
## 아기 토끼: 길을 잃고 숲에 있어요. 말을 걸면 마을로 돌아가요.

## 찾은 뒤에 서 있을 자리 (언니 토끼 옆)
@export var home_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	super()
	if GameState.flags.get("baby_found", false):
		position = home_position


func talk() -> void:
	if GameState.flags.get("baby_found", false):
		Dialogue.start(npc_name, ["코랄 최고! 나도 크면 꼬리 휘두르기 배울 거야!"])
		return

	Dialogue.start(npc_name, [
		"훌쩍... 별똥별을 따라왔다가 길을 잃었어...",
		"그림자가 무서워서 한 발짝도 못 움직이겠어...",
		"(코랄이 아기 토끼를 마을까지 데려다 주었다.)",
	])
	await Dialogue.finished
	GameState.flags["baby_found"] = true
	position = home_position
