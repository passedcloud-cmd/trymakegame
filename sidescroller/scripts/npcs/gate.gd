extends NPC
## 숲으로 가는 문: 갈 스테이지를 골라요. 앞 스테이지를 깨야 다음 스테이지가 열려요.


func talk() -> void:
	var options: Array = []
	var stage_numbers: Array = []
	for i in GameState.STAGES.size():
		var number := i + 1
		if GameState.is_unlocked(number):
			var mark := " ★" if GameState.is_cleared(number) else ""
			options.append("%d. %s%s" % [number, GameState.STAGES[i].name, mark])
			stage_numbers.append(number)
	options.append("그만두기")

	var answer := await Dialogue.ask(npc_name, "문 너머로 숲이 보여요. 어디로 갈까요?", options)
	if answer >= stage_numbers.size():
		return
	Sound.play("select")
	Transition.go(GameState.STAGES[stage_numbers[answer] - 1].scene)
