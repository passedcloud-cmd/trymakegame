extends Enemy
## 가시벌: 하늘에 떠서 기사와 거리를 두고 따라다녀요.
## 몸이 반짝이면(준비) 곧 기사 쪽으로 침을 쏴요.

## 나는 빠르기
@export var speed := 50.0
## 기사를 알아채는 거리
@export var sight_range := 170.0
## 침을 쏘는 간격 (초)
@export var shoot_interval := 2.4
## 침을 쏘기 전에 반짝이는 시간 (초)
@export var windup_time := 0.5
## 침이 날아가는 빠르기
@export var spit_speed := 105.0

const SPIT_SCENE := preload("res://scenes/enemies/spit.tscn")

var home := Vector2.ZERO
var aggro := false
var winding_up := false
var windup_timer := 0.0
var shoot_timer := 1.2


func _ready() -> void:
	super()
	home = global_position
	shoot_timer = randf_range(1.0, 2.0)


func think(delta: float) -> void:
	var player := get_player()
	if player_near(sight_range):
		aggro = true
	elif player == null or player.is_dead:
		aggro = false

	var target := home + Vector2(sin(anim_time * 0.8) * 24.0, 0.0)
	if aggro:
		# 기사의 옆 위쪽, 조금 떨어진 곳에 머물러요.
		var side := -player_side()
		target = player.global_position + Vector2(side * 72.0, -56.0)

	if winding_up:
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		windup_timer -= delta
		if windup_timer <= 0.0:
			winding_up = false
			shoot()
	else:
		var desired := (target - global_position).limit_length(1.0) * speed
		if global_position.distance_to(target) < 6.0:
			desired = Vector2.ZERO
		velocity = velocity.lerp(desired, 3.0 * delta)
		velocity.y += sin(anim_time * 5.0) * 4.0
		shoot_timer -= delta
		if aggro and shoot_timer <= 0.0:
			winding_up = true
			windup_timer = windup_time
			Sound.play("warn")

	move_and_slide()
	sprite.flip_h = (player_side() < 0) if aggro else velocity.x < 0.0
	sprite.frame = 2 if winding_up else int(anim_time * 14.0) % 2
	tint = Color(1.6, 1.1, 0.6) if winding_up else Color.WHITE


func on_hit(dir: Vector2) -> void:
	velocity += dir * 120.0
	# 맞으면 쏘려던 침이 취소돼요.
	winding_up = false
	shoot_timer = maxf(shoot_timer, 0.8)


func shoot() -> void:
	shoot_timer = shoot_interval
	var player := get_player()
	if player == null:
		return
	var spit := SPIT_SCENE.instantiate()
	spit.position = position
	spit.velocity = (player.global_position + Vector2(0, -10) - global_position).normalized() * spit_speed
	get_parent().add_child(spit)
	Sound.play("shoot")
