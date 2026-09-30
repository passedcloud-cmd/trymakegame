extends CharacterBody2D
## 그림자 슬라임: 어슬렁거리다가 코랄이 가까이 오면 쫓아와요.

## 체력 (꼬리에 몇 번 맞으면 사라질지)
@export var max_hp: int = 2
## 움직이는 속도
@export var move_speed: float = 28.0
## 코랄이 이 거리(픽셀) 안에 들어오면 쫓아와요.
@export var chase_range: float = 72.0
## 코랄에게 닿았을 때 주는 피해 (하트 개수)
@export var damage: int = 1
## 별빛이 이 거리(픽셀) 안에 비치면 도망가요.
@export var fear_range: float = 64.0
## 사라질 때 도토리를 떨어뜨릴 확률 (1.0 = 100%)
@export_range(0.0, 1.0) var acorn_drop_chance: float = 1.0

const ACORN_SCENE := preload("res://scenes/acorn.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var contact_area: Area2D = $ContactArea

var hp := 0
var time := 0.0
var knockback := Vector2.ZERO
var wander_direction := Vector2.ZERO
var wander_timer := 0.0
var is_dying := false


func _ready() -> void:
	hp = max_hp
	# 슬라임마다 통통 튀는 박자가 조금씩 달라지게 해요.
	time = randf() * 2.0


func _physics_process(delta: float) -> void:
	if is_dying:
		return

	# 통통 튀는 애니메이션 (2칸을 번갈아 보여줘요)
	time += delta
	sprite.frame = int(time * 3.0) % 2

	# 대화 중에는 가만히 있어요.
	if Dialogue.is_busy():
		return

	velocity = decide_direction(delta) * move_speed + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()

	# 코랄에게 닿으면 피해를 줘요.
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(damage, global_position)


# 어느 쪽으로 움직일지 정해요.
func decide_direction(delta: float) -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var distance := global_position.distance_to(player.global_position) if player else INF
	if player and player.is_starlight_on() and distance < fear_range:
		# 별빛이 무서워서 반대쪽으로 도망가요!
		return player.global_position.direction_to(global_position) * 1.4
	if player and distance < chase_range:
		# 코랄이 가까우면 코랄 쪽으로!
		return global_position.direction_to(player.global_position)

	# 멀면 가끔 방향을 바꾸며 어슬렁거려요. (가만히 쉬기도 해요)
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(1.0, 2.5)
		wander_direction = Vector2.ZERO if randf() < 0.4 else Vector2.from_angle(randf() * TAU)
	return wander_direction * 0.6


## 코랄의 꼬리에 맞았을 때 불려요. from은 코랄의 위치예요.
func take_hit(amount: int, from: Vector2) -> void:
	if is_dying:
		return
	hp -= amount
	Sound.play("hit")
	knockback = (global_position - from).normalized() * 200.0

	# 빨갛게 번쩍!
	sprite.modulate = Color(1, 0.35, 0.35)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	if hp <= 0:
		die()


func die() -> void:
	is_dying = true
	Sound.play("pop")
	if randf() < acorn_drop_chance:
		var acorn := ACORN_SCENE.instantiate()
		acorn.position = position
		get_parent().add_child.call_deferred(acorn)
	# 더 이상 부딪히지 않게 충돌을 꺼요.
	$CollisionShape2D.set_deferred("disabled", true)
	# 납작해지면서 사라져요.
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector2(1.6, 0.2), 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
