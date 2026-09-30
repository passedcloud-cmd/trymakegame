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
	from.get_tree().current_scene.add_child(label)
	label.global_position = world_position - Vector2(60, 8)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 16, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)
