extends NPC
## 약초상: 빛조각을 받고 튼튼해지는 약초를 줘요. (최대 체력 +1)

## 약초 값. [첫 번째, 두 번째]
const COSTS := [40, 90]


func talk() -> void:
	var bought := GameState.bonus_hp
	if bought >= COSTS.size():
		Dialogue.start(npc_name, [
			"미안해요, 튼튼 약초는 다 떨어졌어요.",
			"대신 마을에 오면 체력은 언제나 가득 채워 드릴게요!",
		])
		return

	var cost: int = COSTS[bought]
	var question := "튼튼 약초를 먹으면 가면이 하나 늘어나요. 빛조각 %d개예요. (지금 %d개)" % [cost, GameState.shards]
	var answer := await Dialogue.ask(npc_name, question, ["살래요", "안 살래요"])
	if answer != 0:
		Dialogue.start(npc_name, ["필요하면 또 오세요!"])
		return
	if GameState.shards < cost:
		Sound.play("no")
		Dialogue.start(npc_name, ["어머, 빛조각이 조금 모자라요."])
		return

	GameState.shards -= cost
	GameState.bonus_hp += 1
	GameState.save_game()
	Sound.play("upgrade")
	# 늘어난 체력을 바로 채워 줘요.
	var player := get_player()
	player.max_hp = GameState.max_hp()
	player.heal(player.max_hp)
	Dialogue.start(npc_name, [
		"냠냠... 몸이 튼튼해진 게 느껴지죠?",
		"(최대 체력이 %d칸이 되었어요!)" % GameState.max_hp(),
	])
