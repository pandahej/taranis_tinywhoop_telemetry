# Lua script for Taranis X9D (monocrome) and especially made for Mobula7 1S (SPI ELRS)

# TinyWhoop Telemetry v1.2 (TWTl12.lua)

A custom Lua telemetry script for **Taranis X9D (monochrome)** transmitters, originally designed for the **Mobula7 1S with ExpressLRS (SPI)**.

---

### ✨ Features
- Clean grid-based telemetry layout
- Battery status with per-cell voltage
- RSSI/TRSS and link quality via RQly
- RF mode and telemetry power readout
- Custom timers for flight and total time
- Beeper, arm, and flight mode indicators
- Minimal bitmap usage for fast loading

---


## 🖼️ Preview

![Preview of telemetry screen](https://i.imgur.com/zKpqCM6.jpeg)

![Preview 2](https://i.imgur.com/2NPLUot.jpeg)


### 🛠 Installation

With **EdgeTX**, place the files here on your SD card:

/SCRIPTS/TELEMETRY/TWTL12.LUA
/SCRIPTS/BMP/

> 📢 **Note:** Maximum filename length is **6 characters** on Taranis monochrome radios.

---

### 🧪 Notes

- Originally forked and heavily modified from [Tozes’ Telemetry Script](https://github.com/tozes/taranis_telemetry)
- Modded by **REVEN (revenfpv)** to support:
  - ExpressLRS sensors (TPWR, RFMD, CAPA etc.)
  - Better layout for minimal screen real estate
  - Less reliance on bitmap icons
- It’s not perfect, but it's clean, reliable, and does the job I need.  
  I also learned a ton of Lua in the process – hopefully it helps someone else too.

---

Enjoy flying! 🚁  
– REVEN
