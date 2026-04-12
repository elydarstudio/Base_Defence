extends Control

# ══════════════════════════════════════════════
# skilltree.gd
# Uniform slot structure for all trees:
#   0 = root
#   1 = left branch        (requires 0)
#   2 = right branch       (requires 0)
#   3 = left continues     (requires 1)
#   4 = right continues    (requires 2)
#   5 = keystone           (requires 3 AND 4)
#
# BARRAGE:  0=Rapidfire, 1=Bleed, 2=Range, 3=Focus, 4=Momentum, 5=Chain
# BULWARK:  0=Fortify, 1=Ironclad, 2=Zap, 3=Rampart, 4=Knockback, 5=Pulse
# SIPHON:   0=Vampiric, 1=Overheal, 2=Chill, 3=Surge, 4=Vitality, 5=Drain Beam
#
# Visual layout (top=keystone, bottom=root):
#   [5] → [3, 4] → [1, 2] → [0]
# ══════════════════════════════════════════════

const TREE_DATA = {
	"barrage": {
		"name":        "BARRAGE",
		"subtitle":    "The Artillery",
		"tagline":     "Bullets are the weapon. Distance is the advantage.",
		"description": "Build damage, range, and crit — then fire three streams simultaneously. Highest damage ceiling of any tree.",
		"color":       Color(0.9, 0.4, 0.1),
	},
	"bulwark": {
		"name":        "BULWARK",
		"subtitle":    "The Fortress",
		"tagline":     "Defense becomes offense. The bigger the wall, the harder it hits.",
		"description": "Shield investment isn't just survival — it's damage. Every regen tick fires Zap, every kill restores your wall. Pulse hits everything at once.",
		"color":       Color(0.2, 0.5, 1.0),
	},
	"siphon": {
		"name":        "SIPHON",
		"subtitle":    "The Drain",
		"tagline":     "Sustain becomes offense. The longer you survive, the harder you hit.",
		"description": "HP Regen feeds damage, ticks slow enemies, kills push you into overheal, overheal activates Surge. Drain Beam damages and heals simultaneously.",
		"color":       Color(0.6, 0.1, 0.9),
	},
}

const LOCK_REQUIREMENT: int = 0

var _current_tree: String = ""
var _select_scroll: ScrollContainer
var _tree_scroll: ScrollContainer

func _ready():
	anchor_right  = 1.0
	anchor_bottom = 1.0
	_build_layout()

# ─────────────────────────────────────────────
# ROOT LAYOUT
# ─────────────────────────────────────────────
func _build_layout():
	var bg = ColorRect.new()
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.06, 0.06, 0.08)
	add_child(bg)

	_select_scroll = _make_scroll()
	add_child(_select_scroll)

	_tree_scroll = _make_scroll()
	_tree_scroll.visible = false
	add_child(_tree_scroll)

	_build_select_view()

func _make_scroll() -> ScrollContainer:
	var sc = ScrollContainer.new()
	sc.anchor_right  = 1.0
	sc.anchor_bottom = 1.0
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return sc

# ─────────────────────────────────────────────
# SELECT VIEW
# ─────────────────────────────────────────────
func _build_select_view():
	_clear(_select_scroll)

	var locked = SaveManager.data["phase_tokens_earned"] < LOCK_REQUIREMENT

	var outer = VBoxContainer.new()
	outer.custom_minimum_size = Vector2(696, 0)
	outer.add_theme_constant_override("separation", 10)
	outer.offset_left = 12
	outer.offset_top  = 8
	_select_scroll.add_child(outer)

	var top = HBoxContainer.new()
	top.custom_minimum_size = Vector2(696, 0)
	top.add_theme_constant_override("separation", 8)
	outer.add_child(top)

	var back = _btn("← MENU", Color(0.22, 0.22, 0.25))
	back.custom_minimum_size = Vector2(110, 42)
	back.pressed.connect(_on_back_to_menu)
	top.add_child(back)

	var title = _label("SKILL TREES", 24, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)

	outer.add_child(_build_stat_bar())

	for key in ["barrage", "bulwark", "siphon"]:
		outer.add_child(_build_select_card(key, locked))

func _build_select_card(tree_key: String, locked: bool) -> PanelContainer:
	var d     = TREE_DATA[tree_key]
	var color = d["color"] as Color
	var count = SkillManager.get_tree_skill_count(tree_key)

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.bg_color     = color.darkened(0.78)
	style.border_color = color if not locked else Color(0.28, 0.28, 0.28)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var name_row = HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_theme_constant_override("separation", 6)
	vbox.add_child(name_row)

	var name_lbl = _label(d["name"], 21, color if not locked else Color(0.4, 0.4, 0.4))
	name_row.add_child(name_lbl)
	var sub_lbl = _label("— " + d["subtitle"], 13, Color(0.55, 0.55, 0.55))
	sub_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(sub_lbl)
	name_row.add_child(_spacer())

	vbox.add_child(_wrap_label(d["tagline"], 12, Color(0.72, 0.72, 0.72)))
	vbox.add_child(_wrap_label(d["description"], 11, Color(0.5, 0.5, 0.5)))

	if locked:
		vbox.add_child(_label("🔒 Kill a Phase 3 boss to unlock", 11, Color(0.8, 0.3, 0.3)))
	else:
		vbox.add_child(_label(str(count) + " / 6 skills unlocked", 11, color))

	if not locked:
		var overlay = Button.new()
		overlay.flat          = true
		overlay.anchor_right  = 1.0
		overlay.anchor_bottom = 1.0
		overlay.modulate.a    = 0.0
		overlay.pressed.connect(func(): _open_tree(tree_key))
		card.add_child(overlay)

	return card

# ─────────────────────────────────────────────
# TREE VIEW
# ─────────────────────────────────────────────
func _open_tree(tree_key: String):
	_current_tree          = tree_key
	_select_scroll.visible = false
	_tree_scroll.visible   = true
	_build_tree_view()

func _build_tree_view():
	_clear(_tree_scroll)

	var d      = TREE_DATA[_current_tree]
	var color  = d["color"] as Color
	var skills = SkillManager.SKILL_DATA[_current_tree]

	var outer = VBoxContainer.new()
	outer.custom_minimum_size = Vector2(696, 0)
	outer.add_theme_constant_override("separation", 8)
	outer.offset_left = 12
	outer.offset_top  = 8
	_tree_scroll.add_child(outer)

	var top = HBoxContainer.new()
	top.custom_minimum_size = Vector2(696, 0)
	top.add_theme_constant_override("separation", 8)
	outer.add_child(top)

	var back = _btn("← TREES", Color(0.22, 0.22, 0.25))
	back.custom_minimum_size = Vector2(100, 40)
	back.pressed.connect(_close_tree)
	top.add_child(back)
	top.add_child(_spacer())

	var title = _label(d["name"] + "  —  " + d["subtitle"], 16, color)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)

	outer.add_child(_build_stat_bar())

	# Uniform layout for all trees: keystone top, root bottom
	_add_row(outer, [5], skills, color)
	_add_connector(outer, true)
	_add_row(outer, [3, 4], skills, color)
	_add_connector(outer, false)
	_add_row(outer, [1, 2], skills, color)
	_add_connector(outer, false)
	_add_row(outer, [0], skills, color)

func _add_row(parent: VBoxContainer, slots: Array, skills: Array, color: Color):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 8)
	parent.add_child(hbox)
	for slot in slots:
		hbox.add_child(_build_skill_card(slot, skills[slot], color))

func _add_connector(parent: VBoxContainer, split: bool):
	var lbl = _label("⟋   |   ⟍" if split else "|", 13, Color(0.35, 0.35, 0.35))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func _build_skill_card(slot: int, skill: Dictionary, color: Color) -> PanelContainer:
	var tree        = _current_tree
	var unlocked    = SkillManager.is_skill_unlocked(tree, slot)
	var can_unlock  = SkillManager._check_prereq(tree, slot)
	var level       = SkillManager.get_skill_level(tree, slot)
	var is_keystone = (slot == 5)

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 90)

	var style = StyleBoxFlat.new()
	if unlocked:
		style.bg_color     = color.darkened(0.78)
		style.border_color = color
	elif can_unlock:
		style.bg_color     = Color(0.1, 0.1, 0.13)
		style.border_color = Color(0.42, 0.42, 0.42)
	else:
		style.bg_color     = Color(0.08, 0.08, 0.10)
		style.border_color = Color(0.2, 0.2, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var name_color: Color
	if unlocked:      name_color = color
	elif can_unlock:  name_color = Color(0.65, 0.65, 0.65)
	else:             name_color = Color(0.32, 0.32, 0.32)

	var prefix = "⚡ " if is_keystone else ("" if (unlocked or can_unlock) else "🔒 ")
	var name_text = prefix + skill["name"] + ("  (Lv" + str(level) + ")" if unlocked else "")
	vbox.add_child(_label(name_text, 13, name_color))

	var desc_color = Color(0.55, 0.55, 0.55) if unlocked else Color(0.32, 0.32, 0.32)
	vbox.add_child(_wrap_label(skill["desc"], 10, desc_color))

	var btn_row = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_row)

	if not unlocked:
		var unlock_btn = _btn("UNLOCK  1 🔷", Color(0.12, 0.35, 0.12))
		unlock_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		unlock_btn.disabled = not can_unlock or SkillManager.get_tokens() <= 0
		unlock_btn.pressed.connect(func(): _on_unlock(tree, slot))
		btn_row.add_child(unlock_btn)
		if not can_unlock and SkillManager.get_tokens() > 0:
			vbox.add_child(_label(_prereq_hint(tree, slot), 9, Color(0.5, 0.35, 0.35)))
	else:
		var level_btn = _btn("+LEVEL  1 ⚡", Color(0.12, 0.22, 0.48))
		level_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		level_btn.disabled = SkillManager.get_shards() <= 0
		level_btn.pressed.connect(func(): _on_level(tree, slot))
		btn_row.add_child(level_btn)

	return card

# ─────────────────────────────────────────────
# PREREQ HINT
# ─────────────────────────────────────────────
func _prereq_hint(tree: String, slot: int) -> String:
	match slot:
		1, 2:
			return "Requires: " + SkillManager.SKILL_DATA[tree][0]["name"]
		3:
			return "Requires: " + SkillManager.SKILL_DATA[tree][1]["name"]
		4:
			return "Requires: " + SkillManager.SKILL_DATA[tree][2]["name"]
		5:
			if SkillManager.has_keystone():
				return "Keystone already chosen"
			var missing: Array = []
			if not SkillManager.is_skill_unlocked(tree, 3):
				missing.append(SkillManager.SKILL_DATA[tree][3]["name"])
			if not SkillManager.is_skill_unlocked(tree, 4):
				missing.append(SkillManager.SKILL_DATA[tree][4]["name"])
			return "Requires: " + ", ".join(missing)
	return ""

# ─────────────────────────────────────────────
# HANDLERS
# ─────────────────────────────────────────────
func _on_unlock(tree: String, slot: int):
	SkillManager.unlock_skill(tree, slot)
	_build_tree_view()

func _on_level(tree: String, slot: int):
	SkillManager.level_skill(tree, slot)
	_build_tree_view()

func _close_tree():
	_current_tree          = ""
	_tree_scroll.visible   = false
	_select_scroll.visible = true
	_build_select_view()

func _on_back_to_menu():
	get_tree().change_scene_to_file("res://Scenes/startmenu.tscn")

# ─────────────────────────────────────────────
# STAT BAR
# ─────────────────────────────────────────────
func _build_stat_bar() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(696, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.13)
	style.set_border_width_all(1)
	style.border_color = Color(0.25, 0.25, 0.25)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(676, 0)
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	hbox.add_child(_label("🔷 Tokens: " + str(SkillManager.get_tokens()) + " / " + str(SkillManager.MAX_TOKENS), 13, Color(0.4, 0.7, 1.0)))
	hbox.add_child(_spacer())
	hbox.add_child(_label("⚡ Shards: " + str(SkillManager.get_shards()), 13, Color(0.9, 0.8, 0.2)))
	hbox.add_child(_spacer())
	hbox.add_child(_label("☠ Kills: " + str(SkillManager.get_kills_since_last_shard()) + " / " + str(SkillManager.get_next_shard_threshold()), 13, Color(0.75, 0.75, 0.75)))

	return panel

# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────
func _label(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _wrap_label(text: String, size: int, color: Color) -> Label:
	var l = _label(text, size, color)
	l.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _spacer() -> Control:
	var s = Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s

func _btn(text: String, bg: Color) -> Button:
	var b = Button.new()
	b.text = text
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", normal)
	var hover = StyleBoxFlat.new()
	hover.bg_color = bg.lightened(0.18)
	hover.set_corner_radius_all(4)
	hover.set_content_margin_all(8)
	b.add_theme_stylebox_override("hover", hover)
	var dis = StyleBoxFlat.new()
	dis.bg_color = bg.darkened(0.4)
	dis.set_corner_radius_all(4)
	dis.set_content_margin_all(8)
	b.add_theme_stylebox_override("disabled", dis)
	return b

func _clear(node: Node):
	for child in node.get_children():
		child.queue_free()
