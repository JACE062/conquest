extends SceneTree

const R = preload("res://game/rules.gd")
const AI = preload("res://game/opponent.gd")
var failures = 0
var checks = 0

func expect(condition, description):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL  ",description)

func tile(owner, piece = R.EMPTY, cash = 0):
	return {"owner":owner,"piece":piece,"cash":cash,"spent":false}

func line(pieces: Array):
	var data = {}
	for i in pieces.size():
		data[Vector2i(i,0)] = pieces[i]
	var g = R.new()
	g.setup(data,2)
	return g

func x(n): return Vector2i(n,0)

func _initialize():
	run_suite.call_deferred()

func run_suite():
	test_opening()
	test_opening_recruitment()
	test_reed_sound_opening()
	test_deployment()
	test_movement()
	test_bridge()
	test_economy()
	test_growth()
	test_elimination()
	test_surrender()
	await test_endgame_ui()
	test_unit_selection()
	await test_colors_and_territory()
	await test_map_navigation()
	test_difficulty_selector()
	await test_playable_islands()
	test_opponent()
	test_basin_payroll()
	test_crossing_defense()
	test_capture_costs()
	test_easy_spending()
	test_hard_strategy()
	test_standard_wooded_siege()
	test_hard_forest_recovery()
	test_knight_and_baron_promotions()
	test_breach_reinforcements()
	test_match()
	test_match(true)
	print("%s checks, %s failures" % [checks,failures])
	quit(1 if failures else 0)

func test_opening():
	var g = R.new_game()
	var isolated = {}
	for p in g.cells:
		var side = g.cells[p].owner
		if g.capitals[p] == R.NONE:
			isolated[side] = true
			expect(side >= 0 and side < g.players and g.cells[p].cash == 0, "isolated land retains its house without a treasury")
	expect(isolated.size() == 6, "each house starts with isolated land to reconnect")
	var pair_found = false
	for cap in g.lands:
		if g.cells[cap].owner != 0 and g.lands[cap].size() == 2 and g.finances(cap).x == 2:
			pair_found = true
			expect(g.cells[cap].cash == 8, "two clear hexes start with eight coins before income")
	expect(pair_found, "opening includes a two-hex holding awaiting its first income")

func test_crossing_defense():
	var cells = {x(0): tile(0)}
	for q in range(1,5):
		for r in range(3):
			cells[Vector2i(q,r)] = tile(0)
			cells[Vector2i(-q,-r)] = tile(1)
	var cap = Vector2i(3,2)
	var forest = Vector2i(4,0)
	var spear = Vector2i(4,2)
	cells[cap] = tile(0,R.CAPITAL)
	cells[x(1)] = tile(0,R.PEASANT)
	cells[spear] = tile(0,R.SPEARMAN)
	cells[spear].spent = true
	cells[forest] = tile(0,R.PALM)
	cells[x(-1)] = tile(1,R.CASTLE)
	cells[x(-3)] = tile(1,R.CAPITAL,10)
	var g = R.new()
	g.setup(cells,3)
	expect(g.narrow_crossings == [x(0)], "the two shores have exactly one passage")
	expect(g.legal("move",x(1),forest) and AI.choose(g).is_empty(),
		"the only ready guard holds the crossing against a funded enemy recruit")
	g.cells[x(0)].piece = R.PEASANT
	g.cells[x(0)].spent = true
	expect(AI.choose(g) == ["move",x(1),forest], "a second defender frees the first to clear woodland")
	g.cells[x(1)].piece = R.EMPTY
	g.cells[cap].cash = 15
	expect(AI.choose(g) != ["build",cap,x(1)], "under direct pressure the village keeps funds for a recruit")
	g.cells[x(-1)].owner = 2
	g.rebuild()
	g.cells[cap].cash = 13
	expect(g.legal("recruit",cap,forest) and AI.choose(g).is_empty(),
		"spent troops can wait one payday for an affordable approach castle")
	g.cells[cap].cash = 15
	expect(AI.choose(g) == ["build",cap,x(1)], "an established village builds one hex back to cover the passage")
	g.cells[x(1)].piece = R.PALM
	g.cells[spear].spent = false
	expect(AI.choose(g) == ["move",spear,x(1)], "the village clears a wooded castle site with an existing soldier")
	g.cells[x(1)].piece = R.EMPTY
	g.cells[spear].spent = true
	g.cells[x(-1)].owner = 1
	g.rebuild()
	g.cells[cap].cash = 30
	g.cells[x(-2)].piece = R.KNIGHT
	expect(AI.choose(g) != ["build",cap,x(1)], "a knight across the passage makes the crossing fort a poor purchase")
	g.cells[x(-1)] = tile(0)
	g.cells[x(-2)].piece = R.PEASANT
	g.rebuild()
	expect(AI.crossing_castle_site(g,cap,x(0),{x(-3): R.PEASANT}) == R.NONE,
		"an established village can spend elsewhere once it owns both banks")
	# A second route around the water makes the same two-neighbor hex optional.
	cells[Vector2i(0,3)] = tile(0)
	for r in range(1,4):
		cells[Vector2i(-2,r)] = tile(1)
	cells[Vector2i(-1,3)] = tile(1)
	g.setup(cells,2)
	expect(x(0) not in g.narrow_crossings, "a coastal tile with a bypass does not tie down a guard")

func test_opening_recruitment():
	for island in R.Island.MAPS:
		var layout = R.Island.MAPS[island]
		var g = R.new_game(layout[0], layout[1])
		for cap in g.lands:
			if g.cells[cap].owner == g.active:
				expect(not g.targets("recruit", cap).is_empty(),
					"%s village at %s can place a peasant after the opening payday" % [island, cap])

func test_reed_sound_opening():
	var layout = R.Island.MAPS["Reed Sound"]
	var g = R.new_game(layout[0], layout[1])
	var south = g.capitals[Vector2i(0,7)]
	var west = g.capitals[Vector2i(-2,6)]
	expect(south != R.NONE and west != R.NONE and south != west, "Reed Sound starts with two separate southwestern villages")
	expect(g.cells[south].owner == 0 and g.finances(south).x == 2 and g.cells[south].cash == 10,
		"Ochre's southern village can afford its first peasant after opening tree growth")
	expect(g.apply("recruit",south,Vector2i(-1,6)) and g.capitals[south] == g.capitals[west],
		"the southern village can recruit onto the bridge to join the two holdings on day one")

func test_deployment():
	var g = line([tile(0,R.CAPITAL,20),tile(0,R.CASTLE),tile(1),tile(0)])
	var before = g.cells.duplicate(true)
	expect(g.targets("build",x(0)).is_empty(), "a castle needs an empty friendly hex")
	expect(g.apply("recruit",x(0),x(2)), "a full territory can recruit directly onto an undefended frontier")
	expect(g.cells[x(2)].spent and g.cells[x(0)].cash == 10 and g.capitals[x(3)] == x(0), "deployment spends the action and connects isolated land")
	expect(g.apply("recruit",x(0),x(2)) and g.cells[x(2)].piece == R.SPEARMAN and g.cells[x(2)].spent, "a purchased upgrade inherits the spent action")
	g.restore(before)
	expect(g.cells == before and g.capitals[x(3)] == R.NONE, "undo restores the isolated hex and both purchases")
	g.cells[x(2)].piece = R.PEASANT
	expect(not g.apply("recruit",x(0),x(2)) and g.cells[x(0)].cash == 20,"direct purchase respects defense and leaves cash intact on refusal")
	var tree = line([tile(0,R.CAPITAL,10),tile(0,R.PINE)])
	expect(tree.apply("recruit",x(0),x(1)) and tree.cells[x(1)].spent, "recruit can clear woodland")

func test_movement():
	var g = line([tile(0,R.CAPITAL,30),tile(0,R.PEASANT),tile(0),tile(0),tile(1),tile(1,R.PEASANT),tile(1,R.CAPITAL)])
	expect(g.apply("move",x(1),x(2)) and g.apply("move",x(2),x(3)),"friendly moves may repeat")
	expect(not g.legal("move",x(3),x(4)),"equal adjacent defender holds")
	var before = g.cells.duplicate(true)
	expect(g.apply("recruit",x(0),x(1)) and g.cells[x(0)].cash == 20,"recruit costs ten")
	expect(g.apply("move",x(1),x(3)) and g.cells[x(3)].piece == R.SPEARMAN,"combine two peasants")
	expect(g.apply("move",x(3),x(4)),"first-turn attack from the territory")
	expect(not g.legal("move",x(4),x(5)),"one capture per turn")
	g.restore(before)
	expect(g.cells == before and g.capitals[x(3)] == x(0),"undo restores money, unit and territory")
	expect(g.apply("build",x(0),x(1)) and g.cells[x(0)].cash == 15 and g.defense(x(2)) == 2,"castle cost and defense")
	expect(g.defense(x(0)) == 2 and g.defense(x(5)) == 1,"friendly defenses take the maximum")
	var ranks = line([tile(0,R.CAPITAL),tile(0,R.SPEARMAN),tile(0,R.SPEARMAN),tile(0,R.PEASANT)])
	expect(ranks.apply("move",x(1),x(2)) and ranks.cells[x(2)].piece == R.BARON,"two spearmen form a baron")
	expect(not ranks.legal("move",x(3),x(2)),"four is maximum rank")
	var s = line([tile(0,R.CAPITAL),tile(0,R.PEASANT),tile(1),tile(1,R.CAPITAL)])
	expect(not s.legal("move",x(1),x(2)),"capital shields its neighbor")
	s.cells[x(1)].piece = R.SPEARMAN
	expect(s.apply("move",x(1),x(2)),"spearman breaks capital defense")
	var c = line([tile(0,R.CAPITAL),tile(0,R.KNIGHT),tile(1,R.CAPITAL,50),tile(1),tile(1)])
	expect(c.apply("move",x(1),x(2)) and c.cells[c.capitals[x(3)]].cash == 0,"captured treasury is destroyed")
	var spent = line([tile(0,R.CAPITAL),tile(0,R.PEASANT),tile(0,R.PEASANT)])
	spent.cells[x(2)].spent = true
	expect(spent.apply("move",x(1),x(2)) and spent.cells[x(2)].spent,"combining with an exhausted unit cannot grant another attack")

func test_bridge():
	var g = line([tile(0,R.CAPITAL,12),tile(0,R.KNIGHT),tile(1),tile(0),tile(0,R.CAPITAL,17),tile(0)])
	var middle = x(2)
	var north = Vector2i(2,-1)
	var south = Vector2i(2,1)
	var data = g.cells.duplicate(true)
	data[north] = tile(1,R.CAPITAL,20)
	data[north+Vector2i(0,-1)] = tile(1,R.SPEARMAN)
	data[south] = tile(1)
	data[south+Vector2i(0,1)] = tile(1,R.SPEARMAN)
	g.setup(data,2)
	var before = g.cells.duplicate(true)
	expect(g.apply("move",x(1),middle),"bridge capture succeeds")
	expect(g.capitals[x(0)] == x(4) and g.cells[x(4)].cash == 29,"larger capital holds both treasuries")
	expect(g.capitals[north] != g.capitals[south] and g.cells[north].cash == 20 and g.cells[g.capitals[south]].cash == 0,"split creates an unfunded holding")
	g.end_turn()
	expect(g.cells[north+Vector2i(0,-1)].piece == R.SPEARMAN and g.cells[north].cash == 16,"funded fragment pays wages")
	expect(g.cells[south+Vector2i(0,1)].piece == R.GRAVE,"unfunded fragment starves on its owner's turn")
	g.restore(before)
	expect(g.cells == before,"capture topology can be reconstructed from a snapshot")
	var tie = line([tile(0,R.CAPITAL,3),tile(0,R.KNIGHT),tile(1),tile(0),tile(0,R.CAPITAL,9)])
	tie.apply("move",x(1),x(2))
	expect(tie.capitals[x(2)] == x(4) and tie.cells[x(4)].cash == 12,"equal-size merger retains the last capital visited")
	# Island 1, day 2. From either origin the southeastern village survived.
	var southeast = Vector2i(2,2)
	var link = Vector2i(2,1)
	var equal_holdings = {x(0):tile(0,R.CAPITAL,1),Vector2i(0,1):tile(0),Vector2i(1,1):tile(0,R.PEASANT),
		link:tile(1),southeast:tile(0,R.CAPITAL,1),Vector2i(2,3):tile(0),Vector2i(2,4):tile(0,R.PEASANT)}
	for origin in [Vector2i(1,1),Vector2i(2,4)]:
		var replay = R.new()
		replay.setup(equal_holdings,2)
		expect(replay.apply("move",origin,link) and replay.capitals[link] == southeast and replay.cells[southeast].cash == 2, "reference three-hex merger works from either side")
	# Day 17. The traversal reaches the southern village first from the bridge.
	var northwest = Vector2i(-1,1)
	var bridge = Vector2i(0,2)
	var four_hex_holdings = {x(0):tile(0,R.BARON),northwest:tile(0,R.CAPITAL,4),Vector2i(0,1):tile(0),Vector2i(-1,2):tile(0),
		bridge:tile(1),Vector2i(1,2):tile(0),Vector2i(0,3):tile(0,R.CAPITAL,5),Vector2i(-1,4):tile(0),Vector2i(0,4):tile(0)}
	var reverse_tie = R.new()
	reverse_tie.setup(four_hex_holdings,2)
	expect(reverse_tie.apply("move",x(0),bridge) and reverse_tie.capitals[bridge] == northwest and reverse_tie.cells[northwest].cash == 9, "reference four-hex merger keeps the northwestern village")
	var rebuild = line([tile(0,R.PINE),tile(0),tile(0),tile(0,R.PEASANT)])
	expect(rebuild.capitals[x(0)] == x(1),"replacement capital prefers well-connected open ground")
	var long_holding = line([tile(0),tile(0),tile(0),tile(0),tile(0),tile(0),tile(0)])
	expect(long_holding.capitals[x(0)] == x(1),"first of the equally well-connected interior sites wins on a strip")
	for pieces in [[R.EMPTY,R.GRAVE,R.PINE],[R.GRAVE,R.PINE,R.CASTLE],[R.PINE,R.CASTLE,R.PEASANT],[R.CASTLE,R.PEASANT,R.PEASANT]]:
		var fragment = line([tile(0,pieces[0]),tile(0,pieces[1]),tile(0,pieces[2])])
		expect(fragment.capitals[x(1)] == x(0),"replacement site type takes priority over neighbor count")
	var cut = line([tile(0,R.CAPITAL),tile(0,R.KNIGHT),tile(1),tile(1,R.CAPITAL,7)])
	cut.apply("move",x(1),x(2))
	expect(cut.cells[x(3)].piece == R.PALM and cut.cells[x(3)].cash == 0, "a stranded coastal village immediately becomes a palm and loses its savings")

func test_economy():
	var g = line([tile(0,R.CAPITAL,1),tile(0,R.PEASANT),tile(0,R.SPEARMAN),tile(0,R.KNIGHT),tile(0,R.BARON),tile(0,R.CASTLE),tile(0,R.PINE)])
	expect(g.finances(x(0)) == Vector2i(6,80),"four wage tiers, free castle, no tree income")
	g.begin_turn()
	expect(g.cells[x(0)].cash == 0 and g.cells[x(4)].piece == R.GRAVE,"bankruptcy produces fresh graves")
	g.begin_turn()
	expect(g.cells[x(4)].piece == R.PALM,"coastal graves become palms next turn")
	var broke = line([tile(0,R.CAPITAL),tile(0,R.SPEARMAN),tile(0),tile(0)])
	broke.begin_turn()
	expect(broke.cells[x(1)].piece == R.GRAVE and broke.cells[x(0)].cash == 0,"four hexes cannot pay six wages")
	broke.begin_turn()
	expect(broke.cells[x(1)].piece == R.PALM and broke.cells[x(0)].cash == 3,"the converted grave already costs income that turn")

func test_growth():
	var g = line([tile(0,R.CAPITAL),tile(0,R.PALM),tile(0),tile(0),tile(0,R.PEASANT)])
	g.begin_turn()
	expect(g.cells[x(2)].piece == R.PALM and g.cells[x(3)].piece == R.EMPTY,"coastal growth is simultaneous")
	expect(g.apply("move",x(4),x(2)) and g.cells[x(2)].spent,"clearing spends the unit")
	var data = {Vector2i.ZERO:tile(0)}
	for d in R.DIRS:
		data[d] = tile(0)
	data[R.DIRS[0]] = tile(0,R.PINE)
	data[R.DIRS[1]] = tile(0,R.PINE)
	data[R.DIRS[2]] = tile(0,R.CAPITAL)
	g.setup(data,2)
	g.begin_turn()
	expect(g.cells[Vector2i.ZERO].piece == R.PINE,"two pines seed inland forest")
	g.cells[Vector2i.ZERO].piece = R.GRAVE
	g.begin_turn()
	expect(g.cells[Vector2i.ZERO].piece == R.PINE,"inland graves become pines")
	var grave = line([tile(0,R.CAPITAL),tile(0,R.PEASANT),tile(0,R.GRAVE)])
	expect(grave.apply("move",x(1),x(2)) and grave.cells[x(2)].spent,"clearing a grave uses an action")
	var shore = line([tile(0,R.CAPITAL),tile(0,R.PALM),tile(0),tile(1),tile(1,R.CAPITAL)])
	shore.begin_turn()
	shore.end_turn()
	expect(shore.cells[x(3)].piece == R.EMPTY,"a fresh palm cannot seed across the border on the next house's turn")
	shore.end_turn()
	shore.end_turn()
	expect(shore.cells[x(3)].piece == R.PALM,"the palm can seed the neighboring house after its owner's next growth phase")
	data[R.DIRS[3]] = tile(0,R.PALM)
	data.erase(R.DIRS[5])
	g.setup(data,2)
	g.begin_turn()
	expect(g.cells[Vector2i.ZERO].piece == R.PINE,"two mature pines take priority over a coastal palm")

func test_elimination():
	for piece in [R.EMPTY,R.PALM,R.GRAVE,R.CASTLE]:
		var remnant = line([tile(0,R.CAPITAL),tile(0),tile(1,piece)])
		expect(not remnant.can_take_turn(1) and not remnant.owns_island(0), "isolated land can outlast its house")
		remnant.end_turn()
		expect(remnant.active == 0 and remnant.round_number == 2, "a house with only an isolated hex or fort skips its turn")
	for rank in range(R.PEASANT,R.BARON+1):
		var g = line([tile(0,R.CAPITAL),tile(0),tile(1,rank)])
		expect(g.can_take_turn(1),"a cut-off soldier of any rank keeps its house in turn order")
		g.end_turn()
		expect(g.active == 1 and g.cells[x(2)].piece == R.GRAVE and not g.can_take_turn(1),"the last soldier gets its payday before elimination")
		g.end_turn()
		g.end_turn()
		expect(g.active == 0 and g.cells[x(2)].piece == R.PALM, "even a skipped house's graves age on schedule")

func test_surrender():
	# Eight isolated human hexes outnumber every rival more than three to one.
	var remnants = {}
	var owners = [0,1,1,0,2,0,3,0,4,0,5,0,2,0,3,0]
	for i in owners.size():
		remnants[x(i)] = tile(owners[i],R.PEASANT if i == 0 else R.EMPTY)
	var eliminated = R.new()
	eliminated.setup(remnants,6)
	eliminated.active = 5
	eliminated.end_turn()
	expect(eliminated.active == 0 and not eliminated.can_take_turn(0) and not eliminated.offer_surrender_on_end_turn(),
		"a final payday that kills the last soldier cannot award victory by surrender")
	eliminated.end_turn()
	expect(eliminated.active == 1, "the surviving village takes its turn after the last soldier falls")
	# Equal land ownership in both positions. Only one isolated pine changes.
	var data = {}
	for i in 24:
		data[x(i)] = tile(0)
	data[x(25)] = tile(0,R.PINE)
	for house in range(1,6):
		for i in 8:
			data[x(50 + house * 10 + i)] = tile(house)
	var g = R.new()
	g.setup(data,6)
	expect(not g.offer_surrender_on_end_turn(),"24 against 8 at exact equality produces no offer")
	g.cells[x(25)].piece = R.GRAVE
	expect(g.offer_surrender_on_end_turn(), "25 against 8 offers even with 40 enemy hexes combined; isolated graves count")
	g.decline_surrender()
	g.active = 1
	expect(not g.offer_surrender_on_end_turn(), "a computer never receives the human's offer")
	g.active = 0
	g.cells[x(25)].piece = R.PALM
	expect(not g.offer_surrender_on_end_turn(), "a turn below the threshold does not advance the refusal interval")
	g.cells[x(25)].piece = R.EMPTY
	for i in 3:
		expect(not g.offer_surrender_on_end_turn(), "three eligible turn endings pass after a refusal")
	expect(g.offer_surrender_on_end_turn(), "the fourth qualifying ending gets another offer")
	g.cells[x(62)].piece = R.KNIGHT
	g.cells[x(63)].piece = R.CASTLE
	g.cells[x(64)].piece = R.PINE
	g.cells[x(65)].piece = R.GRAVE
	g.accept_surrender()
	expect(g.owns_island(0) and g.cells[x(62)].piece != R.KNIGHT and g.cells[x(63)].piece != R.CASTLE, "acceptance transfers the island and removes enemy forces")
	expect(g.cells[x(64)].piece == R.PINE and g.cells[x(65)].piece == R.GRAVE, "woods and graves survive the transfer")

func test_endgame_ui():
	var scene = preload("res://game/main.gd").new()
	root.add_child(scene)
	var g = line([tile(0,R.CAPITAL),tile(0),tile(0),tile(0),tile(1,R.CASTLE)])
	scene.game = g
	scene.board.load_game(g)
	scene.select_largest()
	scene.check_result()
	expect(not scene.finished, "owning the only village does not itself win the island")
	scene.end_human_turn()
	expect(scene.surrender_dialog.visible and scene.end_button.disabled and g.round_number == 1, "an offer pauses the committed turn")
	scene.end_human_turn()
	scene.surrender_dialog.get_cancel_button().pressed.emit()
	await process_frame
	expect(not scene.finished and not scene.surrender_pending and g.round_number == 2, "Keep playing advances exactly once")
	for i in 4:
		scene.end_human_turn()
	scene.surrender_dialog.get_ok_button().pressed.emit()
	await process_frame
	expect(scene.finished and scene.result_dialog.visible and g.owns_island(0), "Accept surrender displays victory on the transferred island")
	scene.result_dialog.hide()
	scene.start()
	g = line([tile(0,R.CASTLE),tile(1,R.BARON),tile(1,R.CAPITAL)])
	g.active = 1
	scene.game = g
	scene.board.load_game(g)
	scene.select_largest()
	scene.check_result()
	scene.refresh()
	expect(not scene.finished and scene.turn_label.text == "SPECTATING", "a human with only a fort watches the surviving houses")
	scene._process(1.0)
	var winner = R.Island.HOUSES[scene.board.house_ids[1]]
	expect(scene.finished and g.owns_island(1) and winner in scene.result_dialog.dialog_text, "the last enemy capture names the winning computer house")
	scene.result_dialog.custom_action.emit("territory")
	expect(scene.territory_graph.visible and scene.territory_graph.current[0][1] == 3, "the final territory graph includes the winning capture")
	scene.territory_graph.get_ok_button().pressed.emit()
	await process_frame
	expect(scene.result_dialog.visible, "closing the final graph returns to the result")
	scene.free()

func test_opponent():
	var g = line([tile(1),tile(0,R.CAPITAL),tile(0,R.KNIGHT),tile(1,R.CAPITAL),tile(1)])
	expect(AI.choose(g) == ["move",x(2),x(3)],"AI chooses an exposed capital over an empty hex")
	expect(AI.choose(g,AI.Difficulty.STANDARD) == AI.choose(g),"default and Standard use the same orders")
	expect(AI.choose(g,AI.Difficulty.EASY) == ["move",x(2),x(3)],"Easy can punish an exposed village beside its soldier")
	var poor = line([tile(0,R.CAPITAL,10),tile(0,R.KNIGHT),tile(0),tile(1,R.BARON),tile(1,R.CAPITAL)])
	expect(AI.choose(poor).is_empty(),"AI preserves money needed for wages")
	var join = line([tile(1),tile(0,R.CAPITAL),tile(0,R.PEASANT),tile(1),tile(0),tile(0,R.CAPITAL)])
	expect(AI.choose(join) == ["move",x(2),x(3)],"AI prioritizes connecting friendly holdings")
	for defender in [R.CASTLE, R.KNIGHT]:
		var required = R.guard(defender) + 1
		var siege = line([tile(0,R.CAPITAL,400),tile(0,required - 1),tile(0,R.PEASANT),tile(1,defender),tile(1,R.CAPITAL)])
		var order = AI.choose(siege)
		expect(not order.is_empty() and siege.apply(order[0],order[1],order[2]) and siege.cells[order[2]].piece == required, "AI forms the rank needed to break a defended border")
		var attack = AI.choose(siege)
		expect(not attack.is_empty() and attack[2] == x(3) and siege.apply(attack[0],attack[1],attack[2]), "promoted soldier takes the defended hex")
	var insolvent = line([tile(0,R.CAPITAL),tile(0,R.KNIGHT),tile(0,R.PEASANT),tile(1,R.KNIGHT),tile(1,R.CAPITAL)])
	expect(AI.choose(insolvent).is_empty(), "AI declines a baron it cannot pay")

func test_unit_selection():
	var scene = preload("res://game/main.gd").new()
	root.add_child(scene)
	var g = line([tile(0,R.CAPITAL,20),tile(0),tile(0,R.PEASANT),tile(0),tile(1),tile(1,R.CAPITAL)])
	scene.game = g
	scene.board.load_game(g)
	scene.select_largest()
	scene.refresh()
	scene.choose_purchase("recruit", true)
	scene.board.cursor = x(1)
	var place = InputEventKey.new()
	place.keycode = KEY_ENTER
	place.pressed = true
	scene.board._gui_input(place)
	expect(scene.mode == "" and scene.board.legal_tiles.is_empty() and not g.cells[x(1)].spent, "placing a recruit releases it while keeping it ready")
	var shortcut = InputEventKey.new()
	shortcut.keycode = KEY_N
	shortcut.pressed = true
	shortcut.ctrl_pressed = true
	root.push_input(shortcut)
	expect(g.active == 0 and scene.history.size() == 1, "Ctrl+N does not commit the turn and discard undo")
	for key in [KEY_ENTER,KEY_SPACE]:
		place.keycode = key
		place.echo = true
		scene.board._gui_input(place)
		expect(scene.source == R.NONE and scene.history.size() == 1, "holding the placement key leaves the recruit released")
	scene.board.picked.emit(x(2))
	expect(scene.source == x(2) and g.cells[x(2)].piece == R.PEASANT, "the next click selects a second soldier")
	scene.board.picked.emit(x(3))
	expect(scene.source == R.NONE and scene.selected == x(0) and not g.cells[x(3)].spent, "repositioning releases the soldier and retains its territory")
	scene.board.picked.emit(x(3))
	scene.board.picked.emit(x(3))
	expect(scene.source == R.NONE and scene.history.size() == 2, "clicking the selected soldier sets it down without an order")
	scene.board.picked.emit(x(1))
	scene.board.picked.emit(R.NONE)
	expect(scene.mode == "" and scene.history.size() == 2, "clicking the sea cancels an order")
	scene.board.picked.emit(x(1))
	scene.board.picked.emit(x(3))
	expect(g.cells[x(3)].piece == R.SPEARMAN and scene.source == R.NONE, "an intentional merge completes and releases the merged unit")
	var board = scene.board
	board.hover(x(0), true)
	board.cursor = x(2)
	var right = InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.pressed = true
	board._gui_input(right)
	expect(scene.tile_info.text.contains("Spearman"), "keyboard inspection follows the outline to the merged soldier")
	scene.undo()
	expect(board.inspected_hex() == x(3) and scene.tile_info.text.contains("Peasant"), "undo describes the restored piece at the keyboard cursor")
	board.hover(x(0), true)
	expect(scene.tile_info.text.contains("Your capital"), "moving the mouse within its previous hex identifies the player's capital")
	board.hover(x(3), true)
	scene.choose_purchase("recruit", true)
	expect(scene.tile_info.text.contains("Your capital"), "keyboard recruitment inspects the newly focused capital")
	board.hover(x(3), true)
	scene.undo()
	expect(scene.tile_info.text.contains("Open land"), "a stationary pointer sees the new contents of an undone hex")
	for coins in [0, 1, 2]:
		g.cells[x(0)].cash = coins
		scene.refresh()
		expect(scene.cash_label.text == ["0 coins", "1 coin", "2 coins"][coins], "the treasury formats a balance of %d" % coins)
	scene.free()

func test_map_navigation():
	var scene = preload("res://game/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	var board = scene.board
	var island_sizes = {"Crown Harbour":353, "Osprey Sound":792, "Kettle Mere":780,
		"Gannet Keys":798, "Crookhorn Cape":804, "Alder Estuary":786}
	for island in island_sizes:
		var expected_size = island_sizes[island]
		scene.active_island = island
		scene.start()
		for frame in 3:
			await process_frame
		var fit_width = board.radius * sqrt(3.0)
		var whole_frame = scene.overview_frame()
		expect(board.zoom == 1.0 and scene.game.cells.size() == expected_size and scene.fit_button.disabled, "new board starts at fit on %d hexes" % expected_size)
		var central_hex = scene.selected
		for p in scene.game.cells:
			if board.center(p).distance_to(board.size * 0.55) < board.center(central_hex).distance_to(board.size * 0.55):
				central_hex = p
		var wheel = InputEventMouseButton.new()
		wheel.pressed = true
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.position = board.center(central_hex)
		wheel.factor = 120
		board._gui_input(wheel)
		expect(is_equal_approx(board.zoom,board.ZOOM_STEP), "a coarse wheel event advances one zoom step")
		wheel.factor = 1
		for i in 6:
			board._gui_input(wheel)
		expect(board.zoom == board.MAX_ZOOM and scene.zoom_in.disabled and not scene.fit_button.disabled, "wheel reaches maximum zoom")
		expect(board.hit(wheel.position) == central_hex and board.center(central_hex).distance_to(wheel.position) < 0.1, "pointer zoom keeps its hex in place")
		expect(scene.overview_frame().get_area() < whole_frame.get_area(), "minimap frame shrinks when zoomed in")
		var balances = scene.game.cells.duplicate(true)
		scene.choose_purchase("recruit")
		for mask in [MOUSE_BUTTON_MASK_RIGHT,MOUSE_BUTTON_MASK_MIDDLE]:
			var before_pan = board.view_center
			var drag = InputEventMouseMotion.new()
			drag.relative = Vector2(45,20)
			drag.position = wheel.position
			drag.button_mask = mask
			board._gui_input(drag)
			expect(board.view_center.is_equal_approx(before_pan - drag.relative / board.radius), "drag moves map by the pointer displacement")
		var mini = scene.overview_transform()
		var click = InputEventMouseButton.new()
		click.pressed = true
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = mini * board.extent.get_center()
		scene.overview.gui_input.emit(click)
		expect(scene.overview_frame().get_center().is_equal_approx(click.position), "minimap click centers the visible frame")
		var slide = InputEventMouseMotion.new()
		slide.position = click.position + Vector2(4,2)
		slide.button_mask = MOUSE_BUTTON_MASK_LEFT
		scene.overview.gui_input.emit(slide)
		expect(scene.overview_frame().get_center().is_equal_approx(slide.position), "minimap drag tracks the pointed-to area")
		expect(scene.game.cells == balances and scene.mode == "recruit" and scene.history.is_empty(), "navigation preserves pending orders, treasury and ownership")
		var can_reach_all = true
		for corner in [Vector2(-1,-1),Vector2(1,1),Vector2(-1,1),Vector2(1,-1)]:
			board.look_at_world(corner * 10000)
			var far_center = board.view_center
			board.look_at_world(corner * 20000)
			expect(board.view_center.is_equal_approx(far_center), "panning stops at the coast")
		for p in scene.game.cells:
			board.look_at_world(board.axial_center(p))
			can_reach_all = can_reach_all and board.hit(board.center(p)) == p
		expect(can_reach_all, "every zoomed hex is reachable and pickable on %d tiles" % expected_size)
		board.cursor = central_hex
		board.keyboard_cursor = true
		board.reveal_cursor()
		expect(board.hit(board.center(central_hex)) == central_hex, "keyboard navigation reveals an offscreen hex")
		var target = board.legal_tiles.keys()[0]
		board.look_at_world(board.axial_center(target))
		click.position = board.center(target)
		board._gui_input(click)
		expect(scene.game.cells[target].piece == R.PEASANT and scene.history.size() == 1, "left click after panning deploys the recruit to the intended hex")
		scene.undo()
		expect(scene.game.cells == balances and board.zoom == board.MAX_ZOOM, "undo restores the position and retains zoom")
		print("Map navigation: %d hexes, %.1f px at fit, %.1f px at maximum zoom" % [expected_size,fit_width,board.radius * sqrt(3.0)])
		if island == "Osprey Sound":
			board.look_at_world(board.extent.end)
			expect(board.hit(board.center(scene.selected)) == R.NONE, "the opening capital is offscreen at the far coast")
			board.keyboard_cursor = true
			scene.end_human_turn()
			while scene.game.active != 0:
				scene.next_player()
			expect(board.cursor == scene.selected and board.hit(board.center(board.cursor)) == board.cursor,
				"a new keyboard turn brings the selected capital into view at the existing zoom")
		scene.fit_button.pressed.emit()
		expect(board.zoom == 1.0 and scene.overview_frame().is_equal_approx(whole_frame), "Fit restores the full minimap frame")
	scene.free()

func test_colors_and_territory():
	var scene = preload("res://game/main.gd").new()
	root.add_child(scene)
	scene.set_process(false)
	var original = scene.game.cells.duplicate(true)
	for house in range(R.Island.HOUSES.size()):
		var expected = scene.board.house_ids.duplicate()
		var other_seat = expected.find(house)
		expected[other_seat] = expected[0]
		expected[0] = house
		scene.color_selector.select(house)
		scene.color_selector.item_selected.emit(house)
		expect(scene.board.house_ids == expected and scene.house_label.text == "House " + R.Island.HOUSES[house], "each house has a distinct map color and matching turn label")
		expect(scene.game.cells == original and scene.game.active == 0 and scene.history.is_empty(), "changing color preserves the match")
	scene.active_island = "Egret Delta"
	scene.start()
	expect(scene.color_selector.selected == 5 and scene.legend_labels[5].text == "Amber (you)", "the chosen house carries over to the next island")
	var opening = scene.game.cells.duplicate(true)
	for repeat in 5:
		var previous = scene.board.house_ids.duplicate()
		scene.start()
		var sorted = scene.board.house_ids.duplicate()
		sorted.sort()
		expect(sorted == range(6) and scene.board.house_ids[0] == 5, "each color appears once and the player keeps Amber")
		expect(scene.board.house_ids != previous and scene.game.cells == opening, "a fresh match shuffles opponent colors on the identical starting board")
	var g = line([tile(0,R.CAPITAL),tile(0,R.PEASANT),tile(1),tile(0),tile(1,R.CAPITAL),tile(1,R.PINE)])
	scene.game = g
	scene.board.load_game(g)
	scene.select_largest()
	var graph = scene.territory_graph
	graph.reset(g)
	scene.refresh()
	scene.show_territory()
	expect(not graph.visible and not scene.history_button.visible, "in-match comparison stays in the sidebar")
	expect(scene.land_bars[5].value == 2 and scene.land_values[5].text == "2" and g.territory_counts()[1][0] == 3, "live standings exclude isolated land")
	expect(scene.land_bars[scene.board.house_ids[1]].value == 2, "woodland counts in the opponent's village land")
	scene.pick(x(1))
	scene.pick(x(2))
	expect(scene.land_bars[5].value == 4 and scene.land_values[5].text == "4" and graph.completed[0][0][0] == 2, "capturing a bridge updates live bars and preserves the opening sample")
	scene.undo()
	expect(scene.land_bars[5].value == 2 and graph.completed.size() == 1, "undo restores live territory without adding history")
	scene.next_player()
	scene.next_player()
	expect(graph.completed.size() == 2 and graph.completed[1] == g.territory_counts(), "one historical sample is kept for each completed round")
	scene.finished = true
	scene.refresh()
	scene.history_button.pressed.emit()
	expect(graph.visible and graph.totals[0].text == "Amber (you)  2", "finished matches expose house history")
	graph.metric.select(1)
	graph.metric.item_selected.emit(1)
	expect(graph.totals[0].text == "Amber (you)  3", "postgame owned land includes isolated hexes")
	for frame in 3:
		await process_frame
	var dialog_bounds = Rect2(Vector2.ZERO, Vector2(graph.size))
	expect(dialog_bounds.encloses(graph.plot.get_global_rect()) and dialog_bounds.encloses(graph.totals[1].get_global_rect()), "the final plot and totals fit inside the graph window")
	graph.hide()
	scene.start()
	expect(graph.completed.size() == 1 and graph.completed[0] == scene.game.territory_counts(), "restart begins a fresh graph")
	await process_frame
	scene.free()

func test_difficulty_selector():
	var scene = preload("res://game/main.gd").new()
	root.add_child(scene)
	var selector = scene.difficulty_selector
	expect(selector.get_selected_id() == AI.Difficulty.STANDARD and not selector.disabled, "a new game starts on Standard")
	for tier in [AI.Difficulty.EASY, AI.Difficulty.STANDARD, AI.Difficulty.HARD]:
		var opening = scene.game.cells.duplicate(true)
		selector.select(selector.get_item_index(tier))
		expect(scene.game.cells == opening, "selecting a tier preserves the current board and treasury")
		scene.start()
		expect(selector.get_selected_id() == tier and scene.game.cells == R.new_game().cells, "restart retains the tier and normal opening")
		var g = line([tile(0),tile(1,R.KNIGHT),tile(1,R.CAPITAL),tile(0,R.CAPITAL),tile(0)])
		g.active = 1
		scene.game = g
		scene.board.load_game(g)
		scene.select_largest()
		scene.refresh()
		expect(selector.disabled, "difficulty stays fixed throughout computer turns")
		scene._process(1.0)
		var captured = x(0) if tier == AI.Difficulty.EASY else x(3)
		expect(g.cells[captured].owner == 1 and g.cells[captured].piece == R.KNIGHT, "the computer plays the selected strategy")
		scene.start()
	scene.free()

func test_playable_islands():
	var scene = preload("res://game/main.gd").new()
	root.add_child(scene)
	scene.set_process(false)
	var selector = scene.island_selector
	var sizes = scene.size_selector
	expect(sizes.selected == R.Island.Size.SMALL and scene.active_island == "Kestrel Strait", "Kestrel opens with the Small filter")
	expect(selector.item_count == R.Island.islands_of_size(R.Island.Size.SMALL).size(), "Small shows its islands")
	var original = scene.game
	sizes.select(R.Island.Size.EXTRA_LARGE)
	sizes.item_selected.emit(sizes.selected)
	expect(selector.item_count >= 5 and selector.get_item_text(0) == "Osprey Sound",
		"Extra Large offers Osprey Sound and four more playable islands")
	sizes.select(R.Island.Size.LARGE)
	sizes.item_selected.emit(sizes.selected)
	expect(selector.item_count >= 5, "the Large selector offers at least five playable islands")
	expect(sizes.text == "Large" and selector.get_item_text(0) == "Twinmere",
		"the Large size filter offers Twinmere")
	expect(scene.game == original and selector.selected == -1, "browsing Large keeps the current match")
	sizes.select(R.Island.Size.MEDIUM)
	sizes.item_selected.emit(sizes.selected)
	await process_frame
	var text_width = selector.get_theme_font("font").get_string_size(
		"Choose Island", HORIZONTAL_ALIGNMENT_LEFT, -1, selector.get_theme_font_size("font_size")).x
	var padding = selector.get_theme_stylebox("normal").get_minimum_size().x
	var arrow_width = selector.get_theme_icon("arrow").get_width() + selector.get_theme_constant("h_separation")
	expect(selector.text == "Choose Island" and selector.size.x >= text_width + padding + arrow_width,
		"the full island prompt fits beside the dropdown arrow")
	expect(scene.game == original and not scene.restart_dialog.visible and selector.selected == -1, "browsing Medium preserves the current game")
	expect(selector.item_count >= 5, "the Medium selector offers at least five playable islands")
	expect(selector.item_count == R.Island.islands_of_size(R.Island.Size.MEDIUM).size() and selector.get_item_text(0) == "Heron Lake", "Medium offers Heron Lake")
	selector.select(0)
	selector.item_selected.emit(0)
	expect(scene.restart_dialog.visible and scene.game == original, "choosing the medium island requests confirmation")
	scene.restart_dialog.get_cancel_button().pressed.emit()
	await process_frame
	expect(sizes.selected == R.Island.Size.SMALL and selector.text == scene.active_island and scene.game == original, "cancel restores both filters and the match")
	selector.item_selected.emit(1)
	scene.restart_dialog.get_cancel_button().pressed.emit()
	await process_frame
	expect(scene.game == original and selector.selected == 0, "canceling an island switch preserves the match")
	for tier in [AI.Difficulty.EASY, AI.Difficulty.STANDARD, AI.Difficulty.HARD]:
		scene.difficulty_selector.select(scene.difficulty_selector.get_item_index(tier))
		for island in R.Island.MAPS:
			var island_size = R.Island.MAPS[island][2]
			if sizes.selected != island_size:
				sizes.select(island_size)
				sizes.item_selected.emit(island_size)
			var index = R.Island.islands_of_size(island_size).find(island)
			expect(selector.get_item_text(index) == island, "%s appears in its size group" % island)
			if island == scene.active_island:
				scene.ask_restart()
			else:
				selector.select(index)
				selector.item_selected.emit(index)
			scene.restart_dialog.get_ok_button().pressed.emit()
			await process_frame
			var layout = R.Island.MAPS[island]
			var opening = R.new_game(layout[0],layout[1]).cells
			expect(scene.game.cells == opening and scene.active_island == island and selector.selected == index, "selector loads %s from its benchmark opening" % island)
			expect(scene.difficulty_selector.get_selected_id() == tier and scene.history.is_empty(), "switching starts a fresh match at the chosen difficulty")
			scene.end_human_turn()
			for i in 250:
				if scene.game.active == 0:
					break
				scene._process(1.0)
			expect(scene.game.active == 0 and scene.game.round_number == 2, "five opponents return play on %s" % island)
			scene.ask_restart()
			scene.restart_dialog.get_ok_button().pressed.emit()
			await process_frame
			expect(scene.game.cells == opening and scene.active_island == island and sizes.selected == island_size, "restart restores the selected island and size")
	scene.free()

func test_hard_strategy():
	var border = line([tile(1,R.CAPITAL),tile(1,R.SPEARMAN),tile(1),tile(1),
		tile(0,R.PEASANT),tile(0,R.CAPITAL),tile(1),tile(1),tile(1,R.CAPITAL)])
	expect(border.legal("move",x(4),x(3)) and border.legal("move",x(4),x(6)), "both frontier captures are legal")
	expect(AI.choose(border,AI.Difficulty.HARD) == ["move",x(4),x(6)], "Hard takes the flank beyond the enemy spearman's reach")
	var village = line([tile(0,R.CAPITAL,20),tile(0,R.PEASANT),tile(0),tile(0),tile(0),tile(1),tile(1),tile(1,R.CAPITAL)])
	village.cells[x(1)].spent = true
	expect(AI.choose(village,AI.Difficulty.STANDARD).is_empty(), "Standard holds its existing garrison")
	var action = AI.choose(village,AI.Difficulty.HARD)
	expect(action == ["recruit",x(0),x(5)] and village.apply(action[0],action[1],action[2]), "Hard funds another soldier for a productive frontier")
	expect(village.cells[x(0)].cash == 10 and village.finances(x(0)).y == 4, "Hard pays the usual recruitment fee and wages")
	var siege = line([tile(0,R.CAPITAL,65),tile(0),tile(0,R.PEASANT),tile(1,R.CASTLE),tile(1,R.CAPITAL)])
	for i in 3:
		var order = AI.choose(siege,AI.Difficulty.HARD)
		if order.is_empty() or not siege.apply(order[0],order[1],order[2]):
			expect(false, "Hard can carry out each order in its funded castle attack")
			return
	expect(siege.cells[x(3)].owner == 0 and siege.cells[x(3)].piece == R.KNIGHT and siege.cells[x(0)].cash == 45,
		"Hard funds two upgrades and takes the castle in the same turn")

func test_standard_wooded_siege():
	# Rose has one recruitment fee and a spearman facing a castle. Pairs of
	# empty coastal hexes between palms look productive until the next payday.
	var pieces = [tile(0,R.CAPITAL), tile(0,R.CASTLE), tile(1,R.CAPITAL,10), tile(1,R.SPEARMAN)]
	for i in range(2,58):
		pieces.append(tile(1, R.PALM if i % 3 == 0 else R.EMPTY))
	var g = line(pieces)
	g.active = 1
	var before = g.cells.duplicate(true)
	var cap = x(2)
	expect(g.finances(cap) == Vector2i(39,6), "Rose has enough apparent income to attack the castle")
	expect(g.apply("recruit",cap,x(3)) and g.apply("move",x(3),x(1)), "the immediate Knight assault is legal")
	g.begin_turn()
	expect(g.cells[x(1)].piece == R.GRAVE, "the Knight starves after taking the castle even without a counterattack")
	g.restore(before)
	var order = AI.choose(g)
	expect(order.size() == 3 and order[0] == "move" and order[1] == x(3) and g.cells[order[2]].piece == R.PALM,
		"Standard uses the ready spearman to clear a palm before spending on the siege")
	finish_ai_turn(g)
	g.begin_turn()
	expect(g.finances(cap) == Vector2i(8,8), "the restored income pays the spearman and peasant at the next payday")
	g.restore(before)
	for p in g.cells:
		if g.cells[p].piece == R.PALM:
			g.cells[p].piece = R.PINE
	finish_ai_turn(g)
	g.begin_turn()
	expect(g.cells[x(1)].owner == 1 and g.cells[x(1)].piece == R.KNIGHT,
		"on the same border with stable income Rose takes the castle and pays the Knight")

	var depleted = line([tile(1,R.CAPITAL,10),tile(1,R.GRAVE),tile(1,R.PINE),tile(1,R.PINE),
		tile(1,R.PINE),tile(1,R.PINE),tile(1,R.PINE),tile(1,R.PINE),tile(0,R.PINE),tile(0),tile(0,R.CAPITAL)])
	depleted.active = 1
	order = AI.choose(depleted)
	expect(order.size() == 3 and order[0] == "recruit" and depleted.cells[order[2]].owner == 1
		and R.is_tree(depleted.cells[order[2]].piece), "with fresh graves Rose hires onto its own woodland")
	finish_ai_turn(depleted)
	depleted.begin_turn()
	expect(depleted.finances(x(0)) == Vector2i(2,2), "two productive hexes pay the new forester")

func test_hard_forest_recovery():
	var pieces = [tile(0,R.CAPITAL,10)]
	for i in 8:
		pieces.append(tile(0,R.PINE))
	pieces.append_array([tile(1,R.PINE),tile(1),tile(1,R.CAPITAL)])
	var g = line(pieces)
	expect(g.legal("recruit",x(0),x(9)), "the forested village could raid the enemy border")
	var order = AI.choose(g,AI.Difficulty.HARD)
	expect(order.size() == 3 and order[0] == "recruit" and g.cells[order[2]].owner == 0 and R.is_tree(g.cells[order[2]].piece),
		"Hard can spend its first ten coins clearing its own forest")
	if order.is_empty():
		return
	expect(g.apply(order[0],order[1],order[2]), "the recovery recruit uses an ordinary legal order")
	g.begin_turn()
	expect(g.finances(x(0)) == Vector2i(2,2) and g.cells[x(0)].cash == 0, "the cleared hex supports its worker at payday")
	var worker = order[2]
	order = AI.choose(g,AI.Difficulty.HARD)
	expect(not order.is_empty() and g.apply(order[0],order[1],order[2]), "the forester can extend the clearing")
	g.begin_turn()
	expect(g.cells[worker].piece == R.EMPTY and g.finances(x(0)).x >= 3, "the vacated clearing still earns income on the next payday")

func test_easy_spending():
	var village = line([tile(0,R.CAPITAL,20),tile(0),tile(1),tile(1),tile(1,R.CAPITAL)])
	expect(village.legal("recruit",x(0),x(2)) and AI.choose(village,AI.Difficulty.EASY).is_empty(),
		"Easy voluntarily saves even when a ten-coin capture is legal")
	village.cells[x(0)].cash = 30
	expect(AI.choose(village,AI.Difficulty.EASY) == ["recruit",x(0),x(2)], "Easy can recruit directly onto an open frontier")
	for defender in [R.CASTLE, R.KNIGHT]:
		var rank = R.guard(defender) + 1
		var siege = line([tile(0,R.CAPITAL,400),tile(0,rank-1),tile(0,R.PEASANT),tile(1,defender),tile(1,R.CAPITAL)])
		var merge = AI.choose(siege,AI.Difficulty.EASY)
		expect(not merge.is_empty() and siege.apply(merge[0],merge[1],merge[2]) and siege.cells[merge[2]].piece == rank,
			"Easy can field the required Knight or Baron")
		var attack = AI.choose(siege,AI.Difficulty.EASY)
		expect(not attack.is_empty() and attack[2] == x(3) and siege.apply(attack[0],attack[1],attack[2]),
			"Easy can break the defended border")

func test_knight_and_baron_promotions():
	# Use the opening ledgers of the Windows replays on a single defended border.
	var early_army = [R.SPEARMAN,R.SPEARMAN,R.PEASANT,R.PEASANT,R.PEASANT,R.PEASANT]
	var knight_army = [R.KNIGHT,R.PEASANT,R.PEASANT,R.PEASANT,R.PEASANT,R.PEASANT]
	for situation in [
		[3,200,[R.KNIGHT,R.PEASANT],R.KNIGHT,false],
		[3,400,[R.KNIGHT,R.PEASANT],R.KNIGHT,true],
		[36,33,early_army,R.CASTLE,false],
		[40,32,[R.SPEARMAN,R.SPEARMAN,R.SPEARMAN,R.SPEARMAN,R.PEASANT,R.PEASANT],R.CASTLE,true],
		[96,69,knight_army,R.KNIGHT,false],
		[96,228,knight_army,R.KNIGHT,true],
		[114,87,knight_army,R.KNIGHT,false],
		[114,246,knight_army,R.KNIGHT,true],
	]:
		var income = situation[0]
		var treasury = situation[1]
		var defender = situation[3]
		var pieces = [tile(0,R.CAPITAL,treasury)]
		for rank in situation[2]:
			pieces.append(tile(0,rank))
		while pieces.size() < income:
			pieces.append(tile(0))
		pieces.append_array([tile(1,defender),tile(1,R.CAPITAL)])
		var g = line(pieces)
		var promoted = false
		for i in 100:
			var order = AI.choose(g)
			if order.is_empty() or g.cells[x(income)].owner == 0:
				break
			var combining = g.cells[order[2]].owner == 0 and R.is_unit(g.cells[order[2]].piece)
			expect(g.apply(order[0],order[1],order[2]), "promotion replay orders are legal")
			if combining and g.cells[order[2]].piece > R.guard(defender):
				promoted = true
		expect(promoted == situation[4] and (g.cells[x(income)].owner == 0) == situation[4],
			"promotion against %s with %d income and %d savings" % [R.PIECES[defender],income,treasury])
	var shop = line([tile(0,R.CAPITAL,400),tile(0,R.KNIGHT),tile(1,R.KNIGHT),tile(1,R.CAPITAL)])
	expect(AI.choose(shop) == ["recruit",x(0),x(1)], "a well-funded holding can buy the final rank onto a knight")

func finish_ai_turn(g):
	for i in 60:
		var order = AI.choose(g)
		if order.is_empty():
			return
		if not g.apply(order[0], order[1], order[2]):
			expect(false, "AI turn uses legal orders")
			return
	expect(false, "AI finishes the turn within the order limit")

func test_basin_payroll():
	var layout = R.Island.MAPS["The Basin"]
	for opening in [Vector2i(4, 1), Vector2i(1, 3)]:
		var g = R.new_game(layout[0], layout[1])
		expect(g.apply("recruit", Vector2i(3, 1), opening), "Basin replay starts with a legal capture")
		var capital_raid = opening == Vector2i(4, 1)
		var payday = 12 if capital_raid else 15
		while g.round_number < payday and g.can_take_turn(0):
			finish_ai_turn(g)
			g.end_turn()
		var wages = 0
		for cap in g.lands:
			if g.cells[cap].owner == 0:
				wages += g.finances(cap).y
		expect(g.active == 0 and g.round_number == payday and wages > 0,
			"Ochre still has a paid army after the Basin capital raid or treasury split")
		if not capital_raid:
			var bridge = g.cells[Vector2i(4, 8)]
			expect(bridge.owner == 0 and bridge.piece == R.CASTLE,
				"Standard fortifies the southern connection before spending the castle money on a recruit")
		else:
			while g.round_number < 20 and g.can_take_turn(0):
				finish_ai_turn(g)
				g.end_turn()
			var budget = Vector2i.ZERO
			for cap in g.lands:
				if g.cells[cap].owner == 0:
					budget += g.finances(cap)
			expect(g.round_number == 20 and budget.x >= 7 and budget.y > 0,
				"early clearing keeps taxable land and a paid army in the shared Basin opening on day 20")
			while g.round_number == 20:
				finish_ai_turn(g)
				g.end_turn()
			var spear = Vector2i(1, 6)
			expect(g.cells[spear].owner == 0 and g.cells[spear].piece == R.SPEARMAN,
				"the peasant keeps the Basin spearman connected through the day-21 payday")

	# A neighboring castle has the same defense as a spearman, but cannot raid.
	var pieces = [tile(1,R.CAPITAL), tile(1,R.SPEARMAN), tile(0,R.CAPITAL,20)]
	while pieces.size() < 20:
		pieces.append(tile(0))
	pieces.append_array([tile(0,R.KNIGHT), tile(0,R.PEASANT)])
	var g = line(pieces)
	g.cells[x(20)].spent = true
	g.cells[x(21)].spent = true
	expect(AI.choose(g) == ["build", x(2), x(3)],
		"Standard guards an exposed capital when losing it would bankrupt the army")
	g.cells[x(1)].piece = R.CASTLE
	expect(AI.choose(g) == ["recruit", x(2), x(3)],
		"a stationary enemy castle does not trigger the capital defense")

func test_capture_costs():
	var rescue = line([tile(1), tile(1,R.CAPITAL), tile(0,R.SPEARMAN), tile(0,R.CAPITAL),
		tile(1), tile(0,R.CAPITAL,3), tile(0)])
	var before = rescue.cells.duplicate(true)
	var order = AI.choose(rescue)
	expect(rescue.cells == before, "previewing a capture preserves the live board and treasuries")
	expect(order == ["move", x(2), x(4)], "a spearman facing bankruptcy captures the link to a solvent village")
	if order.size() == 3 and rescue.apply(order[0],order[1],order[2]):
		rescue.begin_turn()
		expect(rescue.cells[x(4)].piece == R.SPEARMAN, "the joined treasury actually pays the spearman")

	var woods = line([tile(1,R.PINE), tile(1,R.PINE), tile(1,R.CAPITAL), tile(1,R.PINE), tile(1,R.PINE)])
	var map = woods.cells.duplicate(true)
	var unit = Vector2i(2,1)
	map[unit] = tile(0,R.SPEARMAN)
	map[Vector2i(2,2)] = tile(0,R.CAPITAL)
	woods.setup(map,2)
	var raid = ["move", unit, x(2)]
	expect(woods.legal("move", unit, x(2)) and AI.choose(woods) != raid,
		"a struggling village avoids giving its rival two productive replacement capitals")
	woods.cells[x(1)].piece = R.EMPTY
	expect(AI.choose(woods) == raid, "a split with no net gain in enemy production remains a worthwhile raid")
	map[x(0)] = tile(1,R.CAPITAL)
	map[x(2)] = tile(1,R.PINE)
	woods.setup(map,2)
	expect(AI.gifts_productive_capitals(woods, x(2)), "cutting a wooded bridge can give the defender taxable land")
	expect(woods.apply("move", unit, x(2)) and woods.cells[x(0)].piece == R.CAPITAL
		and woods.lands.size() == 3, "the wooded bridge raid creates an extra enemy capital")

func test_breach_reinforcements():
	var breach = line([tile(0,R.CAPITAL,400),tile(0,R.BARON),tile(1,R.KNIGHT),
		tile(1,R.SPEARMAN),tile(1,R.CAPITAL),tile(1)])
	var flank = Vector2i(2,1)
	var map = breach.cells.duplicate(true)
	map[flank] = tile(1)
	breach.setup(map, 2)
	var opening = breach.cells.duplicate(true)
	finish_ai_turn(breach)
	expect(breach.cells[x(2)].piece == R.BARON and breach.cells[x(2)].owner == 0, "Baron opens the defended border")
	expect(breach.cells[x(3)].piece == R.KNIGHT and breach.cells[x(3)].owner == 0, "small rich village fields a Knight through the breach")
	expect(breach.cells[flank].piece == R.PEASANT and breach.cells[flank].owner == 0, "village sends a Peasant when the Knight removes the flank's defense")
	breach.restore(opening)
	expect(breach.cells == opening, "undo restores the defenders and clears breach information")

	for coins in [60, 240]:
		var siege = line([tile(1,R.CAPITAL),tile(1,R.CASTLE),tile(0,R.CAPITAL,coins),
			tile(0,R.KNIGHT),tile(1),tile(1,R.CASTLE),tile(1,R.CAPITAL)])
		expect(siege.apply("move", x(3), x(1)), "first Knight takes a castle")
		finish_ai_turn(siege)
		if coins == 240:
			expect(siege.cells[x(4)].piece == R.KNIGHT and siege.cells[x(4)].owner == 0, "second Knight takes the approach to another castle")
		else:
			expect(siege.cells[x(2)].cash == coins and siege.cells[x(4)].owner == 1, "village avoids starting a second Knight it cannot sustain")
		siege.begin_turn()
		expect(not siege.cells[x(1)].has("breached"), "a past breakthrough expires at payday")

	var open_border = line([tile(1,R.CAPITAL),tile(1),tile(0,R.CAPITAL,240),
		tile(0,R.KNIGHT),tile(1),tile(1,R.CASTLE),tile(1,R.CAPITAL)])
	expect(open_border.apply("move", x(3), x(1)), "Knight takes a lightly defended hex")
	finish_ai_turn(open_border)
	expect(open_border.cells[x(2)].cash == 240 and open_border.cells[x(4)].owner == 1, "an ordinary capture keeps the usual recruitment limit")

func test_match(pass_human = false):
	var g = R.new_game()
	expect(g.cells == R.new_game().cells,"repeatable island and opening finances")
	var moves = 0
	var turns = 0
	var seen = {}
	var spectated = false
	while turns < 600 and not g.owns_island(g.active):
		seen[g.active] = true
		var orders = 0
		while orders < 300 and not (pass_human and g.active == 0):
			var action = AI.choose(g)
			if action.is_empty():
				break
			if not g.apply(action[0],action[1],action[2]):
				expect(false,"AI order must be legal")
				return
			orders += 1
		expect(orders < 300,"AI turn terminates")
		moves += orders
		if not g.can_take_turn(0) and not g.owns_island(g.active):
			spectated = true
		if not g.owns_island(g.active):
			g.end_turn()
		turns += 1
	expect(seen.size() == 6 and g.owns_island(g.active),"six factions complete a whole-island match")
	if pass_human:
		expect(spectated and g.active != 0,"the computers finish a match after eliminating a passive human")
	print("Simulation: ",turns," turns, ",moves," orders, leading faction ",g.active)
