class_name WorldOverlay
extends CanvasLayer
## 맵 위에 겹쳐 그리는 층이에요. 데미지 숫자, 몬스터 HP바처럼
## 밤 색깔(CanvasModulate)에 어두워지면 안 되는 것들을 여기에 그려요.
## 맵과 함께 움직여요. (follow_viewport)


## 지금 맵의 겹쳐 그리는 층을 찾아줘요. 없으면 새로 만들어요.
static func of(from: Node) -> CanvasLayer:
	var scene := from.get_tree().current_scene
	var overlay := scene.get_node_or_null("WorldOverlay") as CanvasLayer
	if overlay == null:
		overlay = WorldOverlay.new()
		overlay.name = "WorldOverlay"
		overlay.layer = 2
		overlay.follow_viewport_enabled = true
		scene.add_child(overlay)
	return overlay
