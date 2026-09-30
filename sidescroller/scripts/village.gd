extends Node2D
## 마을이에요. 몬스터가 없어서 편하게 돌아다니며 NPC와 이야기할 수 있어요.
## 마을에 들어오면 체력이 가득 차고, 진행 상황이 저장돼요.

## 배경 음악 이름
@export var music := "village"
## 맵 크기 (픽셀). 맵을 다시 만들면 자동으로 채워져요.
@export var map_size := Vector2(1024, 192)


# 기사보다 먼저 "level" 그룹에 들어가야 기사의 카메라가 맵 크기를 알 수 있어요.
func _enter_tree() -> void:
	add_to_group("level")


func _ready() -> void:
	Sound.play_music(music)
	GameState.save_game()
	# 처음 온 사람에게는 촌장 할아버지가 먼저 알려줘요.
	if not GameState.flags.get("met_elder", false):
		$HUD.show_banner("풀잎 마을", "↑ 키로 마을 사람과 이야기해요", 3.0)
