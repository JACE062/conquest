extends Control

const R = preload("res://game/rules.gd")
const AI = preload("res://game/opponent.gd")
const Island = preload("res://game/island.gd")
const Board = preload("res://game/board.gd")
const SERIF = preload("res://art/CrimsonText-Regular.ttf")
const BANNER = preload("res://art/banner.svg")
const PAPER = Color("#f1ead9")
const INK = Color("#223836")
const MUTED = Color("#526660")
const LIGHT = Color("#ede9d8")
const GOLD = Color("#e5ba68")
const NIGHT = Color("#152e32")
var game
var board = Board.new()
var selected = R.NONE
var source = R.NONE
var mode = ""
var history = []
var round_label: Label
var difficulty_selector = OptionButton.new()
var color_selector = OptionButton.new()
var size_selector = OptionButton.new()
var island_selector = OptionButton.new()
var active_island = Island.TITLE
var requested_island = Island.TITLE
var turn_label: Label
var house_label: Label
var holding_label: Label
var cash_label: Label
var income_label: Label
var wages_label: Label
var recruit_button: Button
var castle_button: Button
var undo_button: Button
var next_village_button: Button
var end_button: Button
var status: Label
var tile_info: Label
var legend_labels = []
var land_bars: Array[ProgressBar] = []
var land_values: Array[Label] = []
var overview = Control.new()
var zoom_out: Button
var zoom_in: Button
var fit_button: Button
var history_button: Button
var help_dialog = preload("res://game/help_dialog.gd").new()
var restart_dialog = ConfirmationDialog.new()
var end_turn_dialog = preload("res://game/end_turn_dialog.gd").new()
var surrender_dialog = ConfirmationDialog.new()
var result_dialog = AcceptDialog.new()
var territory_graph = preload("res://game/territory_graph.gd").new()
var finished = false
var surrender_pending = false
var delay = 0.0
var portrait = preload("res://game/portrait_layout.gd").new()

func _ready():
	build_ui()
	get_window().size_changed.connect(portrait.adapt.bind(self))
	portrait.adapt(self)
	start()

func label(parent, value: String, points: int, color: Color, serif = false) -> Label:
	var node = Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size",points)
	node.add_theme_color_override("font_color",color)
	if serif:
		node.add_theme_font_override("font",SERIF)
	parent.add_child(node)
	return node

func surface(color: Color, border: Color, radius = 5) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func style_button(node: Button, background, foreground, edge, height = 38):
	node.custom_minimum_size.y = height
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","disabled"]:
		var color = background
		if state == "hover":
			color = background.lightened(0.10)
		elif state == "pressed":
			color = background.darkened(0.09)
		node.add_theme_stylebox_override(state,surface(color,edge))
		node.add_theme_color_override("font_%s_color" % state,foreground if state != "disabled" else foreground.lerp(background,0.5))
	node.add_theme_color_override("font_color",foreground)
	node.add_theme_font_size_override("font_size",15)

func button(parent, title, callback, background, foreground, edge, height = 38) -> Button:
	var node = Button.new()
	node.text = title
	style_button(node,background,foreground,edge,height)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func panel(parent, color: Color, expand = false) -> PanelContainer:
	var box = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = color
	box.add_theme_stylebox_override("panel",style)
	if expand:
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box

func margin(parent, horizontal, vertical):
	var node = MarginContainer.new()
	for side in ["left","right"]:
		node.add_theme_constant_override("margin_"+side,horizontal)
	for side in ["top","bottom"]:
		node.add_theme_constant_override("margin_"+side,vertical)
	parent.add_child(node)
	return node

func row(parent, spacing = 10):
	var node = HBoxContainer.new()
	node.add_theme_constant_override("separation",spacing)
	parent.add_child(node)
	return node

func column(parent, spacing = 8):
	var node = VBoxContainer.new()
	node.add_theme_constant_override("separation",spacing)
	parent.add_child(node)
	return node

func spacer(parent, vertical = false):
	var space = Control.new()
	if vertical:
		space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(space)

func rule(parent):
	var line = ColorRect.new()
	line.color = Color("#c8c5b2")
	line.custom_minimum_size.y = 1
	parent.add_child(line)

func icon(parent, texture, side):
	var image = TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = Vector2(side,side)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(image)

func build_ui():
	var root = column(self,0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var header = row(margin(panel(root,NIGHT),28,12),15)
	icon(header,BANNER,40)
	label(header,"Conquest",35,LIGHT,true)
	spacer(header)
	round_label = label(header,"",17,GOLD)
	var colors = row(header,7)
	label(colors,"Your color",15,LIGHT)
	color_selector.accessibility_name = "Your house color"
	color_selector.tooltip_text = "Choose your house color for this match and future islands."
	for i in Island.HOUSES.size():
		var swatch = Image.create(14,14,false,Image.FORMAT_RGBA8)
		swatch.fill(Color(Island.COLORS[i]))
		color_selector.add_icon_item(ImageTexture.create_from_image(swatch),Island.HOUSES[i],i)
	style_button(color_selector,Color("#254247"),LIGHT,Color("#506565"))
	colors.add_child(color_selector)
	color_selector.select(0)
	color_selector.item_selected.connect(choose_color)
	var difficulty = row(header,7)
	label(difficulty,"Difficulty",15,LIGHT)
	difficulty_selector.accessibility_name = "Opponent difficulty"
	difficulty_selector.tooltip_text = "Choose the strategy all five opponents use on their next turns."
	difficulty_selector.add_item("Easy",AI.Difficulty.EASY)
	difficulty_selector.add_item("Standard",AI.Difficulty.STANDARD)
	difficulty_selector.add_item("Hard",AI.Difficulty.HARD)
	difficulty_selector.select(difficulty_selector.get_item_index(AI.Difficulty.STANDARD))
	style_button(difficulty_selector,Color("#254247"),LIGHT,Color("#506565"))
	difficulty_selector.custom_minimum_size.x = 115
	difficulty.add_child(difficulty_selector)
	var help = button(header,"How to play",show_help,Color("#254247"),LIGHT,Color("#506565"))
	var restart = button(header,"Restart",ask_restart,Color("#254247"),LIGHT,Color("#506565"))
	var body = row(root,0)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var map = column(panel(body,Board.SEA,true),0)
	var map_header = row(margin(map,28,14))
	label(map_header,"Size",15,LIGHT)
	size_selector.accessibility_name = "Island size"
	size_selector.tooltip_text = "Filter the island list by size."
	for size_name in Island.SIZE_NAMES:
		size_selector.add_item(size_name)
	style_button(size_selector,Color("#254247"),LIGHT,Color("#506565"))
	map_header.add_child(size_selector)
	size_selector.item_selected.connect(show_islands)
	label(map_header,"Island",15,LIGHT)
	island_selector.accessibility_name = "Island"
	island_selector.tooltip_text = "Choose an island to start a new match."
	island_selector.fit_to_longest_item = false
	style_button(island_selector,Color("#254247"),LIGHT,Color("#506565"))
	island_selector.add_theme_font_override("font",SERIF)
	island_selector.add_theme_font_size_override("font_size",28)
	map_header.add_child(island_selector)
	island_selector.item_selected.connect(choose_island)
	spacer(map_header)
	tile_info = label(map_header,"",14,Color("#c0d1c5"))
	map.add_child(board)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.picked.connect(pick)
	board.inspected.connect(inspect)
	var hint_bar = panel(map,Color("#19383c"))
	var footer = row(margin(hint_bar,20,6),6)
	status = label(footer,"",15,LIGHT)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zoom_out = view_button(footer,"−","Zoom out",zoom_from_center.bind(1.0 / Board.ZOOM_STEP))
	fit_button = view_button(footer,"Fit","Fit whole island",board.fit_island)
	zoom_in = view_button(footer,"+","Zoom in",zoom_from_center.bind(Board.ZOOM_STEP))
	board.view_changed.connect(update_view_controls)
	var sidebar = panel(body,PAPER)
	sidebar.custom_minimum_size.x = 305
	var side = column(margin(sidebar,20,16),6)
	var overview_row = row(side,8)
	var house = column(overview_row,1)
	house.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	turn_label = label(house,"YOUR TURN",13,MUTED)
	house_label = label(house,"",25,INK,true)
	spacer(overview_row)
	overview.custom_minimum_size = Vector2(108,80)
	overview.tooltip_text = "The frame shows your view. Click or drag to look around the island."
	overview.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	overview_row.add_child(overview)
	overview.draw.connect(draw_overview)
	overview.gui_input.connect(navigate_overview)
	overview.resized.connect(overview.queue_redraw)
	rule(side)
	var standings = column(side,6)
	build_standings(standings)
	rule(side)
	holding_label = label(side,"",18,INK)
	var treasury = row(side)
	label(treasury,"Treasury",15,MUTED)
	spacer(treasury)
	cash_label = label(treasury,"",27,INK,true)
	var income = row(side)
	label(income,"Land income",15,MUTED)
	spacer(income)
	income_label = label(income,"",17,INK)
	var wages = row(side)
	label(wages,"Unit wages",15,MUTED)
	spacer(wages)
	wages_label = label(wages,"",17,INK)
	rule(side)
	label(side,"Orders",25,INK,true)
	recruit_button = button(side,"Recruit peasant     ·     10",choose_purchase.bind("recruit"),Color("#faf4e7"),INK,Color("#babaa5"),49)
	recruit_button.icon = Board.ICONS[R.PEASANT]
	castle_button = button(side,"Build castle            ·     15",choose_purchase.bind("build"),Color("#faf4e7"),INK,Color("#babaa5"),49)
	castle_button.icon = Board.ICONS[R.CASTLE]
	for node in [recruit_button,castle_button]:
		node.add_theme_constant_override("icon_max_width",32)
	spacer(side,true)
	var navigation = row(side,6)
	next_village_button = button(navigation,"Next village",next_village,Color("#e8e2d2"),INK,Color("#babaa5"),44)
	next_village_button.tooltip_text = "Find a village with a ready unit or enough coins to recruit."
	undo_button = button(navigation,"Undo move",undo,Color("#e8e2d2"),INK,Color("#babaa5"),40)
	for control in [next_village_button,undo_button]:
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_button = button(side,"Territory history",show_territory,Color("#e8e2d2"),INK,Color("#babaa5"),40)
	end_button = button(side,"End turn",request_end_turn,GOLD,INK,Color("#ad8d4d"),50)
	add_child(portrait)
	portrait.setup(self,root,colors,difficulty,help,restart,standings)
	configure_dialogs()

func build_standings(side):
	var title = label(side,"Village land",20,INK,true)
	title.tooltip_text = "Hexes connected to each house’s villages, including woodland."
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",9)
	grid.add_theme_constant_override("v_separation",1)
	side.add_child(grid)
	var track = StyleBoxFlat.new()
	track.bg_color = Color("#ddd9c8")
	for i in Island.HOUSES.size():
		legend_labels.append(label(grid,Island.HOUSES[i],14,INK))
		var bar = ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(48,9)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.accessibility_name = Island.HOUSES[i] + " village land"
		var fill = StyleBoxFlat.new()
		fill.bg_color = Color(Island.COLORS[i])
		bar.add_theme_stylebox_override("background",track)
		bar.add_theme_stylebox_override("fill",fill)
		grid.add_child(bar)
		land_bars.append(bar)
		var count = label(grid,"0",14,INK)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		land_values.append(count)

func view_button(parent, title, description, callback) -> Button:
	var node = button(parent,title,callback,Color("#254247"),LIGHT,Color("#506565"),32)
	node.tooltip_text = description
	node.accessibility_name = description
	return node

func zoom_from_center(factor: float):
	board.zoom_at(factor,board.size * 0.5)

func update_view_controls():
	zoom_out.disabled = is_equal_approx(board.zoom,1.0)
	fit_button.disabled = zoom_out.disabled
	zoom_in.disabled = is_equal_approx(board.zoom,board.zoom_limit())
	overview.queue_redraw()

func overview_transform() -> Transform2D:
	var r = minf((overview.size.x - 10) / (board.extent.size.x + sqrt(3.0)),
		(overview.size.y - 10) / (board.extent.size.y + 2))
	return Transform2D(0,Vector2.ONE * r,0,overview.size * 0.5 - board.extent.get_center() * r)

func overview_frame() -> Rect2:
	var inner = Rect2(Vector2.ZERO,overview.size).grow(-2)
	return inner.intersection(overview_transform() * board.visible_world())

func navigate_overview(event):
	if not game:
		return
	var press = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var drag = event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT
	if press or drag:
		board.look_at_world(overview_transform().affine_inverse() * event.position)
		overview.accept_event()

func draw_overview():
	overview.draw_rect(Rect2(Vector2.ZERO,overview.size),Board.SEA)
	if not game:
		return
	var transform = overview_transform()
	for p in game.cells:
		var at = transform * board.axial_center(p)
		var house = board.house_ids[game.cells[p].owner]
		overview.draw_colored_polygon(Board.corners(at,transform.x.length()),Color(Island.COLORS[house]))
	if game.lands.has(selected):
		var at = transform * board.axial_center(selected)
		overview.draw_arc(at,4,0,TAU,16,INK,3,true)
		overview.draw_arc(at,4,0,TAU,16,LIGHT,1.5,true)
	var frame = overview_frame()
	overview.draw_rect(frame,NIGHT,false,3)
	overview.draw_rect(frame,LIGHT,false,1)

func configure_dialogs():
	add_child(territory_graph)
	territory_graph.confirmed.connect(return_from_graph)
	territory_graph.canceled.connect(return_from_graph)
	var shade = ColorRect.new()
	shade.color = Color(0.05,0.12,0.13,0.46)
	shade.hide()
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(help_dialog)
	add_child(end_turn_dialog)
	for guide in [help_dialog,end_turn_dialog]:
		guide.visibility_changed.connect(func(): shade.visible = help_dialog.visible or end_turn_dialog.visible)
	for dialog in [restart_dialog,surrender_dialog,result_dialog]:
		add_child(dialog)
		dialog.exclusive = true
		dialog.dialog_autowrap = true
	restart_dialog.confirmed.connect(confirm_new_match)
	end_turn_dialog.confirmed.connect(end_human_turn)
	end_turn_dialog.village_requested.connect(show_reminder_village)
	restart_dialog.canceled.connect(show_active_island)
	surrender_dialog.title = "The other houses offer to surrender"
	surrender_dialog.ok_button_text = "Accept surrender"
	surrender_dialog.cancel_button_text = "Keep playing"
	surrender_dialog.confirmed.connect(resolve_surrender.bind(true))
	surrender_dialog.canceled.connect(resolve_surrender.bind(false))
	result_dialog.ok_button_text = "Play again"
	result_dialog.add_button("Territory history",true,"territory")
	result_dialog.custom_action.connect(func(_action): show_territory())
	result_dialog.confirmed.connect(start)

func start():
	portrait.set_menu(false)
	var layout = Island.MAPS[active_island]
	board.house_ids = Island.house_colors_for_match(color_selector.get_selected_id(), board.house_ids)
	game = R.new_game(layout[0], layout[1])
	territory_graph.reset(game)
	show_active_island()
	surrender_dialog.dialog_text = "Accept their surrender and take control of %s?" % active_island
	finished = false
	surrender_pending = false
	delay = 0.0
	history.clear()
	board.load_game(game)
	board.hovered = R.NONE
	tile_info.text = ""
	select_largest()
	board.cursor = selected
	board.grab_focus()
	status.text = "Tap Recruit to place a peasant." if portrait.active else "Select Recruit peasant, then choose a marked hex."
	refresh()
	if portrait.active:
		portrait.frame_opening(self)

func select_largest():
	selected = R.NONE
	var largest = 0
	for cap in game.lands:
		if game.cells[cap].owner == game.active and game.lands[cap].size() > largest:
			selected = cap
			largest = game.lands[cap].size()
	clear_order()

func clear_order():
	mode = ""
	source = R.NONE

func refresh():
	var player = game.active == 0 and not finished and not surrender_pending
	round_label.text = "Round %02d" % game.round_number
	turn_label.text = "MATCH COMPLETE" if finished else ("YOUR TURN" if player else "COMPUTER TURN")
	if surrender_pending:
		turn_label.text = "SURRENDER OFFER"
	elif not finished and game.active != 0 and not game.can_take_turn(0):
		turn_label.text = "SPECTATING"
	house_label.text = "House " + house_name(game.active)
	portrait.compact_turn.text = "%s · %d" % [turn_label.text,game.round_number]
	var cap = selected if game.lands.has(selected) else R.NONE
	var ledger = game.finances(cap)
	var cash = game.cells[cap].cash if cap != R.NONE else 0
	holding_label.text = "Territory  ·  %d hexes" % game.lands.get(cap,[]).size()
	cash_label.text = "1 coin" if cash == 1 else "%d coins" % cash
	income_label.text = "+%d" % ledger.x
	wages_label.text = "−%d" % ledger.y if ledger.y > 0 else "0"
	portrait.island_name.text = active_island
	portrait.ledger.text = "%d hexes   Income +%d   Wages %s" % [game.lands.get(cap,[]).size(),ledger.x,wages_label.text]
	var space = false
	for p in game.lands.get(cap,[]):
		if game.cells[p].piece == R.EMPTY:
			space = true
			break
	recruit_button.disabled = not player or cash < R.RECRUIT_COST or game.targets("recruit", cap).is_empty()
	castle_button.disabled = not player or cash < 15 or not space
	undo_button.disabled = not player or history.is_empty()
	next_village_button.disabled = not player or village_work().villages.is_empty()
	next_village_button.visible = not finished
	undo_button.visible = not finished
	history_button.visible = finished
	end_button.disabled = not player
	difficulty_selector.disabled = not player
	color_selector.disabled = finished or surrender_pending
	island_selector.disabled = surrender_pending
	size_selector.disabled = surrender_pending
	var connected = game.connected_land_counts()
	connected.resize(legend_labels.size())
	var largest = 1
	for count in connected:
		largest = maxi(largest,count)
	for seat in legend_labels.size():
		var house = board.house_ids[seat]
		legend_labels[house].text = Island.HOUSES[house] + (" (you)" if seat == 0 else "")
		legend_labels[house].modulate.a = 1.0 if game.can_take_turn(seat) else 0.45
		land_bars[house].max_value = largest
		land_bars[house].value = connected[seat]
		land_values[house].text = str(connected[seat])
	overview.queue_redraw()
	board.mark(cap,source,game.targets(mode,source) if mode != "" else [])
	inspect(board.inspected_hex())

func inspect(p):
	if not game or not game.cells.has(p):
		tile_info.text = ""
	else:
		var cell = game.cells[p]
		var land = "Isolated hex" if game.capitals[p] == R.NONE and cell.piece == R.EMPTY else R.PIECES[cell.piece]
		if cell.piece == R.CAPITAL and cell.owner == 0:
			land = "Your capital"
		tile_info.text = "%s  ·  %s  ·  Defense %d" % [house_name(cell.owner),land,game.defense(p)]

func pick(p):
	if game.active != 0 or finished or surrender_pending:
		return
	if p == R.NONE or (mode == "move" and p == source):
		clear_order()
		status.text = "Select a ready unit or purchase a piece for this territory."
	elif mode != "" and game.legal(mode,source,p):
		history.append([game.cells.duplicate(true),selected])
		var previous = mode
		game.apply(mode,source,p)
		selected = game.capitals[p]
		clear_order()
		status.text = "Castle built." if previous == "build" else "Order complete. Select a ready unit or end your turn."
		check_result()
	elif game.cells[p].owner == 0 and game.capitals[p] != R.NONE:
		selected = game.capitals[p]
		clear_order()
		if R.is_unit(game.cells[p].piece) and not game.cells[p].spent:
			mode = "move"
			source = p
			status.text = "Choose a marked destination for your " + R.PIECES[game.cells[p].piece].to_lower() + "."
		else:
			status.text = "Select a ready unit or purchase a piece for this territory."
	elif mode != "":
		status.text = "That hex is unavailable. Choose a marked hex or press Escape."
	elif game.capitals[p] == R.NONE:
		status.text = "This isolated hex belongs to House %s. It has no village or treasury." % house_name(game.cells[p].owner)
	refresh()

func choose_purchase(kind, from_keyboard = false):
	var control = recruit_button if kind == "recruit" else castle_button
	if control.disabled:
		return
	mode = kind
	source = selected
	board.cursor = selected
	if from_keyboard:
		board.keyboard_cursor = true
		board.reveal_cursor()
	board.grab_focus()
	status.text = "Recruit on a marked hex." if kind == "recruit" else "Build on a marked hex."
	refresh()

func undo():
	if history.is_empty() or game.active != 0 or finished or surrender_pending:
		return
	var entry = history.pop_back()
	game.restore(entry[0])
	selected = entry[1]
	clear_order()
	status.text = "Move undone."
	board.grab_focus()
	refresh()

func village_work() -> Dictionary:
	var funded = 0
	var ready = 0
	var villages: Array[Vector2i] = []
	for cap in game.lands:
		if game.cells[cap].owner != 0:
			continue
		var affordable = game.cells[cap].cash >= R.RECRUIT_COST
		if affordable:
			funded += 1
		var ready_before = ready
		for hex in game.lands[cap]:
			var cell = game.cells[hex]
			if R.is_unit(cell.piece) and not cell.spent:
				ready += 1
		if affordable or ready > ready_before:
			villages.append(cap)
	return {"villages":villages,"funded":funded,"ready":ready}

func next_eligible(villages: Array) -> Vector2i:
	return villages[(villages.find(selected) + 1) % villages.size()]

func next_village():
	if game.active != 0 or finished or surrender_pending:
		return
	var villages = village_work().villages
	if not villages.is_empty():
		show_reminder_village(next_eligible(villages))

func request_end_turn():
	if game.active != 0 or finished or surrender_pending or end_turn_dialog.visible:
		return
	var work = village_work()
	var funded = work.funded
	var ready = work.ready
	var reasons = PackedStringArray()
	if funded:
		reasons.append("1 village can afford a peasant." if funded == 1 else "%d villages can afford a peasant." % funded)
	if ready:
		reasons.append("1 unit is still ready." if ready == 1 else "%d units are still ready." % ready)
	if reasons.is_empty():
		end_human_turn()
		return
	end_turn_dialog.offer("\n".join(reasons),next_eligible(work.villages))

func show_reminder_village(cap: Vector2i):
	clear_order()
	selected = cap
	board.cursor = cap
	board.keyboard_cursor = true
	board.zoom_at(maxf(1.0,25.0 / board.radius),board.size * 0.5)
	board.look_at_world(board.axial_center(cap))
	board.grab_focus()
	board.update_inspection()
	status.text = "Village selected. Choose a unit or place an order."
	refresh()

func end_human_turn():
	if game.active != 0 or finished or surrender_pending:
		return
	history.clear()
	if game.offer_surrender_on_end_turn():
		surrender_pending = true
		clear_order()
		refresh()
		show_dialog(surrender_dialog,Vector2i(440,160))
		return
	next_player()

func resolve_surrender(accepted: bool):
	if not surrender_pending:
		return
	surrender_pending = false
	if accepted:
		game.accept_surrender()
		select_largest()
		check_result()
		refresh()
	else:
		game.decline_surrender()
		next_player()

func next_player():
	var previous_round = game.round_number
	game.end_turn()
	if game.round_number != previous_round:
		territory_graph.finish_round(game)
	select_largest()
	if game.active == 0:
		if selected != R.NONE:
			board.cursor = selected
		board.grab_focus()
		if board.keyboard_cursor:
			board.reveal_cursor()
		status.text = "Your turn. Select a ready unit or recruit from a territory." if selected != R.NONE else "Your last soldier has fallen. End your turn to watch the remaining houses."
	else:
		set_computer_status()
	delay = 0.14
	check_result()
	refresh()

func check_result():
	if not finished and game.owns_island(game.active):
		finished = true
		result_dialog.title = "Island conquered" if game.active == 0 else "Defeat"
		result_dialog.dialog_text = "House %s controls %s." % [house_name(game.active),active_island]
		status.text = result_dialog.dialog_text
		show_dialog(result_dialog,Vector2i(410,160))

func _process(delta):
	if portrait.active and portrait.menu.visible:
		return
	if not game or game.active == 0 or finished or surrender_pending or help_dialog.visible or territory_graph.visible or restart_dialog.visible or island_selector.get_popup().visible or size_selector.get_popup().visible or color_selector.get_popup().visible:
		return
	delay -= delta
	if delay > 0:
		return
	var order = AI.choose(game, difficulty_selector.get_selected_id())
	if order.is_empty():
		next_player()
	else:
		game.apply(order[0],order[1],order[2])
		selected = game.capitals[order[2]]
		check_result()
		refresh()
		delay = 0.085

func house_name(seat: int) -> String:
	return Island.HOUSES[board.house_ids[seat]]

func set_computer_status():
	status.text = "House %s is moving." % house_name(game.active) if game.can_take_turn(0) else "House %s has been eliminated. Watching House %s." % [house_name(0),house_name(game.active)]

func choose_color(house: int):
	var other_seat = board.house_ids.find(house)
	board.house_ids[other_seat] = board.house_ids[0]
	board.house_ids[0] = house
	if game.active == 0:
		status.text = "You are playing as House %s." % house_name(0)
	else:
		set_computer_status()
	refresh()

func show_territory():
	if not finished:
		return
	result_dialog.hide()
	territory_graph.show_match(game, board.house_ids, 0)

func return_from_graph():
	if finished:
		show_dialog.call_deferred(result_dialog,Vector2i(410,160))

func show_dialog(dialog, preferred: Vector2i):
	var available = Vector2i(get_viewport_rect().size) - Vector2i(24,64)
	dialog.popup_centered(preferred.min(available))

func show_help():
	help_dialog.open_guide()

func ask_restart():
	requested_island = active_island
	restart_dialog.title = "Restart %s?" % active_island
	restart_dialog.dialog_text = "Start the island again from its opening position?"
	restart_dialog.ok_button_text = "Restart"
	show_dialog(restart_dialog,Vector2i(420,160))

func show_active_island():
	var island_size = Island.MAPS[active_island][2]
	size_selector.select(island_size)
	show_islands(island_size)

func show_islands(island_size: int):
	var islands = Island.islands_of_size(island_size)
	island_selector.clear()
	for island in islands:
		island_selector.add_item(island)
	island_selector.select(islands.find(active_island))
	if island_selector.selected == -1:
		island_selector.text = "Choose Island"

func choose_island(index: int):
	requested_island = island_selector.get_item_text(index)
	if requested_island == active_island:
		return
	restart_dialog.title = "Play %s?" % requested_island
	restart_dialog.dialog_text = "Leave %s and start a new match on %s?" % [active_island,requested_island]
	restart_dialog.ok_button_text = "Start match"
	show_dialog(restart_dialog,Vector2i(420,160))

func confirm_new_match():
	active_island = requested_island
	start()

func _unhandled_key_input(event):
	if surrender_pending or territory_graph.visible or not event.pressed or event.echo:
		return
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return
	if portrait.active and portrait.menu.visible:
		if event.keycode == KEY_ESCAPE:
			portrait.set_menu(false)
			get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_P: choose_purchase("recruit", true)
		KEY_C: choose_purchase("build", true)
		KEY_U: undo()
		KEY_N: request_end_turn()
		KEY_F1: show_help()
		KEY_ESCAPE:
			if game.active == 0 and not finished:
				clear_order()
				status.text = "Order canceled."
				refresh()
		_: return
	get_viewport().set_input_as_handled()
