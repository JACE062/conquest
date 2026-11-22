extends VBoxContainer

# Desktop and portrait share the same board, purchases, and selectors. Only
# their containers change, so rotating a device keeps a pending order intact.
var desktop: Control
var slots: Array = []
var compact_slots := {}
var play: VBoxContainer
var menu: ScrollContainer
var menu_button: Button
var island_name: Label
var ledger: Label
var brand: HBoxContainer
var header_space: Control
var heading: PanelContainer
var compact_titles: VBoxContainer
var compact_overview: HBoxContainer
var round_slot: HBoxContainer
var compact_turn: Label
var compact_funds: HFlowContainer
var compact_orders: HBoxContainer
var stacked_rows: Array[Control] = []
var active := false
var compact := false

func share(control: Control, parent: Container):
	slots.append([control, parent, control.get_parent(), control.get_index()])

func setup(ui, desktop_layout, colors, difficulty, help, restart, standings):
	desktop = desktop_layout
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override("separation",0)
	hide()
	var header = ui.row(ui.margin(ui.panel(self,ui.NIGHT),12,5),7)
	brand = ui.row(header,7)
	ui.icon(brand,ui.BANNER,28)
	ui.label(brand,"Conquest",28,ui.LIGHT,true)
	compact_titles = ui.column(header,0)
	compact_titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compact_titles.hide()
	compact_turn = ui.label(compact_titles,"",13,ui.GOLD)
	compact_turn.clip_text = true
	compact_overview = ui.row(header,5)
	compact_slots[ui.overview] = compact_overview
	header_space = Control.new()
	header_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_space)
	round_slot = ui.row(header,0)
	share(ui.round_label,round_slot)
	compact_slots[ui.next_village_button] = compact_overview
	menu_button = ui.button(header,"Menu",toggle_menu,Color("#254247"),ui.LIGHT,Color("#506565"),44)
	play = ui.column(self,0)
	play.size_flags_vertical = Control.SIZE_EXPAND_FILL
	heading = ui.panel(play,ui.PAPER)
	var heading_row = ui.row(ui.margin(heading,12,5),6)
	var titles = ui.column(heading_row,1)
	island_name = ui.label(titles,"",23,ui.INK,true)
	share(island_name,titles)
	compact_slots[island_name] = compact_titles
	share(ui.turn_label,titles)
	share(ui.tile_info,titles)
	ui.spacer(heading_row)
	share(ui.overview,heading_row)
	var map = ui.column(ui.panel(play,ui.Board.SEA),0)
	map.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	share(ui.board,map)
	var tools = ui.row(ui.margin(ui.panel(play,Color("#19383c")),10,4),4)
	var messages = ui.column(tools,0)
	messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	share(ui.status,messages)
	compact_slots[ui.tile_info] = messages
	for control in [ui.zoom_out,ui.fit_button,ui.zoom_in]:
		share(control,tools)
	var dock = ui.column(ui.margin(ui.panel(play,ui.PAPER),12,8),5)
	compact_funds = HFlowContainer.new()
	compact_funds.add_theme_constant_override("h_separation",10)
	dock.add_child(compact_funds)
	var wallet = ui.row(compact_funds,8)
	wallet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compact_slots[ui.house_label] = wallet
	compact_slots[ui.cash_label] = wallet
	var funds = ui.row(dock,6)
	share(ui.house_label,ui.row(funds,0))
	ui.spacer(funds)
	share(ui.cash_label,ui.row(funds,0))
	ledger = ui.label(dock,"",15,ui.MUTED)
	share(ledger,dock)
	compact_slots[ledger] = compact_funds
	var purchases = ui.row(dock,6)
	share(ui.recruit_button,purchases)
	share(ui.castle_button,purchases)
	var actions = ui.row(dock,6)
	share(ui.next_village_button,actions)
	stacked_rows.assign([funds,purchases,actions])
	for control in [ui.undo_button,ui.history_button,ui.end_button]:
		share(control,actions)
	compact_orders = ui.row(dock,5)
	compact_orders.hide()
	for control in [ui.recruit_button,ui.castle_button,ui.undo_button,ui.history_button,ui.end_button]:
		compact_slots[control] = compact_orders

	menu = ScrollContainer.new()
	menu.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(menu)
	var sheet = ui.panel(menu,ui.NIGHT,true)
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var options = ui.column(ui.margin(sheet,16,12),10)
	for control in [colors,difficulty]:
		share(control,ui.column(options,0))
	for pair in [["Size",ui.size_selector],["Island",ui.island_selector]]:
		var field = ui.row(options,8)
		ui.label(field,pair[0],15,ui.LIGHT)
		share(pair[1],field)
	var commands = ui.row(options,8)
	share(ui.duel_button,ui.row(options,0))
	share(help,commands)
	share(restart,commands)
	var summary = ui.column(ui.margin(ui.panel(options,ui.PAPER),12,10),4)
	share(standings,summary)
	menu.hide()

func toggle_menu():
	set_menu(not menu.visible)

func set_menu(open: bool):
	menu.visible = open
	play.visible = not open
	menu_button.text = "Back" if open else "Menu"
	update_header()

func update_header():
	var show_island = compact and not menu.visible
	brand.visible = not show_island
	header_space.visible = not show_island
	compact_titles.visible = show_island
	compact_overview.visible = show_island
	round_slot.visible = not show_island

func adapt(ui):
	var window = get_window()
	var aspect = float(window.size.x) / maxi(1,window.size.y)
	var use_mobile = aspect <= 1.35
	var use_compact = use_mobile and aspect >= 0.62
	var changed = use_mobile != active or use_compact != compact
	var entering = use_mobile and not active
	var scale_size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	if use_compact:
		# The full-window Web canvas can have several backing pixels per CSS pixel.
		var width = JavaScriptBridge.get_interface("window").innerWidth if OS.has_feature("web") else window.size.x
		scale_size = Vector2i(clampi(int(width),390,900),1)
	elif use_mobile:
		scale_size = Vector2i(390,540)
	var scale_changed = window.content_scale_size != scale_size
	if not changed and not scale_changed:
		return
	if active != use_mobile:
		set_menu(false)
	active = use_mobile
	compact = use_compact
	if scale_changed:
		window.content_scale_size = scale_size
	var narrow = compact and scale_size.x < 530
	ui.recruit_button.icon = null if narrow else ui.Board.ICONS[ui.R.PEASANT]
	ui.castle_button.icon = null if narrow else ui.Board.ICONS[ui.R.CASTLE]
	if not changed:
		return
	desktop.visible = not active
	visible = active
	update_header()
	heading.visible = not compact
	for control in stacked_rows:
		control.visible = not compact
	compact_funds.visible = compact
	compact_orders.visible = compact
	var positions = slots.duplicate()
	if not active:
		positions.sort_custom(func(a,b): return a[3] < b[3])
	for slot in positions:
		var control: Control = slot[0]
		var parent = compact_slots.get(control,slot[1]) if compact else (slot[1] if active else slot[2])
		if control.get_parent() != parent:
			control.reparent(parent,false)
		# Island name and ledger belong to the tall layout even on desktop.
		if not active or (not compact and slot[1] == slot[2]):
			slot[2].move_child(control,slot[3])
	if compact:
		compact_titles.move_child(island_name,0)
		compact_turn.text = "%s · %d" % [ui.turn_label.text,ui.game.round_number] if ui.game else ""
		ui.status.get_parent().move_child(ui.status,0)
	ui.overview.custom_minimum_size = Vector2(68,44) if compact else (Vector2(86,48) if active else Vector2(108,80))
	island_name.clip_text = compact
	island_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if compact else TextServer.OVERRUN_NO_TRIMMING
	island_name.add_theme_color_override("font_color",ui.LIGHT if compact else ui.INK)
	ui.turn_label.add_theme_color_override("font_color",ui.GOLD if compact else ui.MUTED)
	ui.tile_info.add_theme_color_override("font_color",ui.MUTED if active and not compact else Color("#c0d1c5"))
	ui.tile_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if compact else TextServer.AUTOWRAP_OFF
	ui.house_label.add_theme_font_size_override("font_size",17 if compact else 25)
	ui.cash_label.add_theme_font_size_override("font_size",19 if compact else 27)
	ledger.add_theme_font_size_override("font_size",14 if compact else 15)
	ui.recruit_button.text = "Recruit 10" if compact else ("Recruit  ·  10" if active else "Recruit peasant     ·     10")
	ui.castle_button.text = "Castle 15" if compact else ("Castle  ·  15" if active else "Build castle            ·     15")
	ui.undo_button.text = "Undo" if compact else "Undo move"
	ui.history_button.text = "History" if compact else "Territory history"
	for control in [ui.recruit_button,ui.castle_button,ui.undo_button,ui.history_button,ui.end_button]:
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL if active else Control.SIZE_FILL
	ui.undo_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for control in [ui.zoom_in,ui.zoom_out,ui.fit_button]:
		control.custom_minimum_size = Vector2(44,44) if active else Vector2(0,32)
	for selector in [ui.color_selector,ui.difficulty_selector,ui.size_selector,ui.island_selector]:
		selector.custom_minimum_size.y = 46 if active else 38
	ui.board.portrait = active
	ui.board.update_view()
	if ui.game and entering and ui.board.zoom == 1.0:
		frame_opening(ui)

func frame_opening(ui):
	# Reparenting queues container layout. Use the final board size for zoom.
	await get_tree().process_frame
	await get_tree().process_frame
	if active and ui.game.lands.has(ui.selected) and ui.board.zoom == 1.0:
		var board = ui.board
		board.zoom_at(23.0 / board.fit_radius(),board.size * 0.5)
		board.look_at_world(board.axial_center(ui.selected))
