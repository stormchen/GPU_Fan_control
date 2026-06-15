# Nvidia A10 GPU Fan Control — Linux

Two Bash scripts for temperature-based fan/acoustic management of an **Nvidia A10 GPU** on Linux — controls a **chassis fan** (connected to the motherboard PWM header, e.g. AIO_PUMP) using the **Nuvoton NCT6799D** Super I/O chip's sysfs interface.

## Requirements

- **Nvidia A10 GPU** with NVIDIA proprietary driver (provides `nvidia-smi`)
- **ASUS TUF GAMING B650M-PLUS WIFI** (or any board with NCT6799D or compatible Nuvoton chip)
- **Linux kernel ≥6.3** (for built-in `nct6775` WMI support)
- Fan connected to a motherboard PWM header (e.g. AIO_PUMP)

## Quick start

### 1. Install

```bash
sudo ./install.sh
```

This will:
- Load the `nct6775` kernel module
- Detect the Nuvoton hwmon device
- Verify PWM fan control on AIO_PUMP
- Install scripts to `/opt/a10-fan-control/`
- Create config at `/etc/a10-fan-control.conf`
- Install systemd service units

### 2. Start

```bash
# Fan control daemon (auto-start on boot)
sudo systemctl enable --now a10-fanctrl

# Temperature logger (optional)
sudo systemctl enable --now a10-temp-logger
```

### 3. Monitor

```bash
sudo journalctl -u a10-fanctrl -f
```

## How it works

| GPU Temp | Fan Speed | PWM | Effect |
|---|---|---|---|
| < 55°C | 20% | 51 | Silent |
| 55–72°C | 20–100% (linear) | 51–255 | Ramping cooling |
| > 72°C | 100% + GPU power limit → 120W | 255 | Max cooling |

The script reads GPU temperature via `nvidia-smi` (every 8s) and writes the corresponding PWM value to `/sys/class/hwmon/hwmon*/pwm7` (AIO_PUMP). At high temperature it also reduces GPU power limit via `nvidia-smi -pl 120` to bring heat down faster.

## Manual test

```bash
sudo /opt/a10-fan-control/A10_FanCtrl.sh
```

## Temperature logger (for FanControl / monitoring)

```bash
# Runs as a service (2s interval, writes to /opt/a10-fan-control/gpu_temp.sensor)
sudo systemctl start a10-temp-logger

# Stop
sudo /opt/a10-fan-control/stop_logger.sh
```

## Configuration

Edit `/etc/a10-fan-control.conf`:

```bash
HWMON_PATH="/sys/class/hwmon/hwmonX"   # Auto-detected
PWM_CHANNEL=7                           # AIO_PUMP
TEMP_LOW=55                             # °C, fan at minimum below this
TEMP_HIGH=72                            # °C, fan at maximum above this
PWM_MIN=51                              # 20% duty cycle
PWM_MAX=255                             # 100% duty cycle
INTERVAL=8                              # Seconds between polls
GPU_POWER_LIMIT=120                     # Watts, applied when > TEMP_HIGH
```

## Files

| File | Purpose |
|---|---|
| `A10_FanCtrl.sh` | Main fan control loop (8s interval) |
| `A10_Temp_Logger.sh` | Temperature sensor file writer (2s interval) |
| `stop_logger.sh` | Kill the logger process |
| `install.sh` | One-shot installer |
| `a10-fanctrl.service` | systemd service unit |
| `a10-temp-logger.service` | systemd service unit |
| `/etc/a10-fan-control.conf` | Runtime configuration |

## Troubleshooting

**`nct6775` module not loading:**
```bash
sudo modprobe nct6775 force_id=0xd420
```

**No hwmon device detected (kernel <6.3):**
```bash
# Add to GRUB_CMDLINE_LINUX in /etc/default/grub
acpi_enforce_resources=lax
sudo update-grub && reboot
```

**Can't write PWM:**
Run the script/service as root. The sysfs hwmon files are owned by root.
