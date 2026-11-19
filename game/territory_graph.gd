extends AcceptDialog

const Island = preload("res://game/island.gd")

# Entry zero is the opening. Later entries are completed rounds.
var completed: Array = []
var current: Array = []
var houses: Array = []
var human = 0
var metric = OptionButton.new()
var description = Label.new()
var plot = Control.new()
var legend = GridContainer.new()
var totals: Array[Label] = []

func _ready():
	title = "Territory history"
	ok_button_text = "Back"
	exclusive = true
	wrap_controls = false
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	add_child(content)
	metric.add_item("Village-connected land")
	metric.add_item("All owned land")
	metric.accessibility_name = "Territory measure"
	metric.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(metric)
	metric.item_selected.connect(func(_index): update_chart())
	content.add_child(description)
	plot.custom_minimum_size = Vector2(280, 160)
	plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(plot)
	plot.draw.connect(draw_chart)
	plot.resized.connect(plot.queue_redraw)
	var heading = Label.new()
	heading.text = "Current hexes"
	content.add_child(heading)
	legend.columns = 3
	content.add_child(legend)
	for house in Island.HOUSES:
		var item = Label.new()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		legend.add_child(item)
		totals.append(item)

func reset(game):
	completed = [game.territory_counts()]
	current.clear()

func finish_round(game):
	completed.append(game.territory_counts())

func show_match(game, house_ids: Array, player: int):
	current = game.territory_counts()
	houses = house_ids.duplicate()
	human = player
	min_size = Vector2i(720, 430).min(Vector2i(get_parent().get_viewport_rect().size * 0.9))
	legend.columns = 2 if min_size.x < 480 else 3
	update_chart()
	popup_centered(min_size)

func update_chart():
	var counts = current[metric.selected]
	description.text = "Hexes linked to a village, including woodland." if metric.selected == 0 else "Every colored land hex, including isolated hexes and woodland."
	if legend.columns == 2:
		description.text = "Village land, including woodland." if metric.selected == 0 else "All house land, including isolated hexes."
	for seat in totals.size():
		totals[seat].visible = seat < counts.size()
		if seat < counts.size():
			var house = houses[seat]
			totals[seat].text = "%s%s  %d" % [Island.HOUSES[house], " (you)" if seat == human else "", counts[seat]]
			totals[seat].add_theme_color_override("font_color", Color(Island.COLORS[house]).lightened(0.18))
	plot.queue_redraw()

func draw_chart():
	if current.is_empty():
		return
	var series = completed + [current]
	var measure = metric.selected
	var peak = 0
	for sample in series:
		for value in sample[measure]:
			peak = maxi(peak, value)
	var step = maxi(1, ceili(peak / 4.0))
	var area = Rect2(Vector2(42, 14), plot.size - Vector2(56, 46))
	var font = plot.get_theme_default_font()
	var ink = Color("#d2d9d6")
	for i in 5:
		var y = area.end.y - area.size.y * i / 4.0
		plot.draw_line(Vector2(area.position.x,y), Vector2(area.end.x,y), Color("#5a6667"))
		plot.draw_string(font, Vector2(0,y + 5), str(i * step), HORIZONTAL_ALIGNMENT_RIGHT, 34, 14, ink)
	plot.draw_string(font, Vector2(area.position.x,area.end.y + 23), "Opening", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink)
	plot.draw_string(font, Vector2(area.position.x,area.end.y + 23), "Round %d" % completed.size(), HORIZONTAL_ALIGNMENT_RIGHT, area.size.x, 14, ink)
	if completed.size() >= 4:
		var middle = floori(completed.size() * 0.5)
		var x = area.position.x + area.size.x * middle / completed.size()
		plot.draw_line(Vector2(x,area.position.y), Vector2(x,area.end.y), Color("#5a6667"))
		plot.draw_string(font, Vector2(x - 35,area.end.y + 23), str(middle), HORIZONTAL_ALIGNMENT_CENTER, 70, 14, ink)
	var seats = range(current[measure].size())
	seats.erase(human)
	seats.append(human)
	for seat in seats:
		var points = PackedVector2Array()
		for i in series.size():
			var value = series[i][measure][seat]
			points.append(Vector2(area.position.x + area.size.x * i / (series.size() - 1),
				area.end.y - area.size.y * value / (4 * step)))
		var color = Color(Island.COLORS[houses[seat]])
		plot.draw_polyline(points, color, 3.5 if seat == human else 2.0, true)
		plot.draw_circle(points[-1], 4 if seat == human else 3, color)
