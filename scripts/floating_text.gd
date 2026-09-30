class_name FloatingText
extends Label
## 머리 위로 떠올랐다 사라지는 짧은 글자예요. (예: "팅!", "쾅!")


## 사용 예: FloatingText.spawn(self, global_position + Vector2(0, -40), "팅!")
static func spawn(from: Node, world_position: Vector2, message: String, color := Color.WHITE) -> void:
	var label := FloatingText.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(120, 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 20
	WorldOverlay.of(from).add_child(label)
	label.global_position = world_position - Vector2(60, 8)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 16, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


## 데미지 숫자를 띄워요. 톡 튀어나왔다가 위로 떠오르며 사라져요.
## 사용 예: FloatingText.damage(self, global_position + Vector2(0, -12), 10)
static func damage(from: Node, world_position: Vector2, amount: int, color := Color(1, 0.95, 0.6)) -> void:
	var label := FloatingText.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(40, 16)
	label.pivot_offset = label.size / 2.0
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 21
	WorldOverlay.of(from).add_child(label)
	# 여러 번 때려도 숫자가 겹치지 않게 옆으로 살짝씩 흩어져요.
	label.global_position = world_position - label.size / 2.0 + Vector2(randf_range(-6, 6), 0)
	label.scale = Vector2(1.6, 1.6)
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(label, "position:y", label.position.y - 14, 0.7).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.4)
	tween.tween_callback(label.queue_free)
