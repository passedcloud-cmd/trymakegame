class_name Enemy
extends CharacterBody2D
## 모든 몬스터가 함께 쓰는 코드예요.
## 새 몬스터를 만들 때는 스크립트 맨 위에 "extends Enemy"라고 쓰고 think() 함수만 새로 만들면 돼요.
## (crawler.gd가 가장 간단한 예시예요)

## 쓰러지면 알려줘요. (스테이지가 이걸 듣고 "남은 몬스터" 숫자를 줄여요)
signal died(enemy: Enemy)
## 체력이 바뀌면 알려줘요. (보스 체력 막대가 이걸 들어요)
signal health_changed(hp: int, max_hp: int)

## 최대 체력. 기사의 기본 공격력은 10이에요.
@export var max_hp := 20
## 닿으면 기사가 잃는 가면 수
@export var contact_damage := 1
## 쓰러질 때 떨어뜨리는 빛조각(돈) 개수
@export var shard_drop := 3
## 쓰러질 때 회복 하트를 떨어뜨릴 확률 (0~1)
@export_range(0.0, 1.0) var heart_drop_chance := 0.1
## 맞았을 때 밀려나는 세기 (0이면 안 밀려나요)
@export var knockback_power := 140.0
## 중력
@export var gravity := 900.0

const SHARD_SCENE := preload("res://scenes/pickup_shard.tscn")
const HEART_SCENE := preload("res://scenes/pickup_heart.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_box: Area2D = $HurtBox

var hp := 0
var dead := false
var flash_timer := 0.0
var knock_timer := 0.0
var knock_velocity := 0.0
var anim_time := 0.0
## 평소 색깔. 공격 준비 중에는 잠깐 다른 색으로 바뀌어요.
var tint := Color.WHITE
var map_bottom := 100000.0


func _ready() -> void:
	hp = max_hp
	var level := get_tree().get_first_node_in_group("level")
	if level:
		map_bottom = level.map_size.y


func _physics_process(delta: float) -> void:
	if dead or Dialogue.is_busy():
		return
	# 구덩이에 떨어지면 쓰러진 걸로 쳐요. (안 그러면 스테이지를 깰 수 없으니까요)
	if global_position.y > map_bottom + 32.0:
		fall_out()
		return
	anim_time += delta
	knock_timer -= delta
	think(delta)
	if contact_active():
		check_contact()
	# 맞으면 잠깐 하얗게 번쩍여요.
	flash_timer -= delta
	sprite.modulate = Color(5, 5, 5) if flash_timer > 0.0 else tint


## 몬스터마다 다르게 움직이는 부분이에요. 이어받은 스크립트에서 새로 써요.
func think(_delta: float) -> void:
	pass


## 닿으면 아프게 할지 정해요. (보스는 어지러울 때 안 아파요)
func contact_active() -> bool:
	return contact_damage > 0


func check_contact() -> void:
	for body in hurt_box.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(contact_damage, global_position.x)


## 기사의 검에 맞았을 때 불려요. dir은 밀려날 방향이에요.
func take_hit(damage: int, dir: Vector2) -> void:
	if dead:
		return
	hp -= damage
	health_changed.emit(maxi(hp, 0), max_hp)
	flash_timer = 0.08
	Sound.play("hit")
	Effects.burst(get_parent(), global_position + Vector2(0, -8), Color(1, 1, 1), 6, 80.0, 0.25)
	knock_velocity = dir.x * knockback_power
	knock_timer = 0.12
	on_hit(dir)
	if hp <= 0:
		die()


## 맞았을 때 몬스터마다 따로 할 일이 있으면 새로 써요.
func on_hit(_dir: Vector2) -> void:
	pass


func die() -> void:
	dead = true
	died.emit(self)
	Sound.play("pop")
	Effects.burst(get_parent(), global_position + Vector2(0, -8), Color(0.55, 0.85, 1.0), 14, 110.0, 0.5)
	drop_items()
	$CollisionShape2D.set_deferred("disabled", true)
	sprite.modulate = Color(5, 5, 5)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.2), 0.15)
	tween.tween_callback(queue_free)


func fall_out() -> void:
	dead = true
	died.emit(self)
	queue_free()


func drop_items() -> void:
	for i in shard_drop:
		spawn_pickup(SHARD_SCENE)
	if randf() < heart_drop_chance:
		spawn_pickup(HEART_SCENE)


func spawn_pickup(scene: PackedScene) -> void:
	var item := scene.instantiate()
	item.position = position + Vector2(0, -10)
	item.velocity = Vector2(randf_range(-70, 70), randf_range(-190, -120))
	get_parent().add_child.call_deferred(item)


# ── 몬스터들이 함께 쓰는 도우미 ────────────────────────

func apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, 400.0)


## 맞아서 밀려나는 빠르기 (밀려나는 중이 아니면 0)
func knock_x() -> float:
	return knock_velocity if knock_timer > 0.0 else 0.0


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


## 기사가 살아 있고, distance 픽셀 안에 있으면 true
func player_near(distance: float) -> bool:
	var player := get_player()
	return player != null and not player.is_dead \
		and player.global_position.distance_to(global_position) < distance


## 기사가 어느 쪽에 있는지 (1 = 오른쪽, -1 = 왼쪽)
func player_side() -> int:
	var player := get_player()
	if player == null:
		return 1
	return 1 if player.global_position.x >= global_position.x else -1


## dir 쪽으로 distance 픽셀 앞에 밟을 땅이 있으면 true (낭떠러지 확인)
func floor_ahead(dir: int, distance := 8.0) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(dir * distance, 4)
	query.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()
