extends Enemy
## 투구벌레 대장: 마지막 스테이지의 보스예요.
## 기사가 가까이 오면 깨어나서 세 가지 공격을 번갈아 써요.
##   1. 돌진  : 뿔을 세우고(준비) 벽까지 달려와요. 벽에 부딪히면 어지러워하고, 천장에서 돌이 떨어져요.
##   2. 점프  : 기사 위로 뛰어올라 쿵! 땅을 타고 충격파가 양옆으로 퍼져요. (점프로 넘어요)
##   3. 침 뿌리기: 침 구슬을 부채꼴로 뿌려요.
## 체력이 절반 아래로 내려가면 화가 나서 더 빨라져요.

## 보스가 깨어났을 때 알려줘요. (화면 아래 체력 막대가 나타나요)
signal woke_up

## 기사가 이만큼 가까이 오면 깨어나요.
@export var wake_range := 190.0
## 돌진 빠르기
@export var charge_speed := 220.0
## 점프해서 공중에 있는 시간 (초)
@export var leap_time := 0.9
## 벽에 부딪혔을 때 떨어지는 돌 개수
@export var rock_count := 3
## 침 구슬 개수
@export var spit_count := 3

const SPIT_SCENE := preload("res://scenes/enemies/spit.tscn")
const WAVE_SCENE := preload("res://scenes/enemies/shockwave.tscn")
const ROCK_SCENE := preload("res://scenes/enemies/falling_rock.tscn")

enum State { SLEEP, IDLE, CHARGE_WINDUP, CHARGE, STUN, LEAP_WINDUP, LEAP, SPIT_WINDUP, RECOVER }

var state := State.SLEEP
var state_timer := 0.0
var dir := -1
var angry := false
var last_attack := -1
var air_time := 0.0
var arena_left := 0.0
var arena_right := 0.0
var floor_y := 0.0


func _ready() -> void:
	super()
	floor_y = global_position.y


## 깨어났는지
func is_awake() -> bool:
	return state != State.SLEEP


func contact_active() -> bool:
	# 자고 있을 때나 어지러울 때는 닿아도 안 아파요. 마음껏 때려요!
	return state != State.STUN and state != State.SLEEP


func think(delta: float) -> void:
	apply_gravity(delta)
	state_timer -= delta
	sprite.offset = Vector2.ZERO
	var speed_up := 0.7 if angry else 1.0

	match state:
		State.SLEEP:
			velocity.x = 0.0
			sprite.frame = int(anim_time * 1.5) % 2
			if player_near(wake_range):
				wake()
		State.IDLE:
			dir = player_side()
			velocity.x = dir * 25.0
			sprite.frame = int(anim_time * 4.0) % 2
			if state_timer <= 0.0:
				pick_attack()
		State.CHARGE_WINDUP:
			velocity.x = 0.0
			sprite.frame = 2
			sprite.offset.x = randf_range(-1.5, 1.5)
			if state_timer <= 0.0:
				change_state(State.CHARGE, 3.0)
				Sound.play("charge")
		State.CHARGE:
			velocity.x = dir * charge_speed * (1.15 if angry else 1.0)
			sprite.frame = int(anim_time * 10.0) % 2
			if is_on_wall() or state_timer <= 0.0:
				crash_into_wall()
		State.STUN:
			velocity.x = 0.0
			sprite.frame = 3
			if state_timer <= 0.0:
				change_state(State.IDLE, 0.5 * speed_up)
		State.LEAP_WINDUP:
			velocity.x = 0.0
			sprite.frame = 2
			sprite.offset.y = 2.0
			if state_timer <= 0.0:
				start_leap()
		State.LEAP:
			air_time += delta
			sprite.frame = 2
			if is_on_floor() and air_time > 0.15:
				land()
		State.SPIT_WINDUP:
			velocity.x = 0.0
			sprite.frame = 2
			sprite.offset.x = randf_range(-1, 1)
			if state_timer <= 0.0:
				spit_spread()
				change_state(State.RECOVER, 0.6 * speed_up)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			sprite.frame = 0
			if state_timer <= 0.0:
				change_state(State.IDLE, 0.6 * speed_up)

	var warning := state in [State.CHARGE_WINDUP, State.LEAP_WINDUP, State.SPIT_WINDUP]
	tint = Color(1.6, 0.6, 0.6) if warning else (Color(1.2, 0.85, 0.85) if angry else Color.WHITE)
	move_and_slide()
	if state != State.LEAP:
		sprite.flip_h = dir < 0


func change_state(new_state: State, time: float) -> void:
	state = new_state
	state_timer = time


func wake() -> void:
	find_arena()
	Sound.play("roar")
	Sound.play_music("boss")
	Effects.shake(get_tree(), 4.0, 0.8)
	change_state(State.IDLE, 1.4)
	woke_up.emit()


# 보스 방의 왼쪽/오른쪽 벽 위치를 찾아요. (점프해도 방 밖으로 나가지 않게)
func find_arena() -> void:
	var space := get_world_2d().direct_space_state
	var origin := global_position + Vector2(0, -12)
	for side in [-1, 1]:
		var query := PhysicsRayQueryParameters2D.create(origin, origin + Vector2(side * 600, 0), 1)
		var hit := space.intersect_ray(query)
		var wall_x: float = hit.position.x if hit else origin.x + side * 600
		if side < 0:
			arena_left = wall_x + 30.0
		else:
			arena_right = wall_x - 30.0


func pick_attack() -> void:
	var choices := [0, 1, 2]
	choices.erase(last_attack)
	var attack: int = choices.pick_random()
	last_attack = attack
	dir = player_side()
	var speed_up := 0.7 if angry else 1.0
	match attack:
		0:
			change_state(State.CHARGE_WINDUP, 0.7 * speed_up)
			Sound.play("warn")
		1:
			change_state(State.LEAP_WINDUP, 0.45 * speed_up)
			Sound.play("warn")
		2:
			change_state(State.SPIT_WINDUP, 0.55 * speed_up)
			Sound.play("warn")


func crash_into_wall() -> void:
	Sound.play("boom")
	Effects.shake(get_tree(), 5.0, 0.4)
	Effects.burst(get_parent(), global_position + Vector2(dir * 30, -20), Color(0.8, 0.7, 0.6), 16, 120.0)
	change_state(State.STUN, 1.0 if angry else 1.4)
	# 천장에서 돌이 떨어져요.
	var count := rock_count + (2 if angry else 0)
	for i in count:
		var rock := ROCK_SCENE.instantiate()
		var x := randf_range(arena_left, arena_right)
		rock.position = Vector2(x, floor_y - 150.0)
		rock.floor_y = floor_y
		rock.delay = 0.5 + i * 0.25
		get_parent().add_child(rock)


func start_leap() -> void:
	var player := get_player()
	var target_x: float = player.global_position.x if player else global_position.x
	target_x = clampf(target_x, arena_left, arena_right)
	# 공중에 leap_time초 동안 떠 있다가 target_x에 떨어지도록 속도를 계산해요.
	velocity.x = (target_x - global_position.x) / leap_time
	velocity.y = -gravity * leap_time / 2.0
	air_time = 0.0
	change_state(State.LEAP, 3.0)
	Sound.play("jump", 0.0, 0.5)


func land() -> void:
	velocity.x = 0.0
	Sound.play("slam")
	Effects.shake(get_tree(), 5.0, 0.3)
	Effects.dust(get_parent(), global_position + Vector2(-20, 0))
	Effects.dust(get_parent(), global_position + Vector2(20, 0))
	for side in [-1, 1]:
		var wave := WAVE_SCENE.instantiate()
		wave.position = position + Vector2(side * 24, 0)
		wave.dir = side
		wave.speed = 170.0 if angry else 150.0
		get_parent().add_child(wave)
	change_state(State.RECOVER, 0.7)


func spit_spread() -> void:
	var player := get_player()
	var mouth := global_position + Vector2(dir * 26, -22)
	var aim := Vector2(dir, 0)
	if player:
		aim = (player.global_position + Vector2(0, -10) - mouth).normalized()
	var count := spit_count + (2 if angry else 0)
	for i in count:
		var angle := (i - (count - 1) / 2.0) * 0.28
		var spit := SPIT_SCENE.instantiate()
		spit.position = mouth - get_parent().global_position
		spit.velocity = aim.rotated(angle) * 115.0
		get_parent().add_child(spit)
	Sound.play("shoot")


func take_hit(damage: int, dir_: Vector2) -> void:
	# 자고 있을 때 맞으면 깨어나요.
	if state == State.SLEEP:
		wake()
	super(damage, dir_)
	if not dead and not angry and hp * 2 <= max_hp:
		angry = true
		Sound.play("roar")
		Effects.shake(get_tree(), 3.0, 0.5)


func drop_items() -> void:
	super()
	Effects.shake(get_tree(), 6.0, 0.6)
