# Trade and Brainrot

Roblox trading / collection game. Brainrots ride a track — buy them, carry them to your base, earn coins, trade, steal, rebirth, and upgrade.

**Public repo:** https://github.com/fakharkhan/Trade-and-Brainrot

## Play locally

1. Prefer [Rojo](docs/workflow.md): `rojo serve` + Studio plugin  
   **or** run `python3 tools/sync_place.py` then open `TradeAndBrainrot.rbxlx`
2. Press **Play**
3. You spawn at your base with coins (and a starter brainrot in Studio)
4. Buy from the track, place on pedestals, sell extras to the Trader for coins, and spend coins on Levels (top of the screen)

## Features

- 12 brainrots across Common → Mythic (weighted track spawns)
- Auto income, carry/steal/place, Trader sell
- Player trading with offer expiry and optional slot selection
- Super Upgrade (Robux Developer Product; free in Studio when product ID unset)
- Player Levels 1 to 1000 (spend coins, +5% income per level) + Rebirth progression
- Sell brainrots to the Trader for coins (70% of price)
- DataStore persistence (after the place is published)
- Studio-only test helpers gated by `Config.IsStudio`

## Docs

- [Development workflow](docs/workflow.md)
- [Launch checklist](docs/launch-checklist.md)

## Assets

- [`assets/roblox-game-icon.jpg`](assets/roblox-game-icon.jpg)
- [`assets/roblox-game-thumbnail.jpg`](assets/roblox-game-thumbnail.jpg)
- [`assets/brainrot-capsule-creature.jpg`](assets/brainrot-capsule-creature.jpg) — Tralalero-style concept
- [`assets/brainrot-blocky-dude.jpg`](assets/brainrot-blocky-dude.jpg) — Patapim-style concept
- [`assets/brainrot-starburst.jpg`](assets/brainrot-starburst.jpg) — Boom Boom Stellina
- [`assets/brainrot-trio-sheet.jpg`](assets/brainrot-trio-sheet.jpg) — Antennini / Gattini / Spadino sheet
- [`assets/brainrot-flybeak.jpg`](assets/brainrot-flybeak.jpg) — Volanti Beccini
