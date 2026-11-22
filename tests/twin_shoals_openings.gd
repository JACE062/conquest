extends SceneTree

const R = preload("res://game/rules.gd")
const AI = preload("res://game/opponent.gd")
const WEST_OPENINGS = [Vector2i(1,1),Vector2i(2,1),Vector2i(-1,3),Vector2i(-1,4)]

func _initialize():
	for opening in WEST_OPENINGS:
		for first in 2:
			if not replay(opening,first):
				quit(1)
				return
	quit()

func replay(opening: Vector2i, first: int) -> bool:
	var g = R.new_game(R.Island.SHOALS_ROWS,[],2,first)
	var cuts = []
	var fifth_round = []
	for turn in 240:
		for step in 100:
			var action: Array
			if turn < 2 and step == 0:
				var cap = g.lands.keys().filter(func(p): return g.cells[p].owner == g.active)[0]
				var target = opening if g.active == 0 else Vector2i(7,6) - opening
				action = ["recruit",cap,target]
			else:
				action = AI.choose(g)
			if action.is_empty():
				break
			var target = action[2]
			if g.active == 0 and g.round_number in [4,5] and g.cells[target].owner == 1 and g.capitals[target] != R.NONE:
				var land = g.lands[g.capitals[target]]
				var other = land[1] if land[0] == target else land[0]
				if g.component(other,target).size() < land.size() - 1:
					cuts.append([g.round_number,target])
			if not g.apply(action[0],action[1],target) or step == 99:
				push_error("Invalid or unfinished Standard turn: %s" % [action])
				return false
			if g.connected_land_counts()[1-g.active] == 0:
				print(opening," first=",first," cuts=",cuts," round-five land=",fifth_round,
					" winner=",g.active," round=",g.round_number)
				return true
		if g.round_number == 5 and g.active != first:
			fifth_round = Array(g.connected_land_counts())
		g.end_turn()
	print(opening," first=",first," cuts=",cuts," round-five land=",fifth_round," turn limit")
	return true
