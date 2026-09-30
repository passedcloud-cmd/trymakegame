class_name Effects
## 반짝이 가루, 먼지 같은 작은 효과를 만드는 도우미예요.
## 사용 예: Effects.burst(get_parent(), global_position, Color.WHITE, 8)


## pos 자리에서 작은 네모 가루가 사방으로 튀어요.
static func burst(parent: Node, pos: Vector2, color: Color, amount := 8, speed := 70.0, life := 0.35) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = life
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 200)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = color
	p.global_position = pos
	p.z_index = 5
	parent.add_child(p)
	p.emitting = true
	# 다 튀고 나면 스스로 사라져요.
	p.finished.connect(p.queue_free)


## 발밑에서 먼지가 옆으로 퍼져요. (점프하거나 착지할 때)
static func dust(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, Color(0.85, 0.82, 0.75, 0.8), 5, 35.0, 0.25)


## 화면을 흔들어요. (기사의 카메라를 흔들어요)
static func shake(tree: SceneTree, strength: float, time := 0.2) -> void:
	var player := tree.get_first_node_in_group("player")
	if player:
		player.shake(strength, time)
