# Conquest

[Play Conquest in your browser](https://jace062.github.io/conquest/)

Conquest is a singleplayer hex strategy game inspired by Sean O’Connor’s *Slay*. You share an island with five rival houses. Connect villages to pool their treasuries, clear trees for income, and capture land while keeping enough coins to pay your army.

## Your first turn

Look for a village flying the gold flag. Select it, choose **Recruit peasant**, then pick a marked hex. A peasant placed on open friendly land can still move that turn. Recruiting directly onto an enemy hex spends its move. Choose **End turn** when you’re ready for the other houses to play.

There are 24 islands in four sizes. Standard is the default difficulty. You can also choose Easy or Hard, and pick your house color. The in-game **How to play** panel covers combat, upkeep, and controls.

On a touch screen, tap a hex to select it, drag to pan, and pinch to zoom. **Fit** shows the entire island.

In the web build, **End turn** saves a checkpoint in your browser before play passes to the other houses. Reloading the site in the same browser returns you to that point, with your moves still available to undo. Starting a new match clears the old checkpoint.

## Run from source

Open `project.godot` in Godot 4.7.2 Standard and press **F5**. To make a Windows or Web build, install matching export templates and follow the [build instructions](docs/build.md).

[Island guide](docs/islands.md) · [Rules and Windows demo comparisons](docs/rules.md) · [Opponent difficulty](docs/difficulty.md) · [Credits](CREDITS.txt)
