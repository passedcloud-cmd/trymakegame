extends StaticBody2D
## 그림자 장막: 길을 막고 있어요. 별빛을 비추면 스르르 사라져요.

## 별빛이 이 거리(픽셀) 안에 닿으면 사라져요.
@export var dispel_range: float = 56.0

var time := 0.0
var is_fading := false


func _ready() -> void:
	# 이미 걷어낸 장막이면 사라져요.
	if GameState.flags.get(flag_key(), false):
		queue_free()


func _process(delta: float) -> void:
	time += delta
	$Sprite2D.frame = int(time * 4.0) % 2
	if is_fading:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and player.is_starlight_on() \
			and global_position.distance_to(player.global_position) < dispel_range:
		dispel()


func dispel() -> void:
	is_fading = true
	Sound.play("dispel", 0.0, 1.0, 0.0)
	GameState.flags[flag_key()] = true
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween().set_parallel()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.8)
	tween.tween_property($Sprite2D, "scale", Vector2(1.4, 0.2), 0.8)
	tween.chain().tween_callback(queue_free)


func flag_key() -> String:
	return "veil_%s_%d_%d" % [get_tree().current_scene.name, int(position.x), int(position.y)]
