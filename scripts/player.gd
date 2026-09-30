extends CharacterBody2D
## 주인공 여우 "코랄"을 움직이는 코드예요.

## 체력이 바뀔 때마다 알려주는 신호예요. (화면 위 하트가 이걸 듣고 바뀌어요)
signal health_changed(hp: int, max_hp: int)

## 코랄이 1초에 몇 픽셀 움직일지 정해요. 숫자가 클수록 빨라요.
@export var speed: float = 80.0
## 걷기 그림이 1초에 몇 장 넘어갈지 정해요.
@export var walk_fps: float = 8.0

@export_group("전투")
## 최대 체력 (하트 개수)
@export var max_hp: int = 3
## 꼬리 공격이 몬스터에게 주는 피해
@export var attack_damage: int = 1
## 꼬리를 휘두르는 시간 (초)
@export var attack_duration: float = 0.15
## 한 번 휘두른 뒤 다시 휘두를 수 있을 때까지 기다리는 시간 (초)
@export var attack_cooldown: float = 0.35
## 맞은 뒤 무적인 시간 (초)
@export var invincible_time: float = 1.0

@export_group("대시")
## 대시 속도
@export var dash_speed: float = 240.0
## 대시하는 시간 (초)
@export var dash_time: float = 0.16
## 대시 후 다시 대시할 수 있을 때까지 기다리는 시간 (초)
@export var dash_cooldown: float = 0.5

@export_group("그림 줄 번호")
# 스프라이트 시트(assets/coral.png)에서 방향마다 몇 번째 줄을 쓸지 정해요.
# 다른 그림으로 바꿀 때 줄 순서가 다르면 이 숫자만 고치면 돼요.
@export var row_down: int = 0
@export var row_up: int = 1
@export var row_side: int = 2

@onready var sprite: Sprite2D = $Sprite2D
@onready var tail_hitbox: Area2D = $TailHitbox
@onready var tail_swipe: Sprite2D = $TailSwipe
@onready var gap_sensor: Area2D = $GapSensor
@onready var light: PointLight2D = $Light
@onready var camera: Camera2D = $Camera2D

var hp := 0
var facing := Vector2.DOWN       # 코랄이 바라보는 방향
var facing_row := 0
var walk_time := 0.0
var attack_timer := 0.0          # 0보다 크면 지금 꼬리를 휘두르는 중
var cooldown_timer := 0.0
var invincible_timer := 0.0      # 0보다 크면 무적
var knockback := Vector2.ZERO    # 맞았을 때 뒤로 밀려나는 힘
var hit_enemies: Array = []      # 이번 휘두르기에 이미 맞은 몬스터 (한 번에 두 번 맞지 않게)
var is_dead := false
var dash_timer := 0.0            # 0보다 크면 지금 대시하는 중
var dash_cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var dash_extra_time := 0.0       # 틈 위에서 대시가 끝나지 않게 더 간 시간
var ghost_timer := 0.0
var shake_strength := 0.0        # 화면 흔들림 세기
var shake_timer := 0.0


func _ready() -> void:
	# 퀘스트 보상으로 늘어난 하트도 더해요.
	max_hp += GameState.bonus_hearts
	hp = max_hp
	tail_swipe.hide()
	move_to_spawn()
	fit_camera_to_map()
	update_light(false)


# 다른 맵에서 넘어왔으면, 정해진 출발 지점으로 옮겨요.
func move_to_spawn() -> void:
	if GameState.next_spawn == "":
		return
	for marker in get_tree().get_nodes_in_group("spawn"):
		if marker.name == GameState.next_spawn:
			global_position = marker.global_position
			# 새 맵에 들어갈 땐 위쪽(안쪽)을, 동굴에서 나올 땐 아래쪽을 바라봐요.
			var entering := marker.name in ["Entrance", "FromDen"]
			facing = Vector2.UP if entering else Vector2.DOWN
			facing_row = row_up if entering else row_down
			return


# 카메라가 맵 밖을 비추지 않도록 맵 크기에 맞춰요.
func fit_camera_to_map() -> void:
	var bounds := get_tree().get_first_node_in_group("map_bounds")
	if bounds:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(bounds.map_size.x)
		camera.limit_bottom = int(bounds.map_size.y)


# 이 함수는 게임이 돌아가는 동안 1초에 60번씩 자동으로 불려요.
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 방향키 입력을 읽어서 "어느 쪽으로 갈지"를 구해요.
	# 예: 오른쪽 키 → (1, 0), 위쪽 키 → (0, -1)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 대화 중에는 움직이지 않아요.
	if Dialogue.is_busy():
		direction = Vector2.ZERO
	elif Input.is_action_just_pressed("starlight") and GameState.has_starlight():
		GameState.starlight_on = not GameState.starlight_on
		update_light(true)
	elif Input.is_action_just_pressed("dash") and can_dash():
		start_dash(direction)
	elif Input.is_action_just_pressed("attack") and cooldown_timer <= 0.0 and not is_dashing():
		start_attack()

	if is_dashing():
		# 대시 중에는 정해진 방향으로 빠르게 날아가요.
		velocity = dash_direction * dash_speed
	else:
		# 방향 × 속도 = 실제로 움직일 빠르기. 꼬리를 휘두르는 동안은 느려져요.
		var move_speed := speed * (0.4 if attack_timer > 0.0 else 1.0)
		velocity = direction * move_speed + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 600.0 * delta)

	# 실제로 움직여요. 벽에 부딪히면 알아서 멈추거나 미끄러져요.
	move_and_slide()

	update_attack(delta)
	update_dash(delta)
	update_shake(delta)
	update_invincible(delta)
	update_animation(direction, delta)


# ── 공격 ───────────────────────────────────────────────

func start_attack() -> void:
	attack_timer = attack_duration
	cooldown_timer = attack_cooldown
	hit_enemies.clear()

	# 바라보는 방향 앞쪽에 공격 판정과 효과 그림을 놓아요.
	tail_hitbox.position = facing * 12.0 + Vector2(0, 2)
	tail_swipe.position = facing * 8.0 + Vector2(0, 2)
	tail_swipe.rotation = facing.angle()
	tail_swipe.modulate.a = 1.0
	tail_swipe.show()


func update_attack(delta: float) -> void:
	cooldown_timer -= delta
	if attack_timer <= 0.0:
		return

	attack_timer -= delta
	# 효과 그림이 점점 투명해져요.
	tail_swipe.modulate.a = clampf(attack_timer / attack_duration, 0.0, 1.0)

	# 공격 판정 안에 있는 몬스터에게 피해를 줘요.
	for body in tail_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy") and body not in hit_enemies:
			hit_enemies.append(body)
			body.take_hit(attack_damage, global_position)

	if attack_timer <= 0.0:
		tail_swipe.hide()


# ── 화면 흔들림 ────────────────────────────────────────

## 화면을 흔들어요. (보스가 쿵! 할 때)
func shake_camera(strength: float, duration: float) -> void:
	shake_strength = strength
	shake_timer = duration


func update_shake(delta: float) -> void:
	if shake_timer <= 0.0:
		camera.offset = Vector2.ZERO
		return
	shake_timer -= delta
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * shake_strength


# ── 불빛 ───────────────────────────────────────────────

## 별빛이 켜져 있는지 알려줘요. (그림자 장막, 슬라임이 이걸 확인해요)
func is_starlight_on() -> bool:
	return GameState.has_starlight() and GameState.starlight_on


## 코랄 주위의 불빛을 정해요.
## 별빛이 켜져 있으면 크고 밝게, 반딧불이 병만 있으면 작고 은은하게, 둘 다 없으면 꺼요.
func update_light(animate: bool) -> void:
	var light_scale := 0.0
	var energy := 0.0
	var color := Color(0.8, 1.0, 0.55)
	if is_starlight_on():
		light_scale = 3.6
		energy = 1.1
		color = Color(1.0, 0.93, 0.65)
	elif GameState.has_jar():
		light_scale = 1.5
		energy = 0.9
	light.enabled = energy > 0.0 or animate
	if not animate:
		light.texture_scale = maxf(light_scale, 0.1)
		light.energy = energy
		light.color = color
		return
	var tween := create_tween().set_parallel()
	tween.tween_property(light, "texture_scale", maxf(light_scale, 0.1), 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", energy, 0.4)
	tween.tween_property(light, "color", color, 0.4)


# ── 대시 ───────────────────────────────────────────────

func is_dashing() -> bool:
	return dash_timer > 0.0


func can_dash() -> bool:
	return GameState.has_dash() and dash_cooldown_timer <= 0.0 and not is_dashing()


func start_dash(direction: Vector2) -> void:
	# 방향키를 누르고 있으면 그쪽으로, 아니면 바라보는 쪽으로 대시해요.
	dash_direction = direction.normalized() if direction != Vector2.ZERO else facing
	dash_timer = dash_time
	dash_cooldown_timer = dash_cooldown
	dash_extra_time = 0.0
	ghost_timer = 0.0
	knockback = Vector2.ZERO
	# 충돌 레이어 2(다리 틈)를 잠깐 무시해서 틈을 건널 수 있게 해요.
	set_collision_mask_value(2, false)


func update_dash(delta: float) -> void:
	dash_cooldown_timer -= delta
	if not is_dashing():
		return

	# 잔상을 남겨요.
	ghost_timer -= delta
	if ghost_timer <= 0.0:
		ghost_timer = 0.03
		spawn_ghost()

	dash_timer -= delta
	if dash_timer > 0.0:
		return
	# 틈 한가운데서 대시가 끝나면 빠질 수 있으니, 틈을 벗어날 때까지 조금 더 가요.
	if gap_sensor.has_overlapping_bodies() and dash_extra_time < 0.3:
		dash_extra_time += delta
		dash_timer = 0.001
		return
	set_collision_mask_value(2, true)


# 코랄 모양의 반투명한 잔상을 만들어요. 점점 사라져요.
func spawn_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(1, 0.85, 0.55, 0.6)
	get_parent().add_child(ghost)
	ghost.global_position = sprite.global_position
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)


# ── 체력 ───────────────────────────────────────────────

## 몬스터에게 맞았을 때 불려요. from은 때린 몬스터의 위치예요.
func take_damage(amount: int, from: Vector2) -> void:
	# 무적이거나, 대시 중이거나, 대화 중이면 맞지 않아요.
	if invincible_timer > 0.0 or is_dead or is_dashing() or Dialogue.is_busy():
		return
	hp = max(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	knockback = (global_position - from).normalized() * 180.0
	invincible_timer = invincible_time
	if hp <= 0:
		die()


## 체력을 회복해요. (최대 체력을 넘지 않아요)
func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


## 최대 체력을 늘리고, 늘어난 만큼 체력도 채워줘요.
func increase_max_hp(amount: int) -> void:
	max_hp += amount
	hp += amount
	health_changed.emit(hp, max_hp)


func update_invincible(delta: float) -> void:
	if invincible_timer <= 0.0:
		return
	invincible_timer -= delta
	# 무적인 동안 깜빡깜빡해요.
	sprite.visible = invincible_timer <= 0.0 or int(invincible_timer * 15.0) % 2 == 0


func die() -> void:
	is_dead = true
	sprite.visible = true
	tail_swipe.hide()
	# 천천히 사라진 뒤 이 맵에 마지막으로 들어온 곳에서 다시 깨어나요.
	# 별, 도토리, 퀘스트 진행 상황은 그대로 남아요.
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_interval(0.4)
	tween.tween_callback(get_tree().reload_current_scene)


# ── 애니메이션 ─────────────────────────────────────────

# 움직이는 방향에 맞춰 그림을 바꿔요.
func update_animation(direction: Vector2, delta: float) -> void:
	if direction == Vector2.ZERO:
		# 멈춰 있으면 첫 번째 칸(서 있는 그림)을 보여줘요.
		walk_time = 0.0
		sprite.frame_coords = Vector2i(0, facing_row)
		return

	# 좌우로 더 많이 움직이면 옆모습, 아니면 앞/뒷모습
	# 꼬리를 휘두르거나 대시하는 중에는 방향을 바꾸지 않아요.
	if attack_timer <= 0.0 and not is_dashing():
		if absf(direction.x) > absf(direction.y):
			facing = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
			facing_row = row_side
			# 옆모습 그림은 오른쪽을 보고 있어서, 왼쪽으로 갈 땐 좌우를 뒤집어요.
			sprite.flip_h = direction.x < 0
		else:
			facing = Vector2.DOWN if direction.y > 0 else Vector2.UP
			facing_row = row_down if direction.y > 0 else row_up
			sprite.flip_h = false

	# 시간이 흐르는 만큼 다음 칸으로 넘겨요. (0 → 1 → 2 → 3 → 0 ...)
	walk_time += delta
	var column := int(walk_time * walk_fps) % sprite.hframes
	sprite.frame_coords = Vector2i(column, facing_row)
