extends Control

signal picked(hex: Vector2i)
signal inspected(hex: Vector2i)
signal view_changed
const MAX_ZOOM = 4.0
const ZOOM_STEP = 1.25
const R = preload("res://game/rules.gd")
const I = preload("res://game/island.gd")
const PLAYER_CAPITAL = preload("res://art/player_capital.svg")
const ICONS = [null, preload("res://art/peasant.svg"), preload("res://art/spearman.svg"), preload("res://art/knight.svg"), preload("res://art/baron.svg"), preload("res://art/capital.svg"), preload("res://art/castle.svg"), preload("res://art/pine.svg"), preload("res://art/palm.svg"), preload("res://art/grave.svg")]
const SEA = Color("#1d4248")
const INK = Color("#243d37")
var game
var house_ids = range(I.HOUSES.size())
var selected_cap = R.NONE
var source = R.NONE
var cursor = R.NONE
var hovered = R.NONE
var legal_tiles = {}
var extent = Rect2()
var radius = 20.0
var origin = Vector2.ZERO
var zoom = 1.0
var view_center = Vector2.ZERO # In axial_center units, independent of window size.
var keyboard_cursor = false
var portrait = false
var touches = {}
var touch_start = Vector2.ZERO
var touch_moved = false

func _ready():
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	clip_contents = true
	resized.connect(update_view)
	visibility_changed.connect(func(): if not is_visible_in_tree(): touches.clear())
	mouse_exited.connect(func(): hover(R.NONE))
	focus_entered.connect(update_inspection)
	focus_exited.connect(update_inspection)

func load_game(value):
	touches.clear()
	game = value
	var first = true
	for p in game.cells:
		var pos = axial_center(p)
		extent = Rect2(pos,Vector2.ZERO) if first else extent.expand(pos)
		first = false
	fit_island()

func fit_island():
	zoom = 1.0
	view_center = extent.get_center()
	update_view()

func fit_radius() -> float:
	if portrait:
		return maxf(0.1,minf((size.x - 16) / (extent.size.x + sqrt(3.0)),(size.y - 16) / (extent.size.y + 2)))
	return maxf(0.1, minf((size.x - 70) / (extent.size.x + sqrt(3.0)), (size.y - 96) / (extent.size.y + 2)))

func zoom_limit() -> float:
	return maxf(MAX_ZOOM,30.0 / fit_radius()) if portrait else MAX_ZOOM

func update_view():
	if not game or size.x <= 0 or size.y <= 0:
		return
	var fit = fit_radius()
	zoom = minf(zoom,zoom_limit())
	radius = fit * zoom
	# Keep the viewport inside the original fit view and its center within the coasts.
	var travel = ((size / fit - size / radius) * 0.5).min(extent.size * 0.5)
	if portrait:
		# At a coastal village keep the rest of the island in view.
		travel = ((extent.size + Vector2(sqrt(3.0),2) - (size - Vector2(16,16)) / radius) * 0.5).max(Vector2.ZERO)
	view_center = view_center.clamp(extent.get_center() - travel, extent.get_center() + travel)
	origin = size * 0.5 - view_center * radius
	if not keyboard_cursor:
		hover(hit(get_local_mouse_position()))
	queue_redraw()
	view_changed.emit()

func visible_world() -> Rect2:
	return Rect2(-origin / radius,size / radius)

func zoom_at(factor: float, anchor: Vector2):
	var next_zoom = clampf(zoom * factor,1.0,zoom_limit())
	if is_equal_approx(zoom,next_zoom):
		return
	# Preserve the world point beneath the pointer unless the coast limits travel.
	view_center += (anchor - size * 0.5) / radius * (1.0 - zoom / next_zoom)
	zoom = next_zoom
	update_view()

func look_at_world(point: Vector2):
	view_center = point
	update_view()

func reveal_cursor():
	if cursor == R.NONE or not game.cells.has(cursor):
		return
	var at = center(cursor)
	var margin_px = Vector2.ONE * radius
	var inside = at.clamp(margin_px, size - margin_px)
	if not at.is_equal_approx(inside):
		look_at_world(view_center + (at - inside) / radius)

func mark(cap, piece, options: Array):
	selected_cap = cap
	source = piece
	legal_tiles.clear()
	for p in options:
		legal_tiles[p] = true
	queue_redraw()

func axial_center(p: Vector2i) -> Vector2:
	return Vector2(sqrt(3.0) * (p.x + p.y * 0.5), 1.5 * p.y)

func center(p) -> Vector2:
	return origin + axial_center(p) * radius

static func corners(pos: Vector2, hex_radius: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in 6:
		points.append(pos + Vector2.from_angle(deg_to_rad(i * 60.0 - 30.0)) * hex_radius)
	return points

func outline(pos, scale_by, color, width):
	var points = corners(pos,scale_by)
	points.append(points[0])
	draw_polyline(points,color,width,true)

func _draw():
	draw_rect(Rect2(Vector2.ZERO,size), SEA)
	for y in range(18, int(size.y), 38):
		for x in range(12 + (y % 3) * 13, int(size.x), 57):
			var at = Vector2(x,y)
			draw_polyline(PackedVector2Array([at,at+Vector2(3,1.5),at+Vector2(6,0),at+Vector2(9,1.5),at+Vector2(13,0)]),Color("#3b6061"),1,true)
	if not game:
		return
	var visible_cells = []
	var bounds = Rect2(Vector2.ZERO,size).grow(radius * 1.5 + 2)
	for p in game.cells:
		if bounds.has_point(center(p)):
			visible_cells.append(p)
	for layer in [0.42,0.24,0.10]:
		var shade = Color("#2b5055") if layer > 0.3 else (Color("#3d6262") if layer > 0.2 else Color("#adac8b"))
		for p in visible_cells:
			draw_colored_polygon(corners(center(p) + Vector2(0,2), radius * (1 + layer)),shade)
	for p in visible_cells:
		var at = center(p)
		var cell = game.cells[p]
		var hue = Color(I.COLORS[house_ids[cell.owner]])
		var variation = posmod(p.x * 13 + p.y * 7, 7) * 0.009
		draw_colored_polygon(corners(at,radius), hue.lightened(variation))
		outline(at,radius,Color(0.12,0.22,0.19,0.30),1)
		if cell.piece == R.EMPTY:
			var grass = at + Vector2(-0.37,0.25) * radius
			draw_line(grass,grass+Vector2(-2,-2),hue.darkened(0.14),1,true)
			draw_line(grass+Vector2(2,0),grass+Vector2(3,-3),hue.darkened(0.14),1,true)
	# Strong ink borders separate houses. Ivory borders trace the selected holding.
	for p in visible_cells:
		var poly = corners(center(p),radius)
		for i in 6:
			var n = p + R.DIRS[posmod(-i,6)]
			if not game.cells.has(n) or game.cells[p].owner != game.cells[n].owner:
				draw_line(poly[i],poly[(i+1)%6],INK,2.3,true)
	for p in game.lands.get(selected_cap,[]):
		var poly = corners(center(p),radius * 0.95)
		for i in 6:
			if game.capitals.get(p + R.DIRS[posmod(-i,6)],R.NONE) != selected_cap:
				draw_line(poly[i],poly[(i+1)%6],Color("#fff2bb"),2.8,true)
	for p in visible_cells:
		var cell = game.cells[p]
		var at = center(p)
		if cell.piece != R.EMPTY:
			var side = radius * 1.56
			var sprite = PLAYER_CAPITAL if cell.piece == R.CAPITAL and cell.owner == 0 else ICONS[cell.piece]
			draw_texture_rect(sprite,Rect2(at - Vector2(side,side)*0.5,Vector2(side,side)),false)
			if R.is_unit(cell.piece) and not cell.spent and cell.owner == game.active:
				draw_circle(at + Vector2(0.44,0.48)*radius,3.1,Color("#fff9d6"))
		if legal_tiles.has(p):
			var dot = at if cell.piece == R.EMPTY else at + Vector2(0.47,-0.43)*radius
			draw_circle(dot,4,Color("#355449"))
			draw_circle(dot,2.3,Color("#ffedb8"))
	if source != R.NONE:
		outline(center(source),radius * 0.82,Color("#fff5d6"),2.3)
	var pointer = inspected_hex()
	if pointer != R.NONE:
		outline(center(pointer),radius * 0.88,Color.WHITE,1.8)

func hit(local: Vector2) -> Vector2i:
	if not game or radius <= 0 or not Rect2(Vector2.ZERO,size).has_point(local):
		return R.NONE
	# Round fractional axial coordinates in cube space.
	var v = (local - origin) / radius
	var r = 2.0 * v.y / 3
	var q = v.x / sqrt(3.0) - r / 2
	var s = -q-r
	var x = roundi(q)
	var y = roundi(r)
	var z = roundi(s)
	if absf(x-q) > absf(y-r) and absf(x-q) > absf(z-s):
		x = -y-z
	elif absf(y-r) > absf(z-s):
		y = -x-z
	var p = Vector2i(x,y)
	return p if game.cells.has(p) else R.NONE

func inspected_hex() -> Vector2i:
	return cursor if keyboard_cursor and has_focus() else hovered

func update_inspection():
	inspected.emit(inspected_hex())
	queue_redraw()

func hover(p, from_mouse = false):
	var previous = inspected_hex()
	if from_mouse:
		keyboard_cursor = false
	hovered = p
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if p != R.NONE else Control.CURSOR_ARROW
	if previous != inspected_hex():
		update_inspection()

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if touches.is_empty():
				touch_start = event.position
				touch_moved = false
			else:
				touch_moved = true
			touches[event.index] = event.position
		elif touches.erase(event.index) and touches.is_empty() and not touch_moved and not event.canceled:
			if touch_start.distance_to(event.position) <= 8 and Rect2(Vector2.ZERO,size).has_point(event.position):
				pick_at(event.position)
		accept_event()
	elif event is InputEventScreenDrag and touches.has(event.index):
		var old: Vector2 = touches[event.index]
		touches[event.index] = event.position
		if touches.size() == 1:
			if touch_moved or touch_start.distance_to(event.position) > 8:
				look_at_world(view_center - (event.position - old) / radius)
				touch_moved = true
		elif touches.size() == 2:
			var ids = touches.keys()
			var other: Vector2 = touches[ids[1] if ids[0] == event.index else ids[0]]
			var distance = old.distance_to(other)
			if distance > 0:
				zoom_at(event.position.distance_to(other) / distance, (old + other) / 2)
				look_at_world(view_center - (event.position - old) / (2 * radius))
		accept_event()
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		# The native touch release above is the only event that places an order.
		accept_event()
	elif event is InputEventMouseMotion:
		if event.button_mask & (MOUSE_BUTTON_MASK_MIDDLE | MOUSE_BUTTON_MASK_RIGHT):
			look_at_world(view_center - event.relative / radius)
			hover(hit(event.position),true)
			mouse_default_cursor_shape = Control.CURSOR_DRAG
			accept_event()
			return
		hover(hit(event.position), true)
	elif event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:
		if event.pressed:
			grab_focus()
			mouse_default_cursor_shape = Control.CURSOR_DRAG
		else:
			hover(hit(event.position),true)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		# Some web wheel events carry a pixel delta instead of a notch count.
		var steps = minf(event.factor,1.0) if event.factor > 0 else 1.0
		zoom_at(pow(ZOOM_STEP,steps if event.button_index == MOUSE_BUTTON_WHEEL_UP else -steps),event.position)
		hover(hit(event.position),true)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pick_at(event.position)
		accept_event()
	elif event is InputEventKey and event.pressed:
		if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
			return
		var directions = {KEY_RIGHT:0,KEY_E:1,KEY_UP:2,KEY_LEFT:3,KEY_Z:4,KEY_DOWN:5}
		if directions.has(event.keycode):
			keyboard_cursor = true
			if cursor == R.NONE:
				cursor = selected_cap
			var n = cursor + R.DIRS[directions[event.keycode]]
			if game.cells.has(n):
				cursor = n
			reveal_cursor()
			update_inspection()
			accept_event()

		elif event.keycode in [KEY_ENTER,KEY_SPACE] and cursor != R.NONE:
			if not event.echo:
				keyboard_cursor = true
				reveal_cursor()
				update_inspection()
				picked.emit(cursor)
			accept_event()

func pick_at(local: Vector2):
	var p = hit(local)
	grab_focus()
	hover(p,true)
	if p != R.NONE:
		cursor = p
	picked.emit(p)
