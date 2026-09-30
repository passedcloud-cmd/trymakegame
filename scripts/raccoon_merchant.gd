extends NPC
## 너구리 상인: 도토리를 회복 열매로 바꿔줘요.

## 회복 열매 하나에 필요한 도토리 개수
@export var price: int = 2


func talk() -> void:
	var player := get_player()

	if GameState.acorns < price:
		Dialogue.start(npc_name, [
			"어서 오라구! 나는 떠돌이 상인 너구리야.",
			"도토리 %d개를 가져오면 기운이 번쩍 나는 회복 열매로 바꿔 줄게." % price,
			"도토리는 풀밭에 떨어져 있기도 하고, 그림자 슬라임이 떨어뜨리기도 해!",
		])
		return

	if player.hp >= player.max_hp:
		Dialogue.start(npc_name, ["오, 도토리를 모아 왔구나! 그런데 지금은 아픈 데가 없어 보이는걸?", "다치면 다시 오라구!"])
		return

	var answer := await Dialogue.ask(npc_name, "도토리 %d개로 회복 열매를 바꿀래? (지금 도토리: %d개)" % [price, GameState.acorns], ["바꿀래", "다음에"])
	if answer == 0:
		GameState.acorns -= price
		player.heal(player.max_hp)
		Dialogue.start(npc_name, ["거래 성립! 냠냠... 어때, 기운이 펄펄 나지?"])
	else:
		Dialogue.start(npc_name, ["언제든 들르라구!"])
