extends CharacterBody2D
## 주인공 여우 "코랄"을 움직이는 코드예요.

## 코랄이 1초에 몇 픽셀 움직일지 정해요. 숫자가 클수록 빨라요.
@export var speed: float = 80.0


# 이 함수는 게임이 돌아가는 동안 1초에 60번씩 자동으로 불려요.
func _physics_process(_delta: float) -> void:
	# 방향키 입력을 읽어서 "어느 쪽으로 갈지"를 구해요.
	# 예: 오른쪽 키 → (1, 0), 위쪽 키 → (0, -1)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 방향 × 속도 = 실제로 움직일 빠르기
	velocity = direction * speed

	# 실제로 움직여요. 벽에 부딪히면 알아서 멈추거나 미끄러져요.
	move_and_slide()
