extends SceneTree
## 그림자 곰의 굴(보스 싸움터)의 바닥 타일을 처음 한 번 자동으로 깔아 주는 스크립트예요.
## 마을과 같은 타일 모음(assets/village/tileset.tres)을 써요.
##
## 실행: godot --headless -s res://tools/build_den_tilemap.gd
##
## ⚠️ 다시 실행하면 scenes/den_tilemap.tscn을 새로 덮어써요.

const W := 24
const H := 16
const FOREST := Vector2i(7, 0)
const FOREST_TUFT := Vector2i(6, 1)
const FOREST_MUSH := Vector2i(7, 1)
const BUSH := Vector2i(3, 1)

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 21
	var tileset: TileSet = load("res://assets/village/tileset.tres")
	var root := Node2D.new()
	root.name = "DenTilemap"
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	var deco := TileMapLayer.new()
	deco.name = "Deco"
	deco.tile_set = tileset
	root.add_child(ground)
	root.add_child(deco)
	ground.owner = root
	deco.owner = root

	for y in H:
		for x in W:
			var r := rng.randf()
			ground.set_cell(Vector2i(x, y), 0, FOREST_TUFT if r < 0.12 else (FOREST_MUSH if r < 0.15 else FOREST))
			# 가장자리는 덤불 울타리 (아래쪽 가운데만 입구로 비워요)
			var edge := x == 0 or y == 0 or x == W - 1 or y == H - 1
			var entrance := y == H - 1 and x in [11, 12]
			if edge and not entrance:
				deco.set_cell(Vector2i(x, y), 0, BUSH)

	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/den_tilemap.tscn")
	root.free()
	print("scenes/den_tilemap.tscn 을 만들었어요.")
	quit()
