class_name Player
extends CharacterBody2D
## 주인공 "작은 기사"를 움직이는 코드예요.
## 숫자들은 Godot에서 scenes/player.tscn → Player를 선택하면 오른쪽 인스펙터에서 바꿀 수 있어요.

## 체력이 바뀔 때마다 알려줘요. (화면 왼쪽 위 가면이 이걸 듣고 바뀌어요)
signal health_changed(hp: int, max_hp: int)
## 체력이 0이 되어 쓰러지면 알려줘요.
signal died

@export_group("움직임")
## 달리는 빠르기 (1초에 몇 픽셀)
@export var run_speed := 105.0
## 땅에서 속도가 붙는 빠르기. 클수록 바로 멈추고 바로 달려요.
@export var ground_accel := 1400.0
## 공중에서 방향을 바꾸는 빠르기
@export var air_accel := 1000.0
## 아래로 끌어당기는 힘 (중력)
@export var gravity := 900.0
## 떨어지는 최고 속도
@export var max_fall_speed := 330.0
## 점프하는 힘 (음수 = 위쪽). 숫자가 클수록(더 작은 음수일수록) 높이 뛰어요.
@export var jump_velocity := -310.0
## 점프 키를 일찍 떼면 속도가 이만큼으로 줄어요. (짧게 누르면 낮은 점프)
@export var jump_cut := 0.45
## 땅에서 막 떨어진 뒤에도 이 시간 동안은 점프할 수 있어요. (조작이 너그러워져요)
@export var coyote_time := 0.1
## 땅에 닿기 조금 전에 누른 점프도 기억해 뒀다가 뛰어요.
@export var jump_buffer_time := 0.12

@export_group("대시")
## 대시 빠르기
@export var dash_speed := 290.0
## 대시하는 시간 (초). 이 동안은 다치지 않아요.
@export var dash_time := 0.17
## 대시 후 다시 대시할 수 있을 때까지 (초)
@export var dash_cooldown := 0.45

@export_group("전투")
## 한 번 휘두른 뒤 다시 휘두를 수 있을 때까지 (초)
@export var attack_cooldown := 0.3
## 검이 몬스터를 맞출 수 있는 시간 (초)
@export var attack_active_time := 0.1
## 옆으로 벤 뒤 뒤로 살짝 밀려나는 빠르기
@export var recoil_speed := 110.0
## 아래 베기가 맞으면 튀어 오르는 힘
@export var pogo_velocity := -265.0
## 맞은 뒤 무적인 시간 (초)
@export var invincible_time := 1.0
## 맞았을 때 조작이 안 되는 시간 (초)
@export var hurt_stun_time := 0.25

# 그림 번호 (assets/knight.png의 몇 번째 칸인지)
const FRAME_IDLE := 0
const FRAME_RUN := 2
const FRAME_JUMP := 6
const FRAME_FALL := 7
const FRAME_ATTACK := 8
const FRAME_DASH := 9
const FRAME_HURT := 10
const FRAME_LOOK_UP := 11

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var slash: Sprite2D = $Slash
@onready var camera: Camera2D = $Camera2D

var hp := 5
var max_hp := 5
var facing := 1                   # 1 = 오른쪽, -1 = 왼쪽
var is_dead := false
var respawning := false           # 구덩이에 빠져서 다시 서는 중

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var was_on_floor := true

var dash_timer := 0.0             # 0보다 크면 지금 대시하는 중
var dash_cooldown_timer := 0.0
var can_air_dash := true          # 공중에서는 한 번만 대시할 수 있어요.
var ghost_timer := 0.0

var attack_timer := 0.0           # 0보다 크면 검이 몬스터를 맞출 수 있어요.
var attack_cooldown_timer := 0.0
var attack_pose_timer := 0.0      # 검을 휘두르는 그림을 보여주는 시간
var attack_dir := Vector2.RIGHT
var hit_list: Array = []          # 이번 휘두르기에 이미 맞은 몬스터 (한 번에 두 번 맞지 않게)
var pogo_done := false
var recoil_timer := 0.0

var invincible_timer := 0.0
var hurt_timer := 0.0

var safe_position := Vector2.ZERO # 구덩이에 빠지면 돌아올 자리
var safe_timer := 0.0
var map_bottom := 10000.0

var anim_time := 0.0
var shake_strength := 0.0
var shake_timer := 0.0
var look_ahead := 0.0


func _ready() -> void:
	max_hp = GameState.max_hp()
	hp = max_hp
	slash.hide()
	safe_position = global_position
	fit_camera_to_map()


# 카메라가 맵 밖을 비추지 않도록 맵 크기에 맞춰요.
func fit_camera_to_map() -> void:
	var level := get_tree().get_first_node_in_group("level")
	if level == null:
		return
	var size: Vector2 = level.map_size
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	map_bottom = size.y
	camera.reset_smoothing.call_deferred()


# 이 함수는 게임이 돌아가는 동안 1초에 60번씩 자동으로 불려요.
func _physics_process(delta: float) -> void:
	update_timers(delta)
	update_shake(delta)
	if is_dead or respawning:
		return

	# 대화 중이거나 장면을 바꾸는 중에는 조작할 수 없어요.
	var busy := Dialogue.is_busy()
	var dir := 0.0 if busy else Input.get_axis("move_left", "move_right")
	var can_control := not busy and hurt_timer <= 0.0

	if is_on_floor():
		coyote_timer = coyote_time
		can_air_dash = true

	if is_dashing():
		# 대시 중에는 바라보는 쪽으로 곧게 날아가요. (중력 없음)
		velocity = Vector2(facing * dash_speed, 0.0)
		update_ghosts(delta)
	else:
		move_horizontal(dir, can_control, delta)
		apply_gravity(delta)
		if can_control:
			handle_jump()
			if Input.is_action_just_pressed("dash") and can_dash():
				start_dash(dir)
			elif Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
				start_attack()

	move_and_slide()

	# 착지하면 먼지가 폴싹!
	if is_on_floor() and not was_on_floor:
		Sound.play("land", -4.0)
		Effects.dust(get_parent(), global_position)
	was_on_floor = is_on_floor()

	update_attack()
	check_pit()
	update_safe_position(delta)
	update_camera(delta)
	update_animation(delta)


# ── 움직임 ─────────────────────────────────────────────

func move_horizontal(dir: float, can_control: bool, delta: float) -> void:
	if recoil_timer > 0.0:
		# 몬스터를 옆으로 베면 반대쪽으로 살짝 밀려나요.
		velocity.x = -facing * recoil_speed
		return
	if not can_control:
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		return
	var accel := ground_accel if is_on_floor() else air_accel
	velocity.x = move_toward(velocity.x, dir * run_speed, accel * delta)
	# 검을 휘두르는 동안은 방향이 바뀌지 않아요.
	if dir != 0.0 and attack_pose_timer <= 0.0:
		facing = 1 if dir > 0.0 else -1


func apply_gravity(delta: float) -> void:
	var g := gravity
	# 점프 꼭대기에서 살짝 둥실 떠 있어서 조작하기 쉬워요.
	if absf(velocity.y) < 40.0 and Input.is_action_pressed("jump"):
		g *= 0.6
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		Sound.play("jump")
		Effects.dust(get_parent(), global_position)
	# 점프 키를 일찍 떼면 낮게 뛰어요.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut


# ── 대시 ───────────────────────────────────────────────

func is_dashing() -> bool:
	return dash_timer > 0.0


func can_dash() -> bool:
	return dash_cooldown_timer <= 0.0 and (is_on_floor() or can_air_dash)


func start_dash(dir: float) -> void:
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	dash_timer = dash_time
	dash_cooldown_timer = dash_cooldown
	if not is_on_floor():
		can_air_dash = false
	attack_timer = 0.0
	attack_pose_timer = 0.0
	slash.hide()
	Sound.play("dash")


# 대시하는 동안 뒤에 잔상이 남아요.
func update_ghosts(delta: float) -> void:
	ghost_timer -= delta
	if ghost_timer > 0.0:
		return
	ghost_timer = 0.03
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.frame = FRAME_DASH
	ghost.flip_h = sprite.flip_h
	ghost.global_position = sprite.global_position
	ghost.modulate = Color(0.6, 0.8, 1.0, 0.6)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)


# ── 공격 ───────────────────────────────────────────────

func start_attack() -> void:
	attack_cooldown_timer = attack_cooldown
	attack_timer = attack_active_time
	attack_pose_timer = 0.18
	hit_list.clear()
	pogo_done = false
	Sound.play("swipe")

	var shape := attack_shape.shape as RectangleShape2D
	slash.flip_h = false
	slash.flip_v = false
	if Input.is_action_pressed("move_up"):
		# ↑ + X: 위로 베기
		attack_dir = Vector2.UP
		shape.size = Vector2(26, 30)
		attack_shape.position = Vector2(0, -32)
		slash.position = Vector2(0, -30)
		slash.rotation = -PI / 2
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		# 공중에서 ↓ + X: 아래로 베기 (맞으면 통통 튀어 올라요)
		attack_dir = Vector2.DOWN
		shape.size = Vector2(26, 28)
		attack_shape.position = Vector2(0, 8)
		slash.position = Vector2(0, 6)
		slash.rotation = PI / 2
	else:
		# 그냥 X: 바라보는 쪽으로 베기
		attack_dir = Vector2(facing, 0)
		shape.size = Vector2(32, 22)
		attack_shape.position = Vector2(facing * 18, -11)
		slash.position = Vector2(facing * 17, -11)
		slash.rotation = 0.0
		slash.flip_h = facing < 0

	# 휘두르기 효과 그림을 잠깐 보여줘요.
	slash.show()
	slash.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.14)
	tween.tween_callback(slash.hide)


func update_attack() -> void:
	if attack_timer <= 0.0:
		return
	var hit_anything := false
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and not hit_list.has(body) and body.has_method("take_hit"):
			hit_list.append(body)
			# 위/아래로 벨 때도 몬스터는 옆으로 밀려나요.
			var push := attack_dir
			if attack_dir.x == 0.0:
				push = Vector2(signf(body.global_position.x - global_position.x), 0)
			body.take_hit(GameState.attack_damage(), push)
			hit_anything = true
	# 아래 베기로 가시를 치면 다치지 않고 튀어 올라요.
	if attack_dir == Vector2.DOWN:
		for area in attack_area.get_overlapping_areas():
			if area.is_in_group("hazard"):
				hit_anything = true
	if hit_anything:
		on_attack_landed()


func on_attack_landed() -> void:
	if attack_dir == Vector2.DOWN:
		if not pogo_done:
			pogo_done = true
			velocity.y = pogo_velocity
			can_air_dash = true
			Sound.play("pogo")
	elif attack_dir.x != 0.0:
		recoil_timer = 0.08
	if not hit_list.is_empty():
		shake(1.5, 0.08)
		GameState.hitstop(0.045)


# ── 다치기 ─────────────────────────────────────────────

## 몬스터에게 맞았을 때 불려요. from_x는 때린 쪽의 x 위치예요. (그 반대쪽으로 밀려나요)
func take_damage(amount: int, from_x: float) -> void:
	# 무적이거나 대시하는 중에는 다치지 않아요.
	if is_dead or respawning or invincible_timer > 0.0 or is_dashing():
		return
	if not lose_hp(amount):
		return
	invincible_timer = invincible_time
	hurt_timer = hurt_stun_time
	attack_timer = 0.0
	var push := signf(global_position.x - from_x)
	if push == 0.0:
		push = -facing
	velocity = Vector2(push * 160.0, -180.0)


## 가시에 닿거나 구덩이에 빠졌을 때 불려요. 마지막으로 밟은 안전한 땅으로 돌아가요.
func hit_hazard() -> void:
	if is_dead or respawning:
		return
	# 방금 맞아서 무적이면 체력은 그대로, 자리만 옮겨요.
	if invincible_timer <= 0.0:
		if not lose_hp(1):
			return
	respawn_at_safe_position()


# 체력을 깎아요. 쓰러졌으면 false를 돌려줘요.
func lose_hp(amount: int) -> bool:
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	Sound.play("hurt")
	shake(4.0, 0.25)
	GameState.hitstop(0.12)
	Effects.burst(get_parent(), global_position + Vector2(0, -12), Color(0.1, 0.1, 0.15), 10, 90.0)
	if hp <= 0:
		die()
		return false
	return true


## 체력을 채워요.
func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
	Sound.play("heal")


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	slash.hide()
	sprite.frame = FRAME_HURT
	sprite.visible = true
	Sound.play("faint")
	died.emit()
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", -PI / 2 * facing, 0.3)
	tween.parallel().tween_property(sprite, "position:y", -4.0, 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)


func respawn_at_safe_position() -> void:
	respawning = true
	velocity = Vector2.ZERO
	dash_timer = 0.0
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	await tween.finished
	global_position = safe_position
	camera.reset_smoothing()
	invincible_timer = invincible_time
	tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
	await tween.finished
	respawning = false


func check_pit() -> void:
	if global_position.y > map_bottom + 16.0:
		hit_hazard()


# 두 발이 모두 단단한 땅 위에 있고 근처에 가시가 없으면, 그 자리를 "안전한 자리"로 기억해요.
func update_safe_position(delta: float) -> void:
	if not is_on_floor() or hurt_timer > 0.0:
		safe_timer = 0.0
		return
	safe_timer += delta
	if safe_timer < 0.2:
		return
	var space := get_world_2d().direct_space_state
	for dx in [-7.0, 7.0]:
		var ground := PhysicsPointQueryParameters2D.new()
		ground.position = global_position + Vector2(dx, 3)
		ground.collision_mask = 1
		if space.intersect_point(ground, 1).is_empty():
			return
	for dx in [-14.0, 0.0, 14.0]:
		var danger := PhysicsPointQueryParameters2D.new()
		danger.position = global_position + Vector2(dx, -6)
		danger.collision_mask = 16
		danger.collide_with_areas = true
		danger.collide_with_bodies = false
		if not space.intersect_point(danger, 1).is_empty():
			return
	safe_position = global_position


# ── 시간, 카메라, 그림 ─────────────────────────────────

func update_timers(delta: float) -> void:
	coyote_timer -= delta
	jump_buffer_timer -= delta
	dash_cooldown_timer -= delta
	attack_cooldown_timer -= delta
	attack_pose_timer -= delta
	recoil_timer -= delta
	invincible_timer -= delta
	hurt_timer -= delta
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			# 대시가 끝나면 달리기 속도로 돌아가요.
			velocity.x = facing * run_speed
	attack_timer -= delta


## 화면을 흔들어요. strength: 몇 픽셀 흔들지, time: 몇 초 동안
func shake(strength: float, time := 0.2) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_timer = maxf(shake_timer, time)


func update_shake(delta: float) -> void:
	var offset := Vector2.ZERO
	if shake_timer > 0.0:
		shake_timer -= delta
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength
		if shake_timer <= 0.0:
			shake_strength = 0.0
	camera.offset = Vector2(look_ahead, -20.0) + offset.round()


func update_camera(delta: float) -> void:
	# 달리는 쪽을 조금 더 보여줘요.
	var target := facing * 28.0 if absf(velocity.x) > 10.0 else look_ahead
	look_ahead = lerpf(look_ahead, target, 2.0 * delta)


func update_animation(delta: float) -> void:
	anim_time += delta
	sprite.flip_h = facing < 0

	if hurt_timer > 0.0:
		sprite.frame = FRAME_HURT
	elif is_dashing():
		sprite.frame = FRAME_DASH
	elif attack_pose_timer > 0.0:
		sprite.frame = FRAME_ATTACK
	elif not is_on_floor():
		sprite.frame = FRAME_JUMP if velocity.y < 0.0 else FRAME_FALL
	elif absf(velocity.x) > 10.0:
		sprite.frame = FRAME_RUN + int(anim_time * 10.0) % 4
	elif Input.is_action_pressed("move_up") and not Dialogue.is_busy():
		sprite.frame = FRAME_LOOK_UP
	else:
		sprite.frame = FRAME_IDLE + int(anim_time * 2.0) % 2

	# 무적인 동안은 깜빡깜빡
	sprite.visible = invincible_timer <= 0.0 or int(invincible_timer * 20.0) % 2 == 0
