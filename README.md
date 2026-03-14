# 🚗💥 Ultra Realistic Vehicle Damage

> Transform your FiveM server with the most immersive vehicle damage system ever created! 

[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue.svg)](https://fivem.net/)
[![Lua](https://img.shields.io/badge/Lua-5.4-00007C.svg)](https://www.lua.org/)
[![License](https://img.shields.io/badge/License-Custom-red.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/L-E-R-O/fivem_lero_ultra_realistic_vehicle_damage?style=social)](https://github.com/L-E-R-O/fivem_lero_ultra_realistic_vehicle_damage/stargazers)

## ✨ What Makes This Special?

This isn't just another damage script—it's a complete physics overhaul that brings **real consequences** to your driving experience! Every crash, every collision, every scrape matters. Your engine will degrade, your body will crumple, and your fuel tank will leak. It's time to drive like you mean it! 🏁

### 🎯 Key Features

- **🔧 Realistic Engine Damage** - Engine health reacts to collisions and impacts only
- **⚡ Cascading Failures** - Severe damage escalates quickly
- **🛢️ Oil & Fuel System** - Emergency repairs use oil and are temporary
- **🚙 Vehicle Class Balancing** - Motorcycles break easier than tanks (obviously!)
- **🎨 Deformation Physics** - Watch your car crumple realistically
- **💪 Limp Mode** - Even dying engines can crawl home
- **🔨 Emergency Repairs** - MacGyver your way out with duct tape (temporarily!)
- **🌫️ Catastrophic Smoke** - Massive smoke effect when the engine is dead

## 📦 Installation

Super simple! Just like adding sprinkles to a cupcake 🧁

1. **Download** this repository
2. **Drop** the folder into your `resources` directory
3. **Add** to your `server.cfg`:
   ```cfg
   ensure fivem_lero_ultra_realistic_vehicle_damage
   ```
4. **Restart** your server and feel the difference!

## ⚙️ Configuration

Open `config.lua` and unleash your creativity! Here are some highlights:

```lua
cfg = {
    -- Damage multipliers (higher = more damage)
    damageFactorEngine = 5.0,      -- Engine damage intensity
    damageFactorBody = 5.0,        -- Body damage intensity
    damageFactorPetrolTank = 32.0, -- Fuel tank damage intensity

    -- Special features
    torqueMultiplierEnabled = true, -- Damaged engines = less power
    limpMode = false,               -- Allow crawling with dead engine

    -- Thresholds
    minDamageThreshold = 5.0,       -- Minimum raw delta to count as damage
    cascadingFailureThreshold = 360.0, -- When everything falls apart
    engineSafeGuard = 100.0,        -- Minimum engine health

    -- Smoke effects
    engineSmokeEnabled = true,      -- Enable catastrophic engine smoke
    engineSmokeScale = 5.0,         -- Smoke size (1.0 small, 10.0 extreme)
}
```

### 🎨 Per-Class Damage Multipliers

Different vehicles take damage differently! Customize how fragile each vehicle class is:

- 💨 **Motorcycles** (0.2) - Super fragile!
- 🏎️ **Sports/Super** (0.9) - Pretty tough
- 🚜 **Industrial/Military** (0.3) - Built like tanks
- 🚴 **Bicycles** (1.0) - Made of dreams and hope

## 🎮 Commands

- `/repair` - Attempt an emergency field repair (uses oil, temporary fix!)

## 🌟 Why You'll Love This

Traditional damage systems are boring. They just reduce a number and maybe smoke a bit. **Boring!** 😴

This system brings **drama** to your server:
- That fender bender? Your engine health drops immediately.
- Crashed into a wall? Better limp to a mechanic before total failure!
- Got shot? Hope you like walking!
- Oil running low? That repair won't hold for long...

It's not about *if* your car will break down, it's about *when* and *how dramatically*.

## 💡 Pro Tips

1. **Drive carefully** - Repairs are temporary and use oil!
2. **Watch your engine health** - Below 360? Start praying.
3. **Different vehicles = different durability** - Don't crash motorcycles!
4. **Keep oil in your tank** - No oil = no repairs = walking simulator

## 🤝 Contributing

Found a bug? Have an idea? We'd love to hear from you! Open an issue or submit a pull request. Let's make this even better together! 💪

## 📝 License

This project is created with ❤️ by **LERO**. Feel free to use it on your server, but please give credit where credit is due!

## 🙏 Credits

Made with passion by [LERO](https://github.com/L-E-R-O) for the FiveM community.

---

<div align="center">

### ⭐ If you love this, give us a star! ⭐

It really helps and motivates us to keep improving! 🚀

**Drive safe, crash dramatically!** 🎬💥

</div>
