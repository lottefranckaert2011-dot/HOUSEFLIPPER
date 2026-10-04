class_name Hud
extends CanvasLayer
## All on-screen UI: main menu, in-game HUD, pause overlay, tablet and picker.

const TOOL_ICONS := ["hand", "sponge", "roller", "floor", "build"]

var world: GameWorld
var root: Control
var menu: Control
var hud_root: Control
var pause_overlay: Control
var tablet: Tablet
var picker: Picker
## Set by dev tools to keep the pause overlay hidden without a captured mouse.
var suppress_pause := false

var _money_label: Label
var _house_label: Label
var _job_title: Label
var _task_box: VBoxContainer
var _job_card: PanelContainer
var _hint_panel: PanelContainer
var _hint_label: Label
var _crosshair: TextureRect
var _slots: Array[PanelContainer] = []
var _selection_label: Label
var _selection_swatch: TextureRect
var _selection_panel: PanelContainer
var _toasts: VBoxContainer
var _done_banner: PanelContainer
var _continue_btn: Button
var _was_active := false


func setup(p_world: GameWorld) -> void:
	world = p_world
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)

	_build_hud()
	_build_pause()
	tablet = Tablet.new()
	tablet.setup(world)
	root.add_child(tablet)
	picker = Picker.new()
	picker.setup(world.player.tools)
	root.add_child(picker)
	_build_menu()

	var tools := world.player.tools
	tools.hint_changed.connect(_on_hint)
	tools.tool_changed.connect(func(_t): _refresh_tools())
	tools.selection_changed.connect(_refresh_tools)
	Game.money_changed.connect(_on_money)
	Game.toast.connect(_on_toast)
	world.tasks_updated.connect(_on_tasks)
	world.job_changed.connect(_on_job_changed)
	_on_money(Game.money, 0)
	_on_tasks(world.task_progress(), world.tasks_done())
	_refresh_tools()
	hud_root.visible = false


# --- Main menu ------------------------------------------------------------------


func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.04, 0.08, 0.16, 0.25)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(shade)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color(0.07, 0.1, 0.18, 0.86), 24, 36))
	UiTheme.anchor(panel, Control.PRESET_CENTER_LEFT, Vector2(60, 0))
	panel.custom_minimum_size = Vector2(440, 0)
	menu.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var title := UiTheme.shadow_label("Home Flip", 56, Color.WHITE)
	vb.add_child(title)
	var title2 := UiTheme.shadow_label("DESIGNER", 34, UiTheme.GOLD)
	title2.add_theme_constant_override("line_spacing", -10)
	vb.add_child(title2)
	vb.add_child(UiTheme.label("Clean  ·  Renovate  ·  Decorate  ·  Flip", 18, UiTheme.MUTED))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	vb.add_child(spacer)

	_continue_btn = UiTheme.button("Play", UiTheme.GOOD, 300)
	_continue_btn.custom_minimum_size.y = 58
	_continue_btn.add_theme_font_size_override("font_size", 24)
	_continue_btn.pressed.connect(_on_play)
	vb.add_child(_continue_btn)
	if Game.has_save() and (Game.job_index > 0 or not Game.house.is_empty() or Game.house_no > 1):
		_continue_btn.text = "Continue  ·  House #%d" % Game.house_no
		var new_btn := UiTheme.button("New Game", Color(0.35, 0.4, 0.5))
		new_btn.pressed.connect(_on_new_game.bind(new_btn))
		vb.add_child(new_btn)
	var help := UiTheme.button("How to Play", Color(0.35, 0.4, 0.5))
	help.pressed.connect(func(): tablet.open("help"))
	vb.add_child(help)
	var credits := UiTheme.label(
		"3D models by Kenney (CC0)  ·  Font: Nunito (OFL)", 13, UiTheme.MUTED
	)
	vb.add_child(credits)


func _on_play() -> void:
	menu.visible = false
	hud_root.visible = true
	world.start_playing()
	if Game.house.is_empty() and Game.job_index == 0:
		tablet.open("job")


func _on_new_game(btn: Button) -> void:
	if btn.text != "Are you sure?":
		btn.text = "Are you sure?"
		return
	Game.reset_progress()
	get_tree().reload_current_scene()


func show_menu() -> void:
	tablet.close()
	picker.close()
	hud_root.visible = false
	pause_overlay.visible = false
	menu.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	world.show_menu()
	if Game.house_no > 1 or Game.job_index > 0 or not Game.house.is_empty():
		_continue_btn.text = "Continue  ·  House #%d" % Game.house_no


# --- HUD --------------------------------------------------------------------------


func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_root)

	# Money
	var money_panel := PanelContainer.new()
	money_panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, 30, 16))
	UiTheme.anchor(money_panel, Control.PRESET_TOP_LEFT, Vector2(20, 18))
	money_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(money_panel)
	var mh := HBoxContainer.new()
	money_panel.add_child(mh)
	mh.add_child(UiTheme.icon("res://assets/icons/coin.svg", 34))
	_money_label = UiTheme.label("$0", 28, UiTheme.GOLD, true)
	mh.add_child(_money_label)
	_house_label = UiTheme.shadow_label("", 16, Color.WHITE, false)
	UiTheme.anchor(_house_label, Control.PRESET_TOP_LEFT, Vector2(28, 76))
	hud_root.add_child(_house_label)

	# Job card
	_job_card = PanelContainer.new()
	_job_card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, 16, 18))
	UiTheme.anchor(_job_card, Control.PRESET_TOP_RIGHT, Vector2(-20, 18))
	_job_card.custom_minimum_size = Vector2(380, 0)
	_job_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(_job_card)
	var jv := VBoxContainer.new()
	jv.add_theme_constant_override("separation", 6)
	_job_card.add_child(jv)
	var jh := HBoxContainer.new()
	jv.add_child(jh)
	jh.add_child(UiTheme.icon("res://assets/icons/tablet.svg", 22, UiTheme.ACCENT.lightened(0.3)))
	_job_title = UiTheme.label("", 20, Color.WHITE, true)
	jh.add_child(_job_title)
	_task_box = VBoxContainer.new()
	_task_box.add_theme_constant_override("separation", 3)
	jv.add_child(_task_box)
	var tab_hint := UiTheme.label("[Tab] Open tablet", 14, UiTheme.MUTED)
	jv.add_child(tab_hint)

	# Crosshair and hint
	_crosshair = UiTheme.icon("res://assets/icons/dot.svg", 16)
	UiTheme.anchor(_crosshair, Control.PRESET_CENTER)
	hud_root.add_child(_crosshair)
	_hint_panel = PanelContainer.new()
	_hint_panel.add_theme_stylebox_override(
		"panel", UiTheme.box(Color(0.06, 0.08, 0.14, 0.78), 12, 14)
	)
	UiTheme.anchor(_hint_panel, Control.PRESET_CENTER, Vector2(0, 52))
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(_hint_panel)
	_hint_label = UiTheme.label("", 18)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_panel.add_child(_hint_label)
	_hint_panel.visible = false

	# Hotbar
	var bar := HBoxContainer.new()
	UiTheme.anchor(bar, Control.PRESET_CENTER_BOTTOM, Vector2(0, -24))
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(bar)
	for i in 5:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(84, 84)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_slot_input.bind(i))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(v)
		var ic := UiTheme.icon("res://assets/icons/%s.svg" % TOOL_ICONS[i], 40)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var l := UiTheme.label("%d  %s" % [i + 1, ToolController.TOOL_NAMES[i]], 13)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		bar.add_child(slot)
		_slots.append(slot)

	# Selection preview above the hotbar
	_selection_panel = PanelContainer.new()
	_selection_panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, 12, 12))
	UiTheme.anchor(_selection_panel, Control.PRESET_CENTER_BOTTOM, Vector2(0, -122))
	_selection_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(_selection_panel)
	var sh := HBoxContainer.new()
	_selection_panel.add_child(sh)
	_selection_swatch = TextureRect.new()
	_selection_swatch.custom_minimum_size = Vector2(30, 30)
	_selection_swatch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_selection_swatch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sh.add_child(_selection_swatch)
	_selection_label = UiTheme.label("", 16)
	sh.add_child(_selection_label)

	# Toasts
	_toasts = VBoxContainer.new()
	UiTheme.anchor(_toasts, Control.PRESET_CENTER_LEFT, Vector2(22, 0))
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(_toasts)

	# Job-done banner
	_done_banner = PanelContainer.new()
	_done_banner.add_theme_stylebox_override(
		"panel", UiTheme.box(UiTheme.GOOD.darkened(0.15), 14, 18)
	)
	UiTheme.anchor(_done_banner, Control.PRESET_CENTER_TOP, Vector2(0, 20))
	_done_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dl := UiTheme.label("All tasks done!  Press [Tab] to finish the job", 20, Color.WHITE, true)
	_done_banner.add_child(dl)
	_done_banner.visible = false
	hud_root.add_child(_done_banner)

	var keys := UiTheme.shadow_label(
		"[Q] Catalog   [Tab] Tablet   [Esc] Pause", 14, Color(1, 1, 1, 0.8), false
	)
	UiTheme.anchor(keys, Control.PRESET_BOTTOM_LEFT, Vector2(20, -20))
	hud_root.add_child(keys)


func _build_pause() -> void:
	pause_overlay = Control.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	root.add_child(pause_overlay)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.06, 0.12, 0.55)
	bg.gui_input.connect(
		func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_resume()
	)
	pause_overlay.add_child(bg)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color(0.07, 0.1, 0.18, 0.92), 20, 30))
	UiTheme.anchor(panel, Control.PRESET_CENTER)
	pause_overlay.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var t := UiTheme.label("Paused", 34, Color.WHITE, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var resume := UiTheme.button("Resume", UiTheme.GOOD, 280)
	resume.pressed.connect(_resume)
	vb.add_child(resume)
	var tab := UiTheme.button("Open Tablet")
	tab.pressed.connect(func(): tablet.open("job"))
	vb.add_child(tab)
	var settings := UiTheme.button("Settings", Color(0.35, 0.4, 0.5))
	settings.pressed.connect(func(): tablet.open("settings"))
	vb.add_child(settings)
	var quit := UiTheme.button("Main Menu", Color(0.35, 0.4, 0.5))
	quit.pressed.connect(show_menu)
	vb.add_child(quit)


func _resume() -> void:
	pause_overlay.visible = false
	Game.capture_mouse()


func _process(_delta: float) -> void:
	if not Game.playing:
		_set_active(false)
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	pause_overlay.visible = not captured and not Game.is_ui_open() and not suppress_pause
	_set_active(captured and not Game.is_ui_open())


## Tells CrazyGames whether the player is actively playing.
func _set_active(active: bool) -> void:
	if active == _was_active:
		return
	_was_active = active
	if active:
		CrazySDK.gameplay_start()
	else:
		CrazySDK.gameplay_stop()


func _unhandled_input(event: InputEvent) -> void:
	if not Game.playing:
		return
	if event.is_action_pressed("tablet"):
		if tablet.visible:
			tablet.close()
		elif not picker.visible:
			tablet.open("job")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_picker") and not tablet.visible:
		if picker.visible:
			picker.close()
		else:
			picker.open_for_tool()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		if tablet.visible:
			tablet.close()
		elif picker.visible:
			picker.close()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif (
		event is InputEventMouseButton
		and event.pressed
		and not Game.is_ui_open()
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	):
		Game.capture_mouse()
		get_viewport().set_input_as_handled()


func _on_slot_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		world.player.tools.set_tool(i)


func _refresh_tools() -> void:
	var tools := world.player.tools
	for i in _slots.size():
		var active := i == tools.tool
		var sb := UiTheme.box(
			UiTheme.ACCENT if active else UiTheme.PANEL,
			14,
			8,
			Color.WHITE if active else Color(1, 1, 1, 0.15),
			3 if active else 2
		)
		_slots[i].add_theme_stylebox_override("panel", sb)
		_slots[i].scale = Vector2.ONE
	var text := ""
	var tex: Texture2D = null
	var swatch_color := Color.WHITE
	match tools.tool:
		ToolController.Tool.PAINT:
			var d := Catalog.finish("wall", tools.wall_finish)
			text = "%s  $%d / wall    [Q] Change" % [d["name"], d["price"]]
			tex = Mats.tex(d["tex"]) if d.has("tex") else _white_tex()
			swatch_color = d.get("color", d.get("tint", Color.WHITE))
		ToolController.Tool.FLOOR:
			var d := Catalog.finish("floor", tools.floor_finish)
			text = "%s  $%d    [Q] Change" % [d["name"], d["price"]]
			tex = Mats.tex(d["tex"])
			swatch_color = d.get("tint", Color.WHITE)
		ToolController.Tool.BUILD:
			if tools.build_item != "":
				var d := Catalog.item(tools.build_item)
				text = "%s  $%d    [Q] Catalog" % [d["name"], d["price"]]
				var thumb := Catalog.THUMB_DIR % tools.build_item
				tex = load(thumb) if ResourceLoader.exists(thumb) else null
			else:
				text = "Press [Q] to open the furniture catalog"
	_selection_panel.visible = text != ""
	_selection_label.text = text
	_selection_swatch.texture = tex
	_selection_swatch.self_modulate = swatch_color
	_selection_swatch.visible = tex != null
	UiTheme.anchor(_selection_panel, Control.PRESET_CENTER_BOTTOM, Vector2(0, -122))


func _white_tex() -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)


func _on_hint(text: String) -> void:
	_hint_panel.visible = text != ""
	_hint_label.text = text
	UiTheme.anchor(_hint_panel, Control.PRESET_CENTER, Vector2(0, 52))
	_crosshair.modulate = UiTheme.GOLD if text.begins_with("[") else Color.WHITE


func _on_money(amount: int, delta: int) -> void:
	_money_label.text = UiTheme.money(amount)
	_house_label.text = "House #%d" % Game.house_no
	if delta != 0:
		var tw := create_tween()
		_money_label.pivot_offset = _money_label.size / 2
		tw.tween_property(_money_label, "scale", Vector2.ONE * 1.18, 0.08)
		tw.tween_property(_money_label, "scale", Vector2.ONE, 0.15)


func _on_toast(text: String, color: Color) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(Color(0.06, 0.08, 0.14, 0.82), 10, 12))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiTheme.label(text, 17, color, true)
	p.add_child(l)
	_toasts.add_child(p)
	while _toasts.get_child_count() > 6:
		_toasts.get_child(0).free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


func _on_tasks(progress: Array, all_done: bool) -> void:
	var job := world.current_job()
	_job_title.text = job["title"]
	for c in _task_box.get_children():
		c.free()
	if progress.is_empty():
		var l := UiTheme.label("Open the tablet to sell the house!", 16, UiTheme.GOLD)
		_task_box.add_child(l)
	for p in progress:
		var row := HBoxContainer.new()
		var done: bool = p["done"] >= p["total"]
		row.add_child(UiTheme.icon("res://assets/icons/%s.svg" % ("check" if done else "dot"), 18))
		var l := UiTheme.label(p["label"], 15, UiTheme.MUTED if done else UiTheme.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 260
		row.add_child(l)
		if p["total"] > 1:
			row.add_child(
				UiTheme.label(
					"%d/%d" % [p["done"], p["total"]],
					15,
					UiTheme.GOOD if done else UiTheme.GOLD,
					true
				)
			)
		_task_box.add_child(row)
	_done_banner.visible = all_done
	UiTheme.anchor(_job_card, Control.PRESET_TOP_RIGHT, Vector2(-20, 18))


func _on_job_changed() -> void:
	tablet.refresh()
