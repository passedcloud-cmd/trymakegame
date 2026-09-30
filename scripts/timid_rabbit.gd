extends NPC
## 겁많은 토끼: 잃어버린 동생을 찾아달라고 부탁해요. (서브 퀘스트)


func talk() -> void:
	if not GameState.flags.get("baby_found", false):
		Dialogue.start(npc_name, [
			"히익! 아, 코랄이구나... 깜짝 놀랐잖아.",
			"저기... 내 동생이 어젯밤에 별똥별을 쫓아 나갔다가 아직 안 돌아왔어.",
			"나는 무서워서 멀리 못 가겠어... 혹시 동생을 보면 데려와 줄래?",
		])
	elif not GameState.flags.get("rabbit_rewarded", false):
		# 보상: 최대 체력 하트 1칸 증가
		GameState.flags["rabbit_rewarded"] = true
		GameState.bonus_hearts += 1
		get_player().increase_max_hp(1)
		Dialogue.start(npc_name, [
			"동생아! 무사했구나...! 흑흑.",
			"코랄, 정말 고마워. 이건 우리 집에 내려오는 행운의 네잎클로버야.",
			"(최대 체력이 하트 1칸 늘었다!)",
		])
	else:
		Dialogue.start(npc_name, ["동생이 하루 종일 코랄 얘기만 해.", "나도... 조금은 용감해져 볼게!"])
