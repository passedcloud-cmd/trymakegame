extends Node
## 게임 전체에서 기억해야 하는 것들을 모아 둔 곳이에요.
## 어디서든 GameState.shards 처럼 꺼내 쓸 수 있어요.

## 빛조각(돈) 개수가 바뀌면 알려줘요. (화면 왼쪽 위 숫자가 이걸 듣고 바뀌어요)
signal shards_changed(count: int)

## 스테이지 목록. 스테이지를 추가하려면 여기에 한 줄 더 적어요.
const STAGES := [
	{"name": "이끼 숲길", "scene": "res://scenes/stage_1.tscn"},
	{"name": "푸른 동굴", "scene": "res://scenes/stage_2.tscn"},
	{"name": "투구벌레 둥지", "scene": "res://scenes/stage_3.tscn"},
]
const VILLAGE_SCENE := "res://scenes/village.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"

## 기본 체력 (가면 개수). 약초상에게서 늘릴 수 있어요.
const BASE_HP := 5
## 검 레벨마다 공격력. [1레벨, 2레벨, 3레벨]
const SWORD_DAMAGE := [10, 14, 19]

## 가지고 있는 빛조각 개수
var shards := 0:
	set(value):
		shards = value
		shards_changed.emit(shards)

## 검 레벨 (1~3). 대장장이가 강화해 줘요.
var sword_level := 1
## 약초상에게서 늘린 체력
var bonus_hp := 0
## 깬 스테이지 번호 목록 (예: [1, 2])
var cleared: Array = []
## 이야기 진행 메모장. 예: flags["met_elder"] = true
var flags := {}


## 최대 체력
func max_hp() -> int:
	return BASE_HP + bonus_hp


## 지금 검의 공격력
func attack_damage() -> int:
	return SWORD_DAMAGE[sword_level - 1]


## 이 스테이지에 들어갈 수 있는지 (앞 스테이지를 깨야 열려요)
func is_unlocked(stage_number: int) -> bool:
	return stage_number == 1 or cleared.has(stage_number - 1)


func is_cleared(stage_number: int) -> bool:
	return cleared.has(stage_number)


## 모든 스테이지를 깼는지
func all_cleared() -> bool:
	return cleared.size() >= STAGES.size()


func mark_cleared(stage_number: int) -> void:
	if not cleared.has(stage_number):
		cleared.append(stage_number)
		cleared.sort()


# ── 손맛 (타격감) ───────────────────────────────────────

## 아주 잠깐 게임을 거의 멈춰서 "쾅!" 하는 느낌을 줘요. (히트스톱)
func hitstop(duration: float, slow := 0.05) -> void:
	Engine.time_scale = slow
	# 마지막 true: 게임 속도가 느려져도 진짜 시간으로 세요.
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


# ── 저장하기 ──────────────────────────────────────────
# 저장 파일은 컴퓨터(웹 버전은 브라우저)의 user:// 폴더에 있어요.

const SAVE_PATH := "user://save.json"


## 지금 진행 상황을 저장해요. (마을에 들어갈 때, 물건을 살 때, 스테이지를 깼을 때 불려요)
func save_game() -> void:
	var data := {
		"shards": shards,
		"sword_level": sword_level,
		"bonus_hp": bonus_hp,
		"cleared": cleared,
		"flags": flags,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


## 저장 파일이 있는지 알려줘요.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 저장 파일을 읽어서 이어해요.
func load_game() -> void:
	reset()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	shards = int(data.get("shards", 0))
	sword_level = clampi(int(data.get("sword_level", 1)), 1, SWORD_DAMAGE.size())
	bonus_hp = int(data.get("bonus_hp", 0))
	for n in data.get("cleared", []):
		cleared.append(int(n))
	flags = data.get("flags", {})


## 처음부터 시작해요. (저장 파일도 지워요)
func new_game() -> void:
	reset()
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func reset() -> void:
	shards = 0
	sword_level = 1
	bonus_hp = 0
	cleared = []
	flags = {}
