extends NPC
## 부엉이 촌장: 이야기를 이끌어 주고, 주워 온 별을 하늘로 돌려보내 줘요.

const STAR_TEXTURE := preload("res://assets/village/star.png")
const LIGHT_TEXTURE := preload("res://assets/village/light.png")


func talk() -> void:
	var flags := GameState.flags

	if flags.get("star1_found", false) and not flags.get("star1_returned", false):
		await return_first_star()
	elif flags.get("star1_returned", false):
		Dialogue.start(npc_name, [
			"두 번째 별은 강 건너 캄캄한 동굴 쪽에 떨어졌다는구나.",
			"동굴 안은 몹시 어두우니 조심하렴.",
		])
	else:
		Dialogue.start(npc_name, lines)


func return_first_star() -> void:
	Dialogue.start(npc_name, [
		"오오...! 그 빛은... 첫 번째 별이로구나!",
		"자, 별을 하늘로 돌려보내 주자꾸나.",
	])
	await Dialogue.finished

	# 연출: 별이 코랄에게서 하늘로 날아올라요.
	Dialogue.cutscene = true
	await fly_star_to_sky(get_player().global_position)
	GameState.flags["star1_returned"] = true
	GameState.stars_returned += 1
	get_tree().call_group("night_tint", "brighten")
	await get_tree().create_timer(2.5).timeout
	Dialogue.cutscene = false

	Dialogue.start(npc_name, [
		"보아라, 마을이 조금 밝아졌구나! 고맙다, 코랄.",
		"두 번째 별은 강 건너 캄캄한 동굴 쪽으로 떨어졌다는구나.",
		"동쪽 숲 끝의 부서진 다리는... 네 대시라면 건널 수 있을 게다!",
	])


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
