extends Enemy
## 뿔딱정벌레: 평소엔 천천히 걷다가, 앞에 기사가 보이면 눈이 빨개지고(준비) 빠르게 돌진해요.
## 돌진이 끝나면 잠깐 어지러워해요. 그때가 공격할 기회!

## 평소 걷는 빠르기
@export var walk_speed := 22.0
## 돌진 빠르기
@export var charge_speed := 210.0
## 기사를 알아채는 거리
@export var sight_range := 140.0
## 돌진하기 전에 준비하는 시간 (초). 이 동안 피할 준비를 해요!
@export var windup_time := 0.55
## 돌진 후 어지러워하는 시간 (초)
@export var rest_time := 0.9
## 가장 오래 돌진하는 시간 (초)
@export var max_charge_time := 1.3

enum State { PATROL, WINDUP, CHARGE, REST }

var state := State.PATROL
var state_timer := 0.0
var dir := -1
var look_cooldown := 0.0


func think(delta: float) -> void:
	apply_gravity(delta)
	state_timer -= delta
	look_cooldown -= delta
	sprite.offset.x = 0.0

	match state:
		State.PATROL:
			velocity.x = dir * walk_speed + knock_x()
			if is_on_floor() and knock_timer <= 0.0 and (is_on_wall() or not floor_ahead(dir, 12.0)):
				dir = -dir
			sprite.frame = int(anim_time * 5.0) % 2
			if look_cooldown <= 0.0 and sees_player():
				dir = player_side()
				change_state(State.WINDUP, windup_time)
				Sound.play("warn")
		State.WINDUP:
			velocity.x = 0.0
			sprite.frame = 2
			sprite.offset.x = randf_range(-1, 1)  # 부르르 떨어요
			if state_timer <= 0.0:
				change_state(State.CHARGE, max_charge_time)
				Sound.play("charge")
		State.CHARGE:
			velocity.x = dir * charge_speed
			sprite.frame = 2
			if is_on_wall() or not floor_ahead(dir, 14.0) or state_timer <= 0.0:
				if is_on_wall():
					Sound.play("slam", -6.0)
					Effects.shake(get_tree(), 2.0, 0.15)
				change_state(State.REST, rest_time)
		State.REST:
			velocity.x = knock_x()
			sprite.frame = 3
			if state_timer <= 0.0:
				dir = player_side()
				look_cooldown = 0.6
				change_state(State.PATROL, 0.0)

	tint = Color(1.5, 0.7, 0.7) if state == State.WINDUP else Color.WHITE
	move_and_slide()
	sprite.flip_h = dir < 0


func change_state(new_state: State, time: float) -> void:
	state = new_state
	state_timer = time


# 기사가 앞쪽(또는 아주 가까운 뒤쪽)에 있고 높이가 비슷하면 true
func sees_player() -> bool:
	var player := get_player()
	if player == null or player.is_dead or not is_on_floor():
		return false
	var dx := player.global_position.x - global_position.x
	var dy := player.global_position.y - global_position.y
	if absf(dy) > 28.0 or absf(dx) > sight_range:
		return false
	return signf(dx) == dir or absf(dx) < 48.0
