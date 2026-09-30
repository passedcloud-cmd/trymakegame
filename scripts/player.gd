extends CharacterBody2D
## 주인공 여우 "코랄"을 움직이는 코드예요.

## 코랄이 1초에 몇 픽셀 움직일지 정해요. 숫자가 클수록 빨라요.
@export var speed: float = 80.0
## 걷기 그림이 1초에 몇 장 넘어갈지 정해요.
@export var walk_fps: float = 8.0

# 스프라이트 시트(assets/coral.png)에서 방향마다 몇 번째 줄을 쓸지 정해요.
# 다른 그림으로 바꿀 때 줄 순서가 다르면 이 숫자만 고치면 돼요.
@export var row_down: int = 0
@export var row_up: int = 1
@export var row_side: int = 2

@onready var sprite: Sprite2D = $Sprite2D

var facing_row := 0
var walk_time := 0.0


# 이 함수는 게임이 돌아가는 동안 1초에 60번씩 자동으로 불려요.
func _physics_process(delta: float) -> void:
	# 방향키 입력을 읽어서 "어느 쪽으로 갈지"를 구해요.
	# 예: 오른쪽 키 → (1, 0), 위쪽 키 → (0, -1)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 대화 중에는 움직이지 않아요.
	if Dialogue.is_open:
		direction = Vector2.ZERO

	# 방향 × 속도 = 실제로 움직일 빠르기
	velocity = direction * speed

	# 실제로 움직여요. 벽에 부딪히면 알아서 멈추거나 미끄러져요.
	move_and_slide()

	update_animation(direction, delta)


# 움직이는 방향에 맞춰 그림을 바꿔요.
func update_animation(direction: Vector2, delta: float) -> void:
	if direction == Vector2.ZERO:
		# 멈춰 있으면 첫 번째 칸(서 있는 그림)을 보여줘요.
		walk_time = 0.0
		sprite.frame_coords = Vector2i(0, facing_row)
		return

	# 좌우로 더 많이 움직이면 옆모습, 아니면 앞/뒷모습
	if absf(direction.x) > absf(direction.y):
		facing_row = row_side
		# 옆모습 그림은 오른쪽을 보고 있어서, 왼쪽으로 갈 땐 좌우를 뒤집어요.
		sprite.flip_h = direction.x < 0
	else:
		facing_row = row_down if direction.y > 0 else row_up
		sprite.flip_h = false

	# 시간이 흐르는 만큼 다음 칸으로 넘겨요. (0 → 1 → 2 → 3 → 0 ...)
	walk_time += delta
	var column := int(walk_time * walk_fps) % sprite.hframes
	sprite.frame_coords = Vector2i(column, facing_row)
