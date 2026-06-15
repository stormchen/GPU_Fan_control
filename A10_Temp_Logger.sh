#!/bin/bash
set -e

OUTPUT_FILE="/opt/a10-fan-control/gpu_temp.sensor"

echo "=========================================="
echo " Nvidia A10 Temperature Logger Started"
echo " Writing to: $OUTPUT_FILE"
echo "=========================================="

mkdir -p "$(dirname "$OUTPUT_FILE")"

while true; do
    gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)

    if [ -n "$gpu_temp" ] && [[ "$gpu_temp" =~ ^[0-9]+$ ]]; then
        echo "$gpu_temp" > "$OUTPUT_FILE"
        echo "$(date '+%H:%M:%S') | A10 Temp: ${gpu_temp}C -> written to file"
    else
        echo "$(date '+%H:%M:%S') | WARNING: Failed to get GPU temperature." >&2
    fi

    sleep 2
done
