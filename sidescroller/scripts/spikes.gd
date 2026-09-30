extends Area2D
## 가시예요. 기사가 닿으면 가면이 하나 깨지고 마지막으로 밟은 안전한 땅으로 돌아가요.
## 공중에서 ↓+X(아래 베기)로 가시를 치면 다치지 않고 튀어 오를 수 있어요.


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hit_hazard()
