extends StaticBody2D
## 맵의 크기를 알려줘요. 코랄의 카메라가 맵 밖을 비추지 않게 이 크기에 맞춰져요.
## (이 노드 아래의 충돌 모양들은 맵 밖으로 나가지 못하게 막는 투명한 벽이에요.)

## 맵 크기 (픽셀)
@export var map_size: Vector2 = Vector2(800, 384)


func _ready() -> void:
	add_to_group("map_bounds")
