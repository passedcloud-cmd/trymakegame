extends CanvasLayer
## 화면 위쪽에 보스의 체력 막대를 보여줘요.

@onready var fill: ColorRect = $Bar/Fill
@onready var name_label: Label = $Name

var boss_name := ""
@onready var bar_width: float = $Bar.size.x - 2


func _ready() -> void:
	hide()


## 보스를 연결해요. 보스 체력이 바뀌면 막대도 줄어들어요.
func setup(boss: Node) -> void:
	boss_name = name_label.text
	boss.health_changed.connect(update_bar)
	update_bar(boss.hp, boss.max_hp)


func update_bar(hp: int, max_hp: int) -> void:
	var ratio := clampf(float(hp) / max_hp, 0.0, 1.0)
	name_label.text = "%s   %d / %d" % [boss_name, hp, max_hp]
	create_tween().tween_property(fill, "size:x", bar_width * ratio, 0.25)
