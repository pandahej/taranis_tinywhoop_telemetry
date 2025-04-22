# TinyWhoop Telemetry v1.3 (TWTl13.lua)

A Lua telemetry script for **Taranis X9D (monochrome)**, especially made for **Mobula7 1S (SPI ELRS)** and other TinyWhoops running **EdgeTX**.

---

## 📺 Demo

![Demo](https://github.com/pandahej/taranis_tinywhoop_telemetry/releases/download/v1.3/output.gif)  
🎬 [Watch full video on YouTube](https://www.youtube.com/watch?v=5EBpXewKtxs)

---

## ✨ Features

### 🧠 Core Features (v1.2 & v1.3 combined)
- Grid-based layout: 3x2 cell system for clear data separation
- Battery voltage with per-cell calc (`RxBt`)
- RF mode display (`RFMD`)
- Telemetry and link quality: `RQly`, `TQly`, `TRSS`, `TWPR`
- Capacity used: `Capa`
- Timer 1 (Flight), Timer 2 (Total), and real-time clock
- Switch-based display for:
  - ARM (`SF`), FLIP (`SC`), BEEPER (`SG`), FLIGHT MODE (`SE`), Lap Timer (`SH`) + (`SB`)
- Minimal bitmap usage for speed and compatibility

### 🕒 Lap Timer (v1.3)
- Manual lap timer using `SH` toggle
- Visual display of:
  - Current lap time
  - Best lap time (auto-updated if better)
  - Lap number
- Display toggles between `BEST` label and time (when timer is stopped)
- Format: `M:SS.d` (e.g. `1:04.3`)
- All lap timers visible when `SB` is middle or up
- All timers reset when `SB` is up (visual stays)

### 🔊 Audio Feedback (v1.3)
- Lap sounds from `01_lap.wav` to `20_lap.wav`
- New record = `record.wav` played after best time lap
- Toggle via `play_lap_sounds = true/false` in script
- Stored in `/SCRIPTS/TELEMETRY/SOUNDS/`

---

## 🛠 Installation

Unzip `TinyWhoopTelemetry_v1.3.zip` to your SD card:
- /SCRIPTS/TELEMETRY/TWTl13.lua 
- /SCRIPTS/TELEMETRY/BMP/
- /SCRIPTS/TELEMETRY/SOUNDS/

> ✅ **Keep filenames max 6 characters** (`TWTl13.lua`)  
> 🎧 All `.wav` files are 16-bit, mono, 44.1 kHz PCM

---

## ⚙️ EdgeTX Setup (X9D)

1. When files are in place. Start your Taranis X9D and do the following
2. Press `MENU` → Select `Model` → go to `DISPLAY` page
3. Choose `Screen 1,2,3 or 4` → Set Type: `Script`
4. Set Script: `TWTl13`
5. Return to main view and hold `PAGE` ~2 seconds to activate

---

## 🧪 Tested With

- Mobula7 1S (SPI ELRS)
- Taranis X9D (2014)
- EdgeTX 2.9+
- ELRS Telemetry sensors (TPWR, CAPA, RFMD, etc)

---

## 🧠 Credits & Notes

- Originally forked from [tozes/taranis_telemetry](https://github.com/tozes/taranis_telemetry)
- Heavily rewritten & extended by **REVEN (revenfpv)**
- Lap timer audio uses **GLaDOS TTS voice**
- Less dependency on bitmap-based layouts

---

Enjoy and rip some packs!  
~ **REVEN**
