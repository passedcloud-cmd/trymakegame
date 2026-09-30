extends SceneTree
## 글자로 그린 맵(levels/*.txt)을 읽어서 Godot 장면(scenes/*.tscn)을 만들어요.
##
## 실행 방법 (터미널에서, sidescroller 폴더 안에서):
##   godot --headless --script tools/build_levels.gd
##
## ⚠️ 장면을 새로 만들기 때문에, Godot 에디터에서 그 장면에 직접 고친 내용은 사라져요.
##    맵을 글자로 고칠지, 에디터에서 고칠지 한 가지 방법만 쓰는 게 좋아요.

const TILE := 16
const TILESET_PATH := "res://assets/tileset.tres"

## 만들 맵 목록
const LEVELS := [
	{"txt": "res://levels/village.txt", "scene": "res://scenes/village.tscn", "name": "Village",
		"script": "res://scripts/village.gd", "theme": 0, "bg": "village", "music": "village"},
	{"txt": "res://levels/stage_1.txt", "scene": "res://scenes/stage_1.tscn", "name": "Stage1",
		"script": "res://scripts/stage.gd", "theme": 0, "bg": "forest", "music": "forest", "number": 1},
	{"txt": "res://levels/stage_2.txt", "scene": "res://scenes/stage_2.tscn", "name": "Stage2",
		"script": "res://scripts/stage.gd", "theme": 1, "bg": "cave", "music": "cave", "number": 2},
	{"txt": "res://levels/stage_3.txt", "scene": "res://scenes/stage_3.tscn", "name": "Stage3",
		"script": "res://scripts/stage.gd", "theme": 2, "bg": "nest", "music": "boss", "number": 3},
]

## 글자 → 놓을 장면. 발끝(칸의 아래 가운데)에 놓여요.
const ENTITIES := {
	"c": "res://scenes/enemies/crawler.tscn",
	"b": "res://scenes/enemies/charger.tscn",
	"f": "res://scenes/enemies/flyer.tscn",
	"h": "res://scenes/enemies/hopper.tscn",
	"B": "res://scenes/enemies/boss.tscn",
	"E": "res://scenes/npcs/elder.tscn",
	"K": "res://scenes/npcs/smith.tscn",
	"R": "res://scenes/npcs/herbalist.tscn",
	"k": "res://scenes/npcs/kid.tscn",
	"G": "res://scenes/npcs/gate.tscn",
	"S": "res://scenes/npcs/sign.tscn",
}
## 글자 → 배경 소품 그림 (발끝에 놓여요)
const PROPS := {
	"1": "res://assets/house_1.png",
	"2": "res://assets/house_2.png",
	"3": "res://assets/house_3.png",
	"F": "res://assets/forge.png",
	"T": "res://assets/tree.png",
	"L": "res://assets/lamp.png",
}
const ENEMY_CHARS := "cbfhB"

# 타일 그림(assets/tiles.png)의 칸 번호
const T_TOP := 0
const T_INNER := 1
const T_TOP_LEFT := 2
const T_TOP_RIGHT := 3
const T_LEFT := 4
const T_RIGHT := 5
const T_PLATFORM := 6
const T_DECO_A := 7
const T_DECO_B := 8

var tileset: TileSet
var level_root: Node2D


func _initialize() -> void:
	tileset = build_tileset()
	for level in LEVELS:
		build_level(level)
	print("맵을 모두 만들었어요!")
	quit()


# ── 타일셋 만들기 ──────────────────────────────────────

func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)  # 1번 층 = world
	ts.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/tiles.png")
	source.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(source, 0)

	var h := TILE / 2.0
	var full := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	var plank := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h + 4), Vector2(-h, -h + 4)])
	for row in 3:
		for col in 9:
			var coords := Vector2i(col, row)
			source.create_tile(coords)
			var data := source.get_tile_data(coords, 0)
			if col <= T_RIGHT:
				data.add_collision_polygon(0)
				data.set_collision_polygon_points(0, 0, full)
			elif col == T_PLATFORM:
				# 발판: 위에서만 밟히고 아래에서는 뚫고 올라가요.
				data.add_collision_polygon(0)
				data.set_collision_polygon_points(0, 0, plank)
				data.set_collision_polygon_one_way(0, 0, true)
	ResourceSaver.save(ts, TILESET_PATH)
	return load(TILESET_PATH)


# ── 맵 파일 읽기 ───────────────────────────────────────

func read_level(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var grid: Array[String] = []
	var signs: Array = []
	var in_signs := false
	for line in text.split("\n"):
		line = line.strip_edges(false, true)
		if line.begins_with("# ") or line == "#":
			continue
		if line == "---":
			in_signs = true
			continue
		if in_signs:
			if line != "":
				signs.append(line.split("|"))
		elif line != "":
			grid.append(line)
	var width := 0
	for row in grid:
		width = maxi(width, row.length())
	return {"grid": grid, "width": width, "height": grid.size(), "signs": signs}


# ── 장면 만들기 ────────────────────────────────────────

func build_level(level: Dictionary) -> void:
	var data := read_level(level.txt)
	var grid: Array[String] = data.grid
	var width: int = data.width
	var height: int = data.height
	var theme: int = level.theme

	level_root = Node2D.new()
	level_root.name = level.name
	level_root.set_script(load(level.script))
	level_root.map_size = Vector2(width * TILE, height * TILE)
	level_root.music = level.music
	if level.has("number"):
		level_root.stage_number = level.number

	add_background(level.bg)

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	add(level_root, ground)
	var deco := TileMapLayer.new()
	deco.name = "Deco"
	deco.tile_set = tileset
	deco.collision_enabled = false
	add(level_root, deco)

	add_side_walls(width * TILE, height * TILE)

	var props := Node2D.new()
	props.name = "Props"
	add(level_root, props)
	var npcs := Node2D.new()
	npcs.name = "NPCs"
	add(level_root, npcs)
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	add(level_root, enemies)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(level.txt)
	var sign_index := 0
	var player_pos := Vector2(32, 32)

	for y in height:
		for x in width:
			var ch := cell(grid, x, y)
			var foot := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			match ch:
				"#":
					ground.set_cell(Vector2i(x, y), 0, Vector2i(pick_tile(grid, x, y), theme))
					# 윗면에 가끔 풀, 꽃 같은 장식을 놓아요.
					if not is_solid(cell(grid, x, y - 1)) and cell(grid, x, y - 1) == "." and y > 0 \
							and rng.randf() < 0.3:
						var deco_col := T_DECO_A if rng.randf() < 0.6 else T_DECO_B
						deco.set_cell(Vector2i(x, y - 1), 0, Vector2i(deco_col, theme))
				"=":
					ground.set_cell(Vector2i(x, y), 0, Vector2i(T_PLATFORM, theme))
				"^":
					var spikes := instance("res://scenes/spikes.tscn", props)
					spikes.position = foot - Vector2(0, TILE / 2.0)
				"P":
					player_pos = foot
				_:
					if ENTITIES.has(ch):
						var parent := enemies if ENEMY_CHARS.contains(ch) else npcs
						var node := instance(ENTITIES[ch], parent)
						node.position = foot
						if ch == "f":
							node.position = foot - Vector2(0, TILE / 2.0)
						if ch == "S":
							var pages: Array[String] = []
							if sign_index < data.signs.size():
								for page in data.signs[sign_index]:
									pages.append(page)
							node.lines = pages
							sign_index += 1
					elif PROPS.has(ch):
						add_prop(props, PROPS[ch], foot, ch == "L")

	var player := instance("res://scenes/player.tscn", level_root)
	player.name = "Player"
	player.position = player_pos
	var hud := instance("res://scenes/hud.tscn", level_root)
	hud.name = "HUD"

	var packed := PackedScene.new()
	var err := packed.pack(level_root)
	if err != OK:
		push_error("장면을 만들지 못했어요: " + level.scene)
		return
	ResourceSaver.save(packed, level.scene)
	print("  만든 장면: %s (%d×%d칸)" % [level.scene, width, height])
	level_root.free()


func add(parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = level_root


func instance(path: String, parent: Node) -> Node:
	var node: Node = load(path).instantiate()
	add(parent, node)
	return node


func cell(grid: Array[String], x: int, y: int) -> String:
	if y < 0 or y >= grid.size():
		return "#" if y >= grid.size() else "."
	var row: String = grid[y]
	if x < 0 or x >= row.length():
		# 맵 양옆 바깥은 땅이 이어진다고 쳐요. (모서리 타일이 어색하지 않게)
		var edge_x := clampi(x, 0, row.length() - 1)
		return "#" if row[edge_x] == "#" else "."
	return row[x]


func is_solid(ch: String) -> bool:
	return ch == "#"


# 주변 칸을 보고 어울리는 타일(윗면, 모서리, 벽, 속)을 골라요.
func pick_tile(grid: Array[String], x: int, y: int) -> int:
	var up := is_solid(cell(grid, x, y - 1))
	var left := is_solid(cell(grid, x - 1, y))
	var right := is_solid(cell(grid, x + 1, y))
	if not up:
		if not left and right:
			return T_TOP_LEFT
		if not right and left:
			return T_TOP_RIGHT
		return T_TOP
	if not left and right:
		return T_LEFT
	if not right and left:
		return T_RIGHT
	return T_INNER


func add_background(bg_name: String) -> void:
	var background := Node2D.new()
	background.name = "Background"
	background.z_index = -10
	add(level_root, background)
	for layer in [["Far", 0.15], ["Near", 0.4]]:
		var parallax := Parallax2D.new()
		parallax.name = layer[0]
		# y를 0으로 하면 위아래로는 화면에 붙어 있어요.
		parallax.scroll_scale = Vector2(layer[1], 0.0)
		parallax.repeat_size = Vector2(320, 0)
		add(background, parallax)
		var sprite := Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = load("res://assets/bg_%s_%s.png" % [bg_name, String(layer[0]).to_lower()])
		sprite.centered = false
		add(parallax, sprite)


# 맵 왼쪽 끝과 오른쪽 끝에 보이지 않는 벽을 세워요.
func add_side_walls(map_w: float, map_h: float) -> void:
	var walls := StaticBody2D.new()
	walls.name = "SideWalls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	add(level_root, walls)
	for side in [["Left", -8.0], ["Right", map_w + 8.0]]:
		var shape := CollisionShape2D.new()
		shape.name = side[0]
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, map_h + 400)
		shape.shape = rect
		shape.position = Vector2(side[1], map_h / 2.0 - 200)
		add(walls, shape)


func add_prop(parent: Node, texture_path: String, foot: Vector2, glow: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.name = texture_path.get_file().get_basename().to_pascal_case()
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	sprite.position = foot
	sprite.z_index = -1
	add(parent, sprite)
	if glow:
		# 가로등 불빛: 색을 더해서(Add) 부드럽게 빛나 보여요.
		var light := Sprite2D.new()
		light.name = "Glow"
		light.texture = load("res://assets/glow.png")
		light.position = Vector2(0, -27)
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		light.material = material
		add(sprite, light)
