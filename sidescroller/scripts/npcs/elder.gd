extends NPC
## 촌장 할아버지: 이야기를 들려주고, 어디로 가면 좋을지 알려줘요.


func talk() -> void:
	if not GameState.flags.get("met_elder", false):
		GameState.flags["met_elder"] = true
		GameState.save_game()
		Dialogue.start(npc_name, [
			"오, 작은 기사여! 마침 잘 와 주었네.",
			"요즘 숲에 사나운 벌레들이 잔뜩 몰려와서, 마을 사람들이 숲에 들어가지 못하고 있다네.",
			"마을 오른쪽 끝에 있는 '숲으로 가는 문'으로 가면 숲에 들어갈 수 있어.",
			"숲의 구역마다 벌레를 모두 물리쳐야 그 구역을 되찾을 수 있지.",
			"벌레를 물리치면 '빛조각'이 떨어진다네. 대장장이와 약초상에게 가져가 보게나.",
		])
		return

	match GameState.cleared.size():
		0:
			Dialogue.start(npc_name, [
				"첫 번째 구역은 '이끼 숲길'이라네.",
				"벌레의 공격은 미리 티가 나. 눈이 빨개지거나 몸이 반짝이면 곧 공격한다는 뜻이지.",
			])
		1:
			Dialogue.start(npc_name, [
				"이끼 숲길을 되찾았다니, 대단하구먼!",
				"다음은 '푸른 동굴'이야. 날아다니며 침을 쏘는 가시벌이 산다고 하더군.",
			])
		2:
			Dialogue.start(npc_name, [
				"이제 남은 곳은 '투구벌레 둥지'뿐이네.",
				"그곳의 대장은 아주 단단하고 힘이 세. 검을 강화하고 체력을 늘린 뒤에 가게.",
			])
		_:
			Dialogue.start(npc_name, [
				"자네 덕분에 숲에 평화가 돌아왔어. 정말 고맙네, 작은 기사여.",
				"숲에는 아직 벌레가 조금 남아 있을지도 몰라. 수련하고 싶으면 언제든 다시 가 보게.",
			])
