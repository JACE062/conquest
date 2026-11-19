# Rules reference

The reference is Sean O’Connor’s Windows 5.0 demo in single-player challenge mode. These comparisons used island 1, the in-game tutorial, bundled help, a match played through day 37, and controlled copies of saves from that match. Kestrel Strait and its computer strategy are original. [Windows demo](https://www.windowsgames.co.uk/slay.html) · [Windows tutorial text](https://www.windowsgames.co.uk/SlayLanguages/English.txt)

| Situation | Reference finding and game behavior |
| --- | --- |
| Opening land | Six houses divide the land. A lone colored hex has no village, treasury or income. Connecting it brings it into the adjoining holding immediately. Kestrel Strait starts with 45 such hexes out of 124. |
| Opening money | On day one a clear two-hex holding showed 8 savings and 2 income, leaving 10 to spend. The save records 4, 8, 12, 16 and 20 coins for waiting holdings with 1 through 5 productive hexes. Each holding starts with four coins per productive hex and receives normal income on its owner's turn. |
| Deployment and upgrades | A new peasant captured an undefended neighboring hex directly from the shop. On day six a second purchase upgraded the capturing peasant. Combining a separate ready peasant with a spent peasant also left the spearman on the capture hex, unable to attack again. Castles require open friendly land. |
| Bankruptcy and growth | A bankrupt soldier leaves a grave. At the start of its owner's next turn the grave becomes a palm on the coast or a pine inland, before income. Trees produced during that growth phase can first seed on their owner's following turn. The same coastal hex grew a palm beside a mature foreign palm and stayed clear beside a newly grown one. Two mature pines take precedence when both species can seed a site. |
| Clearing graves | A newly recruited peasant placed on a friendly grave cleared it. Trying to move it again immediately produced the demo’s spent-piece message. |
| Joining holdings | The larger holding keeps its capital and combines both treasuries. For equal sizes, the last tied capital encountered in the demo’s depth-first traversal survives. It starts at the first hex in board order and visits neighbors clockwise from north in the Windows layout. The same pair of three-hex holdings kept the southeastern village when linked from either side. |
| Splits and new capitals | A day-four bridge capture left four coins in the original capital and zero in the detached seven-hex holding. A replacement village starts with an empty treasury. It prefers open ground, then a grave, a tree, a castle, and finally a soldier. Within one category the site with the most friendly neighbors wins. Ties take the first site in Windows board order. A village cut down to a single hex immediately becomes a coastal palm or inland pine and loses its cash. |

### Surrender, elimination and victory

At the end of the human turn, count each house’s hexes without a pine or palm. Isolated hexes, graves, buildings and soldiers all count. The opponents offer surrender if the human still has a village or living soldier and has **strictly more than three times the strongest individual rival’s count**. Accepting transfers the remaining land and removes enemy villages, castles and soldiers. Declining hands play to the next house and suppresses the next three offers that would otherwise qualify.

The turn order checks for a **village or a living soldier** before paying wages. A lone soldier therefore earns one last turn and starves at payday. A house with only isolated land, graves, trees or castles is skipped. Its hexes retain their color and their trees continue to grow. An eliminated human can watch the computers finish. Without an accepted surrender, victory requires ownership of every land hex.

| Windows demo replay | Observed outcome |
| --- | --- |
| Day-one saves with identical ownership and five rivals on eight tree-free hexes each | Ending the turn at 23 or 24 produced no offer. At 25 the surrender prompt appeared, and accepting gave victory that day. |
| Day-30 save with the leading house in the human seat | With 114 tree-free hexes against a runner-up on 16, the opponents offered surrender. After a refusal the lead persisted. The next offer and accepted victory came on day 34. |
| Same day-35 position with a peasant or castle on an isolated hex | The peasant’s house received the day-36 turn with a fresh grave. The castle stayed in place and its house’s turn was skipped. |
| Island 1 with the human passing | The human lost its last land by day 16. The remaining houses continued until a computer owned all 162 hexes and received victory on day 37. |

Eleven capture replays covered splits, replacement sites, stranded capitals and equal-size mergers. The three-hex merger kept the southeastern village, while a four-hex merger on day 17 kept the northwestern one. Conquest matched the demo on owner, piece and village treasury across all 162 hexes after each move. The numeric thresholds and turn order above apply to the tested Windows demo. The Steam and mobile editions have not been tested. [Publisher’s description of the Windows builds](https://www.windowsgames.co.uk/slay.html)

### Knights, Barons and computer promotions

The Windows demo’s medieval theme shows the **Knight** (strength 3, wages 18) with a sword and no shield. The **Baron** (strength 4, wages 54) carries a sword and shield. In Conquest, the Knight has a red plume and raised sword. The Baron carries a gold shield and standard. A peasant and spearman make a Knight. Two spearmen, or a Knight and peasant, make a Baron. [Publisher’s rules](https://www.windowsgames.co.uk/slayRules.html)

The AI comparison used island 1 saves with the demo set to **Very Clever**. For each position, the demo was paused after the acting house received income and paid wages. Conquest took that same board, treasury and ready units through one turn. A second copy gave the turn to the Windows AI. The counts below are the acting house’s fielded units at the end of that turn.

| Position | Windows demo | Previous Conquest AI | Tuned Conquest AI |
| --- | --- | --- | --- |
| Day 11, house 6, largest holding earning 36 with 33 coins available | 0 Knights | 2 Knights | 0 Knights |
| Day 14, same house, earning 40 with 32 coins | 1 Knight | 2 Knights | 1 Knight |
| Day 26, same house, starting with 1 Knight | 2 Knights | 4 Knights | 2 Knights |
| Day 28, controlled frontier with an enemy Knight, 69 coins | 2 Knights, 0 Barons | 0 Knights, 1 Baron | 1 Knight, 0 Barons |
| Same day-28 board and troops, 228 coins | 1 Knight, 1 Baron | 0 Knights, 1 Baron | 0 Knights, 1 Baron |

After the first promotion adjustment, both end-of-turn counts matched on **23 of 23** archived board positions, up from 7. No Baron appeared in those 23 Windows turns. On **17 controlled variants** that tested when the AI would field a Baron, the Baron count matched on all 17, up from 6. Both counts matched on 6 of those 17. Six repeat runs reproduced the Windows high-tier counts. The two AIs can take different moves to reach the same counts.

Conquest now weighs the territory’s savings, recurring income, and existing troops before promoting. It keeps cheaper troops available for other captures and discounts income from land just taken or cleared. These are computer spending preferences. Human and computer players use the same merge and upkeep rules.

Replaying the 11 remaining Knight mismatches showed that Windows sometimes used its extra Knight on a lightly defended hex. In three positions, the difference came from how the villages followed up on a defended front. A funded Conquest village can now send troops through its Baron's breach or field a second Knight against a castle. Replaying all 40 positions brought the two-rank match count from **29 to 31**, preserving all 29 earlier matches. [Follow-up attacks and original move traces](knight-replays.md) · [All 40 replay results](breach-replays.csv)
