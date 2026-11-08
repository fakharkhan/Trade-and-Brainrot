# Pre-publish checklist

Use this before making the experience public on Roblox.

## Creator Hub

- [ ] Publish the place at least once (enables DataStores).
- [ ] Create Developer Product **Super Upgrade Brainrot** (e.g. 100 Robux).
- [ ] Paste the product ID into `Config.SuperUpgradeProductId` in [`src/ReplicatedStorage/Shared/Config.lua`](../src/ReplicatedStorage/Shared/Config.lua).
- [ ] Re-sync / Rojo sync, then **Publish to Roblox** again.
- [ ] Set experience **Public** (Audience / Access).
- [ ] Upload `assets/store/game-icon-512.png` (Icon) and `assets/store/game-thumbnail-1920x1080.png` (Thumbnails) in Creator Hub > Experience > Places > Icon / Thumbnails.

## Safety

- [ ] Confirm Studio helpers are off on live (`Config.IsStudio` is false on servers).
- [ ] Play on a published test server: join twice and verify coins/brainrots persist.
- [ ] Verify Super Upgrade prompts Robux (not free grant).
- [ ] Verify the Trader Level Up prompt and the Rebirth pad.
- [ ] Test steal cooldown + 15s protect window with 2 players.
- [ ] Test trade offer expiry (~30s) and decline/accept.
- [ ] Confirm free-coins Studio pad is **absent** on the live server.

## Playtest matrix

| Case | Expected |
|------|----------|
| Buy from track → place | Coins drop, income rises |
| Leave and rejoin | Coins + slots restored |
| DataStore outage | Defaults used; no wipe of prior saves |
| Steal | Cooldown; victim gets protect window |
| Trade while carrying | Blocked with message |
| Rebirth under income | Rejected; at threshold resets + bonus |

## After launch

- [ ] Watch Creator Hub → Analytics / Errors for the first hour.
- [ ] Keep `SuperUpgradeProductId` and DataStore names stable (changing wipe risk).
