extends SceneTree

const R = preload("res://game/rules.gd")
const AI = preload("res://game/opponent.gd")
const Island = preload("res://game/island.gd")
const LAST_ROUND = 150

# Only the defense calculation changes. Ownership, legal orders between
# partners, treasury boundaries and the alliance victory condition stay intact.
class ReplayRules extends "res://game/rules.gd":
	var shared_defense = true

	func defense(target: Vector2i) -> int:
		if shared_defense or cells[target].owner not in [0,1]:
			return super.defense(target)
		var rank = guard(cells[target].piece)
		for p in adjacent[target]:
			if cells[p].owner == cells[target].owner:
				rank = maxi(rank,guard(cells[p].piece))
		return rank

func _initialize():
	var initial = R.new_game(Island.duel_rows(true),Island.MAPS[Island.DUEL_ISLAND][1])
	initial.cooperative = true
	for opener in 2:
		var choices = R.new_game(Island.duel_rows(true),Island.MAPS[Island.DUEL_ISLAND][1])
		choices.cooperative = true
		if opener == 1:
			while true:
				var order = AI.choose(choices)
				if order.is_empty(): break
				if not choices.apply(order[0],order[1],order[2]):
					quit(1)
					return
			choices.end_turn()
		var openings = [[]] if opener == 0 else []
		for cap in choices.lands:
			if choices.cells[cap].owner != opener:
				continue
			var captures = choices.targets("recruit",cap).filter(func(p): return choices.cells[p].owner != opener)
			if not captures.is_empty():
				openings.append(["recruit",cap,captures.front()])
				if captures.back() != captures.front():
					openings.append(["recruit",cap,captures.back()])
		for opening in openings:
			for defense_on in [true,false]:
				if not replay(initial,opener,opening,defense_on):
					quit(1)
					return
	quit()

func replay(initial,opener: int,opening: Array,defense_on: bool) -> bool:
	var g = ReplayRules.new()
	g.setup(initial.cells,6)
	g.cooperative = true
	g.shared_defense = defense_on
	var checkpoints = {}
	var denied = [0,0]
	var examples = ["",""]
	var outcome = "limit"
	var seen = {}
	while g.round_number <= LAST_ROUND:
		var round_played = g.round_number
		var owner = g.active
		for step in 300:
			var order = opening if round_played == 1 and owner == opener and step == 0 and not opening.is_empty() else AI.choose(g)
			if defense_on and owner >= 2 and round_played <= 8:
				# From the identical live position, ask what Standard would
				# actually order if the partner's defenders vanished.
				g.shared_defense = false
				var alternative = AI.choose(g)
				g.shared_defense = true
				if not alternative.is_empty() and not g.legal(alternative[0],alternative[1],alternative[2]):
					var target = alternative[2]
					var ally = g.cells[target].owner
					var key = [round_played,owner,target]
					if not seen.has(key):
						seen[key] = true
						denied[ally] += 1
						if examples[ally].is_empty():
							for neighbor in g.adjacent[target]:
								var cell = g.cells[neighbor]
								if cell.owner == 1-ally and R.guard(cell.piece) == g.defense(target):
									examples[ally] = "round %d bot %d %s blocked by %s at %s" % [round_played,owner,alternative,R.PIECES[cell.piece],neighbor]
									break
			if order.is_empty():
				break
			if step == 299 or not g.apply(order[0],order[1],order[2]):
				push_error("Failed replay at %s" % [order])
				return false
			if not (g.can_take_turn(0) or g.can_take_turn(1)):
				outcome = "bots"
				break
			if not range(2,6).any(func(seat): return g.can_take_turn(seat)):
				outcome = "allies"
				break
		if outcome != "limit":
			break
		g.end_turn()
		if g.round_number != round_played and round_played in [4,8,16]:
			checkpoints[round_played] = Array(g.connected_land_counts()).slice(0,2)
	print("seat=",opener," opening=",opening," shared=",defense_on," land=",checkpoints," denied=",denied,
		" examples=",examples," result=",outcome," round=",mini(g.round_number,LAST_ROUND),
		" final land=",Array(g.connected_land_counts()).slice(0,2))
	return true
