extends Node2D
## 전투 스테이지 하나를 관리해요.
## 스테이지 안의 벌레(enemy 그룹)를 모두 물리치면 클리어!

## 몇 번째 스테이지인지 (GameState.STAGES의 순서, 1부터)
@export var stage_number := 1
## 배경 음악 이름 (assets/music/ 안의 파일 이름)
@export var music := "forest"
## 맵 크기 (픽셀). 카메라가 이 밖을 비추지 않아요. 맵을 다시 만들면 자동으로 채워져요.
@export var map_size := Vector2(1920, 224)
## 처음 깼을 때 받는 보너스 빛조각
@export var clear_reward := 20
## 이미 깬 스테이지를 다시 깼을 때 받는 보너스 빛조각
@export var replay_reward := 5

@onready var hud: CanvasLayer = $HUD
@onready var player: Player = $Player

var total := 0
var remaining := 0
var cleared := false


# 기사보다 먼저 "level" 그룹에 들어가야 기사의 카메라가 맵 크기를 알 수 있어요.
func _enter_tree() -> void:
	add_to_group("level")
	add_to_group("stage")


func _ready() -> void:
	Sound.play_music(music)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		total += 1
		enemy.died.connect(_on_enemy_died)
		if enemy.is_in_group("boss"):
			enemy.woke_up.connect(func(): hud.show_boss(enemy, "투구벌레 대장"))
	remaining = total
	hud.set_monsters(remaining, total)
	hud.show_banner("STAGE %d" % stage_number, GameState.STAGES[stage_number - 1].name)
	player.died.connect(_on_player_died)


func _on_enemy_died(_enemy: Node) -> void:
	remaining -= 1
	hud.set_monsters(remaining, total)
	if remaining <= 0 and not cleared:
		clear()


func clear() -> void:
	cleared = true
	await get_tree().create_timer(0.8).timeout
	if player.is_dead:
		return
	Sound.play_music("")
	Sound.play("clear")

	var first_time := not GameState.is_cleared(stage_number)
	var reward := clear_reward if first_time else replay_reward
	GameState.mark_cleared(stage_number)
	GameState.shards += reward
	hud.show_banner("스테이지 클리어!", "보너스 빛조각 +%d" % reward, 0.0)
	# 바닥에 남은 빛조각은 모두 기사에게 날아와요.
	for item in get_tree().get_nodes_in_group("pickup"):
		if item.kind == "shard":
			item.magnet = true
	GameState.save_game()

	await get_tree().create_timer(3.5).timeout
	# 마지막 스테이지를 처음 깼으면 엔딩으로!
	if first_time and stage_number == GameState.STAGES.size():
		Transition.go(GameState.ENDING_SCENE)
	else:
		Transition.go(GameState.VILLAGE_SCENE)


func _on_player_died() -> void:
	hud.show_message("쓰러졌어요... 다시 도전!")
	GameState.save_game()
	await get_tree().create_timer(1.8).timeout
	Transition.restart()
