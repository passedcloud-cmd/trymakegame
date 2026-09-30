extends Area2D
## 보스가 땅을 쿵! 찍으면 생기는 충격파예요. 땅을 타고 달리다가 벽에 닿으면 사라져요.
## 점프로 넘어요!

var dir := 1
var speed := 150.0
var life := 2.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Sprite2D.flip_h = dir < 0


func _physics_process(delta: float) -> void:
	if Dialogue.is_busy():
		return
	position.x += dir * speed * delta
	life -= delta
	$Sprite2D.scale.y = 1.0 + sin(life * 30.0) * 0.15
	if life <= 0.0 or hits_wall():
		queue_free()


func hits_wall() -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(dir * 8, -6)
	query.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(1, global_position.x - dir * 10)
