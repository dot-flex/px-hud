# PX HUD

**Player Status, Speedometer & Streamed Minimap for FiveM**

![FiveM](https://img.shields.io/badge/FiveM-PX_HUD-00bcd4?style=flat-square)
![Frameworks](https://img.shields.io/badge/frameworks-ESX_%7C_QBCore_%7C_QBox-44cc11?style=flat-square)
![OneSync](https://img.shields.io/badge/OneSync-required-007ec6?style=flat-square)
[![Visitors](https://hits.sh/github.com/dot-flex/px-hud.svg?style=flat-square&label=visitors&color=007ec6)](https://hits.sh/github.com/dot-flex/px-hud/)

## ✨ Features

- **Circular status indicators** - Health, armor, stamina, microphone, hunger and thirst with colored rings and smooth transitions.
- **Digital speedometer** - Three-digit speed, dim leading zeros, gear badge and yellow fuel bar. MPH and KM/H support.
- **HUD customization** - Move and resize elements, save positions and toggle cinematic mode.
- **Three frameworks** - Automatic ESX, QBCore or Qbox detection.
## 📦 Dependencies

- **OneSync** enabled
- **One supported framework setup:**

| Framework | Core | Status source |
| --- | --- | --- |
| ESX | es_extended | esx_status and a needs resource such as esx_basicneeds |
| QBCore | qb-core | Player metadata |
| Qbox | qbx_core | Native Qbox exports and player metadata |

## ⚙️ Installation

Place this folder in your resources directory as **px-hud**. Start it after the framework:

```cfg
ensure px-hud
```
## 🎮 Controls

| Command / key | Action |
| --- | --- |
| /hud | Toggle visibility |
| /hudreload | Refresh minimap placement and needs |
| /hudedit | Open the HUD editor |
| /cinematic | Toggle cinematic bars |
| Y | Toggle engine |
| L | Toggle vehicle lock |
| B | Toggle seatbelt |

Vehicle bindings are configurable.

## 🔌 Integration

Server exports:

```lua
exports['px-hud']:AddStress(playerId, 5)
exports['px-hud']:RelieveStress(playerId, 10)
exports['px-hud']:SetStress(playerId, 25)
exports['px-hud']:Notify(playerId, { description = 'Saved', type = 'success' })
```

Client exports:

```lua
exports['px-hud']:SetVisible(true)
exports['px-hud']:SetSuppressed(true)
exports['px-hud']:SetSuppressed(false)
exports['px-hud']:Notify({ description = 'Saved', type = 'success' })
```
## 🗺️ Map & Stream Credits

- **F5 Studio** - Original GTA VI minimap stream package and FiveM integration.
- **F5 Studio** - FiveM port of the separate atlas map package.


## 📷 Showcase

![Showcase 1](https://i.ibb.co/FkkzX7nx/image.png)
![Showcase 2](https://i.ibb.co/fzVNNk0d/image.png)
