# Build and run Conquest

Use [Godot 4.7.2 Standard](https://godotengine.org/download/archive/4.7.2-stable/) with matching export templates. Import `project.godot` and press F6 in the main scene or F5 from the editor. The project uses GDScript and the Compatibility renderer.

```powershell
godot --headless -s tests/rules_test.gd
./tools/build.ps1 -Godot 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe'
```

The build script imports artwork, runs rules tests, exports Web and Windows Desktop, and packages the Windows ZIP under `build/`. The engine and templates are installed separately.

GitHub Pages serves the contents of the `gh-pages` branch from its root. To update the public game for a release, build the tagged source and publish the contents of `build/web` at that root, retaining `.nojekyll`. Commits to `main` can be tested independently of the live version.

## Run an export

- **Windows** — unzip `build/Conquest-Windows-x64.zip` and run `Conquest.exe` with its accompanying files. The game works offline.
- **Browser** — serve the exported `build/web` directory over HTTP. From the repository root, run `python -m http.server 8765 --bind 127.0.0.1 --directory build/web` and open [the game on localhost](http://127.0.0.1:8765/). Any static web host that serves WebAssembly can also serve this folder.
