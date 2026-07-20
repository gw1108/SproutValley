# Sprout Valley 🌱

A cozy top-down 2D farming simulator built in **Godot 4**, in the spirit of Hay Day and Stardew Valley — with a storybook-style soft cartoon look.

# Itch.io webgl version

https://georgewang.itch.io/sprout-valley

## 🎥 Video

Watch the gameplay video here: **[https://youtu.be/JtmdU_SEURk)**

## About the Game

Sprout Valley has no on-screen player character — you act on the world directly by clicking things. Clear trees, buy seeds and buildings, grow crops, raise animals, process raw goods into refined products, and deliver them for money. Then reinvest and grow your farm.

**Core loop:** clear → buy → grow/raise → harvest → process → deliver → reinvest.

Design pillars:
- **Cozy, low-pressure progression** — no fail states; grow at your own pace.
- **A readable core loop** — plant/raise → harvest → process → sell → reinvest.
- **Meaningful spatial choices** — land is limited and partly blocked, so placement matters.

## Project Structure

| Path | Purpose |
| --- | --- |
| `sprout-valley/` | The Godot project — open **this** folder in the Godot editor. |
| `design/` | Game design documents (`GDD.md` is the source of truth). |
| `SourceArt/` | Source art and audio assets, with a searchable catalog. |
| `VISUAL_RULES.md` | Visual/rendering rules for the game's art style. |

## Running the Game

1. Install [Godot 4](https://godotengine.org/).
2. Open the `sprout-valley/` folder in the Godot editor.
3. Run the main scene.

Tunable gameplay numbers live in `sprout-valley/data/balance.csv` rather than in code constants, so balance can be tweaked without touching scripts.

## Development Notes

This project is developed with heavy use of AI agents (Claude Code). `CLAUDE.md` documents agent working conventions, and tests (gdUnit4, in `sprout-valley/test/`) are written when playtesting or regressions call for them.
