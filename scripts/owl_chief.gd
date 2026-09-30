extends NPC
## 부엉이 촌장: 이야기를 이끌어 주고, 주워 온 별을 하늘로 돌려보내 줘요.

const STAR_TEXTURE := preload("res://assets/village/star.png")
const LIGHT_TEXTURE := preload("res://assets/village/light.png")
const ENDING_SCENE := preload("res://scenes/ending.tscn")

## 별을 가져왔을 때 하는 말 (별 번호마다)
const RETURN_LINES := {
	1: ["오오...! 그 빛은... 첫 번째 별이로구나!", "자, 별을 하늘로 돌려보내 주자꾸나."],
	2: ["두 번째 별이구나! 캄캄한 동굴에서 용케도 찾아왔구나.", "이 따스한 빛... 자, 하늘로 돌려보내 주자꾸나."],
	3: ["오오... 마지막 별이로구나! 그림자 곰을 이겨 낸 게냐?", "아기 곰이었다고...? 허허, 그랬구나. 참 잘했다, 코랄.", "자, 마지막 별을 하늘로 돌려보내 주자꾸나!"],
}
## 별을 돌려보낸 뒤에 하는 말 (별 번호마다)
const AFTER_RETURN_LINES := {
	1: [
		"보아라, 마을이 조금 밝아졌구나! 고맙다, 코랄.",
		"두 번째 별은 강 건너 캄캄한 동굴 쪽으로 떨어졌다는구나.",
		"동쪽 숲 끝의 부서진 다리는... 네 대시라면 건널 수 있을 게다!",
		"동굴은 몹시 어두우니, 거북이 할머니께 먼저 들러 보려무나.",
	],
	2: [
		"마을이 한층 더 밝아졌구나! 이제 별은 하나만 남았다.",
		"마지막 별은... 그림자 곰이 품고 있다는 소문이 있단다.",
		"그 녀석은 무척 강하다. 준비를 단단히 하고 가거라, 코랄.",
		"강 건너 바위 지대 남쪽, 그림자 장막 너머에 녀석의 굴이 있단다.",
	],
	3: [
		"보아라... 반딧불 마을에 빛이 모두 돌아왔구나!",
		"코랄, 네 덕분이다. 마을 모두가 너를 오래오래 기억할 게다.",
	],
}


func talk() -> void:
	var flags := GameState.flags

	# 주워 왔지만 아직 돌려보내지 않은 별이 있으면 돌려보내요.
	for n in [1, 2, 3]:
		if flags.get("star%d_found" % n, false) and not flags.get("star%d_returned" % n, false):
			await return_star(n)
			return

	if flags.get("star3_returned", false):
		Dialogue.start(npc_name, ["별빛이 참 곱구나.", "고맙다, 코랄. 너는 이 마을의 영웅이란다."])
	elif flags.get("star2_returned", false):
		Dialogue.start(npc_name, ["마지막 별은 그림자 곰이 품고 있다는구나.", "강 건너 바위 지대 남쪽, 그림자 장막 너머란다. 조심하렴, 코랄."])
	elif flags.get("star1_returned", false):
		Dialogue.start(npc_name, [
			"두 번째 별은 강 건너 캄캄한 동굴 쪽에 떨어졌다는구나.",
			"동굴은 몹시 어두우니, 거북이 할머니께 먼저 들러 보려무나." if not GameState.has_jar() else "반딧불이 병이 있으니 조금은 앞이 보일 게다. 조심하렴.",
		])
	else:
		Dialogue.start(npc_name, lines)


func return_star(number: int) -> void:
	Dialogue.start(npc_name, RETURN_LINES.get(number, ["별을 하늘로 돌려보내 주자꾸나."]))
	await Dialogue.finished

	# 연출: 별이 코랄에게서 하늘로 날아올라요.
	Dialogue.cutscene = true
	await fly_star_to_sky(get_player().global_position)
	GameState.flags["star%d_returned" % number] = true
	GameState.stars_returned += 1
	get_tree().call_group("night_tint", "brighten")
	await get_tree().create_timer(2.5).timeout
	Dialogue.cutscene = false

	Dialogue.start(npc_name, AFTER_RETURN_LINES.get(number, ["고맙다, 코랄."]))

	# 마지막 별이면 엔딩!
	if GameState.stars_returned >= 3:
		await Dialogue.finished
		await get_tree().create_timer(0.5).timeout
		get_tree().current_scene.add_child(ENDING_SCENE.instantiate())


func fly_star_to_sky(from: Vector2) -> void:
	var star := Sprite2D.new()
	star.texture = STAR_TEXTURE
	star.hframes = 2
	var light := PointLight2D.new()
	light.texture = LIGHT_TEXTURE
	light.color = Color(1, 0.9, 0.5)
	light.texture_scale = 1.6
	star.add_child(light)
	get_parent().add_child(star)
	star.global_position = from + Vector2(0, -12)

	var tween := star.create_tween()
	tween.tween_property(star, "global_position:y", from.y - 60, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(star, "global_position:y", from.y - 200, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(star, "scale", Vector2(0.3, 0.3), 0.9)
	await tween.finished
	star.queue_free()
