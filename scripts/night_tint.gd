extends CanvasModulate
## 마을의 밤 색깔이에요. 별을 하나 돌려보낼 때마다 조금씩 밝아져요.

## 별이 하나도 없을 때 색 (가장 어두움)
@export var darkest: Color = Color(0.45, 0.5, 0.78)
## 별 3개를 모두 돌려보냈을 때 색 (원래 밝기)
@export var brightest: Color = Color(1, 1, 1)


func _ready() -> void:
	add_to_group("night_tint")
	color = color_for(GameState.stars_returned)


func color_for(stars: int) -> Color:
	return darkest.lerp(brightest, stars / 3.0)


## 돌려보낸 별 개수에 맞춰 천천히 밝아져요.
func brighten() -> void:
	var tween := create_tween()
	tween.tween_property(self, "color", color_for(GameState.stars_returned), 2.5)
