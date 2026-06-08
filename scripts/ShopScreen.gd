extends Control

# ShopScreen — buy & equip player skins using wallet gems.

@onready var wallet_label: Label = $VBox/Header/WalletLabel
@onready var cards_container: HBoxContainer = $VBox/Cards
@onready var back_button: Button = $VBox/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back)
	_rebuild_cards()
	# Continue the same BGM playing in MainMenu (autoload at /root/MenuMusic) — no restart.
	var menu_music: Node = get_node_or_null("/root/MenuMusic")
	if menu_music and menu_music.has_method("ensure_playing"):
		menu_music.ensure_playing()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back()


func _rebuild_cards() -> void:
	for c in cards_container.get_children():
		c.queue_free()
	wallet_label.text = "GEMS: %d" % Global.wallet
	for skin_id in Global.SKIN_ORDER:
		cards_container.add_child(_make_card(skin_id))


func _make_card(skin_id: String) -> Control:
	var info: Dictionary = Global.SKINS[skin_id]
	var price: int = int(info["price"])
	var unlocked: bool = Global.is_unlocked(skin_id)
	var equipped: bool = Global.selected_skin == skin_id

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(132, 250)
	panel.self_modulate = Color(0.14, 0.1, 0.22, 0.9) if not equipped else Color(0.25, 0.2, 0.35, 0.95)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)

	# Preview (idle frame 0)
	var preview := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/sprites/player/" + skin_id + "/idle.png") if skin_id != "mask_dude" else load("res://assets/sprites/player/idle.png")
	atlas.region = Rect2(0, 0, 32, 32)
	preview.texture = atlas
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(64, 64)
	preview.modulate = Color(0.7, 0.7, 0.85, 0.6) if not unlocked else Color.WHITE
	vb.add_child(preview)

	var name_label := Label.new()
	name_label.text = String(info["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	vb.add_child(name_label)

	# Show the skin's gameplay perk on the card.
	var ability_label := Label.new()
	ability_label.text = Global.get_ability_text(skin_id)
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_label.custom_minimum_size = Vector2(112, 0)
	ability_label.add_theme_font_size_override("font_size", 8)
	ability_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1, 0.95))
	vb.add_child(ability_label)

	var price_label := Label.new()
	if unlocked:
		price_label.text = "OWNED" if not equipped else "EQUIPPED"
		price_label.add_theme_color_override("font_color", Color(0.4, 1, 0.5, 1) if equipped else Color(0.85, 0.85, 1, 1))
	else:
		price_label.text = "%d gems" % price
		price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 10)
	vb.add_child(price_label)

	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 11)
	if equipped:
		btn.text = "  Equipped  "
		btn.disabled = true
	elif unlocked:
		btn.text = "  Equip  "
		btn.pressed.connect(_on_equip.bind(skin_id))
	elif Global.can_afford(skin_id):
		btn.text = "  Buy  "
		btn.pressed.connect(_on_buy.bind(skin_id))
	else:
		btn.text = "  Locked  "
		btn.disabled = true
	vb.add_child(btn)

	return panel


func _on_buy(skin_id: String) -> void:
	if Global.buy_skin(skin_id):
		Global.equip_skin(skin_id)
		_rebuild_cards()


func _on_equip(skin_id: String) -> void:
	Global.equip_skin(skin_id)
	_rebuild_cards()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
