extends SceneTree
## 캄캄한 동굴의 바닥과 벽 타일을 처음 한 번 자동으로 깔아 주는 스크립트예요.
##
## 실행: godot --headless -s res://tools/build_cave_tilemap.gd
##
## ⚠️ 다시 실행하면 scenes/cave_tilemap.tscn을 새로 덮어써요.
##    Godot 에디터에서 타일을 직접 칠해서 고쳤다면 다시 실행하지 마세요!

const W := 40
const H := 24

const FLOOR := Vector2i(0, 0)
const FLOOR_PEBBLE := Vector2i(1, 0)
const FLOOR_CRACK := Vector2i(2, 0)
const WALL := Vector2i(3, 0)
const WALL_FACE := Vector2i(4, 0)

## 동굴에서 걸어 다닐 수 있는 곳 (왼쪽 위 칸 x, y, 오른쪽 아래 칸 x, y)
const ROOMS := [
	[16, 17, 23, 22],  # 입구 홀
	[19, 23, 20, 23],  # 출구 (맵 아래쪽)
	[18, 12, 21, 16],  # 북쪽 통로
	[14, 8, 25, 11],   # 갈림길 방
	[8, 9, 13, 10],    # 서쪽 통로
	[8, 11, 9, 15],
	[2, 14, 9, 15],
	[2, 6, 3, 13],
	[2, 1, 10, 5],     # 별의 방
	[11, 3, 16, 4],    # 지름길 (그림자 장막으로 막혀 있어요)
	[15, 5, 16, 7],
	[26, 9, 33, 10],   # 동쪽 통로
	[30, 2, 37, 8],    # 북동쪽 방
	[35, 9, 36, 12],   # 숨겨진 방 가는 길 (그림자 장막)
	[33, 13, 38, 17],  # 숨겨진 방
]

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 11
	var tileset := make_tileset()
	ResourceSaver.save(tileset, "res://assets/cave/tileset.tres")
	tileset = load("res://assets/cave/tileset.tres")

	var root := Node2D.new()
	root.name = "CaveTilemap"
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	root.add_child(ground)
	ground.owner = root

	# 1) 걸을 수 있는 칸을 표시해요.
	var open := {}
	for r in ROOMS:
		for y in range(r[1], r[3] + 1):
			for x in range(r[0], r[2] + 1):
				open[Vector2i(x, y)] = true

	# 2) 바닥과 벽을 깔아요. 바로 아래가 바닥인 벽은 "벽 앞면"으로 그려요.
	for y in H:
		for x in W:
			var cell := Vector2i(x, y)
			var tile := WALL
			if open.has(cell):
				var r := rng.randf()
				tile = FLOOR_PEBBLE if r < 0.15 else (FLOOR_CRACK if r < 0.22 else FLOOR)
			elif open.has(cell + Vector2i.DOWN):
				tile = WALL_FACE
			ground.set_cell(cell, 0, tile)

	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/cave_tilemap.tscn")
	root.free()
	print("scenes/cave_tilemap.tscn 을 만들었어요.")
	quit()


func make_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	tileset.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/cave/tiles.png")
	source.texture_region_size = Vector2i(16, 16)
	tileset.add_source(source, 0)

	var square := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	for x in 5:
		var coords := Vector2i(x, 0)
		source.create_tile(coords)
		if coords in [WALL, WALL_FACE]:
			var data := source.get_tile_data(coords, 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, square)
	return tileset
