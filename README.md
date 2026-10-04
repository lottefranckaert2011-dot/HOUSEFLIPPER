# Home Flip Designer

A first-person house renovation game made with [Godot 4](https://godotengine.org/), inspired by
*House Designer: Fix & Flip*. Clean up a trashed house, renovate it room by room for your client,
then flip it for profit. Built as a web game for [CrazyGames](https://www.crazygames.com/).

## Gameplay

- **7 jobs per house**: clean-up, bathroom makeover, living room, kitchen, bedroom & laundry,
  backyard, and finally selling the house. Every job has a task list on your tablet.
- **5 tools**
  - **Hand**: pick up trash, throw away old furniture, move your own furniture.
  - **Sponge**: hold to scrub dirt off floors and walls and to pull weeds.
  - **Paint**: paint, wallpaper or tile walls (Shift-click paints the whole room).
  - **Floor**: lay wood, carpet, tiles or concrete.
  - **Build**: buy and place about 90 pieces of furniture, appliances and garden items.
- **Flip it**: the sale price depends on how much you improved the house. Each new house pays more.
- Progress saves automatically in the browser.

## Controls

| Action                         | Key                 |
| ------------------------------ | ------------------- |
| Move / look                    | WASD / mouse        |
| Use tool                       | Left click          |
| Switch tool                    | 1 - 5 or scroll     |
| Open catalog (paint, floor, furniture) | Q           |
| Rotate furniture               | R or scroll         |
| Cancel placing                 | Right click         |
| Return furniture for a refund  | X                   |
| Tablet (tasks, jobs, settings) | Tab                 |
| Pause                          | Esc                 |

## Running it

1. Install **Godot 4.7** (standard build, not .NET).
2. Import `project.godot` and press **F5**.

The project uses the **Compatibility** renderer so it runs in browsers via WebGL 2.

## Exporting for CrazyGames

The `CrazyGames` export preset (`export_presets.cfg`) builds a single-threaded web export into
`build/web/`. Its HTML head include loads the CrazyGames HTML5 SDK v3 and a small `CGBridge`
helper that the game talks to through `scripts/autoload/crazy_sdk.gd`.

```sh
godot --headless --export-release "CrazyGames" build/web/index.html
cd build/web && zip -r ../home-flip-designer.zip .
```

Upload the zip (with `index.html` at its root) in the CrazyGames Developer Portal. Every push also
builds the export in GitHub Actions (`.github/workflows/web-export.yml`); download it from the
run's artifacts.

SDK integration:

| SDK feature                | When                                                       |
| -------------------------- | ---------------------------------------------------------- |
| `loadingStart/Stop`        | While the engine and level load                            |
| `gameplayStart/Stop`       | Playing vs. menus, tablet, catalog and pause               |
| `happytime`                | Finishing a job or selling a house                         |
| Midgame ad                 | Between jobs and before the next house                     |
| Rewarded ad                | Optional "watch an ad for cash" button on the tablet       |

The game is muted and paused while an ad plays. Outside CrazyGames (or on localhost without
the SDK) every SDK call is skipped safely. Test locally by serving `build/web` on `localhost`.

Build size: about 14 MB transferred (gzip), so it fits the 20 MB mobile homepage limit and the
50 MB general limit. The game currently targets desktop (mouse and keyboard).

## Project layout

```
scenes/game.tscn         Single scene; everything else is built in code
scripts/autoload/        Game state & saving, audio, CrazyGames SDK bridge
scripts/data/            Furniture catalog, finishes, house floor plan, jobs
scripts/world/           House/yard builders, mess, furniture, surfaces, game flow
scripts/player/          First-person controller and tools
scripts/ui/              HUD, tablet, catalog picker, theme
assets/                  Models, generated textures, sounds, icons, fonts, thumbnails
tools/                   Dev tools (not exported), see below
```

## Dev tools

```sh
python3 tools/gen_textures.py      # regenerate textures (Pillow, numpy)
python3 tools/gen_audio.py         # regenerate sound effects and music (numpy)
godot --headless -- --selftest     # automated play-through of the first jobs
xvfb-run godot --rendering-driver opengl3 --resolution 512x512 -- --thumbs   # catalog thumbnails
xvfb-run godot --rendering-driver opengl3 -- --shots <dir>                  # screenshots
gdlint scripts/ tools/ && gdformat --check scripts/ tools/                  # lint (gdtoolkit 4)
```

## Credits

- 3D models: [Kenney](https://kenney.nl) Furniture Kit, Nature Kit and City Kit (Suburban), CC0
- Font: [Nunito](https://fonts.google.com/specimen/Nunito), SIL Open Font License
- Textures, icons, sound effects and music: made for this project (procedurally generated)
