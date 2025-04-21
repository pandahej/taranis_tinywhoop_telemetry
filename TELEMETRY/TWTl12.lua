-- TinyWhoop Telemetry Version 1.2 (TWTl12.lua) - 2025-04-21

-- Lua script for Taranis X9D (monocrome) and especially made for Mobula7 1S (SPI ELRS)
-- Shows battery status, timers, TRSS and flight modes on a grid


-- Modified for ELRS and other things by REVEN (revenfpv)


-- With EdgeTX, place the file in: /SCRIPTS/TELEMETRY/
-- The maximum filename length is SIX characters!


-- Spent way waaay too many hours modifying this. But it was fun learning lua. 
-- Didnt want to have too many bitmaps and also wanted to customise it a bit with ELRS.
-- Its not perfect but its good enough for me. Enjoy!


-- Original script from Tozes https://github.com/tozes/taranis_telemetry

--------------------------------------------------------------------------------
-- 🛠️ CONFIGURATION
--------------------------------------------------------------------------------
local battery_cells = 1         -- Number of cells (1S, 2S, 3S...)
local min_cell_voltage = 3.3    -- Min voltage per cell
local max_cell_voltage = 4.2    -- Max voltage per cell
local min_trss = 0              -- Minumum TRSS. This is different from RSSI
local max_trss = 100            -- Maximum TRSS

-- Image location
local image_location = "/SCRIPTS/TELEMETRY/BMP/"

-- Switches
local SW_ARM   = 'sf'  -- Arming
local SW_FMODE = 'se'  -- Flight mode
local SW_BEEPR = 'sh'  -- Beeper
local SW_FLIP  = 'sg'  -- Flip mode

-- Armed blinking
local should_blink_armed = true  -- true/false
local blink_interval = 90        -- Set blinking interval. 90 means 0.9 seconds

-- Timer labels
local flight_label = "FLT"
local total_label = "TOT"
local time_label = "TIME"

--------------------------------------------------------------------------------
-- ✏️ SENSOR DEFINITIONS
--------------------------------------------------------------------------------
local DS_VFAS  = 'RxBt'   -- Receiver battery voltage (used to calculate per-cell voltage)
local DS_TRSS  = 'TRSS'   -- Telemetry RSSI (signal strength of telemetry uplink)
local DS_BATP  = 'Bat%'   -- Battery percentage (overall battery estimate from RX)
local DS_RQLY  = 'RQly'   -- Link quality (quality of the control link from TX to RX)
local DS_TQLY  = 'TQly'   -- Telemetry quality (quality of telemetry from RX to TX)
local DS_RFMD  = 'RFMD'   -- RF mode (e.g. D25, F100 – used for ExpressLRS mode reporting)
local DS_TPWR  = 'TPWR'   -- Telemetry power (telemetry module's output power in mW)
local DS_CAP   = 'Capa'   -- Capacity used (mAh consumed from battery)

--------------------------------------------------------------------------------
-- 🔢 HELPER: ROUNDING FUNCTION
--------------------------------------------------------------------------------
local function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

--------------------------------------------------------------------------------
-- 📀 DISPLAY GRID
--------------------------------------------------------------------------------
local min_x, min_y = 0, 0                          -- start point of the full screen (top-left)
local max_x, max_y = 211, 63                       -- screen resolution (Taranis X9D: 212x64)
local header_height = 0                            -- reserved space for an optional header (currently not used)
local grid_limit_left, grid_limit_right = 33, 180  -- horizontal limits for the grid (the area excluding battery/RSSI at sides)
local grid_width = round((max_x - (max_x - grid_limit_right) - grid_limit_left), 0) -- calculate grid width by subtracting side margins
local grid_height = round(max_y - min_y - header_height)                            -- total height available for grid (entire screen - header)
local grid_middle = round((grid_width / 2) + grid_limit_left, 0)                    -- calculate center of the grid horizontally (used to split left/right columns)
local cell_height = round(grid_height / 3, 0)                                       -- height of one cell row (grid divided into 3 rows)

--------------------------------------------------------------------------------
-- 📊 CELL GRID BORDERS
--------------------------------------------------------------------------------
local function drawGrid()
  lcd.drawLine(grid_limit_left, min_y, grid_limit_right, min_y, SOLID, FORCE)        -- Top border
  lcd.drawLine(grid_limit_left, min_y, grid_limit_left, max_y, SOLID, FORCE)         -- Left border
  lcd.drawLine(grid_limit_right, min_y, grid_limit_right, max_y, SOLID, FORCE)       -- Right border
  lcd.drawLine(grid_limit_left, max_y, grid_limit_right, max_y, SOLID, FORCE)        -- Bottom border
  lcd.drawLine(grid_middle, min_y + header_height, grid_middle, max_y, SOLID, FORCE) -- Vertical middle
  lcd.drawLine(grid_limit_left, cell_height + header_height - 2, grid_limit_right, cell_height + header_height -2, SOLID, FORCE)          -- Horizontal divider 1
  lcd.drawLine(grid_limit_left, cell_height * 2 + header_height - 1, grid_limit_right, cell_height * 2 + header_height - 1, SOLID, FORCE) -- Horizontal divider 2
end

--------------------------------------------------------------------------------
-- 🔋 BATTERY CELL (LEFT SIDE)
--------------------------------------------------------------------------------
local function drawBatt()
  local batt = getValue(DS_BATP) or 0
  local volt = getValue(DS_VFAS) or 0
  local cell = volt / battery_cells
  local total_steps = 30
  local current_level = math.floor((batt / 100) * total_steps)

  lcd.drawPixmap(2, 2, image_location .. "batt.bmp")  -- background image
  lcd.drawFilledRectangle(3, 10 + (30 - current_level), 26, current_level, SOLID)
  lcd.drawText(1, 45, round(cell, 2) .. "V", DBLSIZE)
end

--------------------------------------------------------------------------------
-- 🧭 CELLS (FLIGHT MODE, SWITCHES, MISC, CLOCK, TIMERS)
--------------------------------------------------------------------------------
-- CELL 1: Flight mode icon and label
local function cell_1()
  local fm = getValue(SW_FMODE)
  local f_mode = "UNKN"
  if fm < -1000 then f_mode = "ACRO"
  elseif fm > 1000 then f_mode = "HRZN"
  else f_mode = "ANGL" end
  lcd.drawPixmap(grid_limit_left + 2, 2, image_location .. "fmode.bmp")
  lcd.drawText(grid_limit_left + 28, 2, f_mode, DBLSIZE)
end

-- CELL 2: ARM, FLIP and BEEPER switch indicators
local function cell_2()
  local base_x = grid_limit_left + 5
  local base_y = min_y + header_height + cell_height + 1
  local pad = 8
  local w1 = 29 -- width of ARMED background
  local w2 = 22 -- width of FLIP background
  local w3 = 33 -- width of BEEPER background
  local h = 8

  local armed = getValue(SW_ARM) > 10
  local flip = getValue(SW_FLIP) > 10
  local beepr = getValue(SW_BEEPR) > 10
  local x_flip = base_x + 30 + pad -- number sets position of where to start drawing flip
  local x_beep = base_x + 25 + pad -- number sets position of where to start drawing beeper
  
  local blink = (should_blink_armed and math.floor(getTime() / blink_interval) % 2 == 0)

  if armed and blink then
    lcd.drawFilledRectangle(base_x, base_y, w1, h, SOLID)
    lcd.drawRectangle(base_x, base_y, w1, h, SOLID)
    lcd.drawText(base_x + 2, base_y + 1, "ARMED", INVERS + SMLSIZE)
  end

  if flip then
    lcd.drawFilledRectangle(x_flip, base_y, w2, h, SOLID)
    lcd.drawRectangle(x_flip, base_y, w2, h, SOLID)
    lcd.drawText(x_flip + 2, base_y + 1, "FLIP", INVERS + SMLSIZE)
  end

  if beepr then
    lcd.drawFilledRectangle(x_beep, base_y + h + 1, w3, h, SOLID)
    lcd.drawRectangle(x_beep, base_y + h + 1, w3, h, SOLID)
    lcd.drawText(x_beep + 2, base_y + h + 2, "BEEPER", INVERS + SMLSIZE)
  end
end

-- CELL 3: Misc data - RF mode, CAPA, TQly, Tpwr
local function cell_3()
  local base_x = grid_limit_left + 5
  local base_y = min_y + header_height + cell_height * 2 + 2 -- last two numbers moves everything down by pixels (cell 3 vertical offset)
  local h = 8

  local rfmd_raw = getValue(DS_RFMD)
  local rfmd_map = {
    [0] = "D25", [1] = "D50", [2] = "D100", [3] = "D150",
    [4] = "D250", [5] = "F50", [6] = "F150", [7] = "F500"
  }
  local rfmd = rfmd_map[rfmd_raw] or (rfmd_raw or "-")

  local tql = getValue(DS_TQLY)
  if tql == nil then 
    tql = "-" 
  else tql = math.min(99, tql)  -- This is set to a maximum of 99% because 100% would need extra space we do not have
  end
  
  local tpwr = getValue(DS_TPWR)
  if tpwr == nil then 
    tpwr = "-"
  end
  
  local cap = getValue(DS_CAP)
  if cap == nil then 
    cap = "-"
  end

  -- First row left: RF mode label and value
  local w_rfmd_lbl = 11           -- width of the label
  local w_rfmd_val = 19           -- width of the value
  local x1 = base_x - 3           -- last value shifts the row 3px left so it is only 0px from the edge. 2 would set 1px from left
  local x2 = x1 + w_rfmd_lbl + 0  -- last value sets spacing between rfmode label and value

  lcd.drawFilledRectangle(x1, base_y, w_rfmd_lbl, h, SOLID)
  lcd.drawRectangle(x1, base_y, w_rfmd_lbl, h, SOLID)
  lcd.drawText(x1 + 1, base_y + 1, "RF", INVERS + SMLSIZE)  -- draw label. first number here moves the label 1px to the right from x1
  lcd.drawText(x2 + 1, base_y + 1, rfmd, SMLSIZE)           -- draw value

  -- First row right: CAP label and value
  local w_cap_lbl = 17            -- width of the label
  local w_cap_val = 20            -- width of the value
  local x3 = x2 + w_rfmd_val + 2  -- last value sets horizontal spacing between RFMD value and CAP label
  local x4 = x3 + w_cap_lbl + 1   -- last value sets spacing between cap label and value

  lcd.drawFilledRectangle(x3, base_y, w_cap_lbl, h, SOLID)
  lcd.drawRectangle(x3, base_y, w_cap_lbl, h, SOLID)
  lcd.drawText(x3 + 1, base_y + 1, "mHa", INVERS + SMLSIZE)   -- draw label. first number here moves the label 1px to the right from x3
  lcd.drawText(x4, base_y + 1, round(cap, 0) .. "", SMLSIZE)  -- draw value
  
  local y2 = base_y + h + 1  -- second row (below the first line)

 -- Second row left: TQly label and value
  local w_tq_lbl = 19           -- width of the label
  local w_tq_val = 17           -- width of the value
  local x5 = base_x - 3         -- last value shifts the row 3px left so it is only 0px from the edge. 2 would set 1px from left
  local x6 = x5 + w_tq_lbl + 0  -- last value sets spacing between tqly label and value

  lcd.drawFilledRectangle(x5, y2, w_tq_lbl, h, SOLID)
  lcd.drawRectangle(x5, y2, w_tq_lbl, h, SOLID)
  lcd.drawText(x5 + 1, y2 + 1, "TQly", INVERS + SMLSIZE)       -- draw label. first number here moves the label 1px to the right from x5
  lcd.drawText(x6 + 1, y2 + 1, round(tql, 0) .. "%", SMLSIZE)  -- draw variable

-- Second row right: Tpwr label and value
  local w_tpwr_lbl = 16           -- width of the label
  local w_tpwr_val = 8            -- width of the value
  local x7 = x6 + w_tq_val + 0    -- the last number sets spacing between TQly value and Tpwr label
  local x8 = x7 + w_tpwr_lbl + 1  -- last value sets spacing between tpwr label and value

  lcd.drawFilledRectangle(x7, y2, w_tpwr_lbl, h, SOLID)
  lcd.drawRectangle(x7, y2, w_tpwr_lbl, h, SOLID)
  lcd.drawText(x7, y2 + 1, "TmW", INVERS + SMLSIZE)
  lcd.drawText(x8, y2 + 1, (type(tpwr) == "number" and round(tpwr, 0) .. "" or tpwr), SMLSIZE) -- draw variable
end


-- CELL 4: Current time (Clock)
local function cell_4()
  local t = getDateTime()
  lcd.drawText(grid_middle + 4, 2, string.format("%02d:%02d:%02d", t.hour, t.min, t.sec), DBLSIZE)
end


-- CELL 5: Timer 1 (Flight time)
local function cell_5()
  local timer = model.getTimer(0).value
  local s = timer
  local time = string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)
  local x = grid_middle + 3
  local y = min_y + header_height + cell_height + 1

  lcd.drawFilledRectangle(x, y, 20, 17, SOLID)
  lcd.drawRectangle(x, y, 20, 17, SOLID)
  lcd.drawText(x + 1, y + 2, flight_label, INVERS + SMLSIZE)  -- draw label first row
  lcd.drawText(x + 1, y + 9, time_label, INVERS + SMLSIZE)    -- draw label second row
  lcd.drawText(grid_middle + 25, y + 3, time, MIDSIZE)        -- draw timer
end


-- CELL 6: Timer 2 (Total time)
local function cell_6()
  local timer = model.getTimer(1).value
  local s = timer
  local time = string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)
  local x = grid_middle + 3
  local y = min_y + header_height + cell_height * 2 + 2

  lcd.drawFilledRectangle(x, y, 20, 17, SOLID)
  lcd.drawRectangle(x, y, 20, 17, SOLID)
  lcd.drawText(x + 1, y + 2, total_label, INVERS + SMLSIZE)  -- draw label first row
  lcd.drawText(x + 1, y + 9, time_label, INVERS + SMLSIZE)   -- draw label second row
  lcd.drawText(grid_middle + 25, y + 3, time, MIDSIZE)       -- draw timer
end

-- 📶 TRSS BAR (based on RQly)
local function drawTRSS()
  local rqly = getValue(DS_RQLY) or 0
  local total_steps = 10
  local step_size = 100 / total_steps
  local current_level = math.floor(rqly / step_size)

  local file = string.format("%02d", math.max(0, math.min(10, current_level)))
  lcd.drawPixmap(grid_limit_right + 2, 2, image_location .. "TRSS" .. file .. ".bmp")
  lcd.drawText(184, 45, round(rqly, 0), DBLSIZE)  -- draw value
end

--------------------------------------------------------------------------------
-- 🔁 MAIN LOOP
--------------------------------------------------------------------------------
local function run(event)
    lcd.clear() -- clear screen before drawing
    drawGrid()
    drawBatt()
    drawTRSS()
    cell_1()
    cell_2()
    cell_3()
    cell_4()
    cell_5()
    cell_6()
end

return { run = run } -- export run function
