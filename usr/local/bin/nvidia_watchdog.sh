#!/usr/bin/env bash
# ===================================================================================
# UNIVAC IX Infrastructure watch - Host NVIDIA Hardware Status Daemon
# Purpose: Detects GPU driver detachment and forces safe-mode container drops
# ===================================================================================

HEALTH_STATE_FILE="/tmp/bridge_health.state"
INTERVAL_SECS=2

echo "[*] Initializing Host-Level NVIDIA GPU PCIe Watchdog Loop..."

while true; do
    # Execute query to verify driver connectivity on the motherboard bus
    nvidia-smi -q -d SUPPORTED_CLOCKS > /dev/null 2>&1
    DRIVER_STATUS=$?

    if [ $DRIVER_STATUS -ne 0 ]; then
        echo -e "\n[!!!] CRITICAL ALARM: HOST HARDWARE-LEVEL NVIDIA GPU DETACHMENT DETECTED!" >&2
        echo "[-] Operating status code $DRIVER_STATUS returned via kernel driver space." >&2
        
        # 1. Breach the Docker Compose local health check file footprint immediately
        if [ -d "/tmp" ]; then
            echo "FAULT_HOST_GPU_DETACHED" > "$HEALTH_STATE_FILE"
        fi

        # 2. Issue forceful tear-down commands to the docker stack to prevent silent logic errors
        echo "[!] Hardware Isolation: Dropping active container infrastructure stacks..." >&2
        docker-compose -f /app/docker-compose.yml down --volumes

        echo "[!] CRITICAL: Closed loop dropped open. Mainframe operations safely isolated." >&2
        exit 1
    fi

    sleep $INTERVAL_SECS
done
