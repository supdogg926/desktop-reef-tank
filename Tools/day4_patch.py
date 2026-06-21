"""Day 4 patch — fix sand polygon, frame-wait safety, proportional tank layout."""
import sys

with open('scripts/Main.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add new constants
content = content.replace(
    'const ANEMONE_SWAY_RADIUS := 4.0\nconst ANEMONE_SWAY_SPEED := 10.0',
    'const ANEMONE_SWAY_RADIUS := 4.0\nconst ANEMONE_SWAY_SPEED := 10.0\nconst HEADER_RATIO := 0.12\nconst FLOOR_RATIO := 0.20\nconst WALL_INSET_RATIO := 0.08'
)

# 2. Rewrite _ready()
old = '''func _ready() -> void:
\tSaveManager.load_game()
\t_position_overlay_window()
\tset_anchors_preset(Control.PRESET_FULL_RECT)
\t_build_top_bar()
\t_build_nav_bar()
\t_build_tank_view()
\t_build_codex_panel()
\t_spawn_saved_creatures()
\tif GameManager:
\t\tGameManager.creature_adopted.connect(_on_creature_adopted)'''

new = '''func _ready() -> void:
\tSaveManager.load_game()
\t_position_overlay_window()
\tset_anchors_preset(Control.PRESET_FULL_RECT)
\tawait get_tree().process_frame
\tawait get_tree().process_frame
\tprint(">>> [DEBUG] window.size=", get_window().size, " self.size=", size)
\t_build_top_bar()
\t_build_nav_bar()
\t_build_tank_view()
\tprint(">>> [DEBUG] tank_rect.size after build=", tank_rect.size)
\t_build_codex_panel()
\t_spawn_saved_creatures()
\tprint(">>> [DEBUG] owned_creatures=", GameManager.owned_creatures if GameManager else "none")
\tif GameManager:
\t\tGameManager.creature_adopted.connect(_on_creature_adopted)'''
content = content.replace(old, new)

# 3. Rewrite _on_tank_resized
old = '''func _on_tank_resized(sand: Polygon2D) -> void:
\tvar w = tank_rect.size.x
\tvar h = tank_rect.size.y
\tvar top_y = h - 60
\tvar bot_y = h
\tsand.polygon = PackedVector2Array(
\t\t[
\t\t\tVector2(0, top_y + 10),
\t\t\tVector2(w, top_y - 10),
\t\t\tVector2(w, bot_y),
\t\t\tVector2(0, bot_y),
\t\t]
\t)'''

new = '''func _on_tank_resized(sand: Polygon2D) -> void:
\tvar w = tank_rect.size.x
\tvar h = tank_rect.size.y
\tvar floor_h = h * FLOOR_RATIO
\tvar wall_inset = w * WALL_INSET_RATIO
\tvar top_y = h - floor_h
\tsand.polygon = PackedVector2Array(
\t\t[
\t\t\tVector2(wall_inset, top_y),
\t\t\tVector2(w - wall_inset, top_y),
\t\t\tVector2(w, h),
\t\t\tVector2(0, h),
\t\t]
\t)
\tprint(">>> [DEBUG] sand polygon recalculated, tank size=", tank_rect.size)'''
content = content.replace(old, new)

# 4. Rewrite _build_top_bar
old = '''func _build_top_bar() -> void:
\tvar bar = ColorRect.new()
\tbar.color = C_BAR_BG
\tbar.custom_minimum_size = Vector2(0, 48)
\tbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
\tadd_child(bar)'''

new = '''func _build_top_bar() -> void:
\tvar header_h := int(round(get_window().size.y * HEADER_RATIO))
\tvar top_h := int(round(header_h * 0.6))
\tvar bar = ColorRect.new()
\tbar.color = C_BAR_BG
\tbar.custom_minimum_size = Vector2(0, top_h)
\tbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
\tadd_child(bar)'''
content = content.replace(old, new)

# 5. Rewrite _build_nav_bar
old = '''func _build_nav_bar() -> void:
\tvar bar = ColorRect.new()
\tbar.color = Color(C_BAR_BG, 0.3)
\tbar.custom_minimum_size = Vector2(0, 28)
\tbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
\tbar.position = Vector2(0, 48)
\tadd_child(bar)

\tvar hbox = HBoxContainer.new()
\thbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
\thbox.position = Vector2(0, 48)'''

new = '''func _build_nav_bar() -> void:
\tvar header_h := int(round(get_window().size.y * HEADER_RATIO))
\tvar top_h := int(round(header_h * 0.6))
\tvar nav_h := int(round(header_h * 0.4))
\tvar bar = ColorRect.new()
\tbar.color = Color(C_BAR_BG, 0.3)
\tbar.custom_minimum_size = Vector2(0, nav_h)
\tbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
\tbar.position = Vector2(0, top_h)
\tadd_child(bar)

\tvar hbox = HBoxContainer.new()
\thbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
\thbox.position = Vector2(0, top_h)'''
content = content.replace(old, new)

# Fix nav hbox size
content = content.replace(
    '\thbox.custom_minimum_size = Vector2(0, 36)',
    '\thbox.custom_minimum_size = Vector2(0, nav_h)'
)

# 6. Rewrite _build_tank_view
old = '''func _build_tank_view() -> void:
\ttank_rect = Control.new()
\ttank_rect.anchor_left = 0.0
\ttank_rect.anchor_top = 0.0
\ttank_rect.anchor_right = 1.0
\ttank_rect.anchor_bottom = 1.0
\ttank_rect.offset_top = 84
\ttank_rect.clip_contents = true
\tadd_child(tank_rect)

\t# 水体背景
\tvar water = ColorRect.new()
\twater.color = C_WATER
\twater.set_anchors_preset(Control.PRESET_FULL_RECT)
\ttank_rect.add_child(water)

\t# 沙地（底部梯形）
\tvar sand = Polygon2D.new()
\tsand.set_meta("needs_resize", true)
\tsand.color = C_SAND
\ttank_rect.add_child(sand)
\ttank_rect.resized.connect(_on_tank_resized.bind(sand))'''

new = '''func _build_tank_view() -> void:
\tvar header_h := int(round(get_window().size.y * HEADER_RATIO))
\ttank_rect = Control.new()
\ttank_rect.anchor_left = 0.0
\ttank_rect.anchor_top = 0.0
\ttank_rect.anchor_right = 1.0
\ttank_rect.anchor_bottom = 1.0
\ttank_rect.offset_top = header_h
\ttank_rect.clip_contents = true
\tadd_child(tank_rect)

\t# 水体背景
\tvar water = ColorRect.new()
\twater.color = C_WATER
\twater.set_anchors_preset(Control.PRESET_FULL_RECT)
\ttank_rect.add_child(water)

\t# 沙地（底部对称梯形，两侧收边）
\tvar sand = Polygon2D.new()
\tsand.color = C_SAND
\ttank_rect.add_child(sand)
\ttank_rect.resized.connect(_on_tank_resized.bind(sand))
\t_on_tank_resized(sand)
\tprint(">>> [DEBUG] sand.polygon after manual call=", sand.polygon)'''
content = content.replace(old, new)

# 7. Rewrite _place_creature
old = '''func _place_creature(rtl: RichTextLabel, data: Dictionary) -> void:
\tvar tank_w = tank_rect.size.x
\tvar tank_h = tank_rect.size.y
\tvar cx = tank_w / 2.0
\tvar sand_y = tank_h - 60

\tif data.type == "anemone":
\t\tvar anchor := Vector2(cx - 60, sand_y - 80)
\t\trtl.position = anchor
\t\trtl.set_meta("fixed", true)
\t\trtl.set_meta("anchor_pos", anchor)
\t\trtl.set_meta("target_pos", anchor)
\t\trtl.set_meta("speed", ANEMONE_SWAY_SPEED)
\telse:
\t\trtl.position = Vector2(randf_range(60, tank_w - 100), randf_range(100, sand_y - 60))
\t\trtl.set_meta("fixed", false)
\t\trtl.set_meta("target_pos", rtl.position)
\t\trtl.set_meta("speed", randf_range(20.0, 50.0))'''

new = '''func _place_creature(rtl: RichTextLabel, data: Dictionary) -> void:
\tvar tank_w = tank_rect.size.x
\tvar tank_h = tank_rect.size.y
\tvar sand_top_y = tank_h * (1.0 - FLOOR_RATIO)
\tprint(
\t\t">>> [DEBUG] _place_creature ",
\t\tdata.get("name_cn", "?"),
\t\t" tank size=",
\t\ttank_rect.size,
\t\t" sand_top_y=",
\t\tsand_top_y,
\t)
\tvar cx = tank_w / 2.0

\tif data.type == "anemone":
\t\tvar anchor := Vector2(cx - 60, sand_top_y - 80)
\t\trtl.position = anchor
\t\trtl.set_meta("fixed", true)
\t\trtl.set_meta("anchor_pos", anchor)
\t\trtl.set_meta("target_pos", anchor)
\t\trtl.set_meta("speed", ANEMONE_SWAY_SPEED)
\telse:
\t\trtl.position = Vector2(
\t\t\trandf_range(60, tank_w - 100), randf_range(100, sand_top_y - 60)
\t\t)
\t\trtl.set_meta("fixed", false)
\t\trtl.set_meta("target_pos", rtl.position)
\t\trtl.set_meta("speed", randf_range(20.0, 50.0))'''
content = content.replace(old, new)

# 8. Update _animate_fish sand references
content = content.replace(
    'var sand_y = tank_h - 60',
    'var sand_top_y = tank_h * (1.0 - FLOOR_RATIO)'
)
content = content.replace(
    'randf_range(80, sand_y - 40)',
    'randf_range(80, sand_top_y - 40)'
)

with open('scripts/Main.gd', 'w', encoding='utf-8') as f:
    f.write(content)
print('Day 4 patch applied successfully')
