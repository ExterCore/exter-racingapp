# QBCore Racing Tablet (NoPixel 4.0 Inspired)

A modern racing tablet script for **QBCore** built with a user interface inspired by **NoPixel 4.0**. This script allows players to create, join, and manage street races directly from a sleek in-game tablet UI.

## 🌟 Features

- Stylish NoPixel 4.0-inspired tablet UI
- Create, manage, and view race tracks
- Supports lap-based races
- Displays Boosting Level (visual only)
- Race info includes:
  - Track name
  - Race class
  - Type (Lap or Point-to-Point)
  - Buy-in amount
  - Total laps and distance
- Active, Pending, and Completed race lists
- Admin tools: Create tracks, view ladders, manage races

## 📦 Requirements

- [QBCore Framework](https://github.com/qbcore-framework)
- A server running on **FiveM**

## 🚀 Installation

1. **Download or Clone the Repository**

```bash
git clone https://github.com/yourusername/exter-racingapp.git
```

2. **Add the Resource to Your Server**

Place the folder into your `resources/[qb]` directory.

3. **Ensure the Script in server.cfg**

```cfg
ensure exter-racingapp
```

4. **Dependencies**

Make sure all required dependencies are installed and running properly (e.g., `qb-core`).

## 🔧 Configuration

Adjust settings in `config.lua` if applicable.

## 📷 Preview

![trt](https://github.com/user-attachments/assets/55222d02-903d-4e34-81b2-06e18c48f4bc)


---

## snippest


# Add this items if you using qb-inventory `qb-core/shared/items.lua`

```lua
racetablet            = { name = 'racetablet', label = 'racetablet', weight = 500, type = 'item', image = 'np_tablet.png', unique = true, useable = true, shouldClose = true, combinable = nil, description= 'Tablet' },
racechip         = { name = 'racechip', label = 'racechip', weight = 500, type = 'item', image = 'underground_chip.png', unique = true, useable = true, shouldClose = true, combinable = nil, description ="racechip" },
trackchip            = { name = 'trackchip', label = 'trackchip', weight = 500, type = 'item', image = 'track_chip.png', unique = true, useable = true, shouldClose = true, combinable = nil, description="trackchip" },
```
# Add this items if you using ox_inventory `ox_inventory/data/items.lua`
```
['racetablet'] = {
    label = 'racetablet',
    weight = 500,
    stack = false,
    close = true,
    description = 'Tablet',
    client = {
        image = 'np_tablet.png'
    }
},

['racechip'] = {
    label = 'racechip',
    weight = 500,
    stack = false,
    close = true,
    description = 'racechip',
    client = {
        image = 'underground_chip.png'
    }
},

['trackchip'] = {
    label = 'trackchip',
    weight = 500,
    stack = false,
    close = true,
    description = 'trackchip',
    client = {
        image = 'track_chip.png'
    }
},
```
## 💬 Support

Open an issue or contact me for help or suggestions.

**Enjoy the race! 🏁**
