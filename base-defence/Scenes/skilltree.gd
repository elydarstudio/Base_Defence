extends Control

# ── Constants ─────────────────────────────────
const TREE_DATA = {
	"barrage": {
		"name": "BARRAGE",
		"subtitle": "The Artillery",
		"tagline": "Bullets are the weapon, distance is the advantage.",
		"description": "Every core stat feeds the machine. Build damage, build range, build crit — then unleash Multishot and watch three streams tear through waves simultaneously. The highest ceiling of any tree if you invest correctly.",
		"color": Color(0.9, 0.4, 0.1)
	},
	"bulwark": {
		"name": "BULWARK",
		"subtitle": "The Fortress",
		"tagline": "Defense becomes offense. The bigger the wall the harder it hits.",
		"description": "Shield investment isn't just survival — it's damage. Every point of Max Shield feeds Fortify, every regen tick fires Zap, every kill restores your wall. Unlock Pulse and your defense becomes an AOE weapon that hits everything at once.",
		"color": Color(0.2, 0.5, 1.0)
	},
	"siphon": {
		"name": "SIPHON",
		"subtitle": "The Drain",
		"tagline": "Sustain becomes offense. The longer you survive the harder you hit.",
		"description": "Healing is power. HP Regen feeds damage, regen ticks slow enemies, kills push you into overheal, overheal activates Surge. Unlock Drain Beam and you damage and heal simultaneously — the longer the fight the stronger you get.",
		"color": Color(0.6, 0.1, 0.9)
	},
}

const LOCK_REQUIREMENT = 1

var current_view: String = "select"
var select_container: VBoxContainer
var tree_container: ScrollContainer

func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()

func _build_ui():
	# Background
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.07, 0.07, 0.09)
	add_child(bg)

	# Top bar
	var top_bar = HBoxContainer.new()
	top_bar.anchor_right = 1.0
	top_bar.offset_left = 10
	top_bar.offset_right = -10
	top_bar.offset_top = 10
	top_bar.offset_bottom = 60
	add_child(top_bar)

	var back_btn = _make_button("← MENU", Color(0.25, 0.25, 0.25))
	back_btn.custom_minimum_size = Vector2(120, 44)
	back_btn.pressed.connect(_on_back_pressed)
	top_bar.add_child(back_btn)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	var currency_label = Label.new()
	currency_label.name = "CurrencyLabel"
	currency_label.add_theme_font_size_override("font_size", 16)
	currency_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(currency_label)

	# Title
	var title = Label.new()
	title.text = "SKILL TREES"
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 65
	title.offset_bottom = 105
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	add_child(title)

	# Select container
	select_container = VBoxContainer.new()
	select_container.anchor_left = 0.0
	select_container.anchor_right = 1.0
	select_container.offset_left = 10
	select_container.offset_right = -10
	select_container.offset_top = 110
	select_container.offset_bottom = -10
	select_container.add_theme_constant_override("separation", 10)
	add_child(select_container)
	_build_select_view()

	# Tree scroll container (hidden by default)
	tree_container = ScrollContainer.new()
	tree_container.anchor_left = 0.0
	tree_container.anchor_right = 1.0
	tree_container.anchor_top = 0.0
	tree_container.anchor_bottom = 1.0
	tree_container.offset_top = 110
	tree_container.offset_left = 10
	tree_container.offset_right = -10
	tree_container.visible = false
	add_child(tree_container)

	_update_currency_label()

func _build_select_view():
	for child in select_container.get_children():
		child.queue_free()

	var locked = SaveManager.data["phase_tokens_earned"] < LOCK_REQUIREMENT

	for tree_key in ["barrage", "bulwark", "siphon"]:
		var data = TREE_DATA[tree_key]
		var card = _build_tree_card(tree_key, data, locked)
		select_container.add_child(card)

func _build_tree_card(tree_key: String, data: Dictionary, locked: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.bg_color = data["color"].darkened(0.75)
	style.border_color = data["color"] if not locked else Color(0.3, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# Name row
	var name_row = HBoxContainer.new()
	vbox.add_child(name_row)

	var name_label = Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", data["color"] if not locked else Color(0.4, 0.4, 0.4))
	name_row.add_child(name_label)

	var subtitle_label = Label.new()
	subtitle_label.text = "  — " + data["subtitle"]
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	subtitle_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(subtitle_label)

	# Tagline
	var tagline = Label.new()
	tagline.text = data["tagline"]
	tagline.add_theme_font_size_override("font_size", 13)
	tagline.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(tagline)

	# Description
	var desc = Label.new()
	desc.text = data["description"]
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	# Lock label
	if locked:
		var lock_label = Label.new()
		lock_label.text = "🔒 Kill a Phase 3 boss to unlock"
		lock_label.add_theme_font_size_override("font_size", 12)
		lock_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		vbox.add_child(lock_label)

	# Skill count
	var count = SkillManager.get_tree_skill_count(tree_key)
	var count_label = Label.new()
	count_label.text = str(count) + " / 5 skills unlocked"
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", data["color"] if not locked else Color(0.3, 0.3, 0.3))
	vbox.add_child(count_label)

	# Invisible tappable button overlay
	if not locked:
		var btn = Button.new()
		btn.flat = true
		btn.anchor_right = 1.0
		btn.anchor_bottom = 1.0
		btn.modulate.a = 0.0
		btn.pressed.connect(func(): _open_tree(tree_key))
		card.add_child(btn)

	return card

func _open_tree(tree_key: String):
	current_view = tree_key
	select_container.visible = false
	tree_container.visible = true
	for child in tree_container.get_children():
		child.queue_free()
	_build_tree_view(tree_key)

func _build_tree_view(tree_key: String):
	var data = TREE_DATA[tree_key]
	var skills = SkillManager.SKILL_DATA[tree_key]

	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 12)
	tree_container.add_child(outer)

	# Back button row
	var top_row = HBoxContainer.new()
	outer.add_child(top_row)

	var back_btn = _make_button("← TREES", Color(0.25, 0.25, 0.25))
	back_btn.custom_minimum_size = Vector2(120, 44)
	back_btn.pressed.connect(_on_tree_back_pressed)
	top_row.add_child(back_btn)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	# Tree title
	var title = Label.new()
	title.text = data["name"] + " — " + data["subtitle"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", data["color"])
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)

	# Skill rows — keystone at top, skill 0 at bottom
	_add_skill_row(outer, tree_key, [4], skills, data["color"])
	_add_connector(outer, true)
	_add_skill_row(outer, tree_key, [2, 3], skills, data["color"])
	_add_connector(outer, false)
	_add_skill_row(outer, tree_key, [1], skills, data["color"])
	_add_connector(outer, false)
	_add_skill_row(outer, tree_key, [0], skills, data["color"])

func _add_skill_row(parent: VBoxContainer, tree_key: String, slots: Array, skills: Array, color: Color):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	parent.add_child(hbox)
	for slot in slots:
		var card = _build_skill_card(tree_key, slot, skills[slot], color)
		hbox.add_child(card)

func _add_connector(parent: VBoxContainer, split: bool):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(hbox)
	var label = Label.new()
	label.text = "⟋  |  ⟍" if split else "|"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	hbox.add_child(label)

func _build_skill_card(tree_key: String, slot: int, skill: Dictionary, color: Color) -> PanelContainer:
	var unlocked = SkillManager.is_skill_unlocked(tree_key, slot)
	var can_unlock = _can_unlock(tree_key, slot)
	var level = SkillManager.get_skill_level(tree_key, slot)

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 110)

	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.8) if unlocked else Color(0.1, 0.1, 0.12)
	style.border_color = color if unlocked else (Color(0.45, 0.45, 0.45) if can_unlock else Color(0.2, 0.2, 0.2))
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Name + level
	var name_label = Label.new()
	var lock_icon = "" if (unlocked or can_unlock) else "🔒 "
	name_label.text = lock_icon + skill["name"] + (" (Lv" + str(level) + ")" if unlocked else "")
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", color if unlocked else (Color(0.6, 0.6, 0.6) if can_unlock else Color(0.35, 0.35, 0.35)))
	vbox.add_child(name_label)

	# Description
	var desc = Label.new()
	desc.text = skill["desc"]
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6) if unlocked else Color(0.35, 0.35, 0.35))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	if not unlocked:
		var unlock_btn = _make_button("UNLOCK (1 🔷)", Color(0.15, 0.4, 0.15))
		unlock_btn.disabled = not can_unlock or SkillManager.get_tokens() <= 0
		unlock_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		unlock_btn.pressed.connect(func(): _on_unlock_pressed(tree_key, slot))
		btn_row.add_child(unlock_btn)
	else:
		var level_btn = _make_button("+LEVEL (1 ⚡)", Color(0.15, 0.25, 0.55))
		level_btn.disabled = SkillManager.get_shards() <= 0
		level_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		level_btn.pressed.connect(func(): _on_level_pressed(tree_key, slot))
		btn_row.add_child(level_btn)

	return card

func _can_unlock(tree_key: String, slot: int) -> bool:
	match slot:
		0: return true
		1: return SkillManager.is_skill_unlocked(tree_key, 0)
		2: return SkillManager.is_skill_unlocked(tree_key, 1)
		3: return SkillManager.is_skill_unlocked(tree_key, 1)
		4:
			return SkillManager.is_skill_unlocked(tree_key, 2) and \
				   SkillManager.is_skill_unlocked(tree_key, 3) and \
				   not SkillManager.has_keystone()
	return false

func _on_unlock_pressed(tree_key: String, slot: int):
	SkillManager.unlock_skill(tree_key, slot)
	_refresh_tree_view(tree_key)
	_update_currency_label()

func _on_level_pressed(tree_key: String, slot: int):
	SkillManager.level_skill(tree_key, slot)
	_refresh_tree_view(tree_key)
	_update_currency_label()

func _refresh_tree_view(tree_key: String):
	for child in tree_container.get_children():
		child.queue_free()
	_build_tree_view(current_view)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/startmenu.tscn")

func _on_tree_back_pressed():
	current_view = "select"
	tree_container.visible = false
	select_container.visible = true
	_build_select_view()
	_update_currency_label()

func _update_currency_label():
	var label = get_node_or_null("CurrencyLabel")
	if label:
		label.text = "🔷 " + str(SkillManager.get_tokens()) + "  ⚡ " + str(SkillManager.get_shards())

func _make_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color.lightened(0.15)
	hover_style.set_corner_radius_all(4)
	hover_style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", hover_style)
	return btn
