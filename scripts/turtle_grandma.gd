extends NPC
## 거북이 할머니: 말을 걸 때마다 다른 옛날이야기를 들려줘요.

## 이야기 목록. 한 번 말을 걸 때마다 다음 이야기를 들려줘요. (끝나면 처음부터)
const STORIES := [
	[
		"오냐, 코랄이구나. 이 할미 옛날이야기 좀 들어 보련?",
		"옛날 옛적, 하늘의 별들은 이 숲을 지켜 주는 수호신이었단다.",
		"별빛이 닿는 곳에는 그림자가 얼씬도 못 했지.",
	],
	[
		"별에는 저마다 힘이 깃들어 있다는구나.",
		"하나는 바람처럼 빠르게, 하나는 어둠을 환하게...",
		"마지막 하나는... 허허, 이 할미도 잊어버렸구나.",
	],
	[
		"그림자 곰 이야기를 들어 봤니?",
		"깊은 숲에 사는 커다란 그림자인데, 반짝이는 걸 무척 좋아한단다.",
		"별 하나쯤은 그 녀석이 품고 있을지도 모르겠구나. 조심하렴.",
	],
]

var story_index := 0


func talk() -> void:
	# 첫 번째 별을 돌려보낸 뒤에는 동굴에 들고 갈 반딧불이 병을 줘요.
	if GameState.flags.get("star1_returned", false) and not GameState.has_jar():
		GameState.flags["has_jar"] = true
		get_player().update_light(true)
		Dialogue.start(npc_name, [
			"오, 코랄. 강 건너 캄캄한 동굴에 가려는 게냐?",
			"그 동굴은 빛 없이는 한 발짝도 들어갈 수 없단다.",
			"옜다, 이 할미가 여름내 모아 둔 반딧불이 병이란다. 조금은 앞이 보일 게야.",
			"(반딧불이 병을 받았다! 코랄 주위가 은은하게 밝아졌다.)",
		])
		return

	Dialogue.start(npc_name, STORIES[story_index])
	story_index = (story_index + 1) % STORIES.size()
