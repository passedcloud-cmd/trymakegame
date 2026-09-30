extends Node2D
## 몬스터 머리 위에 뜨는 작은 체력 막대예요.
## 체력이 많으면 초록색, 절반 아래면 노란색, 조금 남으면 빨간색이 돼요.

## 막대 너비 (픽셀)
@export var width: float = 14.0

@onready var back: ColorRect = $Back
@onready var fill: ColorRect = $Fill

var target: Node2D          # 따라다닐 몬스터
var offset := Vector2.ZERO  # 몬스터 위치에서 얼마나 떨어져 있을지


func _ready() -> void:
	# 밤 색깔에 어두워지지 않도록 "겹쳐 그리는 층"으로 옮겨 가서 몬스터를 따라다녀요.
	target = get_parent() as Node2D
	offset = position
	move_to_overlay.call_deferred()


# 맵 준비가 다 끝난 뒤에 옮겨 가요. (준비 중에는 새 노드를 붙일 수 없어요)
func move_to_overlay() -> void:
	if is_instance_valid(target):
		reparent(WorldOverlay.of(self), false)

	back.position = Vector2(-width / 2.0 - 1.0, -1.0)
	back.size = Vector2(width + 2.0, 4.0)
	fill.position = Vector2(-width / 2.0, 0.0)
	fill.size = Vector2(width, 2.0)


func _process(_delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return
	global_position = target.global_position + offset


## 남은 체력 비율(0~1)을 알려주면 막대가 줄어들어요.
func set_ratio(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	create_tween().tween_property(fill, "size:x", width * ratio, 0.2)
	if ratio > 0.5:
		fill.color = Color(0.45, 0.9, 0.4)
	elif ratio > 0.25:
		fill.color = Color(1.0, 0.82, 0.3)
	else:
		fill.color = Color(1.0, 0.35, 0.35)
