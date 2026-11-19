extends RefCounted

const Island = preload("res://game/island.gd")
enum { EMPTY, PEASANT, SPEARMAN, KNIGHT, BARON, CAPITAL, CASTLE, PINE, PALM, GRAVE }
const PIECES = ["Open land", "Peasant", "Spearman", "Knight", "Baron", "Capital", "Castle", "Pine", "Palm", "Grave"]
const WAGES = [0, 2, 6, 18, 54]
const RECRUIT_COST = 10
const DIRS = [Vector2i(1,0), Vector2i(1,-1), Vector2i(0,-1), Vector2i(-1,0), Vector2i(-1,1), Vector2i(0,1)]
const NONE = Vector2i(-999,-999)
var cells: Dictionary
var capitals = {} # Cell -> capital, or NONE for a one-hex territory.
var lands = {} # Capital -> array of land coordinates.
var adjacent = {}
var narrow_crossings: Array[Vector2i] = []
var active = 0
var round_number = 1
var players = 6
var surrender_wait = 0

static func new_game(rows: Array = Island.ROWS, palms: Array = Island.PALMS):
	var game = new()
	game.setup(Island.tiles(rows), 6)
	for location in palms:
		if game.cells.has(location) and game.cells[location].piece == EMPTY:
			game.cells[location].piece = PALM if game.adjacent[location].size() < 6 else PINE
	for cap in game.lands:
		game.cells[cap].cash = 4 * game.finances(cap).x
	game.begin_turn()
	return game

func setup(initial: Dictionary, count: int):
	cells = initial.duplicate(true)
	players = count
	adjacent.clear()
	lands.clear()
	for p in cells:
		var neighbors = []
		for direction in DIRS:
			if cells.has(p + direction):
				neighbors.append(p + direction)
		adjacent[p] = neighbors
	find_narrow_crossings()
	rebuild()

# A one-hex passage between two sizable banks. Check the coastline once,
# independently of ownership, so captures and undo reuse the same crossings.
func find_narrow_crossings():
	narrow_crossings.clear()
	for p in adjacent:
		var banks = adjacent[p]
		if banks.size() != 2 or banks[1] in adjacent[banks[0]]:
			continue
		var visited = {p: true}
		var sizable_banks = 0
		for bank in banks:
			if visited.has(bank):
				break
			var shore = [bank]
			visited[bank] = true
			var i = 0
			while i < shore.size():
				for n in adjacent[shore[i]]:
					if not visited.has(n):
						visited[n] = true
						shore.append(n)
				i += 1
			if shore.size() >= 10:
				sizable_banks += 1
		if sizable_banks == 2:
			narrow_crossings.append(p)

static func is_unit(piece: int) -> bool:
	return piece >= PEASANT and piece <= BARON

static func is_tree(piece: int) -> bool:
	return piece == PALM or piece == PINE

func component(start: Vector2i, excluded = NONE) -> Array:
	var result = [start]
	var visited = {start: true}
	var index = 0
	while index < result.size():
		for n in adjacent[result[index]]:
			if n != excluded and not visited.has(n) and cells[n].owner == cells[start].owner:
				visited[n] = true
				result.append(n)
		index += 1
	return result

static func earlier_hex(a: Vector2i, b: Vector2i) -> bool:
	# In Windows' flat-topped layout, q + 2r is the staggered screen row.
	var row_a = a.x + 2 * a.y
	var row_b = b.x + 2 * b.y
	return row_a < row_b or (row_a == row_b and a.x < b.x)

func last_visited_capital(group: Array, candidates: Array) -> Vector2i:
	var first = group[0]
	for p in group:
		if earlier_hex(p, first):
			first = p
	var stack = [first]
	var visited = {}
	var cap = NONE
	while not stack.is_empty():
		var p = stack.pop_back()
		if visited.has(p):
			continue
		visited[p] = true
		if p in candidates:
			cap = p
		# Reverse push order visits north first, then clockwise.
		for i in [3,4,5,0,1,2]:
			var n = p + DIRS[i]
			if cells.has(n) and cells[n].owner == cells[p].owner and not visited.has(n):
				stack.append(n)
	return cap

func replacement(group: Array) -> Vector2i:
	var best = group[0]
	var best_priority = 5
	var most_neighbors = -1
	for p in group:
		var piece = cells[p].piece
		var priority = 4
		match piece:
			EMPTY: priority = 0
			GRAVE: priority = 1
			PINE, PALM: priority = 2
			CASTLE: priority = 3
		var neighbors = 0
		for n in adjacent[p]:
			neighbors += int(cells[n].owner == cells[p].owner)
		if priority < best_priority or (priority == best_priority and (neighbors > most_neighbors or (neighbors == most_neighbors and earlier_hex(p, best)))):
			best_priority = priority
			most_neighbors = neighbors
			best = p
	return best

func rebuild():
	var old_lands = lands
	lands = {}
	capitals.clear()
	for p in cells:
		if capitals.has(p):
			continue
		var group = component(p)
		var cap = NONE
		if group.size() > 1:
			var largest = -1
			var candidates = []
			var money = 0
			for n in group:
				if cells[n].piece == CAPITAL:
					money += cells[n].cash
					var prior_size = old_lands.get(n, []).size()
					if prior_size > largest:
						largest = prior_size
						candidates.clear()
					if prior_size == largest:
						candidates.append(n)
					cells[n].piece = EMPTY
					cells[n].cash = 0
			match candidates.size():
				0: cap = replacement(group)
				1: cap = candidates[0]
				_: cap = last_visited_capital(group, candidates)
			cells[cap].piece = CAPITAL
			cells[cap].erase("young_tree")
			cells[cap].cash = money
			lands[cap] = group
		elif cells[p].piece == CAPITAL:
			cells[p].piece = PALM if adjacent[p].size() < 6 else PINE
			cells[p].cash = 0
		for n in group:
			capitals[n] = cap

func connected_land_counts() -> PackedInt32Array:
	var connected := PackedInt32Array()
	connected.resize(players)
	for cap in lands:
		connected[cells[cap].owner] += lands[cap].size()
	return connected

func territory_counts() -> Array[PackedInt32Array]:
	var owned := PackedInt32Array()
	owned.resize(players)
	for cell in cells.values():
		owned[cell.owner] += 1
	return [connected_land_counts(), owned]

func finances(cap: Vector2i) -> Vector2i:
	var totals = Vector2i.ZERO
	for p in lands.get(cap, []):
		var piece = cells[p].piece
		totals.x += int(not is_tree(piece))
		if is_unit(piece):
			totals.y += WAGES[piece]
	return totals

func defense(target: Vector2i) -> int:
	var strength = guard(cells[target].piece)
	for n in adjacent[target]:
		if cells[n].owner == cells[target].owner:
			strength = maxi(strength, guard(cells[n].piece))
	return strength

static func guard(piece: int) -> int:
	if is_unit(piece):
		return piece
	return 2 if piece == CASTLE else int(piece == CAPITAL)

# An order is a move from a unit, or a purchase from a capital, to one hex.
func legal(kind: String, source: Vector2i, target: Vector2i) -> bool:
	if source == target or not cells.has(source) or not cells.has(target):
		return false
	var from = cells[source]
	var to = cells[target]
	var cap = capitals[source]
	if from.owner != active or cap == NONE:
		return false
	if kind == "build":
		return source == cap and from.cash >= 15 and capitals[target] == cap and to.piece == EMPTY
	var rank = from.piece
	if kind == "recruit":
		if source != cap or from.cash < RECRUIT_COST:
			return false
		rank = PEASANT
	elif kind != "move" or not is_unit(rank) or from.spent:
		return false
	if to.owner == active:
		if capitals[target] != cap:
			return false
		return to.piece == EMPTY or is_tree(to.piece) or to.piece == GRAVE or (is_unit(to.piece) and rank + to.piece <= BARON)
	if rank <= defense(target):
		return false
	for n in adjacent[target]:
		if capitals[n] == cap:
			return true
	return false

func targets(kind: String, source: Vector2i) -> Array:
	var result = []
	for p in cells:
		if legal(kind, source, p):
			result.append(p)
	return result

func apply(kind: String, source: Vector2i, target: Vector2i) -> bool:
	if not legal(kind, source, target):
		return false
	var from = cells[source]
	var to = cells[target]
	if kind == "build":
		from.cash -= 15
		to.piece = CASTLE
		to.spent = false
		return true
	var capture = to.owner != active
	if capture:
		# Remember the defense before removing its soldiers or splitting the holding.
		if defense(target) >= SPEARMAN:
			to.breached = true
		else:
			to.erase("breached")
	var rank = from.piece
	if kind == "recruit":
		from.cash -= RECRUIT_COST
		rank = PEASANT
	else:
		from.piece = EMPTY
		from.spent = false
	var combined = not capture and is_unit(to.piece)
	to.spent = capture or is_tree(to.piece) or to.piece == GRAVE or (combined and to.spent)
	to.piece = rank + (to.piece if combined else 0)
	to.erase("young_tree")
	to.cash = 0
	to.owner = active
	if capture:
		rebuild()
	return true

func begin_turn():
	var growth = {}
	for p in cells:
		var cell = cells[p]
		if cell.owner != active:
			continue
		cell.spent = false
		cell.erase("breached")
		cell.erase("young_tree")
		if cell.piece == GRAVE:
			growth[p] = PALM if adjacent[p].size() < 6 else PINE
		elif cell.piece == EMPTY:
			var palms = 0
			var pines = 0
			for n in adjacent[p]:
				var neighbor = cells[n]
				if neighbor.owner != active and neighbor.get("young_tree", false):
					continue
				palms += int(neighbor.piece == PALM)
				pines += int(neighbor.piece == PINE)
			if pines >= 2:
				growth[p] = PINE
			elif adjacent[p].size() < 6 and palms > 0:
				growth[p] = PALM
		elif is_unit(cell.piece) and capitals[p] == NONE:
			cell.piece = GRAVE
	for p in growth:
		cells[p].piece = growth[p]
		cells[p].young_tree = true
	for cap in lands:
		if cells[cap].owner != active:
			continue
		var ledger = finances(cap)
		cells[cap].cash += ledger.x - ledger.y
		if cells[cap].cash < 0:
			cells[cap].cash = 0
			for p in lands[cap]:
				if is_unit(cells[p].piece):
					cells[p].piece = GRAVE

func can_take_turn(player: int) -> bool:
	for cell in cells.values():
		if cell.owner == player and (cell.piece == CAPITAL or is_unit(cell.piece)):
			return true
	return false

func owns_island(player: int) -> bool:
	for cell in cells.values():
		if cell.owner != player:
			return false
	return true

# In a single-player challenge the opponents can concede at the end of
# the human turn. Only qualifying turns count toward a repeat offer.
func offer_surrender_on_end_turn() -> bool:
	if active != 0 or not can_take_turn(0):
		return false
	var scores = PackedInt32Array()
	scores.resize(players)
	for cell in cells.values():
		if not is_tree(cell.piece):
			scores[cell.owner] += 1
	var strongest = 0
	for opponent in range(1, players):
		strongest = maxi(strongest, scores[opponent])
	if scores[0] <= 3 * strongest or owns_island(0):
		return false
	if surrender_wait > 0:
		surrender_wait -= 1
		return false
	return true

func decline_surrender():
	surrender_wait = 3

func accept_surrender():
	for cell in cells.values():
		if cell.owner != active:
			cell.owner = active
			if cell.piece == CAPITAL or cell.piece == CASTLE or is_unit(cell.piece):
				cell.piece = EMPTY
				cell.cash = 0
				cell.spent = false
	rebuild()

func end_turn():
	for i in players:
		active = (active + 1) % players
		if active == 0:
			round_number += 1
		var eligible = can_take_turn(active)
		begin_turn()
		if eligible:
			return

func restore(snapshot: Dictionary):
	cells = snapshot.duplicate(true)
	rebuild()
