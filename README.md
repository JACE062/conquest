# Conquest

[Play Conquest in your browser](https://jace062.github.io/conquest/)

Conquest is a singleplayer hex strategy game inspired by Sean O’Connor’s *Slay*. You share an island with five rival houses. Connect villages to pool their treasuries, clear trees for income, and capture land while keeping enough coins to pay your army.

## Your first turn

Look for a village flying the gold flag. Select it, choose **Recruit peasant**, then pick a marked hex. A peasant placed on open friendly land can still move that turn. Recruiting directly onto an enemy hex spends its move. Choose **End turn** when you’re ready for the other houses to play.

There are 24 islands in four sizes. Standard is the default difficulty. You can also choose Easy or Hard, and pick your house color. The in-game **How to play** panel explains village formation, combat, and upkeep. Under **Controls → Bot turn speed**, choose Slow, Normal, or Fast.

Press **V** to cycle through villages with a ready unit or enough coins to recruit.

On a touch screen, tap a hex to select it, drag to pan, and pinch to zoom. **Fit** shows the entire island.

In the web build, **End turn** saves a checkpoint in your browser before play passes to the other houses. Reloading the site in the same browser returns you to that point, with your moves still available to undo. Starting a new match clears the old checkpoint.

## Local multiplayer

For a shared-device match, choose **Local multiplayer** (under **Menu** on phones). Each player chooses a different house color before playing Foxridge against four Standard bots. The house with seven village-connected hexes goes first, followed by the other human with eight. **Duel options → Swap and rematch** exchanges your starting positions and turn order while keeping your colors.

Choose **Foxridge · Co-op** to play as neighboring allies against four Standard bots. Each house takes its own turn and pays its own troops. Units, villages and castles protect adjacent allied land at their normal strength. Select a defender to see a dashed outline on the partner tiles it covers. You can move or recruit onto an isolated allied hex bordering your village territory, including woodland. Troops can cross connected allied village territory and clear a partner’s tree. Clearing spends the unit’s move and restores income to the village that owns the hex. Capture markers show who will gain the land. Your house takes a hex bordering one of your own village territories, and your partner takes a hex reachable only from their frontier. Away from home, a unit and the village paying its wages display matching house-colored tags, even on another village’s land of the same color. A warning triangle marks each cut-off unit for both players. Tap it to see whose payday is the deadline for reopening the route. Recruitment and upgrades still happen at home. Defeat all four bots for a shared victory, or propose conceding together from **Co-op options**.

For a direct match, select **Twin Shoals · Head-to-head** in the same setup. Each player starts with one four-hex village and takes turns expanding into unowned land. The last player with a village wins. Choose **Reverse turn order** to keep your colors and villages and let the other village open the rematch. **Swap and rematch** exchanges villages and keeps the same village moving first. Both choices are available during play under **Duel options** and after the match under **Rematch options**.

On your turn, choose **Duel options → Resign duel** to give the other player the win. On Foxridge, to end a losing match together, choose **Propose conceding to bots** and pass the device for the other player to accept or keep playing. Both endings show the round and offer territory history and a swapped rematch.

## Run from source

Open `project.godot` in Godot 4.7.2 Standard and press **F5**. To make a Windows or Web build, install matching export templates and follow the [build instructions](docs/build.md).

[Island guide](docs/islands.md) · [Rules and Windows demo comparisons](docs/rules.md) · [Opponent difficulty](docs/difficulty.md) · [Credits](CREDITS.txt)
