extends Enemy
## 통통벼룩: 가만히 있다가 몸을 웅크리고(준비), 기사 쪽으로 크게 뛰어올라요.

## 옆으로 뛰는 빠르기
@export var hop_speed := 85.0
## 뛰어오르는 힘 (음수 = 위)
@export var hop_velocity := -260.0
## 땅에서 기다리는 시간 (초)
@export var wait_time := 1.1
## 뛰기 전에 웅크리는 시간 (초). 이게 보이면 조심!
@export var crouch_time := 0.35
## 기사를 알아채는 거리
@export var sight_range := 170.0

var wait_timer := 1.0
var in_air := false
var dir := -1


func _ready() -> void:
	super()
	wait_timer = randf_range(0.5, wait_time)


func think(delta: float) -> void:
	apply_gravity(delta)
	if is_on_floor():
		if in_air:
			in_air = false
			wait_timer = wait_time
			Effects.dust(get_parent(), global_position)
		velocity.x = knock_x()
		wait_timer -= delta
		sprite.frame = 1 if wait_timer < crouch_time else 0
		if wait_timer <= 0.0:
			hop()
	else:
		sprite.frame = 2
		if is_on_wall():
			velocity.x = -velocity.x * 0.5
	move_and_slide()
	sprite.flip_h = dir < 0


func hop() -> void:
	if player_near(sight_range):
		dir = player_side()
	# 뛰어서 떨어질 자리에 땅이 없으면 반대로 뛰어요.
	var landing := hop_speed * (-2.0 * hop_velocity / gravity)
	if not floor_ahead(dir, landing):
		dir = -dir
		if not floor_ahead(dir, landing):
			velocity.y = hop_velocity * 0.6  # 양쪽 다 낭떠러지면 제자리에서 폴짝
			in_air = true
			return
	velocity = Vector2(dir * hop_speed, hop_velocity)
	in_air = true
