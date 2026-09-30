extends NPC
## 아기 곰: 그림자 곰의 굴에서 구한 뒤로 마을에서 지내요.


func _ready() -> void:
	super()
	# 아직 구하지 않았으면 마을에 없어요.
	if not GameState.flags.get("bear_saved", false):
		queue_free()


func talk() -> void:
	if GameState.flags.get("ending_seen", false):
		Dialogue.start(npc_name, [
			"여우야! 이 마을 사람들은 다 친절해!",
			"너구리 아저씨가 도토리 세는 법도 알려 줬어. 하나, 둘, 셋... 헤헤.",
		])
	else:
		Dialogue.start(npc_name, [
			"여우야, 나 마을에 먼저 와 있었어!",
			"어서 부엉이 할아버지께 별을 가져다드려!",
		])
