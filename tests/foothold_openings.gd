extends "res://tests/difficulty_benchmark.gd"

var observation_day = 8

# Replay four regional captures and a village link to the requested player turn.
func _initialize():
	var names = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--day="):
			var value = arg.trim_prefix("--day=")
			if not value.is_valid_int() or value.to_int() < 2:
				printerr("Use --day=N with a day of 2 or later")
				quit(1)
				return
			observation_day = value.to_int()
		else:
			names.append(arg)
	if names.is_empty():
		printerr("Pass one or more island names after --")
		quit(1)
		return
	for island in names:
		if not Island.MAPS.has(island):
			printerr("Unknown island: ",island)
			quit(1)
			return
		sample(island)
		if failed:
			break
	quit(1 if failed else 0)

func sample(island):
	var layout = Island.MAPS[island]
	var opening = R.new_game(layout[0],layout[1])
	var candidates = {}
	var villages = 0
	var can_recruit = 0
	for cap in opening.lands:
		if opening.cells[cap].owner != 0:
			continue
		villages += 1
		var targets = opening.targets("recruit",cap)
		can_recruit += int(not targets.is_empty())
		for target in targets:
			if opening.cells[target].owner != 0:
				candidates[cap] = target
				break
	print(island," | tiles ",opening.cells.size()," | connected ",opening.connected_land_counts(),
		" | player villages ",villages,", can recruit ",can_recruit,", can capture ",candidates.size())
	var board_size = Vector2i(0,layout[0].size())
	for row in layout[0]:
		board_size.x = maxi(board_size.x,row.length())
	var sampled = []
	for fraction in [Vector2(.2,.2),Vector2(.8,.2),Vector2(.2,.8),Vector2(.8,.8)]:
		if candidates.is_empty():
			break
		var offset = (Vector2(board_size - Vector2i.ONE) * fraction).round()
		var anchor = Island.axial(int(offset.x),int(offset.y))
		var nearest = R.NONE
		var distance = INF
		for cap in candidates:
			var d = cap - anchor
			var steps = maxi(maxi(absi(d.x),absi(d.y)),absi(d.x+d.y))
			if steps < distance:
				nearest = cap
				distance = steps
		replay(layout,nearest,candidates[nearest])
		if failed:
			return
		sampled.append([nearest,candidates[nearest]])
		candidates.erase(nearest)
	var link = largest_link(opening,sampled)
	if not link.is_empty():
		print("Largest first-turn village link:")
		replay(layout,link[0],link[1])

# Choose the capture that adds the most land to its recruiting village while
# joining another capital. Each distinct neighboring holding contributes once.
func largest_link(game,sampled):
	var best = []
	var most_land = 0
	for cap in game.lands:
		if game.cells[cap].owner != 0:
			continue
		for target in game.targets("recruit",cap):
			if game.cells[target].owner == 0 or [cap,target] in sampled:
				continue
			var other_villages = {}
			var gain = 1
			for n in game.adjacent[target]:
				if game.cells[n].owner != 0:
					continue
				var other = game.capitals[n]
				if other == R.NONE:
					gain += 1
				elif other != cap and not other_villages.has(other):
					other_villages[other] = true
					gain += game.lands[other].size()
			if not other_villages.is_empty() and gain > most_land:
				most_land = gain
				best = [cap,target]
	return best

func replay(layout,cap,target):
	var game = R.new_game(layout[0],layout[1])
	var initial_size = game.lands[cap].size()
	if not game.apply("recruit",cap,target):
		push_error("Illegal first capture")
		failed = true
		return
	while game.round_number < observation_day:
		if game.active == 0 and game.round_number == 8:
			report(game,cap,target,initial_size)
		play_turn(game,STANDARD)
		if failed:
			return
		if game.owns_island(game.active) or not game.can_take_turn(0) or game.offer_surrender_on_end_turn():
			break
		game.end_turn()
	report(game,cap,target,initial_size)

func report(game,cap,target,initial_size):
	var owner = game.cells[target].owner
	var local = game.lands.get(game.capitals[target],[]).size()
	print(cap," -> ",target," | day ",game.round_number," | connected ",game.connected_land_counts(),
		" | opening village size ",initial_size," | first capture owner (seat) ",owner,
		" | holding at first capture ",local if owner == 0 else 0)
