extends "res://tests/difficulty_benchmark.gd"

# Force the same first purchase, then let Standard finish the game.
func replay_opening(layout: Array, cap: Vector2i, target: Vector2i, end_day_one: bool) -> Array:
	var g = R.new_game(layout[0], layout[1])
	var land_on_day_eight = -1
	if not g.apply("recruit", cap, target):
		push_error("Opening purchase could not be replayed")
		failed = true
		return []
	for turn in TURN_LIMIT:
		if g.active == 0 and g.round_number == 8:
			land_on_day_eight = 0
			for village in g.lands:
				if g.cells[village].owner == 0:
					land_on_day_eight += g.lands[village].size()
		if turn > 0 or not end_day_one:
			play_turn(g, STANDARD)
		if failed:
			return []
		if g.owns_island(0) or g.offer_surrender_on_end_turn():
			return [g.cells.size() if land_on_day_eight < 0 else land_on_day_eight, "win"]
		if not g.can_take_turn(0):
			return [maxi(0, land_on_day_eight), "loss"]
		g.end_turn()
	return [land_on_day_eight, "turn limit"]

func _initialize():
	var args = Array(OS.get_cmdline_user_args())
	var sample = args.has("--sample")
	args.erase("--sample")
	var island = "The Basin" if args.is_empty() else args[0]
	if not Island.MAPS.has(island):
		push_error("Unknown island: " + island)
		quit(1)
		return
	var layout = Island.MAPS[island]
	var opening = R.new_game(layout[0], layout[1])
	if sample:
		var starting_land = 0
		for cap in opening.lands:
			if opening.cells[cap].owner == 0:
				starting_land += opening.lands[cap].size()
		print(island, " | Starting connected land: ", starting_land)
		print("Village -> first capture | finish day one (day-8 land, outcome)")
	else:
		print("Village -> capture | finish day one (day-8 land, outcome) | end day one (day-8 land, outcome)")
	for cap in opening.lands:
		if opening.cells[cap].owner != 0:
			continue
		for target in opening.targets("recruit", cap):
			if opening.cells[target].owner == 0:
				continue
			var finish = replay_opening(layout, cap, target, false)
			if failed:
				quit(1)
				return
			if sample:
				print(cap, " -> ", target, " | ", finish)
				break
			var stop = replay_opening(layout, cap, target, true)
			if failed:
				quit(1)
				return
			print(cap, " -> ", target, " | ", finish, " | ", stop)
	quit()
