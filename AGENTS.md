# AGENTS.md

## What this repo does

Two standalone PowerShell scripts for **Nvidia A10 GPU** temperature-based fan/acoustic management on Windows — no AMD hardware involved despite the directory name:

- **`A10_FanCtrl.ps1`** — Polls GPU temp every 8s via `nvidia-smi` and switches Windows power plan (Saver <55°C, Balanced 55–72°C, High Perf >72°C) to indirectly control motherboard fan curves.
- **`A10_Temp_Logger.ps1`** — Polls GPU temp every 2s via `nvidia-smi` and writes to `gpu_temp.sensor` for [FanControl](https://getfancontrol.com/) file sensor input. Launched hidden via `Run_A10_Logger_Hidden.vbs`.

## Key requirements

- `nvidia-smi` must be on PATH (from NVIDIA GPU drivers).
- FanControl (third-party app) needed only for the logger+sensor workflow.
- All scripts run from `D:\GPU_Fan_control\`. Paths are hardcoded (not relative).

## Files at a glance

| File | Purpose |
|---|---|
| `A10_FanCtrl.ps1` | Power-plan loop (8s interval) |
| `A10_Temp_Logger.ps1` | Sensor-file writer (2s interval) |
| `Run_A10_Logger_Hidden.vbs` | Launch logger with no console window |
| `Stop_A10_Logger.bat` | Kill logger process by command-line match |
| `Enable_Autostart.ps1` | Install VBS launcher into Windows Startup folder |
| `fix_config.ps1` | Disable NvAPI/LibreHardwareMonitor in FanControl config to avoid crash |
| `gpu_temp.sensor` | Output consumed by FanControl |

## No toolchain

No build, test, lint, typecheck, package manager, or CI. Scripts run directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File A10_FanCtrl.ps1
```

## Updating scripts

Hardcoded paths (`D:\GPU_Fan_control\`), power-plan GUIDs, and temperature thresholds (55°C, 72°C) are the values most likely to need changing. No other gotchas.
