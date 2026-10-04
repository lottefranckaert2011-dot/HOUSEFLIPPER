class_name Picker
extends Control
## Catalog overlay for choosing paint, flooring or furniture.

const WALL_TABS := [["paint", "Paint"], ["wallpaper", "Wallpaper"], ["tiles", "Tiles"]]
const FLOOR_TABS := [
	["wood", "Wood"], ["carpet", "Carpet"], ["tiles", "Tiles"], ["concrete", "Concrete"]
]

var tools: ToolController
var _kind := "build"  # build, wall or floor
var _tab := ""
var _title: Label
var _tabs: HBoxContainer
var _grid: GridContainer
var _money: Label


func setup(p_tools: ToolController) -> void:
	tools = p_tools
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.04, 0.1, 0.45)
	dim.gui_input.connect(
		func(e):
			if e is InputEventMouseButton and e.pressed:
				close()
	)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color(0.08, 0.11, 0.19, 0.96), 22, 22))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -500
	panel.offset_right = 500
	panel.offset_top = -310
	panel.offset_bottom = 310
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	_title = UiTheme.label("", 28, Color.WHITE, true)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	head.add_child(UiTheme.icon("res://assets/icons/coin.svg", 28))
	_money = UiTheme.label("", 24, UiTheme.GOLD, true)
	head.add_child(_money)
	var close_btn := UiTheme.button("X", Color(0.85, 0.35, 0.35))
	close_btn.custom_minimum_size = Vector2(44, 40)
	close_btn.pressed.connect(close)
	head.add_child(close_btn)
	_tabs = HBoxContainer.new()
	vb.add_child(_tabs)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)
	Game.money_changed.connect(func(_a, _d): _money.text = UiTheme.money(Game.money))


func open_for_tool() -> void:
	match tools.tool:
		ToolController.Tool.PAINT:
			open("wall")
		ToolController.Tool.FLOOR:
			open("floor")
		_:
			open("build")


func open(kind: String) -> void:
	_kind = kind
	match kind:
		"wall":
			_title.text = "Walls"
			_tab = Catalog.finish("wall", tools.wall_finish).get("cat", "paint")
		"floor":
			_title.text = "Flooring"
			_tab = Catalog.finish("floor", tools.floor_finish).get("cat", "wood")
		_:
			_title.text = "Furniture Catalog"
			if _tab == "" or not _tab in Catalog.SHOP_TABS.map(func(t): return t[0]):
				_tab = _suggest_tab()
	visible = true
	Game.push_ui(&"picker")
	_money.text = UiTheme.money(Game.money)
	_refresh()
	Sfx.play("whoosh", 0.05, -6.0)


## Opens the shop on the tab that matches the room the player stands in.
func _suggest_tab() -> String:
	var room := HouseLayout.room_at(tools.camera().global_position)
	match room:
		"bedroom":
			return "bedroom"
		"kitchen", "utility":
			return "kitchen"
		"bathroom":
			return "bathroom"
		"backyard", "frontyard":
			return "garden"
	return "living"


func close() -> void:
	if not visible:
		return
	visible = false
	Game.pop_ui(&"picker")
	Game.capture_mouse()


func _refresh() -> void:
	UiTheme.clear(_tabs)
	UiTheme.clear(_grid)
	var tabs: Array = (
		WALL_TABS if _kind == "wall" else (FLOOR_TABS if _kind == "floor" else Catalog.SHOP_TABS)
	)
	if not _tab in tabs.map(func(t): return t[0]):
		_tab = tabs[0][0]
	for t in tabs:
		var b := UiTheme.button(t[1])
		b.custom_minimum_size = Vector2(120, 40)
		b.modulate = Color.WHITE if t[0] == _tab else Color(1, 1, 1, 0.5)
		b.pressed.connect(
			func():
				_tab = t[0]
				_refresh()
		)
		_tabs.add_child(b)
	if _kind == "build":
		for id in Catalog.items_in_tab(_tab):
			var d := Catalog.item(id)
			var thumb := Catalog.THUMB_DIR % id
			var tex: Texture2D = load(thumb) if ResourceLoader.exists(thumb) else null
			_grid.add_child(
				_card(
					d["name"],
					d["price"],
					tex,
					Color.WHITE,
					id == tools.build_item,
					func(): _choose_item(id)
				)
			)
	else:
		for id in Catalog.shop_finishes(_kind):
			var d := Catalog.finish(_kind, id)
			if d["cat"] != _tab:
				continue
			var tex: Texture2D = Mats.tex(d["tex"]) if d.has("tex") else null
			var col: Color = d.get("color", d.get("tint", Color.WHITE))
			var selected: bool = (
				id == (tools.wall_finish if _kind == "wall" else tools.floor_finish)
			)
			_grid.add_child(
				_card(d["name"], d["price"], tex, col, selected, func(): _choose_finish(id))
			)


func _card(
	title: String, price: int, tex: Texture2D, tint: Color, selected: bool, on_pick: Callable
) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 176)
	var normal := UiTheme.box(
		Color(1, 1, 1, 0.08),
		14,
		8,
		UiTheme.GOLD if selected else Color(1, 1, 1, 0.1),
		3 if selected else 2
	)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override(
		"hover", UiTheme.box(Color(1, 1, 1, 0.18), 14, 8, UiTheme.ACCENT, 3)
	)
	b.add_theme_stylebox_override(
		"pressed", UiTheme.box(Color(1, 1, 1, 0.25), 14, 8, UiTheme.ACCENT, 3)
	)
	var affordable := Game.can_afford(price)
	b.pressed.connect(
		func():
			Sfx.play("click")
			on_pick.call()
	)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 8
	v.offset_bottom = -6
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var img := TextureRect.new()
	img.custom_minimum_size = Vector2(0, 110)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if _kind == "build"
		else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex:
		img.texture = tex
		img.self_modulate = tint
	else:
		var swatch := ColorRect.new()
		swatch.color = tint
		swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.add_child(swatch)
	v.add_child(img)
	var name_l := UiTheme.label(title, 15, Color.WHITE, true)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	v.add_child(name_l)
	var price_l := UiTheme.label(
		UiTheme.money(price), 16, UiTheme.GOLD if affordable else Color(1, 0.45, 0.4), true
	)
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(price_l)
	return b


func _choose_item(id: String) -> void:
	tools.select_item(id)
	close()


func _choose_finish(id: String) -> void:
	if _kind == "wall":
		tools.select_wall_finish(id)
	else:
		tools.select_floor_finish(id)
	close()
