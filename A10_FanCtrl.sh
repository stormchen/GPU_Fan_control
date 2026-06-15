#!/bin/bash

CONFIG="/etc/a10-fan-control.conf"
HWMON_PATH=""
PWM_CHANNEL=7
TEMP_LOW=55
TEMP_HIGH=72
PWM_MIN=51
PWM_MAX=255
INTERVAL=8
GPU_POWER_LIMIT=120

[ -f "$CONFIG" ] && . "$CONFIG"

find_hwmon() {
    local d name
    for d in /sys/class/hwmon/hwmon*/name; do
        name=$(cat "$d" 2>/dev/null)
        case "$name" in
            nct679*|nct677*|nct61*)
                HWMON_PATH=$(dirname "$d")
                return 0
                ;;
        esac
    done
    return 1
}

if [ -z "$HWMON_PATH" ]; then
    if ! find_hwmon; then
        echo "FATAL: No Nuvoton hwmon device found. Load nct6775 module." >&2
        exit 1
    fi
fi

PWM="${HWMON_PATH}/pwm${PWM_CHANNEL}"
PWM_ENABLE="${HWMON_PATH}/pwm${PWM_CHANNEL}_enable"

if [ ! -w "$PWM" ]; then
    echo "FATAL: $PWM not writable. Run as root." >&2
    exit 1
fi

echo 1 > "$PWM_ENABLE" 2>/dev/null || true

cleanup() {
    echo 2 > "$PWM_ENABLE" 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "A10 Fan Control started"
echo "  hwmon: $HWMON_PATH"
echo "  fan:   pwm${PWM_CHANNEL}"
echo "  temp:  ${TEMP_LOW}°C / ${TEMP_HIGH}°C"
echo "  PID:   $$"

while true; do
    gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)

    if [ -z "$gpu_temp" ] || ! [[ "$gpu_temp" =~ ^[0-9]+$ ]]; then
        echo "$(date '+%H:%M:%S') | WARNING: Cannot read GPU temperature" >&2
        sleep "$INTERVAL"
        continue
    fi

    if [ "$gpu_temp" -lt "$TEMP_LOW" ]; then
        pwm_val=$PWM_MIN
    elif [ "$gpu_temp" -lt "$TEMP_HIGH" ]; then
        pwm_val=$(( PWM_MIN + (gpu_temp - TEMP_LOW) * (PWM_MAX - PWM_MIN) / (TEMP_HIGH - TEMP_LOW) ))
    else
        pwm_val=$PWM_MAX
        nvidia-smi -pl "$GPU_POWER_LIMIT" &>/dev/null || true
    fi

    echo "$pwm_val" > "$PWM" 2>/dev/null || true
    pct=$(( pwm_val * 100 / 255 ))
    echo "$(date '+%H:%M:%S') | GPU: ${gpu_temp}°C | PWM: ${pwm_val} (${pct}%)"

    sleep "$INTERVAL"
done
