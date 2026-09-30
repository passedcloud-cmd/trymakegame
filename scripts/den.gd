extends Node2D
## 그림자 곰의 굴: 보스 싸움의 시작과 끝(연출)을 맡아요.

const STAR_SCENE := preload("res://scenes/star.tscn")
const STAR3_LINES: Array[String] = [
	"★ 세 번째 별을 찾았다!",
	"이제 별이 모두 모였다.",
	"(부엉이 촌장에게 가져가자!)",
]

@onready var bear: Node2D = $Objects/ShadowBear
@onready var boss_bar: CanvasLayer = $BossBar


func _ready() -> void:
	# 싸움 전에는 조용히... (곰이 으르렁대면 보스 음악이 시작돼요)
	Sound.play_music("ending" if GameState.flags.get("bear_saved", false) else "")
	if GameState.flags.get("bear_saved", false):
		# 이미 곰을 구했어요. 별을 아직 안 주웠으면 별만 다시 놓아요.
		bear.queue_free()
		if not GameState.flags.get("star3_found", false):
			spawn_star(Vector2(192, 110))
		return
	boss_bar.setup(bear)
	bear.defeated.connect(_on_bear_defeated)
	intro.call_deferred()


func intro() -> void:
	await get_tree().create_timer(0.6).timeout
	var first_time: bool = not GameState.flags.get("bear_intro_seen", false)
	GameState.flags["bear_intro_seen"] = true
	var intro_lines: Array[String] = ["그르르르르...!"]
	if first_time:
		intro_lines = [
			"그르르르르...",
			"반짝이는 건... 전부... 내 거다...!",
			"(그림자 곰이 앞을 가로막았다!)",
			"(그림자 갑옷에는 꼬리가 통하지 않을 것 같다... 별빛을 비추면 어떨까?)",
		]
	Sound.play("roar", 0.0, 1.0, 0.0)
	Dialogue.start("그림자 곰", intro_lines)
	await Dialogue.finished
	Sound.play_music("boss", 0.3)
	boss_bar.show()
	bear.start_fight()


func _on_bear_defeated() -> void:
	boss_bar.hide()
	Sound.play_music("", 1.5)
	Dialogue.cutscene = true
	# 남은 슬라임과 그림자 공격을 모두 치워요.
	for node in get_tree().get_nodes_in_group("enemy"):
		if node != bear:
			node.queue_free()
	get_tree().call_group("boss_attack", "queue_free")
	await get_tree().create_timer(0.8).timeout
	await bear.melt_into_cub()
	Dialogue.cutscene = false

	Dialogue.start("아기 곰", [
		"으... 여기가 어디지...?",
		"별똥별이 떨어졌을 때, 그 빛이 너무 예뻐서 꼭 끌어안았는데...",
		"갑자기 그림자가 나를 뒤덮어 버렸어. 너무 무섭고 캄캄했어...",
		"구해 줘서 고마워, 여우야. 이 별은 하늘에 돌려줄게.",
		"나도... 너희 마을에 놀러 가도 될까?",
	])
	await Dialogue.finished
	GameState.flags["bear_saved"] = true
	Sound.play_music("ending", 2.0)
	spawn_star(bear.global_position + Vector2(0, 24))


func spawn_star(at: Vector2) -> void:
	var star := STAR_SCENE.instantiate()
	star.star_number = 3
	star.pickup_lines = STAR3_LINES
	$Objects.add_child(star)
	star.global_position = at
