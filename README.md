# Trade and Brainrot

Roblox trading / collection game. Brainrots ride a track — buy them, carry them to your base, earn coins, trade, steal, rebirth, and upgrade.

**Public repo:** https://github.com/fakharkhan/Trade-and-Brainrot

## Play locally

1. Prefer [Rojo](docs/workflow.md): `rojo serve` + Studio plugin  
   **or** run `python3 tools/sync_place.py` then open `TradeAndBrainrot.rbxlx`
2. Press **Play**
3. You spawn at your base with coins (and a starter brainrot in Studio)
4. Buy from the track, place on pedestals, claim Daily Bonus / Rebirth near the showcase

## Features

- 12 brainrots across Common → Mythic (weighted track spawns)
- Auto income, carry/steal/place, Trader sell
- Player trading with offer expiry and optional slot selection
- Super Upgrade (Robux Developer Product; free in Studio when product ID unset)
- Daily bonus + Rebirth progression
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
