extends NPC
## 대장장이: 빛조각을 받고 검을 강화해 줘요. (공격력이 올라가요)

## 강화 값. [1→2레벨, 2→3레벨]
const COSTS := [30, 70]


func talk() -> void:
	var level := GameState.sword_level
	if level >= GameState.SWORD_DAMAGE.size():
		Dialogue.start(npc_name, [
			"자네 검은 이미 최고로 날카롭다네!",
			"그 검이면 어떤 껍질도 뚫을 수 있지. 허허!",
		])
		return

	var cost: int = COSTS[level - 1]
	var question := "검을 강화해 줄까? 빛조각 %d개면 된다네. (지금 %d개)" % [cost, GameState.shards]
	var answer := await Dialogue.ask(npc_name, question, ["강화한다", "그만둔다"])
	if answer != 0:
		Dialogue.start(npc_name, ["언제든 다시 오게."])
		return
	if GameState.shards < cost:
		Sound.play("no")
		Dialogue.start(npc_name, ["빛조각이 모자라군. 숲에서 벌레를 더 물리치고 오게나."])
		return

	var before := GameState.attack_damage()
	GameState.shards -= cost
	GameState.sword_level += 1
	GameState.save_game()
	Sound.play("upgrade")
	Dialogue.start(npc_name, [
		"탕! 탕! 탕!",
		"자, 검이 더 날카로워졌네! (공격력 %d → %d)" % [before, GameState.attack_damage()],
	])
