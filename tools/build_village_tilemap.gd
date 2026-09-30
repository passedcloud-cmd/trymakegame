extends SceneTree
## 반딧불 마을의 바닥 타일을 처음 한 번 자동으로 깔아 주는 스크립트예요.
##
## 실행: godot --headless -s res://tools/build_village_tilemap.gd
##
## ⚠️ 다시 실행하면 scenes/village_tilemap.tscn을 새로 덮어써요.
##    Godot 에디터에서 타일을 직접 칠해서 고쳤다면 다시 실행하지 마세요!

const W := 40  # 맵 가로 칸 수 (한 칸 = 16픽셀)
const H := 24  # 맵 세로 칸 수

# 타일 모음(assets/village/tiles.png)에서 각 타일의 위치
const GRASS := Vector2i(0, 0)
const GRASS_TUFT := Vector2i(1, 0)
const FLOWERS := Vector2i(2, 0)
const PATH := Vector2i(3, 0)
const PATH_PEBBLE := Vector2i(4, 0)
const WATER := Vector2i(5, 0)
const WATER_SPARK := Vector2i(6, 0)
const FOREST := Vector2i(7, 0)
const FENCE_H := Vector2i(0, 1)
const FENCE_V := Vector2i(1, 1)
const FENCE_POST := Vector2i(2, 1)
const BUSH := Vector2i(3, 1)
const TALL_GRASS := Vector2i(4, 1)
const WATER_TOP := Vector2i(5, 1)
const FOREST_TUFT := Vector2i(6, 1)
const FOREST_MUSH := Vector2i(7, 1)

## 부딪히는 타일 (지나갈 수 없어요)
const SOLID := [WATER, WATER_SPARK, WATER_TOP, FENCE_H, FENCE_V, FENCE_POST, BUSH]

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 7
	var tileset := make_tileset()
	ResourceSaver.save(tileset, "res://assets/village/tileset.tres")
	tileset = load("res://assets/village/tileset.tres")

	var root := Node2D.new()
	root.name = "VillageTilemap"
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

	paint_ground(ground)
	paint_deco(deco, ground)

	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/village_tilemap.tscn")
	root.free()
	print("scenes/village_tilemap.tscn 을 만들었어요.")
	quit()


func make_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	tileset.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/village/tiles.png")
	source.texture_region_size = Vector2i(16, 16)
	tileset.add_source(source, 0)

	var square := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	var thin_v := PackedVector2Array([Vector2(-3, -8), Vector2(3, -8), Vector2(3, 8), Vector2(-3, 8)])
	for y in 2:
		for x in 8:
			var coords := Vector2i(x, y)
			source.create_tile(coords)
			if coords in SOLID:
				var data := source.get_tile_data(coords, 0)
				data.add_collision_polygon(0)
				data.set_collision_polygon_points(0, 0, thin_v if coords in [FENCE_V, FENCE_POST] else square)
	return tileset


func paint_ground(ground: TileMapLayer) -> void:
	for y in H:
		for x in W:
			var tile := GRASS
			if x >= 29:
				# 동쪽 숲
				var r := rng.randf()
				tile = FOREST_TUFT if r < 0.15 else (FOREST_MUSH if r < 0.19 else FOREST)
			else:
				var r := rng.randf()
				tile = GRASS_TUFT if r < 0.2 else (FLOWERS if r < 0.27 else GRASS)
			ground.set_cell(Vector2i(x, y), 0, tile)

	# 흙길: 큰길(가로), 광장, 집으로 가는 샛길
	fill_path(ground, 2, 12, 39, 13)   # 큰길 (서쪽 → 동쪽 숲)
	fill_path(ground, 11, 10, 18, 15)  # 광장
	fill_path(ground, 14, 7, 15, 9)    # 촌장 회관 앞
	fill_path(ground, 23, 11, 24, 11)  # 토끼네 집 앞
	fill_path(ground, 6, 14, 7, 20)    # 거북이 할머니 집 앞
	fill_path(ground, 30, 14, 31, 19)  # 숲속 오솔길
	fill_path(ground, 32, 19, 36, 20)

	# 연못
	for y in range(17, 22):
		for x in range(13, 20):
			var corner := (x == 13 or x == 19) and (y == 17 or y == 21)
			if corner:
				continue
			var tile := WATER_TOP if y == 17 or (y == 18 and (x == 13 or x == 19)) else \
					(WATER_SPARK if rng.randf() < 0.2 else WATER)
			ground.set_cell(Vector2i(x, y), 0, tile)


func fill_path(ground: TileMapLayer, x1: int, y1: int, x2: int, y2: int) -> void:
	for y in range(y1, y2 + 1):
		for x in range(x1, x2 + 1):
			ground.set_cell(Vector2i(x, y), 0, PATH_PEBBLE if rng.randf() < 0.2 else PATH)


func paint_deco(deco: TileMapLayer, ground: TileMapLayer) -> void:
	# 마을과 숲 사이 울타리 (큰길 자리만 비워요)
	for y in H:
		if y in [12, 13]:
			continue
		deco.set_cell(Vector2i(28, y), 0, FENCE_POST if y in [11, 14] else FENCE_V)

	# 연못 둘레 작은 울타리
	for x in range(12, 21):
		if x == 16:
			continue  # 연못 구경하는 자리
		deco.set_cell(Vector2i(x, 22), 0, FENCE_H)

	# 덤불 (지나갈 수 없어요)
	for cell in [Vector2i(2, 16), Vector2i(3, 16), Vector2i(21, 6), Vector2i(22, 6),
			Vector2i(10, 7), Vector2i(26, 17), Vector2i(26, 18), Vector2i(1, 7),
			Vector2i(34, 9), Vector2i(35, 9), Vector2i(38, 15), Vector2i(33, 23)]:
		deco.set_cell(cell, 0, BUSH)

	# 긴 풀 (장식, 지나갈 수 있어요) - 풀밭 위에만 드문드문
	for i in 40:
		var cell := Vector2i(rng.randi_range(0, W - 1), rng.randi_range(0, H - 1))
		var under := ground.get_cell_atlas_coords(cell)
		if under in [GRASS, GRASS_TUFT, FOREST, FOREST_TUFT] and deco.get_cell_source_id(cell) == -1:
			deco.set_cell(cell, 0, TALL_GRASS)
