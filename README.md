# 34tools: Play 2s Before Next Marker or Region

**Line:** 34tools Edit  
**Category:** Transport / Navigation  

## Overview

A tiny REAPER Lua script that jumps playback **2 seconds before** the **next marker** or **next region start** (whichever is closer), relative to your current position.

- If REAPER is **playing / paused / recording**, it uses the **play cursor** and **seeks without stopping**.
- If REAPER is **stopped**, it uses the **edit cursor**, jumps, and **starts playback**.

## Features

- Jumps to **(next marker OR next region start) - 2.0 seconds**
- Never goes before **0.0s**
- While playing: **no stop**, just a seek/jump
- While stopped: **sets edit cursor** and starts playback
- No dependencies (no SWS, no js_ReaScriptAPI)

## Who is it for

- Editors who want a fast **pre-roll** before the next edit point
- Podcast / dialogue editing workflows where markers or regions define the next checkpoint
- Anyone who wants a single hotkey for “play 2 seconds before next marker/region”

## Installation

1. Download the `.lua` file from this repository.
2. In REAPER: **Actions → Show action list…**
3. Click **ReaScript → Load…** and select the script:
   - `34tools_Edit_Play_2s_Before_Next_Marker_Or_Region.lua`
4. Assign a shortcut/hotkey if you want.

## Configuration

Open the script in a text editor and adjust:

- `PRE_ROLL_SEC` — pre-roll in seconds (default `2.0`)

## License

MIT — see [LICENSE](LICENSE).
