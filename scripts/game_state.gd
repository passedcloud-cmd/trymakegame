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

## 퀘스트 보상으로 늘어난 하트 개수
var bonus_hearts := 0

## 퀘스트 진행 상황을 적어두는 메모장이에요.
## 예: flags["baby_found"] = true → 아기 토끼를 찾았음
var flags := {}


## 게임을 처음부터 다시 시작할 때 모두 지워요.
func reset() -> void:
	acorns = 0
	bonus_hearts = 0
	flags.clear()
