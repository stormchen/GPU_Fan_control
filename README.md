# Nvidia A10 GPU Fan Control

Two PowerShell scripts for temperature-based fan/acoustic management of an **Nvidia A10 GPU** on Windows — no AMD hardware, despite the directory name.

## How it works

This project controls GPU cooling by manipulating **Windows power plans**, which indirectly changes motherboard fan curves set by your BIOS. No third-party kernel drivers or fan-modding tools are needed.

| Temperature | Power Plan | Effect |
|---|---|---|
| &lt; 55°C | **Power Saver** | CPU throttles, motherboard fans spin down to silent |
| 55–72°C | **Balanced** | Standard voltage/fan profile |
| &gt; 72°C | **High Performance** | CPU unlocked, BIOS detects high load, fans ramp up hard |

A separate logger script writes the GPU temperature to a file every 2 seconds for use with [FanControl](https://getfancontrol.com/) (optional).

## Requirements

- **Nvidia A10 GPU** (or any Nvidia GPU — edit the thresholds to suit your card)
- NVIDIA GPU drivers (provides `nvidia-smi`)
- Windows 10/11 with `powercfg` available
- [FanControl](https://getfancontrol.com/) (optional, only for the sensor file workflow)

## Quick start

### Fan control loop (power plan switching)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File A10_FanCtrl.ps1
```

Leave this running in a terminal. It polls GPU temp every 8 seconds and switches power plans automatically.

### Temperature logger (for FanControl integration)

Launch hidden (recommended):

```cmd
wscript Run_A10_Logger_Hidden.vbs
```

Or visible:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File A10_Temp_Logger.ps1
```

The logger writes to `gpu_temp.sensor`. In FanControl, add a **File Sensor** pointing to this file.

Stop the logger:

```cmd
Stop_A10_Logger.bat
```

### Autostart (optional)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Enable_Autostart.ps1
```

Creates a Startup shortcut that launches the logger hidden on every boot.

### Fix FanControl crashes (optional)

If FanControl crashes with NvAPI wrapper or LibreHardwareMonitor GPU sensors enabled:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File fix_config.ps1
```

## Configuration

All paths, thresholds, and power plan GUIDs are hardcoded in the scripts. The values most likely to need changing:

| Value | Location | Default |
|---|---|---|
| Temp threshold (low→balanced) | `A10_FanCtrl.ps1:25` | 55°C |
| Temp threshold (balanced→high) | `A10_FanCtrl.ps1:30` | 72°C |
| Power plan GUIDs | `A10_FanCtrl.ps1:6-8` | Windows built-in GUIDs |
| Script root path | multiple files | `D:\GPU_Fan_control\` |
| Polling interval | `A10_FanCtrl.ps1:51` | 8s |
| Polling interval | `A10_Temp_Logger.ps1:36` | 2s |

## Files

| File | Purpose |
|---|---|
| `A10_FanCtrl.ps1` | Power-plan switching loop (8s interval) |
| `A10_Temp_Logger.ps1` | Sensor file writer (2s interval) |
| `Run_A10_Logger_Hidden.vbs` | Launches logger without a console window |
| `Stop_A10_Logger.bat` | Kills the logger process |
| `Enable_Autostart.ps1` | Installs VBS launcher in Windows Startup |
| `fix_config.ps1` | Disables crash-causing sensors in FanControl |
| `gpu_temp.sensor` | Output file consumed by FanControl |
