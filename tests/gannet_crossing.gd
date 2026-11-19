extends "res://tests/difficulty_benchmark.gd"

const CROSSING = Vector2i(24,13)
const APPROACH = Vector2i(25,12)
const VILLAGE = Vector2i(26,10)

func _initialize():
	for strategy in ["Standard","Immediate castle"]:
		if not replay_crossing(strategy):
			quit(1)
			return
	quit()

func replay_crossing(strategy: String) -> bool:
	var layout = Island.MAPS["Gannet Keys"]
	var game = R.new_game(layout[0],layout[1])
	print(strategy)
	if not game.apply("recruit",VILLAGE,APPROACH):
		return false
	if strategy == "Immediate castle" and not game.apply("build",VILLAGE,CROSSING):
		return false
	while true:
		var day = game.round_number
		if game.active == 0 and day in [8,20,30,40,60]:
			var held = game.cells[CROSSING].owner == 0
			var local = game.lands.get(game.capitals[CROSSING],[]).size() if held else 0
			print("Day ",day," | village land ",game.connected_land_counts()[0],
				" | crossing owner ",game.cells[CROSSING].owner," | player holding ",local)
			if day == 60:
				break
		for i in 300:
			var order = AI.choose(game,STANDARD)
			if order.is_empty():
				break
			if order[0] == "build" and order[2] in game.adjacent[CROSSING]:
				print("Approach castle on day ",day," by seat ",game.active," at ",order[2])
			if order[2] == CROSSING and game.cells[CROSSING].owner == 0 and game.active != 0:
				print("Crossing taken on day ",day," by seat ",game.active," with ",order)
			if not game.apply(order[0],order[1],order[2]) or i == 299:
				printerr("Replay failed on day ",day,", order ",i,": ",order)
				return false
		if game.owns_island(game.active) or not game.can_take_turn(0) or game.offer_surrender_on_end_turn():
			print("Game ended on day ",day)
			break
		game.end_turn()
	return true
