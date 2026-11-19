extends Window

const R = preload("res://game/rules.gd")
const Board = preload("res://game/board.gd")
const PREFERRED_SIZE = Vector2i(650,640)

@onready var ui = get_parent()
var tabs = TabContainer.new()

func _init():
	title = "How to play"
	visible = false
	borderless = true
	unresizable = true
	transient = true
	exclusive = true

func _ready():
	var sheet = ui.panel(self,ui.PAPER)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content = ui.column(ui.margin(sheet,16,12),8)
	var header = ui.row(content,10)
	ui.label(header,title,30,ui.INK,true)
	ui.spacer(header)
	ui.button(header,"Close",hide,ui.NIGHT,ui.LIGHT,ui.MUTED,44)

	content.add_child(tabs)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	for state in ["selected","unselected","hovered"]:
		var style = StyleBoxFlat.new()
		style.draw_center = false
		style.border_width_bottom = 3 if state == "selected" else 1
		style.border_color = ui.INK if state == "selected" else Color("#c8c5b2")
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		tabs.add_theme_stylebox_override("tab_" + state,style)
		tabs.add_theme_color_override("font_" + state + "_color",ui.MUTED if state == "unselected" else ui.INK)
	tabs.get_tab_bar().focus_mode = Control.FOCUS_ALL
	build_rules(page("Rules"))
	build_upkeep(page("Unit upkeep"))
	build_controls(page("Controls"))
	close_requested.connect(hide)
	window_input.connect(func(event):
		if event.is_action_pressed("ui_cancel"):
			set_input_as_handled()
			hide())
	ui.get_viewport().size_changed.connect(fit_open_guide.call_deferred)

func page(tab_title: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.follow_focus = true
	tabs.add_child(scroll)
	var inset = ui.margin(scroll,2,12)
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return ui.column(inset,12)

func paragraph(parent: Container, value: String):
	var body = ui.label(parent,"",16,ui.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.text = value

func section(parent: Container, heading: String, value: String) -> VBoxContainer:
	var block = ui.column(parent,2)
	ui.label(block,heading,23,ui.INK,true)
	paragraph(block,value)
	return block

func build_rules(body: Container):
	section(body,"Take your first turn",
		"Select a village flying the gold flag. Choose Recruit and place a peasant on a marked hex. Look for an undefended hex along your border.")
	var defense = section(body,"Protect your border",
		"Each unit, village, and castle defends its own hex and any of the six neighboring hexes held by its house. An attacker must outrank the strongest defender covering the hex.")
	var example = ui.row(defense,12)
	var diagram = Control.new()
	diagram.custom_minimum_size = Vector2(80,78)
	diagram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	example.add_child(diagram)
	diagram.draw.connect(draw_castle_example.bind(diagram))
	paragraph(example,"This castle guards all seven hexes with the strength of a spearman. A knight or baron can break through. A village defends like a peasant.")
	section(body,"Move and merge",
		"A ready unit can move anywhere in its connected territory. Capturing land or clearing a tree ends its move. Place one peasant on another to make a spearman.")
	section(body,"Pay your troops",
		"Each tree-free hex connected to a village earns one coin per turn. Check Unit upkeep before merging. If the village can’t cover its wages, all its troops starve. Choose End turn when you’re ready.")

func draw_castle_example(diagram: Control):
	var center = diagram.size * 0.5
	var color = Color(R.Island.COLORS[ui.board.house_ids[0]])
	for p in [Vector2i.ZERO] + R.DIRS:
		var at = center + ui.board.axial_center(p) * 15.0
		diagram.draw_colored_polygon(Board.corners(at,15),ui.INK)
		diagram.draw_colored_polygon(Board.corners(at,14),color)
	var icon_size = Vector2(24,24)
	diagram.draw_texture_rect(Board.ICONS[R.CASTLE],Rect2(center - icon_size * 0.5,icon_size),false)

func build_upkeep(body: Container):
	paragraph(body,"Each village pays its own troops at the start of your turn, after it collects income.")
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",9)
	body.add_child(grid)
	for heading in ["Unit","Strength","Coins per turn"]:
		var cell = ui.label(grid,heading,14,ui.MUTED)
		if heading == "Strength":
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif heading == "Coins per turn":
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for rank in range(R.PEASANT,R.BARON + 1):
		var unit = ui.row(grid,6)
		unit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ui.icon(unit,Board.ICONS[rank],32)
		ui.label(unit,R.PIECES[rank],17,ui.INK)
		var strength = ui.label(grid,str(R.guard(rank)),17,ui.INK)
		strength.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var wages = ui.label(grid,str(R.WAGES[rank]),17,ui.INK)
		wages.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.rule(body)
	paragraph(body,"Two peasants cost %d coins per turn together. Merge them into a spearman and the same village pays %d." % [2 * R.WAGES[R.PEASANT],R.WAGES[R.SPEARMAN]])

func build_controls(body: Container):
	section(body,"Move around the island","Drag with one finger to pan and pinch to zoom. With a mouse, right-drag to pan and use the scroll wheel to zoom. Choose Fit to see the whole island.")
	var keyboard = section(body,"Keyboard","Use the arrow keys, E, and Z to move between hexes. Press Enter to select the highlighted hex.")
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",5)
	keyboard.add_child(grid)
	for pair in [["P","Recruit a peasant"],["C","Build a castle"],["U","Undo a move"],["Escape","Cancel an order"],["N","End your turn"]]:
		ui.label(grid,pair[0],16,ui.MUTED)
		ui.label(grid,pair[1],16,ui.INK)

func fit_open_guide():
	if visible:
		var available = Vector2i(ui.get_viewport_rect().size)
		size = PREFERRED_SIZE.min(available - Vector2i(24,32))
		position = (available - size) / 2

func open_guide():
	tabs.current_tab = 0
	for scroll in tabs.get_children():
		if scroll is ScrollContainer:
			scroll.scroll_vertical = 0
	popup()
	fit_open_guide()
	tabs.get_tab_bar().grab_focus()
