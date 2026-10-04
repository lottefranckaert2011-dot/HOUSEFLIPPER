class_name Tablet
extends Control
## The in-game tablet: current job, job list, settings and help.

var world: GameWorld
var _tab := "job"
var _content: VBoxContainer
var _tab_buttons := {}
var _money: Label
var _sold_value := -1
var _last_reward_ad := -1000000


func setup(p_world: GameWorld) -> void:
	world = p_world
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.04, 0.1, 0.55)
	add_child(dim)

	var bezel := PanelContainer.new()
	bezel.add_theme_stylebox_override(
		"panel", UiTheme.box(Color(0.1, 0.11, 0.14), 34, 22, Color(0.25, 0.27, 0.32), 3)
	)
	bezel.set_anchors_preset(Control.PRESET_CENTER)
	bezel.custom_minimum_size = Vector2(940, 600)
	bezel.offset_left = -470
	bezel.offset_right = 470
	bezel.offset_top = -300
	bezel.offset_bottom = 300
	add_child(bezel)
	var screen := PanelContainer.new()
	screen.add_theme_stylebox_override("panel", UiTheme.box(Color(0.93, 0.95, 0.98), 18, 22))
	bezel.add_child(screen)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	screen.add_child(vb)

	var header := HBoxContainer.new()
	vb.add_child(header)
	for t in [
		["job", "Current Job"],
		["jobs", "All Jobs"],
		["settings", "Settings"],
		["help", "How to Play"]
	]:
		var b := UiTheme.button(t[1])
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(open.bind(t[0]))
		header.add_child(b)
		_tab_buttons[t[0]] = b
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(UiTheme.icon("res://assets/icons/coin.svg", 28))
	_money = UiTheme.label("", 24, Color(0.75, 0.52, 0.05), true)
	header.add_child(_money)
	var close_btn := UiTheme.button("X", Color(0.85, 0.35, 0.35))
	close_btn.custom_minimum_size = Vector2(44, 40)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)
	world.tasks_updated.connect(_on_tasks_updated)
	Game.money_changed.connect(func(_a, _d): _money.text = UiTheme.money(Game.money))


func _on_tasks_updated(_progress: Array, _done: bool) -> void:
	if visible:
		refresh()


func open(tab: String) -> void:
	_tab = tab
	visible = true
	Game.push_ui(&"tablet")
	refresh()
	Sfx.play("whoosh", 0.05, -6.0)


func close(force := false) -> void:
	if not visible:
		return
	# The house is sold: the only way forward is the Next House button.
	if _sold_value >= 0 and not force:
		return
	visible = false
	Game.pop_ui(&"tablet")
	Game.capture_mouse()


func refresh() -> void:
	_money.text = UiTheme.money(Game.money)
	for k in _tab_buttons:
		var b: Button = _tab_buttons[k]
		b.modulate = Color.WHITE if k == _tab else Color(1, 1, 1, 0.55)
	UiTheme.clear(_content)
	match _tab:
		"job":
			_build_job()
		"jobs":
			_build_jobs()
		"settings":
			_build_settings()
		_:
			_build_help()


func _dark(text: String, size := 18, bold := false, wrap := false) -> Label:
	var l := UiTheme.label(text, size, UiTheme.TEXT_DARK, bold)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _build_job() -> void:
	if _sold_value >= 0:
		_build_sold()
		return
	var job := world.current_job()
	var head := HBoxContainer.new()
	_content.add_child(head)
	head.add_child(UiTheme.icon("res://assets/icons/tablet.svg", 34, UiTheme.ACCENT))
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 0)
	head.add_child(tv)
	tv.add_child(
		_dark("Job %d of %d  ·  House #%d" % [Game.job_index + 1, Jobs.count(), Game.house_no], 15)
	)
	tv.add_child(_dark(job["title"], 30, true))
	var msg := PanelContainer.new()
	msg.add_theme_stylebox_override(
		"panel", UiTheme.box(Color(1, 1, 1), 12, 16, Color(0.82, 0.86, 0.92), 2)
	)
	_content.add_child(msg)
	var mv := VBoxContainer.new()
	msg.add_child(mv)
	mv.add_child(_dark("From: " + job["client"], 15, true))
	mv.add_child(_dark('"' + job["brief"] + '"', 18, false, true))

	if world.is_sell_job():
		_build_sell()
		return

	for p in world.task_progress():
		var row := HBoxContainer.new()
		_content.add_child(row)
		var done: bool = p["done"] >= p["total"]
		row.add_child(
			UiTheme.icon(
				"res://assets/icons/%s.svg" % ("check" if done else "dot"),
				24,
				Color.WHITE if done else Color(0.4, 0.45, 0.55)
			)
		)
		var l := _dark(p["label"], 18)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(180, 22)
		bar.max_value = p["total"]
		bar.value = p["done"]
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", UiTheme.box(Color(0.82, 0.85, 0.9), 6, 0))
		row.add_child(bar)
		row.add_child(_dark("%d/%d" % [p["done"], p["total"]], 16, true))

	var foot := HBoxContainer.new()
	_content.add_child(foot)
	foot.add_child(_dark("Reward: ", 20))
	foot.add_child(
		UiTheme.label(
			UiTheme.money(Jobs.reward(Game.job_index, Game.house_no)),
			22,
			Color(0.2, 0.6, 0.25),
			true
		)
	)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	var btn := UiTheme.button(
		"Complete Job" if world.tasks_done() else "Finish the tasks first", UiTheme.GOOD, 260
	)
	btn.disabled = not world.tasks_done()
	btn.pressed.connect(
		func():
			world.complete_job()
			refresh()
	)
	foot.add_child(btn)
	_add_reward_ad_offer()
	var tip := "Tip: aim at a wall with the Paint tool and hold Shift to paint the whole room."
	_content.add_child(_dark(tip, 14, false, true))


## Offers a rewarded video for some extra cash (CrazyGames only).
func _add_reward_ad_offer() -> void:
	if not CrazySDK.is_available():
		return
	var ready := Time.get_ticks_msec() - _last_reward_ad > 180000
	var row := HBoxContainer.new()
	_content.add_child(row)
	var amount := 300 + 100 * (Game.house_no - 1)
	var l := _dark("Short on cash? Watch a short ad for %s." % UiTheme.money(amount), 17)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var btn := UiTheme.button(
		"Watch ad  +%s" % UiTheme.money(amount) if ready else "Come back later",
		UiTheme.GOLD.darkened(0.2),
		230
	)
	btn.disabled = not ready
	btn.pressed.connect(
		func():
			btn.disabled = true
			CrazySDK.ad_finished.connect(
				func(ok: bool):
					if ok:
						_last_reward_ad = Time.get_ticks_msec()
						Game.add_money(amount, "Ad reward")
						Sfx.play("cash")
					refresh(),
				CONNECT_ONE_SHOT
			)
			CrazySDK.request_rewarded_ad()
	)
	row.add_child(btn)


func _build_sell() -> void:
	var v := world.house_value()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	_content.add_child(grid)
	for row in [
		["Base house value", v["base"]],
		["Furniture", v["furniture"]],
		["New walls & floors", v["finishes"]],
		["Mess & junk left", -v["penalty"]]
	]:
		grid.add_child(_dark(row[0], 19))
		var col: Color = Color(0.2, 0.55, 0.25) if row[1] >= 0 else Color(0.75, 0.25, 0.2)
		grid.add_child(UiTheme.label(UiTheme.money(row[1]), 19, col, true))
	grid.add_child(_dark("Asking price", 24, true))
	grid.add_child(UiTheme.label(UiTheme.money(v["total"]), 26, Color(0.75, 0.52, 0.05), true))
	_content.add_child(
		_dark(
			(
				"You keep the profit above the purchase price of %s."
				% UiTheme.money(15000 + 3000 * (Game.house_no - 1))
			),
			15,
			false,
			true
		)
	)
	var btn := UiTheme.button("Sell House", UiTheme.GOOD, 300)
	btn.custom_minimum_size.y = 56
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.pressed.connect(
		func():
			_sold_value = world.sell_house()
			refresh()
	)
	_content.add_child(btn)


func _build_sold() -> void:
	var t := _dark("SOLD!", 64, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color(0.2, 0.6, 0.25))
	_content.add_child(t)
	var l := _dark(
		"The house sold for %s. Time to flip the next one!" % UiTheme.money(_sold_value),
		22,
		false,
		true
	)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(l)
	var btn := UiTheme.button("Next House  >", UiTheme.GOOD, 320)
	btn.custom_minimum_size.y = 58
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(
		func():
			close(true)
			world.load_next_house()
	)
	_content.add_child(btn)


func _build_jobs() -> void:
	_content.add_child(_dark("House #%d" % Game.house_no, 26, true))
	for i in Jobs.count():
		var job := Jobs.get_job(i)
		var row := PanelContainer.new()
		var current := i == Game.job_index
		row.add_theme_stylebox_override(
			"panel", UiTheme.box(Color(0.85, 0.93, 1.0) if current else Color(1, 1, 1), 10, 14)
		)
		_content.add_child(row)
		var h := HBoxContainer.new()
		row.add_child(h)
		var icon := "check" if i < Game.job_index else "dot"
		h.add_child(
			UiTheme.icon(
				"res://assets/icons/%s.svg" % icon,
				26,
				Color.WHITE if i < Game.job_index else Color(0.45, 0.5, 0.6)
			)
		)
		var l := _dark("%d. %s" % [i + 1, job["title"]], 20, current)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var status := "Done" if i < Game.job_index else ("In progress" if current else "Locked")
		if job["reward"] > 0:
			status += "  ·  " + UiTheme.money(Jobs.reward(i, Game.house_no))
		h.add_child(_dark(status, 16))


func _build_settings() -> void:
	_content.add_child(_dark("Settings", 26, true))
	for s in [
		["sensitivity", "Mouse sensitivity", 0.2, 3.0],
		["music", "Music volume", 0.0, 1.0],
		["sfx", "Sound effects", 0.0, 1.0]
	]:
		var row := HBoxContainer.new()
		_content.add_child(row)
		var l := _dark(s[1], 19)
		l.custom_minimum_size.x = 240
		row.add_child(l)
		var slider := HSlider.new()
		slider.focus_mode = Control.FOCUS_NONE
		slider.min_value = s[2]
		slider.max_value = s[3]
		slider.step = 0.05
		slider.value = Game.settings[s[0]]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value_changed.connect(func(v): Game.set_setting(s[0], v))
		row.add_child(slider)
	var sp := Control.new()
	sp.custom_minimum_size.y = 20
	_content.add_child(sp)
	var reset := UiTheme.button("Reset all progress", Color(0.8, 0.3, 0.3), 260)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(
		func():
			if reset.text != "Click again to confirm":
				reset.text = "Click again to confirm"
				return
			Game.reset_progress()
			get_tree().reload_current_scene()
	)
	_content.add_child(reset)


func _build_help() -> void:
	_content.add_child(_dark("How to Play", 26, true))
	_content.add_child(
		_dark("Take on renovation jobs, earn money, then flip the house for profit!", 18)
	)
	var rows := [
		["WASD / Mouse", "Move and look around"],
		["Left click", "Use the current tool"],
		["1 - 5 / Scroll", "Switch tools: Hand, Sponge, Paint, Floor, Build"],
		["Q", "Open the catalog for paint, floors or furniture"],
		["R / Scroll", "Rotate furniture while placing"],
		["Right click", "Cancel placing furniture"],
		["X", "Return a placed item to the store for a full refund"],
		["Shift + click", "Paint every wall in the room at once"],
		["Tab", "Open the tablet with your job and tasks"],
		["Esc", "Pause"],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 6)
	_content.add_child(grid)
	for r in rows:
		grid.add_child(UiTheme.label(r[0], 18, UiTheme.ACCENT_DARK, true))
		grid.add_child(_dark(r[1], 18))
	(
		_content
		. add_child(
			_dark(
				"Hand: pick up trash and throw away old furniture.  Sponge: hold to scrub dirt and pull weeds.  Paint & Floor: click walls or floors to apply.  Build: place furniture from the catalog.",
				16,
				false,
				true
			)
		)
	)
