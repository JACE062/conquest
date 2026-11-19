extends SceneTree

const R = preload("res://game/rules.gd")
const AI = preload("res://game/opponent.gd")
const Island = preload("res://game/island.gd")
const EASY = AI.Difficulty.EASY
const STANDARD = AI.Difficulty.STANDARD
const TURN_LIMIT = 900
var failed = false

func play_turn(g, tier, captures = null):
	for i in 300:
		var order = AI.choose(g, tier)
		if order.is_empty():
			return
		if captures != null and g.cells[order[2]].owner != g.active:
			var target = order[2]
			captures[target] = captures.get(target, 0) + 1
		if not g.apply(order[0], order[1], order[2]):
			push_error("Illegal difficulty benchmark order %s" % [order])
			failed = true
			return
	push_error("AI exceeded 300 orders in one turn")
	failed = true

# Record a village at risk only when one ready soldier could legally take
# either its capital or a different open enemy hex from the same holding.
func exposed_capitals(g) -> Dictionary:
	var exposed = {}
	for cap in g.lands:
		if g.cells[cap].owner != g.active:
			continue
		var soldier = R.NONE
		for p in g.lands[cap]:
			var cell = g.cells[p]
			if R.is_unit(cell.piece) and not cell.spent and (soldier == R.NONE or cell.piece > g.cells[soldier].piece):
				soldier = p
		if soldier == R.NONE:
			continue
		var capitals = []
		var open_hex = false
		for target in g.targets("move", soldier):
			var cell = g.cells[target]
			if cell.owner == g.active:
				continue
			if cell.piece == R.CAPITAL:
				capitals.append(target)
			elif cell.piece == R.EMPTY:
				open_hex = true
		if open_hex:
			for target in capitals:
				exposed[target] = true
	return exposed

func play_match(layout, standard_seats: Array, exposure: Array = [], challenger = EASY, replay = false) -> int:
	var g = R.new_game(layout[0], layout[1])
	var captures = {}
	for i in TURN_LIMIT:
		var targets = {}
		if not exposure.is_empty() and g.round_number <= 20:
			targets = exposed_capitals(g)
			if not targets.is_empty():
				var copy = R.new()
				copy.setup(g.cells, g.players)
				copy.active = g.active
				play_turn(copy, EASY)
				exposure[0] += targets.size()
				for target in targets:
					exposure[1] += int(copy.cells[target].owner == g.active)
		play_turn(g, STANDARD if g.active in standard_seats else challenger,
			captures if replay and i >= TURN_LIMIT - 60 else null)
		if failed:
			return -1
		for target in targets:
			exposure[2] += int(g.cells[target].owner == g.active)
		if g.owns_island(g.active):
			if replay:
				print(Island.HOUSES[g.active], " conquered the island on active turn ", i + 1)
			return g.active
		g.end_turn()
	if replay:
		print("Final 60 active turns: ", captures.values().reduce(func(a,b): return a+b, 0),
			" captures across ", captures.size(), " different hexes.")
		for cap in g.lands:
			var budget = g.finances(cap)
			print(Island.HOUSES[g.cells[cap].owner], " at ", cap, ": ", g.lands[cap].size(),
				" land, ", budget.x, " income, ", budget.y, " wages, ", g.cells[cap].cash, " coins.")
	return -1

# Rotate the opening holdings into the human seat. The same proxy passes its
# first two days, then uses Standard and accepts the game's normal surrender.
func recovery_match(layout, starting_house: int, opposition: int) -> Vector2i:
	var rotated = []
	for row in layout[0]:
		var line = ""
		for symbol in row:
			line += "." if symbol == "." else str(posmod(int(symbol) - starting_house, 6))
		rotated.append(line)
	var g = R.new_game(rotated, layout[1])
	var land_on_day_eight = -1
	for i in TURN_LIMIT:
		if g.active == 0 and g.round_number == 8:
			land_on_day_eight = 0
			for p in g.cells:
				land_on_day_eight += int(g.cells[p].owner == 0 and g.capitals[p] != R.NONE)
		if g.active != 0 or g.round_number > 2:
			play_turn(g, STANDARD if g.active == 0 else opposition)
		if failed:
			return Vector2i(-1, land_on_day_eight)
		if g.owns_island(0) or g.offer_surrender_on_end_turn():
			return Vector2i(1, g.cells.size() if land_on_day_eight == -1 else land_on_day_eight)
		if not g.can_take_turn(0):
			return Vector2i(0, maxi(0, land_on_day_eight))
		g.end_turn()
	return Vector2i(-1, land_on_day_eight)

func _initialize():
	var requested = Array(OS.get_cmdline_user_args())
	var hard = requested.has("--hard")
	requested.erase("--hard")
	var replay_mask = -1
	for arg in requested.duplicate():
		if arg.begins_with("--replay="):
			var value = arg.trim_prefix("--replay=")
			if not value.is_valid_int() or value.to_int() < 0 or value.to_int() >= 64 or String.num_uint64(value.to_int(), 2).count("1") != 3:
				push_error("A replay mask needs three Standard seats among the six houses.")
				quit(1)
				return
			replay_mask = value.to_int()
			requested.erase(arg)
	var challenger = AI.Difficulty.HARD if hard else EASY
	for name in requested:
		if not Island.MAPS.has(name):
			push_error("Unknown test island: " + name)
			quit(1)
			return
	for island in Island.MAPS:
		if not requested.is_empty() and island not in requested:
			continue
		var layout = Island.MAPS[island]
		var opening = R.new_game(layout[0], layout[1])
		for seat in 6:
			if not opening.can_take_turn(seat):
				push_error("%s starts without a village for seat %d" % [island,seat])
				quit(1)
				return
		var wins = [0, 0, 0] # Standard, challenger, unfinished.
		for mask in 64:
			if replay_mask != -1 and mask != replay_mask:
				continue
			var standard_seats = []
			for seat in 6:
				if mask & (1 << seat):
					standard_seats.append(seat)
			if standard_seats.size() != 3:
				continue
			var winner = play_match(layout, standard_seats, [], challenger, replay_mask != -1)
			if failed:
				quit(1)
				return
			if winner == -1:
				wins[2] += 1
			elif winner in standard_seats:
				wins[0] += 1
			else:
				wins[1] += 1
		if replay_mask != -1:
			continue
		if hard:
			print(island, " — mixed wins (Standard, Hard, unfinished) ", wins)
			var wins_against_hard = 0
			var unfinished_against_hard = 0
			var land_against_hard = 0
			for seat in 6:
				var outcome = recovery_match(layout, seat, challenger)
				wins_against_hard += int(outcome.x == 1)
				unfinished_against_hard += int(outcome.x == -1)
				land_against_hard += outcome.y
			print("  Missed-opening results against Hard: wins ", wins_against_hard,
				", unfinished ", unfinished_against_hard, ", day-8 village land total ", land_against_hard)
			continue
		var exposure = [0, 0, 0] # Opportunities, Easy captures, Standard captures.
		var reference_winner = play_match(layout, range(6), exposure)
		var easy_winner = play_match(layout, [])
		var recovery_wins = [0, 0]
		var unfinished = [0, 0]
		var recovery_land = [0, 0]
		for seat in 6:
			for tier in [EASY, STANDARD]:
				var outcome = recovery_match(layout, seat, tier)
				var column = int(tier == STANDARD)
				recovery_wins[column] += int(outcome.x == 1)
				unfinished[column] += int(outcome.x == -1)
				recovery_land[column] += outcome.y
		print(island, " — mixed wins (Standard, Easy, unfinished) ", wins)
		print("  Capital exposures (seen, taken by Easy, taken by Standard) ", exposure)
		print("  Missed-opening results against Easy and Standard: wins ", recovery_wins,
			", unfinished ", unfinished, ", day-8 village land totals ", recovery_land)
		print("  Winning seats in all-Standard and all-Easy games (-1 = turn limit) ",
			[reference_winner, easy_winner])
	quit(1 if failed else 0)
