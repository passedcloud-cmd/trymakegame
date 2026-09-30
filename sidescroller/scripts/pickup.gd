extends CharacterBody2D
## 몬스터가 떨어뜨리는 아이템이에요. 기사가 가까이 가면 저절로 빨려 와요.
##   shard: 빛조각(돈). 대장장이와 약초상에게 쓸 수 있어요.
##   heart: 회복 하트. 가면(체력)을 하나 채워요.

@export_enum("shard", "heart") var kind := "shard"
## 몇 개짜리인지
@export var value := 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collect_area: Area2D = $CollectArea

var age := 0.0
## true면 기사에게 날아가요.
var magnet := false


func _physics_process(delta: float) -> void:
	age += delta
	if sprite.hframes > 1:
		sprite.frame = int(age * 8.0) % sprite.hframes
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.is_dead:
		fall(delta)
		return

	var target: Vector2 = player.global_position + Vector2(0, -10)
	if not magnet and age > 0.4 and wants_player(player) and global_position.distance_to(target) < 40.0:
		magnet = true
	if magnet:
		# 벽을 지나서라도 기사에게 날아가요.
		global_position = global_position.move_toward(target, (140.0 + age * 160.0) * delta)
	else:
		fall(delta)

	if age > 0.25 and wants_player(player):
		for body in collect_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				collect(body)
				return


func fall(delta: float) -> void:
	var falling_speed := velocity.y
	velocity.y = minf(velocity.y + 700.0 * delta, 300.0)
	move_and_slide()
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		# 세게 떨어지면 통 하고 한 번 튀어요.
		if falling_speed > 80.0:
			velocity.y = -falling_speed * 0.35


# 하트는 체력이 가득 차 있으면 안 먹어요.
func wants_player(player: Node) -> bool:
	return kind == "shard" or player.hp < player.max_hp


func collect(player: Node) -> void:
	if kind == "shard":
		GameState.shards += value
		Sound.play("shard")
	else:
		player.heal(value)
	Effects.burst(get_parent(), global_position, Color(0.7, 0.95, 1.0) if kind == "shard" else Color(1, 0.5, 0.6), 5, 40.0, 0.2)
	queue_free()
