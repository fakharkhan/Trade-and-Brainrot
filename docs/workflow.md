# Development workflow

## Source of truth

All game logic lives under [`src/`](../src/). Do **not** treat `TradeAndBrainrot.rbxlx` as the place to edit scripts by hand — Studio will overwrite disk changes when you save/close.

## Recommended: Rojo

1. Install [Rojo](https://rojo.space/) (`aftman add rojo-rbx/rojo` or download a release).
2. From the project root:
   ```bash
   rojo serve
   ```
3. In Roblox Studio, install the Rojo plugin and connect to `localhost:34872`.
4. Press Play. Edits under `src/` sync live.

Project file: [`default.project.json`](../default.project.json).

## Without Rojo: sync script

If Rojo is not installed, rebuild the place file from `src/`:

```bash
python3 tools/sync_place.py
```

Then open `TradeAndBrainrot.rbxlx` in Studio. **Close Studio first** (Don't Save if prompted) so Studio does not overwrite the synced file.

## Module layout

| Path | Role |
|------|------|
| `src/ReplicatedStorage/Shared/Config.lua` | Tunables, Studio vs live flags |
| `src/ReplicatedStorage/Shared/BrainrotDefs.lua` | Catalog + weighted pick |
| `src/ReplicatedStorage/Shared/Remotes.lua` | RemoteEvent factory |
| `src/ServerScriptService/Modules/*` | Server systems |
| `src/ServerScriptService/Main.server.lua` | Boot / world build |
| `src/ServerScriptService/TradeServer.server.lua` | P2P trading |
| `src/StarterPlayer/StarterPlayerScripts/TradeClient.client.lua` | HUD + trade UI |

## Studio vs live

`Config.IsStudio` gates:

- Higher start coins
- Free starter brainrot
- Free coins pad
- Free Super Upgrade when `SuperUpgradeProductId == 0`

These helpers do **not** run on a published live server.
