#!/bin/bash
set -e

INSTALL_DIR="/opt/a10-fan-control"
CONFIG_FILE="/etc/a10-fan-control.conf"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)."
    exit 1
fi

echo "=========================================="
echo " A10 Fan Control - Linux Installation"
echo "=========================================="

echo ""
echo "[1/6] Checking dependencies..."

if ! command -v nvidia-smi &>/dev/null; then
    echo "ERROR: nvidia-smi not found. Install NVIDIA driver first." >&2
    exit 1
fi

if ! lsmod | grep -q nct6775; then
    echo "Loading nct6775 kernel module..."
    modprobe nct6775 2>/dev/null || modprobe nct6775 force_id=0xd420 2>/dev/null || true
fi

echo "  nvidia-smi: OK"
echo "  nct6775:    $(lsmod | grep -q nct6775 && echo 'OK' || echo 'NOT LOADED')"

echo ""
echo "[2/6] Detecting Nuvoton hwmon device..."

HWMON_PATH=""
for d in /sys/class/hwmon/hwmon*/name; do
    name=$(cat "$d" 2>/dev/null)
    case "$name" in
        nct679*|nct677*|nct61*)
            HWMON_PATH=$(dirname "$d")
            echo "  Found: $HWMON_PATH ($name)"
            break
            ;;
    esac
done

if [ -z "$HWMON_PATH" ]; then
    echo "ERROR: No Nuvoton hwmon device detected." >&2
    echo "  Try: sudo modprobe nct6775 force_id=0xd420" >&2
    echo "  If on kernel <6.3, upgrade or add acpi_enforce_resources=lax to GRUB." >&2
    exit 1
fi

echo ""
echo "[3/6] Verifying PWM fan control (AIO_PUMP = pwm7)..."

PWM="${HWMON_PATH}/pwm7"
PWM_ENABLE="${HWMON_PATH}/pwm7_enable"
FAN_INPUT="${HWMON_PATH}/fan7_input"

if [ ! -e "$PWM" ]; then
    echo "  WARNING: pwm7 not found. Available PWMs:"
    for p in "$HWMON_PATH"/pwm[0-9]; do
        echo "    $(basename $p)"
    done
    echo ""
    read -p "  Enter PWM channel for AIO_PUMP (e.g. 7): " pwm_sel
    PWM_CHANNEL="${pwm_sel:-7}"
    PWM="${HWMON_PATH}/pwm${PWM_CHANNEL}"
    PWM_ENABLE="${HWMON_PATH}/pwm${PWM_CHANNEL}_enable"
    FAN_INPUT="${HWMON_PATH}/fan${PWM_CHANNEL}_input"
else
    PWM_CHANNEL=7
fi

if [ ! -e "$PWM" ]; then
    echo "ERROR: $PWM does not exist." >&2
    exit 1
fi

echo "  PWM channel: pwm${PWM_CHANNEL}"
echo "  Testing fan at 30% speed for 3 seconds..."

echo 1 > "$PWM_ENABLE" 2>/dev/null || true
echo 77 > "$PWM" 2>/dev/null

sleep 3

if [ -f "$FAN_INPUT" ]; then
    rpm=$(cat "$FAN_INPUT")
    echo "  Fan RPM: $rpm"
fi

echo 0 > "$PWM_ENABLE" 2>/dev/null || true
echo 255 > "$PWM" 2>/dev/null || true

echo "  Fan test complete (restored to auto)."

echo ""
echo "[4/6] Creating configuration..."

cat > "$CONFIG_FILE" <<EOF
# A10 Fan Control Configuration
# Installed: $(date)

HWMON_PATH="$HWMON_PATH"
PWM_CHANNEL=$PWM_CHANNEL
TEMP_LOW=55
TEMP_HIGH=72
PWM_MIN=51
PWM_MAX=255
INTERVAL=8
GPU_POWER_LIMIT=120
EOF

echo "  Config written to $CONFIG_FILE"

echo ""
echo "[5/6] Installing scripts to $INSTALL_DIR..."

mkdir -p "$INSTALL_DIR"

cp "$(dirname "$0")/A10_FanCtrl.sh" "$INSTALL_DIR/"
cp "$(dirname "$0")/A10_Temp_Logger.sh" "$INSTALL_DIR/"
cp "$(dirname "$0")/stop_logger.sh" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/A10_FanCtrl.sh"
chmod +x "$INSTALL_DIR/A10_Temp_Logger.sh"
chmod +x "$INSTALL_DIR/stop_logger.sh"

echo ""
echo "[6/6] Installing systemd services..."

cp "$(dirname "$0")/a10-fanctrl.service" /etc/systemd/system/
cp "$(dirname "$0")/a10-temp-logger.service" /etc/systemd/system/

systemctl daemon-reload

echo ""
echo "=========================================="
echo " Installation complete!"
echo "=========================================="
echo ""
echo "Start fan control:    sudo systemctl enable --now a10-fanctrl"
echo "Start logger:         sudo systemctl enable --now a10-temp-logger"
echo "Stop logger:          sudo $INSTALL_DIR/stop_logger.sh"
echo "Monitor:              sudo journalctl -u a10-fanctrl -f"
echo ""
echo "To test now (without systemd):"
echo "  sudo $INSTALL_DIR/A10_FanCtrl.sh"
echo ""
echo "Config: $CONFIG_FILE"
