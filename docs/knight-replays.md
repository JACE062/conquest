# Where the Knight counts diverged

## After tuning the follow-up attack

We replayed all 40 positions in the Windows 5.0 demo at **Very Clever** and ran both Conquest AIs from the same post-payday boards. The 23 archived positions and 17 controlled variants each count once. An exact match here means the acting house ended its turn with the same numbers of Knights and Barons as Windows.

| Sample | Previous matches | Tuned matches | Earlier matches lost |
| --- | ---: | ---: | ---: |
| Archived positions | 23/23 | 23/23 | 0 |
| Controlled variants | 6/17 | 8/17 | 0 |
| All positions | 29/40 | 31/40 | 0 |

- **Day 11, 400 coins.** Both Barons took the enemy Knight on 554. Conquest then bought a Knight in three purchases, took the defending Spearman on 519, and sent Spearmen onto 537 and 536. Windows sent Knights to 537 and 536 before taking 519 with a third Knight. Conquest now captures all three follow-up hexes and finishes with one Knight there. The previous village stopped immediately after the Baron’s capture.
- **Day 26, 37 and 69 coins.** In both variants Conquest still took castle 324 with its first Knight. It assembled a second Knight and used it on 428, an open hex protected by castle 393. Those are the same two Knight captures Windows made. The previous AI stopped at one Knight in each variant.
- **Other turns.** The Baron count matched Windows in all 40 positions. On the day-24 archived position and the smaller-army day-27 variant, Conquest used different soldiers but captured the same hexes as before and finished with the same counts in all four ranks. The other 35 positions replayed the previous Conquest orders exactly.

Nine turns still differ on Knight count. Counting the hexes captured by only one of the two games, Conquest’s choice of territory moved closer to Windows on the three target positions and held steady on the other 37. The CSV gives those counts and the two ranks for every position. [All 40 replay results](breach-replays.csv)

## The original 11 mismatches

These are the 11 edited positions where Conquest and the Windows 5.0 demo previously finished one turn with different Knight counts. Each replay used the same board, treasury and ready pieces after payday, on challenge island 1 at **Very Clever**. All 11 reproduced their earlier counts. The two games agreed on the Baron count in every case.

The Windows turn animation cleared the acting house’s soldiers and then placed them at their destinations. Each placement appeared in its own saved board frame. This reveals the destination, rank, and defense immediately before each capture. The animation does not identify which soldiers supplied a Knight or Baron. Conquest’s log records each individual order, including both field merges and upgrades purchased from a village.

The table gives the acting house’s Knight count at the end of the turn, before the follow-up attack was tuned. Hex numbers are zero-based slots in the Windows save, shared by both sides of the comparison. In Conquest’s axial coordinates `(q, r)`, the slot is `18q + 35r` for these imported positions. The log contains all 131 visible Windows unit placements and all 228 original Conquest orders. Its order numbers start at one separately for each game and position. [Move log (CSV)](knight-replay-moves.csv)

| Position and available coins | Windows Knights | Conquest Knights | Moves that account for the difference |
| --- | ---: | ---: | --- |
| Day 11, three-hex holding, 400 (`d11p4siege400`) | 3 | 0 | Both Barons took the enemy Knight on 554. Windows then sent Knights to 537 and 536, both guarded by the Spearman on 519, and a third Knight took the Spearman itself. Conquest ended with just a spent Baron in that holding. At four productive hexes its recruitment limit was one soldier, even with all 400 coins still in the village. |
| Day 26, original army plus enemy Knight, 37 (`d26p5guard`) | 2 | 1 | Both opened by taking castle 324 with a Knight. Windows used a second Knight on move 10 for open hex 428, protected by castle 393. Conquest sent Spearmen to capitals 347 and 329 and left 428 alone. |
| Day 26, smaller army, 69 (`d26p5lean`) | 2 | 1 | Same two Windows Knight targets, with 428 taken on move 4. After castle 324, Conquest merged two pairs of Peasants into Spearmen, took 306 and 364 with them, then bought another Spearman upgrade. It never attacked 428. |
| Day 28, 69 (`d28p5lean`) | 2 | 1 | Windows put a Knight on grave 375, protected by a capital, then another on undefended 306. Conquest used its Knight on 357. Its Spearman reached 306 on order 7, after an enemy capital had relocated there. |
| Day 28, 228 (`d28p5purse`) | 1 | 0 | Windows put a Knight on grave 375 and a Baron directly on enemy Knight 376. Conquest merged its opening Knight into a Baron and attacked 358. After its Spearman took capital 340, Conquest could take grave 375 with a newly recruited Peasant. |
| Day 29, 85 (`d29p5lean`) | 2 | 1 | Both opened with a Knight on castle 237. Windows used another Knight on open hex 305, guarded only by capital 322. Conquest went after the Peasants on 255 and 220 with Spearmen and left 305 alone. |
| Day 29, 238 (`d29p5purse`) | 2 | 1 | Windows again used Knights on 237 and 305, then took enemy Knight 357 with its Baron. Conquest first made a Baron and took capital 322. It bought a Knight upgrade to take castle 237 and recruited a Peasant directly onto the now-undefended 305. |
| Day 30, four extra Spearmen, 63 (`d30p5lean2`) | 2 | 1 | Both used a Knight on capital 238, defended by a Spearman. Windows also put a Knight on 305 while capital 322 still guarded it. Conquest sent its four ready Spearmen to 344, 327, 168 and 151 before attacking 238, and never attacked 305. |
| Day 30, 246 (`d30p5purse`) | 2 | 1 | Windows used Knights on 305 and capital 238, with its Baron taking enemy Knight 357 between those moves. Conquest used the Baron on capital 322 first, bought a Peasant onto 305, and later bought a Knight upgrade to take 238. |
| Day 30, two starting Spearmen, 95 (`d30p5spearpair`) | 1 | 0 | Windows put a Knight on 305 and a Baron on enemy Knight 357. Conquest merged its two Spearmen into a Baron, took capital 322, and bought a Peasant onto 305. |
| Day 31, 248 (`d31p5purse`) | 2 | 3 | Windows took castle 185 with a Knight, then took 168 and capital 344 with Spearmen. Conquest spent its opening Knight on 344, merged cheaper troops up to a Baron for capital 322, and bought separate Knight upgrades for 168 and capital 238. Both used a Knight on 238. |

In seven of the ten turns where Windows ended with more Knights, the extra Knight landed on a hex with defense zero or one. A Peasant could take the undefended hex, and a Spearman could take any of the seven. In the other three turns, the day-11 Spearman and the day-26 castle gave the Windows targets strength-two defenses. On day 31, taking castle 185 early removed its protection from 168 and let a Windows Spearman do a job Conquest later used a Knight for.
