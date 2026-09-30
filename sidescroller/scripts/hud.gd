extends CanvasLayer
## 화면 위에 겹쳐 보이는 정보예요.
##   왼쪽 위: 체력(가면), 빛조각 개수   오른쪽 위: 남은 벌레 수
##   가운데: 스테이지 이름, 클리어 글자   아래: 보스 체력 막대

const MASK_FULL := preload("res://assets/mask_full.png")
const MASK_EMPTY := preload("res://assets/mask_empty.png")

@onready var masks: HBoxContainer = $Masks
@onready var shard_label: Label = $ShardLabel
@onready var monster_label: Label = $MonsterLabel
@onready var banner: Label = $Banner
@onready var banner_sub: Label = $BannerSub
@onready var message: Label = $Message
@onready var boss_bar: Control = $BossBar
@onready var boss_fill: ColorRect = $BossBar/Fill
@onready var boss_name: Label = $BossBar/Name

var banner_tween: Tween
var boss_width := 0.0


func _ready() -> void:
	monster_label.hide()
	banner.hide()
	banner_sub.hide()
	message.hide()
	boss_bar.hide()
	boss_width = boss_fill.size.x
	GameState.shards_changed.connect(_on_shards_changed)
	_on_shards_changed(GameState.shards)
	connect_player.call_deferred()


func connect_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(update_masks)
		update_masks(player.hp, player.max_hp)


func update_masks(hp: int, max_hp: int) -> void:
	for child in masks.get_children():
		child.queue_free()
	for i in max_hp:
		var icon := TextureRect.new()
		icon.texture = MASK_FULL if i < hp else MASK_EMPTY
		masks.add_child(icon)


func _on_shards_changed(count: int) -> void:
	shard_label.text = str(count)


## 남은 벌레 수를 보여줘요.
func set_monsters(remaining: int, total: int) -> void:
	monster_label.show()
	monster_label.text = "남은 벌레 %d / %d" % [remaining, total]


## 화면 가운데에 큰 글자를 잠깐 보여줘요.
func show_banner(title: String, sub := "", time := 2.2) -> void:
	banner.text = title
	banner_sub.text = sub
	banner.show()
	banner_sub.visible = sub != ""
	banner.modulate.a = 0.0
	banner_sub.modulate.a = 0.0
	if banner_tween:
		banner_tween.kill()
	banner_tween = create_tween()
	banner_tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	banner_tween.parallel().tween_property(banner_sub, "modulate:a", 1.0, 0.3)
	if time > 0.0:
		banner_tween.tween_interval(time)
		banner_tween.tween_property(banner, "modulate:a", 0.0, 0.5)
		banner_tween.parallel().tween_property(banner_sub, "modulate:a", 0.0, 0.5)


## 화면 아래쪽에 한 줄 글을 보여줘요.
func show_message(text: String) -> void:
	message.text = text
	message.show()


## 보스 체력 막대를 보여줘요.
func show_boss(boss: Node, boss_title: String) -> void:
	boss_name.text = boss_title
	boss_bar.show()
	boss.health_changed.connect(_on_boss_health_changed)
	_on_boss_health_changed(boss.hp, boss.max_hp)


func _on_boss_health_changed(hp: int, max_hp: int) -> void:
	boss_fill.size.x = boss_width * float(hp) / max_hp
	if hp <= 0:
		boss_bar.hide()
