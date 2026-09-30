extends Node
## 게임 전체에서 기억해야 하는 것들을 모아 둔 곳이에요.
## 어디서든 GameState.acorns 처럼 꺼내 쓸 수 있어요.

## 도토리 개수가 바뀌면 알려줘요. (화면 위 도토리 숫자가 이걸 듣고 바뀌어요)
signal acorns_changed(count: int)

## 가지고 있는 도토리 개수
var acorns := 0:
	set(value):
		acorns = value
		acorns_changed.emit(acorns)

## 별 개수가 바뀌면 알려줘요.
signal stars_changed(count: int)

## 하늘로 돌려보낸 별 개수 (0~3)
var stars_returned := 0:
	set(value):
		stars_returned = value
		stars_changed.emit(stars_returned)

## 퀘스트 보상으로 늘어난 하트 개수
var bonus_hearts := 0

## 다음 맵에 들어갈 때 코랄이 설 출발 지점 이름 (비어 있으면 맵에 놓인 자리 그대로)
var next_spawn := ""

## 별빛을 켜 두었는지 (맵을 옮겨도 그대로 유지돼요)
var starlight_on := false

## 퀘스트 진행 상황을 적어두는 메모장이에요.
## 예: flags["baby_found"] = true → 아기 토끼를 찾았음
var flags := {}


## 대시를 배웠는지 알려줘요. (첫 번째 별을 주우면 배워요)
func has_dash() -> bool:
	return flags.get("has_dash", false)


## 반딧불이 병을 받았는지 (거북이 할머니가 줘요)
func has_jar() -> bool:
	return flags.get("has_jar", false)


## 별빛을 배웠는지 (두 번째 별을 주우면 배워요)
func has_starlight() -> bool:
	return flags.get("has_starlight", false)


# ── 저장하기 ──────────────────────────────────────────
# 저장 파일은 컴퓨터(웹 버전은 브라우저)의 user:// 폴더에 있어요.

const SAVE_PATH := "user://save.json"
const TITLE_SCENE := "res://scenes/title.tscn"


## 지금 진행 상황을 저장해요. (대화가 끝날 때, 맵에 들어갈 때 등 자동으로 불려요)
func save_game() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == "" or scene.scene_file_path == TITLE_SCENE:
		return  # 타이틀 화면에서는 저장하지 않아요.
	var data := {
		"scene": scene.scene_file_path,
		"spawn": next_spawn,
		"acorns": acorns,
		"stars_returned": stars_returned,
		"bonus_hearts": bonus_hearts,
		"starlight_on": starlight_on,
		"flags": flags,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


## 저장 파일이 있는지 알려줘요.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 저장한 진행 상황을 불러와요. 이어서 시작할 맵과 출발 지점을 돌려줘요.
func load_game() -> Dictionary:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	acorns = int(data.get("acorns", 0))
	stars_returned = int(data.get("stars_returned", 0))
	bonus_hearts = int(data.get("bonus_hearts", 0))
	starlight_on = bool(data.get("starlight_on", false))
	flags = data.get("flags", {})
	next_spawn = str(data.get("spawn", ""))
	return {"scene": str(data.get("scene", "res://scenes/main.tscn")), "spawn": next_spawn}


## 저장 파일을 지워요. (처음부터 시작할 때)
func delete_save() -> void:
	var dir := DirAccess.open("user://")
	if dir and has_save():
		dir.remove(SAVE_PATH.get_file())


## 게임을 처음부터 다시 시작할 때 모두 지워요.
func reset() -> void:
	acorns = 0
	stars_returned = 0
	bonus_hearts = 0
	next_spawn = ""
	starlight_on = false
	flags.clear()
