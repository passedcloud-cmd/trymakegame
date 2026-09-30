extends Enemy
## 이끼벌레: 땅 위를 천천히 왔다 갔다 해요. 벽이나 낭떠러지를 만나면 뒤로 돌아요.

## 걷는 빠르기
@export var speed := 28.0

var dir := -1


func think(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = dir * speed + knock_x()
	move_and_slide()
	if is_on_floor() and knock_timer <= 0.0 and (is_on_wall() or not floor_ahead(dir, 9.0)):
		dir = -dir
	sprite.flip_h = dir < 0
	sprite.frame = int(anim_time * 6.0) % 2
