# Opponent difficulty

All three tiers use the same opening, legal moves, income, prices, wages, promotions and victory conditions. Standard weighs the next payroll when its capital or a connection to its army is exposed. Easy prefers open borders, notices an exposed capital beside a ready soldier, and gives successive attacks from the same village lower priority. It budgets a 20-coin reserve when deciding whether to hire another soldier. It still merges units and buys upgrades when it needs to overcome a defense.

## How does Hard compare with Standard?

Hard gives extra weight to captures that join villages, protect adjacent land, or destroy an enemy soldier. When two captures look equally valuable, it favors the flank where an enemy army is less likely to retake the hex. It fields more peasants when they can gain ground and can pay for several upgrades to breach a defense if its treasury and income cover three paydays.

Each island hosted 20 six-house games covering every way to assign three seats to each tier. A second test rotated a single Standard player through all six starting seats against five Hard opponents. That player passed its first two turns, then played normally and accepted surrender when offered.

| Island | Hard wins | Standard wins | Unfinished at 900 turns | Missed-opening player wins against Hard | Against Standard |
| --- | ---: | ---: | ---: | ---: | ---: |
| Kestrel Strait | 11 | 8 | 1 | 1/6 | 2/6 |
| The Narrows | 10 | 10 | 0 | 0/6 | 1/6 |
| The Basin | 6 | 2 | 12 | 0/6 | 1/6 |
| Reed Sound | 13 | 7 | 0 | 1/6 | 0/6 |
| **All four** | **40** | **27** | **13** | **2/24** | **4/24** |

The missed-opening player averaged 9.3 village-supported hexes on day eight against Hard and 12.3 against Standard. All 24 games against Hard finished. Four against Standard reached the limit.

```powershell
godot --headless -s tests/difficulty_benchmark.gd -- --hard
```

## Why did Basin games run out of turns?

In all 16 original timeouts, the houses were still capturing land. Each game recorded 44–78 captures in its last 60 active turns. In one replay there were 70 captures across just 34 hexes. Dense pines and coastal palms left villages with little taxable land, and moving a soldier off a clearing could let it regrow before payday. Taking another border hex often failed to fund the next soldier.

We saved each game before active turn 841 and ran both versions forward from the same position. Here are three of the first decisions where Hard changed its move. Income and wages are coins per payday.

| Replay | Holding at the decision | Earlier Hard move | Tuned Hard move | Outcome from the checkpoint |
| --- | --- | --- | --- | --- |
| 28, turn 846 | Amber, 43 hexes, 4 income, 4 wages, 0 coins | Capture an Azure pine | Use that soldier to clear a pine at home | Amber conquered on turn 1,148 |
| 38, turn 848 | Ochre, 18 hexes, 3 income, 0 wages, 12 coins | Hire a peasant on a Rose pine | Hire it on an Ochre palm | Ochre conquered on turn 1,626 |
| 41, turn 842 | Rose, 7 hexes, 1 income, 0 wages, 10 coins | Pass | Hire a peasant on a friendly palm. Clearing it provides the second coin for wages. | Still unfinished at turn 1,740 |

Hard now considers recovery when at least six hexes and a third of a holding are wooded. It weighs which trees threaten taxable land, whether a second cut could keep a clearing open, and whether the soldier’s old hex would regrow. From the 16 saved positions, tuned Hard won five by turn 1,740 (replays 25, 28, 38, 50 and 56). All 16 controls with the earlier Hard were still playing at that same limit.

Replaying from the **opening** with the original 900-turn limit answered a different question. Five former Basin timeouts became Hard wins (7, 25, 35, 38 and 56), and the four previously completed games kept their winners. With the island layouts used for that comparison, Hard went from 40 to 46 wins, Standard from 18 to 21, and unfinished games from 22 to 13. One previous Hard win on Kestrel timed out. On the original Reed Sound layout four Hard wins went to Standard while one Standard win went to Hard.

The stalemate experiments above used the original Basin layout. To inspect the same seat assignment on the current layout, use its seat mask. Each bit assigns Standard to a house in turn order (Ochre 1, Rose 2, Sage 4, Azure 8, Heather 16, Amber 32). The remaining three seats play Hard. A timeout prints its final 60 turns’ capture count, distinct captured hexes, and village finances.

```powershell
godot --headless -s tests/difficulty_benchmark.gd -- --hard --replay=28 "The Basin"
```

## Reed Sound’s opening on Standard

The palm at axial (0, 8) used to seed Ochre’s southern two-hex village before the player’s first move. Its eight coins in savings earned just one more at payday. Moving that palm three hexes east to isolated coastal land at (3, 8) gives the village two income and ten coins. Ochre can now recruit from all three villages, including onto the hex that connects the two southwestern holdings. All six houses kept their starting land and villages. Rotating each house into the first seat showed that the other five kept their original day-one income.

We replayed every first-turn peasant capture available to Ochre on both layouts. Each of the 11 matched orders uses the same treasury and destination in both games. Five Standard opponents played normally throughout. After the first purchase, Ochre either finished day one using Standard strategy or ended the turn immediately. It used Standard strategy from day two onward and accepted surrender. The land counts are medians at the start of day eight and the wins are deterministic replay outcomes.

| Ochre’s opening | Day-eight village land before → after | Wins before → after |
| --- | ---: | ---: |
| Finish day one with Standard | 16 → 17 | 3/11 → 4/11 |
| End day one after the first purchase | 10 → 16 | 0/11 → 4/11 |

The southern village adds three more first-purchase options. Across all 14 revised openings, ending day one after the first purchase produced five wins. Passing both opening turns still lost against Standard in all six seat rotations.

## First-turn recruitment on the other islands

We checked each Ochre treasury after opening growth and payday, then asked the game for its legal peasant placements. Two villages fell below the ten-coin price.

| Island | Villages able to recruit before → after | Opening finding |
| --- | ---: | --- |
| Kestrel Strait | 4/5 → 5/5 | A palm inside the central two-hex village cut both starting savings and income, leaving five coins. Moving it from (7, 4) to (1, 2) gives the village ten. The northern four-hex village still starts with a palm and can recruit with 15 coins. |
| The Narrows | 3/4 → 4/4 | A palm at (11, 4) spread into the eastern two-hex village before payday, leaving nine coins. Moving it to (5, 7) restores the tenth coin. |
| The Basin | 3/3 | All three villages start clear, with 10, 15 and 15 coins. Each has at least three legal first-turn captures. |

Both relocated palms occupy isolated coastal hexes. Rotating each house into the first seat confirmed that every other village could start with at least its previous treasury. The table below compares the same first-purchase captures on both layouts, using the Reed Sound replay method. Each revised island also has one new first-turn capture from the newly funded village, excluded from these paired counts.

| Island | First purchases compared | Median day-eight village land if Ochre ended day one after buying | Median if Standard finished day one | Wins if Ochre ended day one after buying |
| --- | ---: | ---: | ---: | ---: |
| Kestrel Strait | 22 | 13 → 20 | 17 → 25 | 1 → 2 |
| The Narrows | 12 | 14 → 15 | 8.5 → 12 | 4 → 4 |

## What gives Ochre a foothold on The Basin?

On the original layout, Ochre still owned its first capture the following morning in all ten replays where Standard chose the remaining moves. By the end of day two, however, an opponent had taken at least one original Ochre capital in nine replays. In five, Rose took both the northwestern and central capitals. For example, after Ochre opened at (4, 1), Rose linked its villages into a 14-hex holding on day one. On day two it merged two peasants into a spearman to take the central capital and upgraded another peasant to take the northwestern one. Ochre entered day three with two replacement villages that had zero savings and just enough income to pay their troops.

We kept that northern threat and tested a way for Ochre to build elsewhere. The revised southern village owns (3, 8), east of its capital, and Heather owns (1, 8), west of it. Each house keeps the same land count. All six seat rotations gave every starting village the same capital site, size, treasury and income as before. In the (4, 1) replay, Sage previously took (2, 7) on day five, splitting Ochre’s southern holding into two four-hex pieces. On the revised coast the southern holding stayed connected, reaching 12 productive hexes on day eight. Across the island Ochre held 17 village-supported hexes in that replay, up from six.

We counted a foothold as **at least 12 village-supported hexes at the start of day eight**, compared with eight at the opening. Five Standard opponents played normally. We forced one legal peasant capture, then either let Standard finish day one for Ochre or ended the turn immediately. Standard made all subsequent moves and accepted surrender when offered. Games ran for up to 900 active turns.

| Opening comparison | Footholds before → after | Median day-eight land before → after |
| --- | ---: | ---: |
| Same nine captures, Standard finishes day one | 3/9 → 9/9 | 7 → 17 |
| Same nine captures, end day one after buying | 1/9 → 5/9 | 5 → 12 |
| All legal first captures, Standard finishes day one | 3/10 → 10/12 | 6.5 → 17 |
| All legal first captures, end day one after buying | 1/10 → 5/12 | 5.5 → 11 |

The following counts show which captures changed. Each entry is Ochre’s day-eight land when Standard finished day one. A dash means the southern village could not make that capture on that layout.

| Opening village | Capture hex | Original | Revised |
| --- | --- | ---: | ---: |
| Northwest | (4, 1) | 6 | 17 |
| Northwest | (3, 2) | 21 | 15 |
| Northwest | (1, 3) | 12 | 12 |
| Northwest | (2, 3) | 7 | 18 |
| Central | (8, 1) | 6 | 17 |
| Central | (7, 2) | 19 | 23 |
| Central | (8, 3) | 5 | 17 |
| South | (3, 7) | 7 | 17 |
| South | (3, 8) | 6 | — |
| South | (3, 9) | 6 | 18 |
| South | (4, 7) | — | 14 |
| South | (1, 8) | — | 6 |
| South | (4, 8) | — | 11 |

With Standard finishing day one, the revised openings produced one win, seven losses and four timeouts, compared with zero wins, eight losses and two timeouts before. In the two-purchase check, opening northwest at (3, 2) and centrally at (8, 3) still won in either order, now on day nine instead of day 18. The old winning pair at (1, 3) and (3, 9) reached the turn limit in both orders. In the 20 mixed Hard/Standard games the number of timeouts rose from 11 to 12. These results measure the tradeoff between early expansion and finishing the game.

All coordinates are axial. This command replays every first capture on the current layout.

```powershell
godot --headless -s tests/opening_captures.gd -- "The Basin"
```

## Why do four revised Basin openings reach the turn limit?

We replayed the four first purchases that timed out when Standard finished day one. Three purchases produced identical boards by the start of day two, including units and treasuries. Extending the limit from 900 to 1,800 active turns gave two distinct games.

| First capture | Ochre's village land on day 8 | Land / income at turn 900 | Extended Standard result |
| --- | ---: | ---: | --- |
| Northwest (4, 1), central (8, 1), or south (3, 7) | 17 | 18 / 7 | Still playing at turn 1,800 with 9 land and 4 income |
| Northwest (1, 3) | 12 | 11 / 4 | Ochre eliminated on turn 1,632 (day 398) |

**Three openings share a day-11 payroll failure.** After joining its villages, Ochre has 24 land, 20 income, 14 wages and 10 coins. It spends all 10 promoting the peasant at (7, 3), then takes Heather's capital at (7, 0). Rose takes Ochre's capital at (2, 8). The replacement village faces 18 wages and no savings. Trees spread before payday, cutting income from 20 to 16, and all three spearmen starve. Replaying from just before the promotion and ending the turn there leaves three soldiers alive on day 12. Ochre still stalls, with just two income on 25 land by day 20.

**The northwest (1, 3) game loses its army to two separate village budgets.** Ochre finishes day 14 with 30 productive hexes, 20 wages and nine coins. Enemy captures at (2, 5) and (4, 8) sever the connections to its capital. The two cut-off villages have no savings and owe six and 12 wages. Their payday incomes are five and 11. Each loses its troops while the original capital keeps all nine coins. Standard had 19 coins before its last recruit and only considers building a castle with at least 25. Substituting a legal 15-coin castle at (4, 8) for that recruit keeps two soldiers alive on day 15. By day 20, Ochre earns 18 from 29 land, up from 12 from 25. It holds 50 land at turn 900, but earns only six and still hasn't won by turn 1,800.

**Trees prolong both games.** In the last 60 active turns before the original limit, Ochre made 16 captures and cleared one tree on its own land in the shared game. In the other it made nine captures and cleared none. We restarted both boards at turn 841. When Standard would pass, Ochre could clear a tree in a heavily wooded village with a ready peasant, or hire directly onto a tree if the village had no troops and could afford the hire. In both games the first change was a hire in a village with 10 coins, one income and no wages. Clearing the tree raised income to two, enough to cover the new peasant's wages. Both games remained unfinished at turn 1,800. Giving those clearings priority over captures also produced no wins by that point.

The old layout provides a control. With the same purchases and Standard policies, Ochre lost the first three openings on days 20, 20 and 9 respectively. The (1, 3) opening reached the same day-398 elimination on both layouts. The southern swap gives three openings time to develop. Standard can preserve its army on the existing board by protecting a connection or holding back a promotion. Across the two distinct positions tested, neither intervention on its own produced a win.

## What changed when Standard learned to protect its payroll?

We compared the previous and revised Standard on the same four shipping layouts. A village with at least 12 coins in wages and 10–24 coins in savings checks whether an enemy soldier can reach its capital. It limits promotions to the wages it estimates the land could still pay after tree growth and the loss of the capital. With 15–24 coins, a planned recruit or purchased upgrade can also become a castle. Standard checks which branches a single enemy capture would detach, estimates each branch's income without its treasury, and protects the largest threatened payroll it can afford to save. It weighs the risk against the village's surplus and checks that the castle can stop the attacker.

All six houses used the tested version of Standard, from the same forced first purchase onward. Three purchases again converged by day two. A replay from each historical decision also confirmed the change in orders.

| First capture | Revised decision | Following Ochre payday | Ochre land / income at turn 900, before → after |
| --- | --- | --- | --- |
| Northwest (4, 1), central (8, 1), south (3, 7) | On day 11, the peasant at (7, 3) takes (6, 4) and Ochre buys a peasant at (8, 3). Rose can still take the capital. | Four soldiers survive on 19 income and 16 wages. Previously all three spearmen starved. | 18 / 7 → 26 / 4 |
| Northwest (1, 3) | On day 14, Ochre spends 15 of its 19 coins on a castle at (4, 8), keeping the southern army connected. | Two spearmen survive. The smaller cut-off village still goes bankrupt. Previously both armies starved. | 11 / 4 → 50 / 6 |

All four revised games remained unresolved at both 900 and 1,800 active turns. The northwest (1, 3) game formerly ended in defeat on turn 1,632. The three shared openings still suffer an economic collapse later. By day 20 their 27 hexes produce just one coin and the army is gone.

| Paired regression check | Result |
| --- | --- |
| 124 first-purchase games on four islands, covering both ways of finishing day one | All 24 previous wins held. Two Kestrel losses became wins when Ochre passed after buying. When Standard finished day one, Kestrel (10, 4) → (12, 4) went from timeout to loss. One Basin loss became a timeout. |
| 94 ordered pairs of first-day Basin captures from different villages | All six wins held on the same victory days. Northwest (2, 3) plus south (3, 9) went from timeout to defeat on day 27 in either order. |
| 80 mixed Standard/Hard games | Every winning house and timeout held. |
| 80 mixed Standard/Easy games | Standard wins rose from 55 to 58. Four Easy wins flipped to Standard and one Standard win flipped to Easy on The Basin (seat mask 37). One Easy win became a timeout and one timeout became an Easy win. |
| 72 missed-opening seat rotations | One Kestrel loss against Easy became a win. The other 71 outcomes held. |
| 40 saved Windows-demo promotion positions | All 31 previous Knight/Baron matches held, with the same counts of both ranks in every position. The day-14 archived turn ended with two fewer peasants. Windows results came from the recorded demo turns. |

## Which trees can save the shared Basin opening?

The northwest (4, 1), central (8, 1) and southern (3, 7) purchases reach the same position. We replayed Ochre's days 12–20 with the payroll-aware Standard as the control. On each morning through day 19, we tried every legal first order that cleared a tree inside an Ochre village, including direct hires. We changed just that order, then let the original Standard finish the turn and play every house through day 20. Each soldier/tree combination counts separately.

| Morning | What Ochre could do | What happened |
| --- | --- | --- |
| 12 | Four soldiers could each clear either pine at (6, 5) or (7, 5), or any of four palms. | Standard took two capitals, open land, and an enemy pine. Pines grew on both hexes its peasants vacated. Sending either peasant to (6, 5) instead raised day-20 income from one to ten, though no troops remained that morning. |
| 13 | Three soldiers could each clear nine trees. The pines at (6, 4) and (6, 5) each prevented growth on (5, 5). | All 27 single-order alternatives improved day-20 income. Sending the peasant at (9, 3) to (6, 5) gave ten income and three soldiers. Sending it to (6, 4) gave seven and two. Standard had sent it to open land at (9, 4). |
| 14–15 | There were 56 choices on day 14, including hires, and 51 on day 15. | The best day-20 incomes were five and two respectively. Standard promoted its last peasant on day 14. By day 16 its three spearmen owed 18 against 15 income and no savings. Their graves became trees the following day. |
| 16–19 | Ochre had no soldier or recruitment money on days 16 and 17. Day 18 offered 29 direct hires onto friendly trees. On day 19 it again lacked the ten coins to hire. | Hiring onto (5, 4) on day 18 recovered five income and one soldier by day 20. The control hired onto an enemy palm and finished with one income and no army. |

Standard now diverts a peasant from capturing empty land when a friendly tree can be felled to keep another hex productive. The village must have less than ten coins, at least 12 in wages, woods on at least a quarter of its land, and at most two coins of projected income above wages after growth. The last check preserved a Kestrel win that the broader clearing policy lost. It prevents foregoing an attack solely because a prosperous village has a large forest.

In the shared opening the peasant clears (6, 4) on day 13. By day 20 Ochre holds 33 village hexes, earns seven and has two soldiers, compared with 27 hexes, one income and no soldiers. The three starts still time out at 1,800 active turns. The separate northwest (1, 3) opening now wins on active turn 465.

Across 124 four-island first-purchase replays and 94 ordered Basin purchase pairs, every previous win and every day-eight land count held. One single opening and six ordered pairs went from timeout to victory. All other win/loss/timeout outcomes held. All 72 missed-opening seat rotations retained their outcomes and day-eight land counts. In the mixed games, Standard gained two wins against Easy on The Basin. Every winning tier and timeout in the 80 Standard/Hard games held, with a different Standard house winning one Narrows game.

## Why does only the northwest Basin opening win after day 20?

We replayed Standard in all six seats. Northwest (4, 1) represents the three starts that reach the same board by day two. Northwest (1, 3) is the separate winning line. Days below are Ochre paydays. Active turns count each house that takes a turn.

| Ochre at the start of the day | Shared opening | Northwest (1, 3) |
| --- | --- | --- |
| Day 20 | 33 village hexes, 7 income, 2 soldiers | 29 village hexes, 18 income, 2 soldiers |
| Day 25 | 27 hexes, 3 income, no soldiers | 24 hexes, 5 income, no soldiers |
| Day 30 | 22 hexes, 4 income, 1 soldier | 31 hexes, 3 income, 1 soldier |
| Day 159 | Rose, Heather and Amber are still active | Heather offers surrender on active turn 465 |

**The shared opening loses its connection on day 20.** A spearman takes Azure's capital at (1, 6). Ochre's peasant then leaves (3, 6) to take a palm at (9, 1), joining its two villages. Rose immediately recruits onto the vacated (3, 6), cutting the spearman off in a two-hex village with no savings. That village earns two against six wages. The spearman starves on day 21 while the main village keeps seven coins. On day 24 the remaining peasant takes a pine at (4, 6), briefly reconnecting Ochre's land. Rose's spearman retakes the hex and kills it. By day 25 each of Ochre's three villages earns just one coin.

Holding the peasant at (3, 6) after the day-20 capital capture keeps both soldiers alive for one more payday. By day 22 the holding has 32 hexes, three income and no soldiers. This one-order change also reaches turn 1,800. In the last 60 active turns of the normal replay, Ochre takes 22 hexes and loses 19. Its 24 village hexes then earn eight, while Rose and Amber each have six non-tree hexes. Ochre's closest approach to surrender after day 20 was seven against three on day 249. It needed ten.

**The northwest opening also stalls, then outlasts its rivals.** By day 30 it earns only three coins. On days 95–97 one spearman takes two Heather capitals and then Azure's last capital at (5, 4), leaving Heather as the only active rival. Ochre's own last spearman starves on day 152. Its final recruit dies on day 155.

Heather's day-156 raid decides the game. Its spearman captures (9, 2), breaking Ochre's ten-hex village into groups of three, two and four. Each receives a replacement capital on wooded land. Ochre loses one capital hex and gains three productive ones, raising its surrender score from three to five. Heather has two coins left, earns two next payday and owes six. The spearman starves on day 157. Its grave still counts that day, then becomes a tree on day 158, leaving Heather with one scoring hex. Ochre makes no move on day 159. Five exceeds three times one, so Heather offers surrender. Ochre owns 45 of the island's 102 hexes at that point.

Ending Heather's day 156 before the raid and returning all later decisions to Standard leaves Ochre with three scoring hexes on day 159. That replay also reaches turn 1,800. These two controls isolate one decision each on the original boards.

## Can Standard recognize a costly capture?

We saved the boards immediately before Ochre's day-20 move and Heather's day-156 raid, compared the old and new orders from each identical board, then replayed the openings from day one with all six houses using the revised Standard.

| Original position | Previous Standard | Revised Standard |
| --- | --- | --- |
| Shared opening, day 20 | The peasant at (3, 6) took the distant palm at (9, 1). Rose recruited onto (3, 6), and the isolated spearman starved. | The peasant takes the neighboring pine at (4, 5), still defending (3, 6) against a recruit. Both soldiers are paid on day 21. The village spends its last three coins, and both soldiers are gone on day 22. |
| Northwest opening, Heather's day 156 | Taking (9, 2) turned two Ochre capitals into four and raised Ochre's non-tree count from three to five. | Heather takes the pine at (10, 2). Ochre keeps two capitals and three non-tree hexes. We replayed every legal spearman move and holding, 74 choices in all. Heather lost the spearman at its next payday in every case. |

Standard makes this check when a village has one ready soldier left, less than ten coins, and wages of at least six that exceed income. It considers which enemy troops could newly reach a vacated connection, including a peasant an enemy could hire after payday. A guard can still capture an adjacent tile and protect the connection. When an ordinary capture cannot pay the army, Standard previews captures that join friendly land and gives extra weight to a link that covers the projected payroll. Against a village with less than ten coins, it also checks where replacement capitals would appear. A split that makes wooded land productive for the defender can be worth passing up.

**Full games.** The three equivalent shared starts all timed out again at 1,800 active turns. In the separate northwest game, the first different order comes on day 110, so the historical day-156 position is never reached. Ochre still wins by surrender, now on active turn 707 (day 280), previously turn 465. Its spearman takes Heather's capital at (7, 6), raising Ochre's non-tree count to seven against Heather's two.

| Paired check against the previous Standard | Result |
| --- | --- |
| 124 first-purchase games and 94 ordered Basin purchase pairs | Every previous win held. One Basin single purchase and 12 ordered pairs went from loss to timeout at 900 active turns. The two Reed Sound replays of (7, 4) → (5, 5) each had one fewer village hex on day eight and still ended in defeat. All other day-eight land counts held. |
| 72 missed-opening seat rotations | The Basin's Heather start against Standard went from timeout to loss. All other outcomes and every day-eight land count held. |
| 160 mixed-tier games | A Hard win on The Basin (mask 52) became a timeout. On Basin mask 44 against Easy, the winning Easy house changed. Every other winner and timeout held. |
| 40 Windows-demo promotion positions | The Conquest replay logs matched the previous run, retaining the same 31 Knight/Baron matches against the recorded demo results. |

## Heron Lake’s opening on Standard

Ochre starts with seven villages on this 188-hex medium island. Each can recruit and capture on day one. We replayed all 27 legal first-purchase captures twice, with Standard playing every house after the forced opening.

| Ochre’s play after the first capture | Wins | Losses | Unfinished at 900 active turns |
| --- | ---: | ---: | ---: |
| Let Standard finish day one | 7 | 17 | 3 |
| End day one immediately | 3 | 18 | 6 |

Six of the seven villages produced a winning opening when Standard finished the turn. From the six-hex northeastern village, taking Amber at (15, 1) led to 47 village-connected hexes on day eight and an eventual win. Taking the other Amber hex at (18, 1) reached 48 on day eight but ran to the turn limit. From the southeastern village, taking Rose at (11, 12) won under both ways of finishing day one.

To reproduce the games, run `godot --headless -s tests/opening_captures.gd -- "Heron Lake"`.

## Standard openings on the four other medium islands

For each Ochre village with a legal first-purchase capture, we replayed the first and last enemy targets in the game's move order, counting a sole target once. Standard finished Ochre's first turn and played all six houses thereafter. A foothold means Ochre held more village-connected land at the start of day eight than at setup. Unfinished games reached the limit of 900 active turns.

| Island | Starting connected hexes | Day-eight range | Footholds / openings | Wins / losses / unfinished | One winning village → capture |
| --- | ---: | ---: | ---: | ---: | --- |
| Lantern Causeway | 19 | 16–46 | 10/12 | 6 / 5 / 1 | (12, 9) → (11, 10) |
| Bracken Fjord | 23 | 20–53 | 12/13 | 4 / 9 / 0 | (16, 10) → (15, 11) |
| Tern Steps | 22 | 19–38 | 11/12 | 6 / 5 / 1 | (-1, 2) → (0, 2) |
| Clover Downs | 24 | 25–52 | 17/17 | 8 / 5 / 4 | (15, 5) → (16, 5) |

We used the first capture from each village to select layouts with multiple viable starts, then checked the last capture as a second opening where possible. To reproduce the sample, run the Heron Lake command above with the desired island name and read the first and last capture for each village in the “finish day one” column.

## Standard openings on Twinmere

Twinmere has 298 land hexes. Ochre starts with 33 hexes connected to 12 villages. Each village could recruit directly onto enemy land on day one. We replayed the first legal enemy capture from each village and let Standard play the rest of the match for all six houses.

| Openings | More connected land on day eight | Day-eight range | Ochre wins | Ochre losses | Unfinished at 900 active turns |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 12 | 11 | 33–48 | 9 | 1 | 2 |

South of the western lake, recruiting from (3, 10) onto Azure’s (3, 9) gave Ochre 48 connected hexes in total by day eight and an eventual win. On the eastern coast, opening from (25, 5) onto Rose’s (25, 4) grew Ochre to 38 connected hexes by day eight, but Ochre ultimately lost.

To reproduce the sample, run `godot --headless -s tests/opening_captures.gd -- "Twinmere"` and read the first capture from each village in the “finish day one” column.

## Standard openings on the four other large islands

We tried several starting positions on each coastline before choosing the playable layouts. On each final map, every Ochre village could recruit onto enemy land. We replayed its first legal enemy capture, let Standard finish day one and play all six houses, and counted a foothold when Ochre's village-connected land on day eight exceeded its starting total.

| Island | Starting connected hexes | Day-eight range | Footholds / openings | Wins / losses / unfinished | One winning village → capture |
| --- | ---: | ---: | ---: | ---: | --- |
| Stagfork | 30 | 37–59 | 10/10 | 7 / 0 / 3 | (8, 13) → (8, 12) |
| Bellwater Ring | 29 | 57–66 | 8/8 | 5 / 2 / 1 | (7, 1) → (9, 0) |
| Greychain | 36 | 61–82 | 13/13 | 11 / 1 / 1 | (22, 9) → (22, 8) |
| Sable Reach | 32 | 38–63 | 12/12 | 4 / 0 / 8 | (10, 10) → (10, 9) |

Greychain produced wins from 11 of 13 starting villages. On Sable Reach every opening gained land by day eight, but eight games were still unresolved at the 900-active-turn limit. These deterministic replays show viable first moves on the selected layouts.

To reproduce a map's sample, run `godot --headless -s tests/opening_captures.gd -- "Greychain" --sample` with its island name.

## Where does Ochre stall on Sable Reach?

We replayed three of the eight timed-out first purchases, including the weakest day-eight position and a 61-hex opening on the eastern point. The comparison was the 63-hex opening that wins. Standard finished every turn. Land and income below are totals across Ochre's villages at the start of its turn, after growth and payday. Income counts one coin for each connected hex without a tree.

| Opening village → capture | Day 8 land / income | Day 20 land / income | Day 25 land / income | Outcome |
| --- | ---: | ---: | ---: | --- |
| (1, 5) → (1, 3) | 38 / 35 | 46 / 13 | 49 / 11 | Limit, day 150 |
| (−1, 9) → (−2, 8) | 47 / 43 | 73 / 28 | 74 / 10 | Limit, day 174 |
| (24, 9) → (26, 8) | 61 / 60 | 97 / 45 | 88 / 7 | Limit, day 208 |
| (10, 10) → (10, 9) | 63 / 62 | — | — | Surrender offer, day 13 |

**What the win did differently.** On day seven both the winning and eastern games captured (2, 14) from a nine-hex village. It joined up to 38 hexes in the winning game and 21 in the eastern one. On day nine the eastern game's main village lost five soldiers at payday and an isolated soldier died. The winning game continued linking productive holdings. On day twelve a spearman took (8, 8), expanding its village from 65 to 92 hexes in one move. By the end of day thirteen Ochre had 105 tree-free hexes to Azure's 31, enough for the surrender offer.

**What kept the three games going.** The western opening lost its capital at (1, 5) to Rose on day two. The eastern opening lasted much longer as a fighting force. On day 23 its main village had 99 hexes, 23 income, 26 wages and two coins. On day 24 its remaining knight and peasant died at payday. Borders continued moving in all three games. Across days 30–79 Ochre made 214 captures, 165 of them on wooded hexes, and cleared only two trees on its own land. By day 100 the southwestern game held 123 connected hexes earning just eight coins per day.

**Tests from identical positions.** We saved each timed-out game at the start of Ochre's day 25. Resuming with Standard reproduced all three original finishes. For the alternative we enabled the existing forest-recovery scoring for Ochre alone, keeping the other five houses on Standard. In holdings where trees covered at least six hexes and one third of the land, this let Standard prioritize clearing trees that threatened income, including hiring a peasant to clear one. The island, treasury, legal moves and 900-active-turn limit were identical within each comparison.

| Starting position | Change only the first differing order, then resume Standard | Keep the clearing priority from day 25 onward |
| --- | --- | --- |
| Western | Limit | Surrender offered on day 32 |
| Southwestern | Limit | Surrender offered on day 44 |
| Eastern point | Limit | Limit |

In the western game the first alternative hired a peasant on the friendly pine at (22, 9). Standard instead sent a spearman to take Sage's pine at (18, 9). Repeating the clearing priority raised western income to 21 on the winning turn, even though Ochre then held only 44 connected hexes. Surrender depends on tree-free land relative to the strongest rival.

The eastern position was sensitive to timing. Starting sustained recovery on day 12 led to a win on day 32. Starting on day 18 led to defeat on day 161, while starting on day 20 led to a win on day 89. These branches establish that Ochre can recover on this layout and that Standard sometimes neglects its tax base. The day-18 result also shows that a standing preference for forestry can produce a worse outcome. The experiment used a replay-only strategy variant.

## When does Standard clear woodland before a siege?

Standard estimates how much land will pay tax after the next round of tree growth before it buys or merges troops into a Knight or Baron. A village with at least ten coins can also prioritize clearing its own woodland when trees occupy at least six hexes and a third of its land. It does this when it owes at least six coins in wages and expects to break even or run a deficit, or when it has fresh graves and expects at most two coins left after wages. It favors trees whose removal also protects nearby productive land.

In a controlled coastal position, Rose had ten coins, a spearman and 39 taxable hexes beside an enemy castle. The previous Standard bought a Knight and took the castle. Even with the enemy passing, palm growth cut Rose's income to three at payday and the Knight died. With the revised Standard the spearman and a new peasant each cleared one palm. Eight hexes then paid their combined eight wages. With stable pines in the same position, Rose took the castle and paid its Knight.

All six houses used Standard in twelve Sable Reach opening replays. Ochre went from four wins and eight timeouts to nine wins and three timeouts at the same 900-turn limit. All four earlier wins held, and each opening had the same day-eight land count as before. On The Basin, the northwest opening still won on turn 707 and the three openings that converged still reached the 1,800-turn limit.

Run the current Sable Reach sample with `godot --headless -s tests/opening_captures.gd -- "Sable Reach" --sample`.

## How do the three new islands play on Standard?

Each Ochre village on these islands could recruit onto enemy land on day one. We forced its first legal enemy capture, let Standard play all six houses, and accepted surrender when offered. A foothold means Ochre held more village-supported land on day eight than at setup. Each column counts deterministic openings. The limit was 900 active turns.

| Island | Starting village land | Day-eight land range | Footholds | Ochre wins / losses / limits |
| --- | ---: | ---: | ---: | ---: |
| Foxridge | 10 | 16 | 3/3 | 2 / 1 / 0 |
| Egret Delta | 24 | 6–39 | 8/10 | 1 / 6 / 3 |
| Crown Harbour | 36 | 53–82 | 13/13 | 11 / 2 / 0 |

Egret Delta rewarded the opening from (0, 7) to (1, 6). Opening from (4, 6) to (3, 6) left Ochre with only six connected hexes on day eight. Foxridge produced the same day-eight land count from all three villages, yet starting in the northern village led to a loss. Run `godot --headless -s tests/opening_captures.gd -- "Egret Delta" --sample` with any of the three island names to reproduce the first-purchase games.

In a separate check we rotated each of the six starting houses into the human seat. It passed its first two turns and then played Standard against five opponents on the indicated tier. The table shows average village-supported land at the start of day eight.

| Island | Easy opponents | Standard opponents | Hard opponents |
| --- | ---: | ---: | ---: |
| Foxridge | 26.8 | 5.2 | 8.0 |
| Egret Delta | 61.3 | 20.5 | 18.5 |
| Crown Harbour | 107.5 | 31.8 | 45.2 |

Standard left less room to recover than Easy in all 18 paired starting seats. Hard applied more early pressure than Standard on average on Egret Delta. Standard applied more on the other two. This check measures the cost of a slow opening through day eight.

## Can the player establish a foothold on Osprey Sound?

Each house opens with 132 of the 792 land hexes. The player has 82 village-connected hexes across 27 villages. All 27 can recruit on day one, and 26 can recruit directly onto enemy land. The opening belongs to the player seat regardless of house color.

We sampled the first legal enemy capture from the village nearest each of five landmarks. Standard then finished the player's first turn and played all six houses. At the start of day eight, only one of five openings on the first layout had gained village land (70–90 hexes). Swapping the player's starting holdings with the fourth seat kept the same coast, trees and starting land total. All five landmark openings on the playable layout grew beyond 82.

| Opening on the playable layout | Village → first capture (axial) | Player village land on day eight | Largest player holding |
| --- | --- | ---: | ---: |
| Western lake | (1, 11) → (2, 10) | 121 | 32 |
| Central crossing | (20, 11) → (19, 11) | 122 | 32 |
| Northeast shore | (34, 5) → (33, 5) | 122 | 32 |
| Southwest arm | (8, 19) → (7, 18) | 129 | 39 |
| Southeast arm | (31, 18) → (32, 17) | 121 | 33 |

The player lost the first captured hex in all five games while growing elsewhere. We also tried two northern openings near a holding that had prospered in the western-lake replay. Recruiting from (22, 7) onto (24, 7) reached 108 connected hexes but lost the target. Recruiting from (25, 5) onto (26, 6) kept the target and grew its own village from four to 32 hexes, with 122 connected hexes island-wide. These replays ended at the start of day eight.

## How do the other four Extra Large islands open?

We tested five distinct first purchases on each island. For four, we took the first legal enemy hex from a different village near each corner of the map. For the fifth, we chose the remaining village-linking capture that immediately added the most land to its recruiting village. Standard finished day one and played all six houses through the start of day eight. As on Osprey Sound, the player established a foothold if village-connected land grew beyond the starting total.

| Island | Player villages able to recruit | Starting village land | Day-eight land across five openings | Footholds | First capture in a player village on day eight |
| --- | ---: | ---: | ---: | ---: | ---: |
| Kettle Mere | 28/28 | 76 | 111–123 | 5/5 | 3/5 |
| Gannet Keys | 27/27 | 79 | 80–104 | 5/5 | 0/5 |
| Crookhorn Cape | 31/31 | 85 | 107–112 | 5/5 | 1/5 |
| Alder Estuary | 32/32 | 83 | 135–139 | 5/5 | 2/5 |

On Kettle Mere, recruiting from (5, 25) onto (5, 23) linked villages. By day eight the captured hex belonged to a 31-hex holding. On Gannet Keys, two captures from (43, 10) gave quite different island-wide results. Taking (44, 9) led to 80 connected hexes, just one above the opening total. Linking through (44, 11) led to 96. Both first targets had fallen by day eight.

Run the same opening-week sample with Godot 4.7.2.

```powershell
godot --headless -s tests/foothold_openings.gd -- "Kettle Mere" "Gannet Keys" "Crookhorn Cape" "Alder Estuary"
```

## Does Gannet Keys need a wider crossing?

Keep the current coastline. The first-purchase benchmark previously reported zero for both an isolated player hex and an enemy-owned hex. Replaying every order showed three recaptures and two isolations. The player started with 79 village-connected hexes. Land counts below are taken at the start of the player's turn, after payday.

| Opening capture (axial) | What happened to that hex | Day 8 land | Day 20 land | Day 30 land |
| --- | --- | ---: | ---: | ---: |
| (11, 5) → (11, 4) | A rival spearman took the original capital on day 3. By day 6 the opening hex was the capital of the last two tiles. A spearman took it against rank-one defense. | 95 | 90 | 70 |
| (43, 10) → (44, 9) | Two rival spearmen acted on day 3. The first took the old capital, the second took the opening hex after it became the replacement capital. | 80 | 88 | 93 |
| (5, 14) → (5, 12) | The player's merged spearman left on day 2. On day 6 a rival spearman took the neighboring capital at (5, 13), isolating the opening hex. It remained player-owned through day 30. | 104 | 97 | 87 |
| (42, 18) → (43, 18) | The capital fell on day 2. A spearman took the final connection at (43, 19) on day 5. The opening hex remained player-owned through day 30. | 90 | 67 | 70 |
| (43, 10) → (44, 11) | On day 3 a peasant left (45, 10) to capture (43, 14). Defense of the opening hex dropped from one to zero and a rival peasant entered from (44, 9). | 96 | 97 | 84 |

Holding that last peasant at (45, 10) for day 3 postponed the first recapture until a spearman took the hex on day 12. The change helped locally, although the player had 56 connected hexes island-wide on day 30 versus 84 with the ordinary move. Across the five baseline games, each player kept a contiguous block of 11 hexes under uninterrupted ownership from the start of day 8 to the start of day 30. At that point the player's territory containing the central crossing covered 36–45 hexes.

### Fortifying the central crossing

The middle hex (24, 13) has two land neighbors. Removing it from the land graph splits the island into components of 418 and 379 hexes. To compare defending it, we recruited from (26, 10) onto (25, 12) in every trial. This joined the isolated middle hex to the village and left 15 coins. All opponents used Standard. The player also used Standard except for the specified orders.

| Player decisions | Day 30 village land | Day 60 village land | Crossing outcome |
| --- | ---: | ---: | --- |
| Standard continuation | 84 | 112 | Held a 45-hex territory at the crossing at the start of day 40. A peasant captured the undefended middle hex later that day. |
| Spend the last 15 coins on a castle on the middle hex on day 1 | 25 | 13 | A knight took the neighboring capital on day 21 and the castle on day 22. |
| Save for a castle covering the middle hex from the eastern approach | 105 | 112 | Built at (25, 12) on day 16. Both castle and crossing were still player-owned on day 60, in one 60-hex territory. |

The delayed approach used existing troops to clear the crossing and its approach, passed up purchases from the local treasury, and built after the garrison vacated the site. In a separate trial we saved for two castles farther inland with at least one peasant, one spearman and income covering wages. Both castles survived to day 60, but neither covered the middle hex. The same rival peasant took it on day 40. Castles guard their own tile and adjacent friendly tiles. On the narrow middle hex, only two of the six neighboring positions are land.

The five ordinary replays produced zero to two enemy promotions to knight or baron per game through day 30. The immediate-castle trial shows why even one knight matters once the village behind the fort has shrunk. These are deterministic position comparisons through the stated day, with no estimate of human win rate.

```powershell
godot --headless -s tests/foothold_openings.gd -- "Gannet Keys" --day=30
godot --headless -s tests/gannet_crossing.gd
```

### How does Standard defend the crossing on its own?

Standard recognizes a one-hex passage with two land neighbors when removing it separates banks of at least ten hexes each. In a village of at least 12 hexes, it checks whether moving a soldier would give an opposing army or funded peasant recruit enough strength to enter. A guard can still move along the passage, or leave when another defender can hold it. In a Kestrel Strait replay on day 24, seat four kept its spearman at (9, 4) and sent the soldier at (8, 6) to the same target at (10, 4). This kept rank-two defense against an opposing spearman.

When the far bank is outside the village, an army with at least two soldiers including a spearman can save for a castle on the near bank. The site must cover the crossing and at least two other friendly hexes. The village checks its next payroll, keeps a recruitment fee if an enemy can already attack the crossing, and can clear or vacate the site. Ordinary spending resumes when the village owns both banks. In the original eastern opening, losing (44, 11) on day three still leaves all nine other village hexes connected.

All six seats used the revised Standard. For the central opening from (26, 10) to (25, 12), the player built the approach castle on day 13. It held the crossing through day 60 in a 76-hex village. The earlier Standard lost the crossing on day 40. Island-wide land was 84 → 94 on day 30 and 112 → 112 on day 60. Forcing the immediate castle on day one still lost it on day 22. The crossing runner now reports autonomous construction after the opening purchase alongside the immediate-castle trial. The day-16 castle above was a scripted experiment with the earlier AI.

| First target | Day 8 village land, both versions | Day 30 before | Day 30 after |
| --- | ---: | ---: | ---: |
| Northwest (11, 4) | 95 | 70 | 80 |
| Northeast (44, 9) | 80 | 93 | 88 |
| Southwest (5, 12) | 104 | 87 | 97 |
| Southeast (43, 18) | 90 | 70 | 54 |
| Eastern village link (44, 11) | 96 | 84 | 94 |

Across 130 earlier opening replays to victory, elimination or 900 active turns, Kestrel Strait gained one player win in 46 games. Recruiting from (9, 8) to (9, 9) and ending day one immediately had previously lost. All 48 Lantern Causeway, 24 Basin and 12 Sable Reach outcomes matched. Every day-eight land count matched across those 130 games and another 20 openings on the other four extra-large islands. At 1,800 turns the three shared Basin games still timed out and the northwest game still won on turn 707.

On Kestrel Strait, the mixed-tier benchmark played all 20 ways to assign three seats to Standard. Against Easy, Standard won 16 games, up from 15. Two Easy wins became Standard wins, one Standard win became an Easy win, and the previous timeout became an Easy win. Against Hard every assignment kept the same winning tier or timeout, with eight Standard wins, 11 Hard wins and one timeout.

## Why do three Sable Reach openings still time out?

We replayed the three remaining timeouts and the newly winning eastern point with all six houses on Standard. Each replay starts with the listed first purchase and runs through surrender, elimination or 900 active turns. The day-25 counts are Ochre's village-supported land and taxable income at the start of its turn.

| Opening village → capture | Day 25 land / income | What happened under Standard |
| --- | ---: | --- |
| West (1, 5) → (1, 3) | 44 / 11 | Rose took two capitals on day 2. Three soldiers died at the next payday. By day 25 Ochre again had no troops. At the limit it had 74 connected hexes earning seven coins. |
| Northwest (−1, 5) → (−1, 4) | 86 / 11 | On day 20 the village at (5, 13) lost four spearmen at payday. By day 25 it held 58 hexes earning five coins. Heather captured its capital on day 26. |
| Southwest (−1, 9) → (−2, 8) | 74 / 10 | The opening village lost both spearmen at payday on day 22. It kept 52 hexes from day 22 through day 25, but its income fell from nine to two. |
| Eastern point (24, 9) → (26, 8) | 136 / 46 | The eastern village alone earned 38 coins against 22 in wages. On day 29 the capture at (8, 4) joined holdings and took one village from 91 to 146 hexes. On day 32 Ochre ended its turn with 50 tree-free hexes to Azure's 15, enough for surrender. |

From days 30 through 79, the three stalled games produced 271 Ochre captures. Of those, 200 took wooded enemy hexes. Ochre cleared only two trees on its own land. Even the western game's largest village still bordered 20 undefended enemy hexes at the limit.

We saved all four games at the start of Ochre's day 25. Resuming with Standard reproduced each original result. For the experiment we allowed every heavily wooded village to use Standard's existing forest-recovery scoring, lifting the cash and payroll conditions that activate it. The same six-tree and one-third-of-land thresholds, move costs and promotion checks applied. We compared changing Ochre's first differing order, keeping the preference for Ochre, and keeping it for all six houses.

| Day-25 position | Current Standard | One Ochre order | Ongoing for Ochre | Ongoing for all houses |
| --- | --- | --- | --- | --- |
| West | Limit | Win, day 55 | Win, day 32 | Win, day 32 |
| Northwest | Limit | Limit | Win, day 41 | Win, day 52 |
| Southwest | Limit | Limit | Win, day 47 | Win, day 35 |
| Eastern point | Win, day 32 | Win, day 28 | Win, day 32 | Win, day 43 |

The first differing order came from the village at (24, 9) in every game. In the west and southwest it had no soldiers. Standard hired onto open enemy land. Hiring onto a friendly palm instead gave the same village a soldier and a new source of tax. In the northwest the village had a spearman, six income, six wages and nine coins. Its cash was one coin below the threshold for prioritizing woodland. Standard sent the spearman to capture Amber's capital at (18, 10). The alternative cleared its own pine at (22, 10). One clearing settled only the western timeout. Sustained clearing settled the other two, even when the opponents could do the same. These comparisons start on day 25 and cover these four positions.

## How much room does Easy give the player?

The same automated player passed its first two turns, then used Standard strategy and accepted surrender when offered. Each of the six opening houses took a turn in the human seat on each island. The table compares that player's results against five Easy opponents and against five Standard opponents.

| Island | Average village-supported hexes on day 8 against Easy | Against Standard | Player wins against Easy | Against Standard |
| --- | ---: | ---: | ---: | ---: |
| Kestrel Strait | 34.7 | 18.0 | 2/6 | 2/6 |
| The Narrows | 28.3 | 11.2 | 3/6 | 1/6 |
| The Basin | 41.8 | 14.3 | 4/6 | 1/6 |
| Reed Sound | 27.7 | 5.7 | 2/6 | 0/6 |
| **All four** | **33.1** | **12.3** | **11/24** | **4/24** |

Land was measured at the start of the player’s eighth turn. Early elimination counts as zero and early victory as the whole island. Four games against Standard on The Basin were unresolved at the 900-turn limit. Easy gave the player more room to recover on every island on average. Kestrel Strait had the same number of eventual player wins on both tiers.

## Which mistakes did Easy punish?

During the first 20 days of one all-Standard game on each island, we recorded each enemy capital hex a ready soldier could capture when that same soldier could also capture an open enemy hex. We replayed the whole acting house’s turn on Easy from the identical board and counted whether it took the original capital hex. A capital can present another opportunity on a later turn.

| Island | Opportunities | Capital hex taken by Easy | By Standard | Mixed-game winners (Standard / Easy / unfinished) |
| --- | ---: | ---: | ---: | ---: |
| Kestrel Strait | 65 | 27 | 47 | 12 / 8 / 0 |
| The Narrows | 68 | 26 | 41 | 15 / 5 / 0 |
| The Basin | 46 | 22 | 30 | 11 / 7 / 2 |
| Reed Sound | 44 | 20 | 29 | 17 / 3 / 0 |
| **All four** | **223** | **95 (43%)** | **147 (66%)** | **55 / 23 / 2** |

The mixed games were six-house free-for-alls. Each island used all 20 ways to put Standard in three seats and Easy in the other three. The mixed games ran to whole-island conquest or 900 active turns. In separate single-tier runs, all four Easy games reached conquest. The all-Standard Basin game reached the turn limit.

All four benchmark islands are playable from the Island selector and use these same opening layouts. These deterministic simulations measure the response to mistakes and relative playing strength. Human playtesting will tell us how the pace feels.

Run the comparison from the project root with Godot 4.7.2. To run just one island, append `-- "Reed Sound"` or the name of another island in the table.

```powershell
godot --headless -s tests/difficulty_benchmark.gd
```
