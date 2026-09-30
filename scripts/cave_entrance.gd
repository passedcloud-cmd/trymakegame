extends NPC
## 캄캄한 동굴 입구: 반딧불이 병이 있으면 안으로 들어갈 수 있어요.

@export_file("*.tscn") var cave_scene: String = "res://scenes/cave.tscn"


func talk() -> void:
	if not GameState.has_jar():
		var hint: Array[String] = lines.duplicate()
		if GameState.flags.get("star1_returned", false):
			hint.append("(거북이 할머니라면 빛을 구할 방법을 알고 계실지도...)")
		Dialogue.start(npc_name, hint)
		return

	var answer := await Dialogue.ask(npc_name, "반딧불이 병을 꺼내 들었다. 동굴 안으로 들어갈까?", ["들어간다", "그만둔다"])
	if answer == 0:
		Transition.go(cave_scene, "Entrance")
