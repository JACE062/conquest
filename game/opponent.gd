extends RefCounted

const R = preload("res://game/rules.gd")
const CAPITAL_BONUS = 45
const DEFENSE_PAYROLL = 2 * R.WAGES[R.SPEARMAN]
const ESTABLISHED_CROSSING_LAND = 12
const CROSSING_FORT_PRIORITY = 88
enum Difficulty { STANDARD, EASY, HARD }

static func capture_value(g, p, cap) -> int:
	var tile = g.cells[p]
	var score = 40 + R.guard(tile.piece) * 6
	if tile.piece == R.CAPITAL:
		score += CAPITAL_BONUS + mini(tile.cash, 20)
	elif R.is_tree(tile.piece):
		# Taking a wooded frontier also removes a seed source in the same move.
		score += 4 + 4 * maxi(0, clearing_value(g, p))
	var friendly = {}
	var enemy_neighbors = 0
	for n in g.adjacent[p]:
		if g.cells[n].owner == g.active:
			var other = g.capitals[n]
			if other != cap:
				friendly[other] = true
		elif g.cells[n].owner == tile.owner:
			enemy_neighbors += 1
	for other in friendly:
		score += 8 if other == R.NONE else 26 + mini(g.lands[other].size(), 10)
	if enemy_neighbors >= 2:
		var survivors = g.lands.get(g.capitals[p], []).size() - 1
		for n in g.adjacent[p]:
			if g.cells[n].owner == tile.owner:
				if g.component(n, p).size() < survivors:
					score += 32
				break
	return score

# Compare the captures an upgrade unlocks with captures available this turn.
static func upgrade_score(values: Array, ready_rank: int, new_rank: int, desired_rank: int) -> int:
	var score = 0
	for defense in range(ready_rank, new_rank):
		if values[defense] > 0:
			score = maxi(score, values[defense] - 2 * new_rank)
	if new_rank <= desired_rank:
		# A nearby army can redeploy anywhere within its holding on its next turn.
		score = maxi(score, 42 + 3 * new_rank)
	return score

static func clearing_value(g, tree) -> int:
	var piece = g.cells[tree].piece
	var value = 0
	for n in g.adjacent[tree]:
		if g.cells[n].owner != g.active:
			continue
		if g.cells[n].piece == R.EMPTY:
			value += int(piece == R.PINE or (piece == R.PALM and g.adjacent[n].size() < 6))
		elif g.cells[n].piece == piece:
			value -= 1
	return value

# Would the empty site grow a tree if this particular seed source were felled?
static func would_regrow(g, site, felled = R.NONE) -> bool:
	var pines = 0
	for n in g.adjacent[site]:
		if n == felled:
			continue
		var piece = g.cells[n].piece
		if piece == R.PALM and g.adjacent[site].size() < 6:
			return true
		pines += int(piece == R.PINE)
	return pines >= 2

static func forestry_value(g, tree) -> int:
	var value = int(not would_regrow(g, tree))
	for n in g.adjacent[tree]:
		if g.cells[n].owner != g.active or g.cells[n].piece != R.EMPTY:
			continue
		if would_regrow(g, n) and not would_regrow(g, n, tree):
			value += 2
	return value

# Pick a clearing that can be extended. Where even the first cleared tile
# would regrow, felling a second tree next turn can keep both sites productive.
static func next_clearing(g, tree) -> int:
	var seeds = 0
	var pair = false
	for n in g.adjacent[tree]:
		if not R.is_tree(g.cells[n].piece):
			continue
		seeds += 1
		if g.cells[n].owner == g.active and not would_regrow(g, tree, n):
			pair = true
	return 6 - seeds + (4 if pair else 0)

static func castle_value(g, p) -> int:
	if g.defense(p) >= R.guard(R.CASTLE):
		return 0
	var pressure = 0
	var vulnerable = 0
	for n in g.adjacent[p]:
		if g.cells[n].owner == g.active:
			vulnerable += int(g.defense(n) < 2)
		else:
			if g.cells[n].piece in [R.KNIGHT, R.BARON]:
				return 0
			pressure += 1
	return 27 + vulnerable if pressure >= 2 and vulnerable >= 2 else 0

# A soldier can attack from anywhere in its village on its owner's next turn.
static func attacking_rank(g, site, armies: Dictionary) -> int:
	var rank = 0
	for n in g.adjacent[site]:
		if g.cells[n].owner != g.active:
			rank = maxi(rank, armies.get(g.capitals[n], 0))
	return rank

# Record only soldiers whose departure would let an enemy army or a funded
# recruit take the passage. Another sufficient defender frees the soldier.
static func crossing_guards(g, armies: Dictionary) -> Dictionary:
	var guards = {}
	for crossing in g.narrow_crossings:
		var cap = g.capitals[crossing]
		if g.cells[crossing].owner != g.active or g.lands.get(cap, []).size() < ESTABLISHED_CROSSING_LAND:
			continue
		var threat = attacking_rank(g, crossing, armies)
		if threat == 0:
			continue
		var defender = R.NONE
		for p in [crossing] + g.adjacent[crossing]:
			var cell = g.cells[p]
			if cell.owner != g.active or R.guard(cell.piece) < threat:
				continue
			if defender != R.NONE or not R.is_unit(cell.piece) or cell.spent:
				defender = R.NONE
				break
			defender = p
		if defender != R.NONE:
			if not guards.has(defender):
				guards[defender] = []
			guards[defender].append(crossing)
	return guards

static func leaves_crossing(g, guards: Dictionary, unit, target) -> bool:
	if guards.has(unit):
		for crossing in guards[unit]:
			if target != crossing and target not in g.adjacent[crossing]:
				return true
	return false

# Extending past a single entrance gives a spearman two hexes for one
# capture. A peasant placed alongside the entrance can keep a second route.
static func fragile_extension(g, target, cap, breach_ranks) -> bool:
	if g.cells[target].owner != R.Island.NEUTRAL:
		return false
	var entrance = R.NONE
	for n in g.adjacent[target]:
		if g.capitals[n] == cap:
			if entrance != R.NONE:
				return false
			entrance = n
	return entrance != R.NONE and attacking_rank(g,entrance,breach_ranks) > maxi(R.PEASANT,g.defense(entrance))

# An inexpensive capture can cost a village its connection, or leave a
# peasant free to follow a stronger attacker through a newly opened border.
static func cheap_followup(g, site, cap, armies, followups) -> bool:
	for edge in g.adjacent[site]:
		if g.capitals[edge] != cap:
			continue
		var defense = maxi(R.PEASANT,g.defense(edge))
		for n in g.adjacent[edge]:
			var enemy = g.capitals[n]
			if followups.has(enemy) and armies[enemy] > defense:
				return true
	return false

static func interior_guard(g, cap, armies, breach_ranks, followups, ready, guards) -> Array:
	var land = g.lands[cap]
	for site in land:
		if R.guard(g.cells[site].piece) > R.PEASANT:
			continue
		var threat = attacking_rank(g, site, armies)
		var needs_guard = false
		if threat == R.PEASANT and site != cap and attacking_rank(g,site,breach_ranks) == R.PEASANT:
			needs_guard = g.component(cap,site).size() + 1 < land.size()
		elif threat == 0:
			needs_guard = cheap_followup(g,site,cap,armies,followups)
		if not needs_guard:
			continue
		var existing = R.NONE
		var covered = false
		for post in [site] + g.adjacent[site]:
			if g.cells[post].owner != g.active or R.guard(g.cells[post].piece) == 0:
				continue
			# A piece on the breach itself disappears in the first attack.
			if threat == 0 and attacking_rank(g,post,armies) > R.guard(g.cells[post].piece):
				continue
			if post not in ready or existing != R.NONE:
				covered = true
				break
			existing = post
		if covered:
			continue
		if existing != R.NONE:
			# Keep this peasant out of reach of the initial attack.
			if not guards.has(existing):
				guards[existing] = []
			guards[existing].append(site)
			continue
		for post in [site] + g.adjacent[site]:
			if g.cells[post].piece != R.EMPTY or attacking_rank(g,post,armies) > 0:
				continue
			for unit in ready:
				if not guards.has(unit) and g.legal("move",unit,post):
					return ["move",unit,post]
	return []

# A castle must cover the crossing and at least two other village tiles.
static func crossing_castle_site(g, cap, crossing, armies) -> Vector2i:
	var attack = attacking_rank(g, crossing, armies)
	if g.defense(crossing) >= R.SPEARMAN or attack > R.SPEARMAN:
		return R.NONE
	var banks = g.adjacent[crossing]
	# Once we hold both banks, an enemy must first take an approach.
	# Keep the troops and treasury available for the wider front.
	if g.capitals[banks[0]] == g.capitals[banks[1]]:
		return R.NONE
	# Under direct pressure keep a recruitment fee for a mobile response.
	# An isolated hex on the far bank has no treasury or army of its own.
	if attack > 0 and g.cells[cap].cash < 25:
		return R.NONE
	for site in banks:
		var threat = attacking_rank(g, site, armies)
		if g.capitals[site] != cap or threat > R.SPEARMAN or g.cells[site].piece == R.CAPITAL:
			continue
		var cover = 0
		for n in g.adjacent[site]:
			cover += int(g.capitals[n] == cap)
		if cover >= 3:
			return site
	return R.NONE

static func prepare_crossing_castle(g, cap, crossing, site, troops, guards) -> Array:
	if g.legal("build", cap, site):
		return ["build", cap, site]
	if R.is_unit(g.cells[site].piece):
		for p in g.lands[cap]:
			if p in g.adjacent[crossing] or leaves_crossing(g, guards, site, p):
				continue
			if g.cells[p].piece == R.EMPTY and g.legal("move", site, p):
				return ["move", site, p]
		if R.is_tree(g.cells[crossing].piece) or g.cells[crossing].piece == R.GRAVE:
			if g.legal("move", site, crossing) and not leaves_crossing(g, guards, site, crossing):
				return ["move", site, crossing]
	else:
		for unit in troops:
			if g.legal("move", unit, site) and not leaves_crossing(g, guards, unit, site):
				return ["move", unit, site]
	return []

static func payday_income(g, land: Array) -> int:
	var income = 0
	for p in land:
		var piece = g.cells[p].piece
		if not R.is_tree(piece) and piece != R.GRAVE and not (piece == R.EMPTY and would_regrow(g, p)):
			income += 1
	return income

# Before sending a peasant to take open land, see whether it can stop a tree
# spreading at home. Only divert it when growth threatens an established payroll.
static func preventive_clearing(g, move: Array) -> Array:
	var peasant = move[1]
	var target = g.cells[move[2]]
	if g.cells[peasant].piece != R.PEASANT or target.owner == g.active or target.piece != R.EMPTY:
		return move
	var cap = g.home_village(peasant)
	if g.cells[cap].cash >= 10:
		return move
	var land = g.lands[cap]
	var budget = g.finances(cap)
	var woods = land.size() - budget.x
	if budget.y < DEFENSE_PAYROLL or woods * 4 < land.size():
		return move
	if payday_income(g, land) - budget.y > R.WAGES[R.PEASANT]:
		return move
	var best = move
	var highest = 0
	for tree in land:
		if not R.is_tree(g.cells[tree].piece):
			continue
		var value = forestry_value(g, tree)
		# Keeping one neighboring taxable hex clear is worth two points.
		if value < 2:
			continue
		var score = 10 * value + next_clearing(g, tree)
		if score > highest:
			highest = score
			best = ["move", peasant, tree]
	return best

# A cut-off army starts with no treasury. Price each detached village separately.
static func payroll_at_risk(g, cap, cut) -> int:
	var connected = g.component(cap, cut)
	if connected.size() + 1 == g.lands[cap].size():
		return 0
	var risk = 0
	var visited = {}
	for n in g.adjacent[cut]:
		if g.capitals[n] != cap or n in connected or visited.has(n):
			continue
		var branch = g.component(n, cut)
		var wages = 0
		for p in branch:
			visited[p] = true
			if R.is_unit(g.cells[p].piece):
				wages += R.WAGES[g.cells[p].piece]
		if wages > payday_income(g, branch):
			risk += wages
	return risk

# Can the enemy take this soldier's hex as soon as it moves away, stranding
# a detachment that cannot pay even one spearman's wages?
static func guards_payroll(g, cap, unit) -> bool:
	var support = 0
	var enemies = {}
	for n in g.adjacent[unit]:
		if g.cells[n].owner == g.active:
			support = maxi(support, R.guard(g.cells[n].piece))
		elif g.capitals[n] != R.NONE:
			enemies[g.capitals[n]] = true
	var rank = g.cells[unit].piece
	if enemies.is_empty() or support >= rank or payroll_at_risk(g, cap, unit) < R.WAGES[R.SPEARMAN]:
		return false
	for enemy in enemies:
		var land = g.lands[enemy]
		# Enemy growth and captures can change its ledger before the reply.
		var budget = g.finances(enemy)
		if support == 0 and g.cells[enemy].cash + budget.x - budget.y >= 10:
			return true
		for p in land:
			var piece = g.cells[p].piece
			if R.is_unit(piece) and support < piece and piece <= rank:
				return true
	return false

# A wooded fragment becomes more productive when a tree becomes its capital.
# Account for the captured hex and any original capital left isolated.
static func gifts_productive_capitals(g, target) -> bool:
	var old_cap = g.capitals[target]
	if old_cap == R.NONE or g.cells[old_cap].cash >= 10:
		return false
	var neighbors = []
	for n in g.adjacent[target]:
		if g.capitals[n] == old_cap:
			neighbors.append(n)
	if neighbors.size() < 2:
		return false
	var visited = {}
	var reclaimed = 0
	var lost = int(not R.is_tree(g.cells[target].piece))
	for n in neighbors:
		if visited.has(n):
			continue
		var branch = g.component(n, target)
		for p in branch:
			visited[p] = true
		if branch.size() == 1 and n == old_cap:
			lost += 1
		if branch.size() >= 2 and old_cap not in branch and R.is_tree(g.cells[g.replacement(branch)].piece):
			reclaimed += 1
	return reclaimed > lost

# Only preview a rescue when this village would otherwise miss payroll.
# Even with no growth, an ordinary capture adds at most one taxable hex.
static func link_covers_payroll(g, unit, target) -> bool:
	var joins_land = false
	for n in g.adjacent[target]:
		if g.cells[n].owner == g.active and g.capitals[n] != g.home_village(unit):
			joins_land = true
			break
	if not joins_land or not g.legal("move", unit, target):
		return false
	var preview = R.new()
	preview.cooperative = g.cooperative
	preview.setup(g.cells, g.players)
	preview.active = g.active
	if not preview.apply("move", unit, target):
		return false
	var cap = preview.home_village(target)
	if not preview.lands.has(cap):
		return false
	return preview.cells[cap].cash + payday_income(preview, preview.lands[cap]) >= preview.finances(cap).y

static func protective_castle(g, cap, armies: Dictionary, purchase: Array) -> Array:
	var land = g.lands[cap]
	var wages = g.finances(cap).y
	if wages < DEFENSE_PAYROLL:
		return []
	var income = payday_income(g, land)
	if g.cells[cap].cash - 15 + income < wages:
		return []
	var best = R.NONE
	var best_risk = 0
	for p in land:
		var attack = attacking_rank(g, p, armies)
		if attack <= g.defense(p) or attack > R.guard(R.CASTLE):
			continue
		# A recruit that already guards this hex can go ahead.
		if attack <= R.PEASANT and (purchase[2] == p or purchase[2] in g.adjacent[p]):
			continue
		var risk = 0
		if p == cap:
			if income - 1 < wages + added_wages(g, purchase):
				risk = wages
		else:
			risk = payroll_at_risk(g, cap, p)
		# Avoid diverting a prosperous offensive for a small outlying army.
		if risk < DEFENSE_PAYROLL or risk < income - wages or risk <= best_risk:
			continue
		for site in [p] + g.adjacent[p]:
			if g.legal("build", cap, site):
				best = site
				best_risk = risk
				break
	return [] if best == R.NONE else ["build", cap, best]

static func can_pay(cash: int, purchase: int, surplus: int, added_wages: int) -> bool:
	# A temporary deficit is viable when reserves cover three paydays.
	return cash >= purchase and cash - purchase + 3 * (surplus - added_wages) >= 0

static func can_promote(cash_after_purchase: int, surplus: int, extra_wages: int, rank: int, established_income: int, troops_by_rank: Array, growth_loss: int = 0) -> bool:
	# Price a Knight or Baron against the land that will still pay tax after growth.
	if rank >= R.KNIGHT:
		surplus -= growth_loss
		established_income -= growth_loss
	if not can_pay(cash_after_purchase, 0, surplus, extra_wages):
		return false
	if rank < R.KNIGHT:
		return true
	# Retain inexpensive troops for other captures before duplicating a high rank.
	var peers = troops_by_rank[rank]
	var available_peasants = troops_by_rank[R.PEASANT] + floori(cash_after_purchase / 10.0)
	var support_per_peer = 4 if rank == R.KNIGHT else 8
	if peers > 0 and available_peasants <= 4 + support_per_peer * peers:
		return false
	var wage = R.WAGES[rank]
	var projected_balance = cash_after_purchase + 2 * (surplus - extra_wages)
	if projected_balance >= rank * wage:
		return true
	# A strong recurring income can support a promotion with less in the bank.
	var heavy_wages = troops_by_rank[R.KNIGHT] * R.WAGES[R.KNIGHT] + troops_by_rank[R.BARON] * R.WAGES[R.BARON]
	var funded_by_land = established_income > 2 * (heavy_wages + wage)
	var required_surplus = extra_wages if rank == R.KNIGHT and funded_by_land else 2 * extra_wages
	return surplus >= required_surplus and (funded_by_land or cash_after_purchase >= 2 * wage)

static func guarded_by_castle(g, target) -> bool:
	if g.cells[target].piece == R.CASTLE:
		return true
	for n in g.adjacent[target]:
		var cell = g.cells[n]
		if cell.owner == g.cells[target].owner and cell.piece == R.CASTLE:
			return true
	return false

# Estimate a reply from armies that will still border this hex after capture.
# Value the land this capture protects or connects, including a potential
# connection one capture further along the same border.
static func hard_frontier(g, cap, target, enemy_armies: Dictionary) -> Vector2i:
	var reply = 0
	var connection = 0
	var support = 0
	var value = 0
	var joined = {}
	var victim = g.capitals[target]
	var tile = g.cells[target]
	if R.is_unit(tile.piece):
		value += 18 * tile.piece
	elif tile.piece == R.CAPITAL:
		value -= maxi(0, CAPITAL_BONUS - tile.cash)
	if victim != R.NONE:
		# Taking either half of a two-hex village wipes out its treasury.
		value += 24 if g.lands[victim].size() == 2 else 8
	for n in g.adjacent[target]:
		if g.cells[n].owner == g.active:
			support = maxi(support, R.guard(g.cells[n].piece))
			var other = g.capitals[n]
			if other == R.NONE:
				value += 18
			elif other != cap and not joined.has(other):
				value += 24 + mini(30, g.lands[other].size() + g.cells[other].cash)
				joined[other] = true
			if g.defense(n) == 0:
				value += 6
			continue
		reply = maxi(reply, enemy_armies.get(g.capitals[n], 0))
		for beyond in g.adjacent[n]:
			if g.cells[beyond].owner == g.active and g.capitals[beyond] != cap:
				connection = maxi(connection, 12 if g.capitals[beyond] == R.NONE else 30)
	return Vector2i(value + connection, reply if reply > support else 0)

# Use a ready soldier, or price the whole reinforcement before the first order.
static func reinforce(cash: int, cap, target, required: int, ready: Array, clearings: Array,
		surplus: int, established_income: int, troops_by_rank: Array, hard: bool = false, growth_loss: int = 0) -> Array:
	for rank in range(required, R.BARON + 1):
		if not ready[rank].is_empty():
			return ["move", ready[rank][0], target]
	var parts = []
	var strength = 0
	var existing_wages = 0
	for rank in range(required - 1, 0, -1):
		for unit in ready[rank]:
			if strength + rank > required:
				break
			parts.append(unit)
			strength += rank
			existing_wages += R.WAGES[rank]
	var purchase = 10 * (required - strength)
	var extra_wages = R.WAGES[required] - existing_wages
	if hard:
		if not can_pay(cash, purchase, surplus, extra_wages):
			return []
	elif not can_promote(cash - purchase, surplus, extra_wages, required, established_income, troops_by_rank, growth_loss):
		return []
	if required == R.PEASANT:
		return ["recruit", cap, target]
	if parts.size() >= 2:
		return ["move", parts[1], parts[0]]
	if not parts.is_empty():
		return ["recruit", cap, parts[0]]
	if not clearings.is_empty():
		return ["recruit", cap, clearings[0]]
	return []

static func choose(g, difficulty: Difficulty = Difficulty.STANDARD) -> Array:
	var best = []
	var highest = 0
	var easy = difficulty == Difficulty.EASY
	var hard = difficulty == Difficulty.HARD
	var enemy_armies = {}
	var payroll_guards = {}
	var payroll_links = []
	var enemy_strength = {}
	var followups = {}
	var breach_ranks = {}
	for enemy in g.lands:
		if g.cells[enemy].owner != g.active and not g.allied(g.active,g.cells[enemy].owner):
			var strength = 1
			var soldiers = 0
			var peasants = 0
			for p in g.lands[enemy]:
				strength = maxi(strength, R.guard(g.cells[p].piece))
				if not easy and R.is_unit(g.cells[p].piece):
					soldiers += 1
					peasants += int(g.cells[p].piece == R.PEASANT)
					enemy_armies[enemy] = maxi(enemy_armies.get(enemy, 0), g.cells[p].piece)
			if difficulty == Difficulty.STANDARD:
				var can_hire = g.cells[enemy].cash >= R.RECRUIT_COST
				if can_hire:
					enemy_armies[enemy] = maxi(R.PEASANT,enemy_armies.get(enemy,0))
				var attack = enemy_armies.get(enemy,0)
				if attack >= R.SPEARMAN and (peasants > 0 or can_hire):
					followups[enemy] = true
				var can_merge = soldiers >= 2 or (soldiers > 0 and can_hire)
				breach_ranks[enemy] = maxi(attack,R.SPEARMAN if can_merge else 0)
			enemy_strength[enemy] = strength
	var guards = crossing_guards(g, enemy_armies) if difficulty == Difficulty.STANDARD else {}
	for cap in g.lands:
		if g.cells[cap].owner != g.active:
			continue
		var land = g.lands[cap]
		var budget = g.finances(cap)
		var cash = g.cells[cap].cash
		var frontier = {}
		var open_frontier = false
		var troops = []
		var clearings = []
		var woods = []
		var has_graves = false
		for p in land:
			var piece = g.cells[p].piece
			if R.is_unit(piece):
				if g.commander(p) == g.active and g.home_village(p) == cap:
					troops.append(p)
			elif piece == R.EMPTY:
				clearings.append(p)
			elif R.is_tree(piece) or piece == R.GRAVE:
				woods.append(p)
				has_graves = has_graves or piece == R.GRAVE
			for n in g.adjacent[p]:
				if g.cells[n].owner != g.active:
					frontier[n] = true
					if g.cells[n].owner == R.Island.NEUTRAL:
						open_frontier = true
		if g.cooperative and g.active < 2:
			troops = g.army(cap)
			frontier.clear()
			for p in g.supply_route(cap):
				for n in g.adjacent[p]:
					if g.cells[n].owner != g.active and (not g.allied(g.active,g.cells[n].owner) or g.claimable_allied_hex(g.active,n)):
						frontier[n] = true
		var ready_rank = 0
		# Clear sources that threaten open land before working into dense forest.
		var best_tree = R.NONE
		var tree_value = -7
		var tree_scores = {}
		# Recover when woods cost at least a spearman's wages and cover a
		# third of the holding. Small wooded pockets keep normal priorities.
		var forest_size = land.size() - budget.x
		var heavily_wooded = forest_size >= R.WAGES[R.SPEARMAN] and forest_size * 3 >= land.size()
		var expected_income = budget.x
		if difficulty == Difficulty.STANDARD and (cash >= 10 or troops.size() >= 2):
			expected_income = payday_income(g, land)
		var expected_surplus = expected_income - budget.y
		# At the next recruitment fee, restore income before rebuilding a costly army.
		var tight_payroll = budget.y >= R.WAGES[R.SPEARMAN] and expected_surplus <= 0
		var recovering_army = has_graves and expected_surplus <= R.WAGES[R.PEASANT]
		var recover_before_spending = difficulty == Difficulty.STANDARD and cash >= 10 and (tight_payroll or recovering_army)
		var forest_recovery = heavily_wooded and (hard or recover_before_spending)
		for tree in woods:
			var value = clearing_value(g, tree)
			if forest_recovery and R.is_tree(g.cells[tree].piece):
				value = 6 * forestry_value(g, tree) + next_clearing(g, tree)
				tree_scores[tree] = 78 + 4 * value
			if value > tree_value:
				tree_value = value
				best_tree = tree
		var holding_rank = 0
		var troops_by_rank = [0, 0, 0, 0, 0]
		var knight_broke_through = false
		var beside_baron_breach = {}
		var ready = [[], [], [], [], []]
		var deployed = 0
		var established_income = budget.x
		for unit in troops:
			var rank = g.cells[unit].piece
			troops_by_rank[rank] += 1
			holding_rank = maxi(holding_rank, rank)
			if g.cells[unit].spent:
				deployed += 1
				# A freshly taken or cleared hex may change hands before payday.
				established_income -= 1
				if g.cells[unit].get("breached", false):
					if rank == R.KNIGHT:
						knight_broke_through = true
					elif rank == R.BARON:
						for n in g.adjacent[unit]:
							beside_baron_breach[n] = true
			else:
				ready[rank].append(unit)
				ready_rank = maxi(ready_rank, rank)
		var capture_values = [0, 0, 0, 0, 0]
		var surplus = budget.x - budget.y
		if difficulty == Difficulty.STANDARD and not ready[R.PEASANT].is_empty() and surplus >= 0 and open_frontier:
			var post = interior_guard(g,cap,enemy_armies,breach_ranks,followups,ready[R.PEASANT],guards)
			# Just above an ordinary open-land capture. Rescues, village
			# links, attacking troops, and urgent forestry still take priority.
			if not post.is_empty() and highest < 40:
				best = post
				highest = 40
		if (difficulty == Difficulty.STANDARD and land.size() >= ESTABLISHED_CROSSING_LAND
				and holding_rank >= R.SPEARMAN and troops.size() >= 2
				and surplus >= 0 and cash >= 10 and cash + expected_surplus >= 15):
			for crossing in g.narrow_crossings:
				if g.capitals[crossing] != cap:
					continue
				var site = crossing_castle_site(g, cap, crossing, enemy_armies)
				if site == R.NONE:
					continue
				var fort = prepare_crossing_castle(g, cap, crossing, site, troops, guards) if cash >= 15 else []
				if fort.is_empty():
					# Save this village's next payday for the fort. Free orders
					# and purchases by the other villages still compete normally.
					cash = maxi(0, cash - 15)
				elif highest < CROSSING_FORT_PRIORITY:
					best = fort
					highest = CROSSING_FORT_PRIORITY
				break
		var growth_loss = budget.x - expected_income
		var last_unit = R.NONE
		if (difficulty == Difficulty.STANDARD and troops.size() - deployed == 1
				and cash < 10 and surplus < 0 and budget.y >= R.WAGES[R.SPEARMAN]):
			last_unit = ready[ready_rank][0]
			if troops.size() > 1 and guards_payroll(g, cap, last_unit):
				payroll_guards[last_unit] = true
		var wage_room = R.WAGES[R.BARON]
		# If buying leaves too little for a castle, a captured capital can
		# leave the army with only the surviving land to meet its next payroll.
		if difficulty == Difficulty.STANDARD and cash >= 10 and cash < 25 and budget.y >= DEFENSE_PAYROLL:
			if attacking_rank(g, cap, enemy_armies) > g.defense(cap):
				wage_room = maxi(0, payday_income(g, land) - 1 - budget.y)
		if tree_scores.has(best_tree):
			# A peasant deployed on the tree immediately adds one taxable hex.
			var hire_score = tree_scores[best_tree] - 12
			if can_pay(cash, 10, expected_surplus + 1, R.WAGES[R.PEASANT]) and hire_score > highest:
				best = ["recruit", cap, best_tree]
				highest = hire_score
		# Leave productive land to fund promotions. Filling the payroll with
		# peasants as soon as ten coins arrive prevents an army ever saving up.
		var force_limit = maxi(1, ceili(budget.x / 5.0))
		if hard:
			force_limit = 1 + floori(budget.x / 3.0)
		# Easy keeps two recruitment fees in reserve when expanding its army.
		var recruit_funds = cash - 20 if easy else cash
		var hiring_surplus = expected_surplus if forest_recovery else surplus
		var can_recruit = troops.size() < force_limit and can_pay(recruit_funds, 10, hiring_surplus, R.WAGES[R.PEASANT])
		var desired_rank = 0
		var spent_knights = troops_by_rank[R.KNIGHT] - ready[R.KNIGHT].size()
		var second_knight = knight_broke_through and spent_knights == 1 and troops_by_rank[R.BARON] == 0
		for target in frontier:
			var rescues_army = last_unit != R.NONE and cash + surplus < -1 and link_covers_payroll(g, last_unit, target)
			if last_unit != R.NONE and not rescues_army and gifts_productive_capitals(g, target):
				continue
			var threat = enemy_strength.get(g.capitals[target], 0)
			if difficulty == Difficulty.STANDARD and threat in [R.SPEARMAN, R.KNIGHT] and holding_rank <= threat:
				desired_rank = maxi(desired_rank, threat + 1)
			var guard = g.defense(target)
			# Easy prefers a lightly defended border. Each committed soldier makes
			# another attack from this village less attractive in the same turn.
			var value: int
			if easy:
				value = 52 - 6 * guard - 4 * R.guard(g.cells[target].piece) - 24 * deployed
			else:
				value = capture_value(g, target, cap) + 4 * guard
				if difficulty == Difficulty.STANDARD and fragile_extension(g,target,cap,breach_ranks):
					value -= 18
			if rescues_army:
				value += CAPITAL_BONUS
				payroll_links.append(["move", last_unit, target])
			var reply_rank = 0
			if hard:
				var frontier_eval = hard_frontier(g, cap, target, enemy_armies)
				value += frontier_eval.x
				reply_rank = frontier_eval.y
				if forest_recovery:
					if R.is_tree(g.cells[target].piece):
						value += 20 * forestry_value(g, target)
					elif g.capitals[target] != R.NONE:
						# Capturing productive enemy land also cuts its payroll.
						value += 24
			capture_values[guard] = maxi(capture_values[guard], value)
			for unit in troops:
				if payroll_guards.has(unit) and target not in g.adjacent[unit]:
					continue
				if g.legal("move",unit,target) and not leaves_crossing(g, guards, unit, target):
					var score = value - g.cells[unit].piece
					if hard:
						# Use the least costly soldier that can take the hex.
						score -= 8 * (g.cells[unit].piece - guard - 1)
						if forest_recovery and would_regrow(g,unit,target):
							score -= 46
					if hard and reply_rank > g.cells[unit].piece:
						score -= 10 * g.cells[unit].piece
					if easy and g.cells[target].piece == R.CAPITAL and target in g.adjacent[unit]:
						# Even a cautious soldier will notice a village right beside it.
						score += 16
					if score > highest:
						highest = score
						best = ["move",unit,target]
			var deployment_score = value - 12
			if hard and reply_rank > R.PEASANT:
				deployment_score -= 10
			if can_recruit and g.legal("recruit", cap, target) and deployment_score > highest:
				highest = deployment_score
				best = ["recruit", cap, target]
			# A second Knight can press another castle. Around a Baron's breach
			# the village may also need fresh recruits beyond its usual troop limit.
			var castle_assault = second_knight and guard == R.SPEARMAN and guarded_by_castle(g, target)
			var needs_support = guard == R.SPEARMAN or (guard < R.SPEARMAN and not can_recruit)
			var exploit_breach = beside_baron_breach.has(target) and needs_support
			var priority = value + CAPITAL_BONUS
			var blocked = hard and ready_rank <= guard and guard in [R.PEASANT, R.SPEARMAN, R.KNIGHT]
			if blocked and not (castle_assault or exploit_breach):
				priority = value - 2 * (guard + 1)
				# Capture open land with existing troops before funding a siege.
				priority -= 5 * guard
			if not easy and (castle_assault or exploit_breach or blocked) and ready_rank < R.BARON and priority > highest:
				var order = reinforce(cash, cap, target, guard + 1, ready, clearings,
					surplus, established_income, troops_by_rank, hard, growth_loss)
				if not order.is_empty() and g.legal(order[0],order[1],order[2]) and not payroll_guards.has(order[1]) and not leaves_crossing(g, guards, order[1], order[2]) and added_wages(g, order) <= wage_room:
					highest = priority
					best = order
		for unit in troops:
			if g.cells[unit].spent or payroll_guards.has(unit):
				continue
			var rank = g.cells[unit].piece
			if rank < R.BARON and g.legal("recruit", cap, unit):
				var extra = R.WAGES[rank + 1] - R.WAGES[rank]
				var prepare = desired_rank if surplus >= extra and rank + 1 > holding_rank else 0
				var score = upgrade_score(capture_values, ready_rank, rank + 1, prepare) - 2
				if score > highest and extra <= wage_room and can_promote(cash - 10, surplus, extra, rank + 1, established_income, troops_by_rank, growth_loss):
					highest = score
					best = ["recruit", cap, unit]
			for other in troops:
				var rank_sum = g.cells[unit].piece + g.cells[other].piece
				if g.cells[other].spent or rank_sum > R.BARON or not g.legal("move",unit,other) or leaves_crossing(g, guards, unit, other):
					continue
				var extra = R.WAGES[rank_sum] - R.WAGES[g.cells[unit].piece] - R.WAGES[g.cells[other].piece]
				if extra <= wage_room and can_promote(cash, surplus, extra, rank_sum, established_income, troops_by_rank, growth_loss):
					var prepare = desired_rank if surplus >= extra and rank_sum > holding_rank else 0
					var score = upgrade_score(capture_values, ready_rank, rank_sum, prepare)
					# A spearman can be an intermediate step against a knight or castle.
					if rank_sum == R.SPEARMAN and ready_rank == R.PEASANT and (capture_values[2] or capture_values[3]):
						score = maxi(score, 26)
					if score > highest:
						highest = score
						best = ["move",unit,other]
			var clear_score = 37 + tree_value * 4 + (5 if surplus <= 0 else 0)
			var destination = best_tree
			if not tree_scores.is_empty():
				# Compare destinations for this particular soldier. The tree beside
				# its old position may be the one that keeps that position clear.
				clear_score = 0
				for tree in tree_scores:
					var score = tree_scores[tree]
					if would_regrow(g,unit,tree):
						score -= 50
					if score > clear_score:
						clear_score = score
						destination = tree
			if destination != R.NONE and highest < clear_score and g.legal("move",unit,destination) and not leaves_crossing(g, guards, unit, destination):
				highest = clear_score
				best = ["move",unit,destination]
		if frontier.is_empty():
			continue
		# Protect a weak border when several friendly hexes benefit from a castle.
		var castle_reserve = 15 if hard else 25
		if cash >= castle_reserve and surplus >= 0:
			for p in clearings:
				var score = castle_value(g, p)
				if hard and score > 0:
					score += 32
				if score > highest and g.legal("build", cap, p):
					best = ["build", cap, p]
					highest = score
		var sites = clearings if not clearings.is_empty() else woods
		# Hard saves for a breach when its existing soldiers have no target.
		if hard and not troops.is_empty():
			continue
		if can_recruit and not sites.is_empty() and g.legal("recruit",cap,sites[0]) and highest < 25:
			best = ["recruit",cap,sites[0]]
			highest = 25
	if difficulty == Difficulty.STANDARD and not best.is_empty() and best[0] == "move":
		if payroll_guards.has(best[1]) or best in payroll_links:
			return best
		var clearing = preventive_clearing(g, best)
		return best if leaves_crossing(g, guards, clearing[1], clearing[2]) or not g.legal(clearing[0],clearing[1],clearing[2]) else clearing
	if difficulty == Difficulty.STANDARD and not best.is_empty() and best[0] == "recruit":
		var cap = g.capitals[best[1]]
		var cash = g.cells[cap].cash
		# This purchase would spend the last chance to fortify before the reply.
		if cash >= 15 and cash < 25:
			var castle = protective_castle(g, cap, enemy_armies, best)
			if not castle.is_empty():
				return castle
	return best

static func added_wages(g, order: Array) -> int:
	var moving = g.cells[order[1]].piece if order[0] == "move" else R.PEASANT
	var target = g.cells[order[2]]
	var resident = target.piece if target.owner == g.active and R.is_unit(target.piece) else 0
	return R.WAGES[moving + resident] - R.WAGES[resident] - (R.WAGES[moving] if order[0] == "move" else 0)
