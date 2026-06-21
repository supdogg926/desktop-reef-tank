extends Control
## 桌面海缸 主界面 — Day 2 垂直切片

const C_WATER = Color8(184, 226, 239)
const C_SAND = Color8(232, 220, 196)
const C_BAR_BG = Color8(140, 196, 216)
const C_BAR_TEXT = Color8(40, 80, 100)
const C_NAV_ACTIVE = Color8(40, 80, 100)
const C_NAV_INACTIVE = Color8(150, 150, 150)
const C_BTN_ADOPT = Color8(76, 175, 80)
const ANEMONE_SWAY_RADIUS := 4.0
const ANEMONE_SWAY_SPEED := 10.0
const HEADER_RATIO := 0.12
const FLOOR_RATIO := 0.20
const WALL_INSET_RATIO := 0.08

var tank_rect: Control
var codex_panel: PanelContainer
var time_label: Label
var creature_nodes: Dictionary = {}  # instance_id → Control


func _ready() -> void:
	SaveManager.load_game()
	_position_overlay_window()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	print(">>> [DEBUG] window.size=", get_window().size, " self.size=", size)
	_build_top_bar()
	_build_nav_bar()
	_build_tank_view()
	print(">>> [DEBUG] tank_rect.size after build=", tank_rect.size)
	_build_codex_panel()
	_spawn_saved_creatures()
	print(">>> [DEBUG] owned_creatures=", GameManager.owned_creatures if GameManager else "none")
	if GameManager:
		GameManager.creature_adopted.connect(_on_creature_adopted)


func _on_tank_resized(sand: Polygon2D) -> void:
	var w = tank_rect.size.x
	var h = tank_rect.size.y
	var floor_h = h * FLOOR_RATIO
	var wall_inset = w * WALL_INSET_RATIO
	var top_y = h - floor_h
	sand.polygon = PackedVector2Array(
		[
			Vector2(wall_inset, top_y),
			Vector2(w - wall_inset, top_y),
			Vector2(w, h),
			Vector2(0, h),
		]
	)
	print(">>> [DEBUG] sand polygon recalculated, tank size=", tank_rect.size)


func _process(_delta: float) -> void:
	if time_label:
		time_label.text = Time.get_datetime_string_from_system()
	_animate_fish(_delta)


# ── 顶部信息栏 ─────────────────────────────────────────────────


func _build_top_bar() -> void:
	var header_h := int(round(get_window().size.y * HEADER_RATIO))
	var top_h := int(round(header_h * 0.6))
	var bar = ColorRect.new()
	bar.color = C_BAR_BG
	bar.custom_minimum_size = Vector2(0, top_h)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(bar)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hbox.add_theme_constant_override("separation", 16)
	add_child(hbox)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(left_vbox)

	var name_lbl = _make_label("船长", 14, C_BAR_TEXT)
	left_vbox.add_child(name_lbl)

	var level_hbox = HBoxContainer.new()
	level_hbox.add_theme_constant_override("separation", 6)
	left_vbox.add_child(level_hbox)

	var lv_label = _make_label("Lv.1  0/100", 12, C_BAR_TEXT)
	level_hbox.add_child(lv_label)

	var coin_lbl = _make_label("海洋币 0", 12, C_BAR_TEXT)
	level_hbox.add_child(coin_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	time_label = _make_label(Time.get_datetime_string_from_system(), 12, C_BAR_TEXT)
	hbox.add_child(time_label)

	var pad_r = Control.new()
	pad_r.custom_minimum_size = Vector2(12, 0)
	hbox.add_child(pad_r)


# ── 导航栏 ─────────────────────────────────────────────────────


func _build_nav_bar() -> void:
	var header_h := int(round(get_window().size.y * HEADER_RATIO))
	var top_h := int(round(header_h * 0.6))
	var nav_h := int(round(header_h * 0.4))
	var bar = ColorRect.new()
	bar.color = Color(C_BAR_BG, 0.3)
	bar.custom_minimum_size = Vector2(0, nav_h)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.position = Vector2(0, top_h)
	add_child(bar)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hbox.position = Vector2(0, top_h)
	hbox.custom_minimum_size = Vector2(0, nav_h)
	hbox.add_theme_constant_override("separation", 24)
	add_child(hbox)

	var spacer_l = Control.new()
	spacer_l.custom_minimum_size = Vector2(12, 0)
	hbox.add_child(spacer_l)

	var nav_items = [
		{"text": "码头", "active": false},
		{"text": "工具", "active": false},
		{"text": "图鉴", "active": true},
		{"text": "任务", "active": false},
		{"text": "出海", "active": false},
		{"text": "菜单", "active": false},
	]

	for item in nav_items:
		var btn = Button.new()
		btn.text = item.text
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 12)
		if item.active:
			btn.add_theme_color_override("font_color", Color8(60, 110, 140))
			btn.pressed.connect(_on_codex_tab_clicked)
		else:
			btn.add_theme_color_override("font_color", Color8(150, 150, 150, 160))
		btn.custom_minimum_size = Vector2(48, 24)
		hbox.add_child(btn)

	var spacer_r = Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_r)


# ── 鱼缸主视图 ──────────────────────────────────────────────────


func _build_tank_view() -> void:
	var header_h := int(round(get_window().size.y * HEADER_RATIO))
	tank_rect = Control.new()
	tank_rect.anchor_left = 0.0
	tank_rect.anchor_top = 0.0
	tank_rect.anchor_right = 1.0
	tank_rect.anchor_bottom = 1.0
	tank_rect.offset_top = header_h
	tank_rect.clip_contents = true
	add_child(tank_rect)

	# 水体背景
	var water = ColorRect.new()
	water.color = C_WATER
	water.set_anchors_preset(Control.PRESET_FULL_RECT)
	tank_rect.add_child(water)

	# 沙地（底部对称梯形，两侧收边）
	var sand = Polygon2D.new()
	sand.color = C_SAND
	tank_rect.add_child(sand)
	tank_rect.resized.connect(_on_tank_resized.bind(sand))
	_on_tank_resized(sand)
	print(">>> [DEBUG] sand.polygon after manual call=", sand.polygon)


# ── 图鉴面板 ────────────────────────────────────────────────────


func _build_codex_panel() -> void:
	codex_panel = PanelContainer.new()
	codex_panel.set_anchors_preset(Control.PRESET_CENTER)
	codex_panel.custom_minimum_size = Vector2(400, 320)
	codex_panel.visible = false
	var style = StyleBoxFlat.new()
	style.bg_color = Color8(10, 25, 45, 240)
	style.set_corner_radius_all(8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color8(100, 180, 220)
	codex_panel.add_theme_stylebox_override("panel", style)
	add_child(codex_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	codex_panel.add_child(vbox)

	var title = _make_label("📖 图鉴 — 可领养生物", 16, Color8(255, 215, 0))
	vbox.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): codex_panel.visible = false)
	close_btn.custom_minimum_size = Vector2(60, 30)
	vbox.add_child(close_btn)

	# 三条物种记录
	for species_id in CreatureData.SPECIES:
		var data = CreatureData.SPECIES[species_id]
		var card = HBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		vbox.add_child(card)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 2)
		card.add_child(info_vbox)

		var name_text = "[color=#%s]%s[/color]" % [_color_to_hex(data.main_color), data.name_cn]
		if data.type == "fish" and data.gender != null:
			var gender_symbol = "♂" if data.gender == "m" else "♀"
			var gender_color = _color_to_hex(data.main_color)
			name_text += (
				" [color=#FFFFFF]丨[/color][color=#%s]%s[/color]" % [gender_color, gender_symbol]
			)
		var name_rtl = RichTextLabel.new()
		name_rtl.bbcode_enabled = true
		name_rtl.text = name_text
		name_rtl.fit_content = true
		name_rtl.add_theme_font_size_override("normal_font_size", 14)
		info_vbox.add_child(name_rtl)

		if data.latin != null:
			info_vbox.add_child(_make_label(data.latin, 11, Color8(150, 150, 150)))

		info_vbox.add_child(_make_label(data.desc, 11, Color8(180, 180, 180)))

		# 领养按钮
		var adopt_btn = Button.new()
		adopt_btn.name = "AdoptButton_" + species_id
		adopt_btn.text = "领养"
		adopt_btn.custom_minimum_size = Vector2(64, 32)
		adopt_btn.pressed.connect(func(): _on_adopt(species_id))
		card.add_child(adopt_btn)


func _on_adopt(species_id: String) -> void:
	if GameManager:
		GameManager.adopt(species_id)


func _on_codex_tab_clicked() -> void:
	codex_panel.visible = not codex_panel.visible


# ── 生物渲染 ────────────────────────────────────────────────────


func _on_creature_adopted(instance_id: String, species_id: String) -> void:
	_spawn_creature(instance_id, species_id)


func _spawn_saved_creatures() -> void:
	if not GameManager:
		return
	for entry in GameManager.owned_creatures:
		_spawn_creature(entry.instance_id, entry.species_id)


func _spawn_creature(instance_id: String, species_id: String) -> void:
	if creature_nodes.has(instance_id):
		return
	var data = CreatureData.SPECIES.get(species_id, {})
	if data.is_empty():
		return

	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.add_theme_font_size_override("normal_font_size", data.font_size)

	var color_hex = _color_to_hex(data.main_color)
	var name_text = "[color=#%s]%s[/color]" % [color_hex, data.name_cn]
	if data.type == "fish" and data.gender != null:
		var gs = "♂" if data.gender == "m" else "♀"
		name_text += (
			" [color=#FFFFFF]丨[/color][color=#%s]%s[/color]" % [_color_to_hex(data.main_color), gs]
		)
	rtl.text = name_text

	# 初始位置 (use deferred to ensure tank_rect.size is available)
	_place_creature.call_deferred(rtl, data)
	tank_rect.add_child(rtl)
	creature_nodes[instance_id] = rtl


func _place_creature(rtl: RichTextLabel, data: Dictionary) -> void:
	var tank_w = tank_rect.size.x
	var tank_h = tank_rect.size.y
	var sand_top_y = tank_h * (1.0 - FLOOR_RATIO)
	print(
		">>> [DEBUG] _place_creature ",
		data.get("name_cn", "?"),
		" tank size=",
		tank_rect.size,
		" sand_top_y=",
		sand_top_y,
	)
	var cx = tank_w / 2.0

	if data.type == "anemone":
		var anchor := Vector2(cx - 60, sand_top_y - 80)
		rtl.position = anchor
		rtl.set_meta("fixed", true)
		rtl.set_meta("anchor_pos", anchor)
		rtl.set_meta("target_pos", anchor)
		rtl.set_meta("speed", ANEMONE_SWAY_SPEED)
	else:
		rtl.position = Vector2(randf_range(60, tank_w - 100), randf_range(100, sand_top_y - 60))
		rtl.set_meta("fixed", false)
		rtl.set_meta("target_pos", rtl.position)
		rtl.set_meta("speed", randf_range(20.0, 50.0))


func _animate_fish(delta: float) -> void:
	for node in creature_nodes.values():
		if not is_instance_valid(node):
			continue
		var target: Vector2 = node.get_meta("target_pos", node.position)
		var speed: float = node.get_meta("speed", 30.0)
		var dist = node.position.distance_to(target)
		if node.get_meta("fixed", false):
			# 海葵：基于锚点小范围摆动
			if dist < 2.0:
				var anchor: Vector2 = node.get_meta("anchor_pos", node.position)
				target = Vector2(
					anchor.x + randf_range(-ANEMONE_SWAY_RADIUS, ANEMONE_SWAY_RADIUS),
					anchor.y + randf_range(-ANEMONE_SWAY_RADIUS * 0.7, ANEMONE_SWAY_RADIUS * 0.7)
				)
				node.set_meta("target_pos", target)
			else:
				node.position = node.position.move_toward(target, speed * delta)
		else:
			# 鱼：满屏游动
			if dist < 4.0:
				var tank_w = tank_rect.size.x
				var tank_h = tank_rect.size.y
				var sand_top_y = tank_h * (1.0 - FLOOR_RATIO)
				target = Vector2(randf_range(40, tank_w - 80), randf_range(80, sand_top_y - 40))
				node.set_meta("target_pos", target)
				node.set_meta("speed", randf_range(20.0, 50.0))
			else:
				node.position = node.position.move_toward(target, speed * delta)


func _color_to_hex(c: Color) -> String:
	return (
		"%02X%02X%02X"
		% [clampi(int(c.r8), 0, 255), clampi(int(c.g8), 0, 255), clampi(int(c.b8), 0, 255)]
	)


func _position_overlay_window() -> void:
	var screen_id := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen_id)
	var rect := OverlayLayout.calculate_overlay_rect(screen_size)
	var window := get_window()
	window.borderless = true
	window.always_on_top = true
	window.size = Vector2i(rect.size)
	window.position = Vector2i(rect.position)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


# ── 帮助函数 ────────────────────────────────────────────────────


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl
