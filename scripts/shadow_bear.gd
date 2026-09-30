extends CharacterBody2D
## 그림자 곰 (보스)
##
## - 그림자 갑옷을 입고 있을 때는 꼬리 공격이 통하지 않아요. ("팅!")
## - 별빛을 가까이서 비추면 갑옷이 벗겨지고 어질어질해져요. → 이때 꼬리로 때려요!
## - 돌진하다가 벽에 부딪혀도 어질어질해져요. → 대시로 피하면서 벽으로 유도해요!
## - 체력이 절반 아래로 떨어지면 더 빨라지고 슬라임을 불러요. (2단계)

## 체력이 바뀌면 알려줘요. (화면 위 체력 막대가 들어요)
signal health_changed(hp: int, max_hp: int)
## 쓰러지면 알려줘요.
signal defeated

@export var max_hp: int = 10
## 평소에 코랄 쪽으로 걸어오는 속도
@export var walk_speed: float = 28.0
## 돌진 속도
@export var charge_speed: float = 230.0
## 별빛이 이 거리(픽셀) 안에서 비쳐야 갑옷이 벗겨져요.
@export var starlight_range: float = 80.0
## 별빛을 몇 초 동안 비춰야 갑옷이 벗겨지는지
@export var starlight_time_needed: float = 1.0
## 별빛에 갑옷이 벗겨진 뒤 어질어질한 시간 (초)
@export var dazed_time: float = 2.5
## 벽에 부딪힌 뒤 어질어질한 시간 (초)
@export var crash_time: float = 2.0
## 어질어질에서 깨어난 뒤, 갑옷이 단단해져서 별빛이 안 통하는 시간 (초)
@export var armor_harden_time: float = 4.0

const ORB_SCENE := preload("res://scenes/shadow_orb.tscn")
const SPIKE_SCENE := preload("res://scenes/shadow_spike.tscn")
const SLIME_SCENE := preload("res://scenes/shadow_slime.tscn")
const CUB_TEXTURE := preload("res://assets/boss/bear_cub.png")

const SHADOW_COLOR := Color(0.32, 0.2, 0.48)

enum State { WAIT, IDLE, WINDUP, CHARGE, ORBS, SLAM, DAZED, DEFEATED }

# 그림 칸 번호
const FRAME_IDLE := 0
const FRAME_WINDUP := 1
const FRAME_CHARGE := 2
const FRAME_DAZED := 3

@onready var sprite: Sprite2D = $Sprite2D
@onready var eyes: Sprite2D = $Sprite2D/Eyes
@onready var aura: CPUParticles2D = $Aura
@onready var dazed_stars: Node2D = $DazedStars
@onready var contact_area: Area2D = $ContactArea

var hp := 0
var state := State.WAIT
var state_time := 0.0
var state_length := 0.0          # 지금 상태를 얼마나 오래 할지
var armored := true              # 그림자 갑옷을 입고 있는지
var starlight_exposure := 0.0    # 별빛을 받은 시간
var harden_timer := 0.0          # 0보다 크면 갑옷이 단단해서 별빛이 안 통해요
var phase_two := false
var next_attack := ""
var last_attack := ""
var charge_direction := Vector2.ZERO
var knockback := Vector2.ZERO
var hit_cooldown := 0.0
var shown_armor_hint := false


func _ready() -> void:
	hp = max_hp
	set_armored(true)
	dazed_stars.hide()


## 싸움을 시작해요. (굴 장면이 인사말이 끝난 뒤 불러요)
func start_fight() -> void:
	var player := get_player()
	if player:
		# 코랄과 부딪혀 멈추지 않고 그대로 지나가며 들이받아요.
		add_collision_exception_with(player)
	enter(State.IDLE)


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	# 빛나는 눈은 몸과 같은 칸을 보여줘요.
	if eyes.visible:
		eyes.frame = sprite.frame
		eyes.offset = sprite.offset
	# 어질어질 별이 머리 위에서 빙글빙글 돌아요.
	if dazed_stars.visible:
		dazed_stars.rotation += delta * 4.0
		for star in dazed_stars.get_children():
			star.rotation = -dazed_stars.rotation


func _physics_process(delta: float) -> void:
	if state in [State.WAIT, State.DEFEATED] or Dialogue.is_busy():
		return
	state_time += delta
	hit_cooldown -= delta
	var player := get_player()
	if player == null:
		return
	update_starlight(player, delta)

	match state:
		State.IDLE:
			sprite.frame = FRAME_IDLE
			sprite.offset.y = -24 + round(sin(state_time * 6.0))
			velocity = global_position.direction_to(player.global_position) * walk_speed
			if state_time > state_length:
				choose_attack()
		State.WINDUP:
			# 공격 준비: 부르르 떨어요.
			sprite.offset.x = round(sin(state_time * 60.0))
			velocity = Vector2.ZERO
			if state_time > state_length:
				sprite.offset.x = 0
				do_attack(player)
		State.CHARGE:
			velocity = charge_direction * charge_speed * (1.2 if phase_two else 1.0)
		State.ORBS, State.SLAM:
			velocity = Vector2.ZERO
			if state_time > state_length:
				enter(State.IDLE)
		State.DAZED:
			velocity = Vector2.ZERO
			if state_time > state_length:
				set_armored(true)
				harden_timer = armor_harden_time
				FloatingText.spawn(self, global_position + Vector2(0, -52), "그림자 갑옷이 다시 생겼다!", Color(0.85, 0.7, 1))
				dazed_stars.hide()
				enter(State.IDLE)

	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()

	if state == State.CHARGE:
		if get_slide_collision_count() > 0:
			crash()
		elif state_time > 1.4:
			enter(State.IDLE)

	# 어질어질할 때가 아니면 몸에 닿기만 해도 아파요.
	if state != State.DAZED:
		for body in contact_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				body.take_damage(1, global_position)


func enter(new_state: State, length := 0.0) -> void:
	state = new_state
	state_time = 0.0
	state_length = length
	if new_state == State.IDLE:
		state_length = randf_range(0.6, 1.0) if phase_two else randf_range(1.0, 1.6)


# ── 공격 ───────────────────────────────────────────────

func choose_attack() -> void:
	var options := ["charge", "orbs", "slam"]
	options.erase(last_attack)  # 같은 공격을 두 번 연속으로 하지 않아요.
	next_attack = options.pick_random()
	last_attack = next_attack
	var windup := {"charge": 0.7, "orbs": 0.5, "slam": 0.6}[next_attack] as float
	if phase_two:
		windup *= 0.75
	sprite.frame = FRAME_CHARGE if next_attack == "charge" else FRAME_WINDUP
	sprite.offset.y = -24
	enter(State.WINDUP, windup)


func do_attack(player: Node2D) -> void:
	match next_attack:
		"charge":
			charge_direction = global_position.direction_to(player.global_position)
			Sound.play("roar", -6.0, 1.4)
			sprite.frame = FRAME_CHARGE
			enter(State.CHARGE)
		"orbs":
			fire_orbs(player)
			if phase_two:
				get_tree().create_timer(0.4).timeout.connect(fire_orbs.bind(player))
			enter(State.ORBS, 0.9)
		"slam":
			slam(player)
			enter(State.SLAM, 1.0)


# 그림자 구슬을 부채꼴로 쏴요.
func fire_orbs(player: Node2D) -> void:
	if state == State.DEFEATED or not is_instance_valid(player):
		return
	Sound.play("orb")
	var count := 7 if phase_two else 5
	var spread := deg_to_rad(80.0)
	var center := (player.global_position - global_position).angle()
	for i in count:
		var angle := center - spread / 2.0 + spread * i / (count - 1)
		var orb := ORB_SCENE.instantiate()
		orb.velocity = Vector2.from_angle(angle) * (85.0 if phase_two else 70.0)
		get_parent().add_child(orb)
		orb.global_position = global_position + Vector2(0, -16)


# 쿵! 땅을 내리쳐서 코랄 주변에 그림자 가시를 솟게 해요.
func slam(player: Node2D) -> void:
	sprite.frame = FRAME_IDLE
	var squash := create_tween()
	squash.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.08)
	squash.tween_property(sprite, "scale", Vector2.ONE, 0.2)
	player.shake_camera(3.0, 0.3)
	Sound.play("slam")
	get_tree().create_timer(0.8).timeout.connect(Sound.play.bind("spike"))
	var spots := [player.global_position + Vector2(0, 4)]
	for i in (4 if phase_two else 2):
		spots.append(player.global_position + Vector2(0, 4) + Vector2.from_angle(randf() * TAU) * randf_range(20.0, 44.0))
	for spot in spots:
		var spike := SPIKE_SCENE.instantiate()
		get_parent().add_child(spike)
		spike.global_position = spot


# 돌진하다 벽에 부딪혔어요!
func crash() -> void:
	var player := get_player()
	if player:
		player.shake_camera(4.0, 0.4)
	Sound.play("boom")
	FloatingText.spawn(self, global_position + Vector2(0, -52), "쾅!", Color(1, 0.85, 0.5))
	knockback = -charge_direction * 80.0
	daze(crash_time)


# ── 갑옷과 어질어질 ────────────────────────────────────

func set_armored(on: bool) -> void:
	armored = on
	starlight_exposure = 0.0
	sprite.self_modulate = SHADOW_COLOR if on else Color.WHITE
	eyes.visible = on
	aura.emitting = on


func daze(duration: float) -> void:
	Sound.play("daze", 0.0, 1.0, 0.0)
	set_armored(false)
	sprite.frame = FRAME_DAZED
	sprite.offset = Vector2(0, -24)
	dazed_stars.show()
	enter(State.DAZED, duration)


# 별빛을 가까이서 받으면 갑옷이 점점 옅어지다가 벗겨져요.
func update_starlight(player: Node2D, delta: float) -> void:
	if not armored or state == State.DAZED:
		return
	if harden_timer > 0.0:
		# 갑옷이 단단해진 동안은 별빛을 비춰도 소용없어요. (그림자가 더 짙게 일렁여요)
		harden_timer -= delta
		return
	var lit: bool = player.is_starlight_on() \
			and global_position.distance_to(player.global_position) < starlight_range
	if lit:
		starlight_exposure += delta
	else:
		starlight_exposure = maxf(starlight_exposure - delta * 0.5, 0.0)
	sprite.self_modulate = SHADOW_COLOR.lerp(Color.WHITE, starlight_exposure / starlight_time_needed * 0.7)
	if starlight_exposure >= starlight_time_needed:
		FloatingText.spawn(self, global_position + Vector2(0, -52), "그림자 갑옷이 벗겨졌다!", Color(1, 0.95, 0.6))
		daze(dazed_time)


## 코랄의 꼬리에 맞았을 때 불려요.
func take_hit(amount: int, from: Vector2) -> void:
	if state in [State.WAIT, State.DEFEATED] or hit_cooldown > 0.0:
		return
	hit_cooldown = 0.25

	if armored:
		Sound.play("clink")
		FloatingText.spawn(self, global_position + Vector2(0, -52), "팅!", Color(0.8, 0.8, 1))
		if not shown_armor_hint:
			shown_armor_hint = true
			FloatingText.spawn(self, global_position + Vector2(0, -38), "별빛을 비춰 봐!", Color(1, 0.95, 0.6))
		return

	hp = max(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	Sound.play("hit", 0.0, 0.8)
	knockback = from.direction_to(global_position) * 120.0
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", Color(1, 0.4, 0.4), 0.05)
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	if hp <= 0:
		die()
	elif not phase_two and hp * 2 <= max_hp:
		start_phase_two()


func start_phase_two() -> void:
	phase_two = true
	Sound.play("roar", 0.0, 1.0, 0.0)
	FloatingText.spawn(self, global_position + Vector2(0, -52), "크아아앙!", Color(1, 0.5, 0.6))
	# 그림자 슬라임 두 마리를 불러요.
	for offset in [Vector2(-60, 20), Vector2(60, 20)]:
		var slime := SLIME_SCENE.instantiate()
		slime.acorn_drop_chance = 0.0
		get_parent().add_child(slime)
		slime.global_position = global_position + offset


func die() -> void:
	state = State.DEFEATED
	velocity = Vector2.ZERO
	dazed_stars.hide()
	contact_area.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	defeated.emit()


## 쓰러진 뒤 그림자가 녹아내리고 아기 곰으로 돌아가요. (연출)
func melt_into_cub() -> void:
	set_armored(false)
	sprite.frame = FRAME_DAZED
	var tween := create_tween()
	for i in 3:
		tween.tween_property(sprite, "modulate", Color(3, 3, 3), 0.15)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	tween.tween_property(sprite, "scale", Vector2(0.3, 0.3), 0.6).set_trans(Tween.TRANS_BACK)
	await tween.finished
	sprite.texture = CUB_TEXTURE
	sprite.hframes = 2
	sprite.frame = 0
	sprite.offset = Vector2(0, -8)
	sprite.scale = Vector2.ONE
	await get_tree().create_timer(0.5).timeout
