#!/usr/bin/env bash
# ===================================================================================
# UNIVAC IX Infrastructure watch - Host NVIDIA Hardware Status Daemon
# Purpose: Detects GPU driver detachment, triggers audio alarms, and drops stack.
# ===================================================================================

HEALTH_STATE_FILE="/tmp/bridge_health.state"
INTERVAL_SECS=2

echo "[*] Initializing Host-Level NVIDIA GPU PCIe Watchdog Loop with Audio Alerts..."

trigger_control_room_audio() {
    echo "[!] ALERT: BROADCASTING CRITICAL HARDWARE FAULT OVER ALARM HORN TRANSMITTERS..."
    
    # Loop an audible terminal audio alarm warning pattern
    for i in {1..5}; do
        # Method A: Direct motherboard PC speaker tone frequency injection
        echo -e "\a" > /dev/tty1
        
        # Method B: ALSA audio infrastructure wav injection if a speaker channel is active
        if command -v aplay > /dev/null 2>&1; then
            aplay /usr/share/sounds/alsa/Rear_Center.wav > /dev/null 2>&1
        fi
        sleep 0.5
    done
}

while true; do
    # Execute query to verify driver connectivity on the motherboard bus
    nvidia-smi -q -d SUPPORTED_CLOCKS > /dev/null 2>&1
    DRIVER_STATUS=$?

    if [ $DRIVER_STATUS -ne 0 ]; then
        echo -e "\n[!!!] CRITICAL ALARM: HOST HARDWARE-LEVEL NVIDIA GPU DETACHMENT DETECTED!" >&2
        
        # Ingress the hardware failure footprint immediately for the Docker healthcheck
        if [ -d "/tmp" ]; then
            echo "FAULT_HOST_GPU_DETACHED" > "$HEALTH_STATE_FILE"
        fi

        # Execute control room audio warning loops instantly before stack termination finishes
        trigger_control_room_audio

        # Drop active container networks to isolate processing lines cleanly
        echo "[!] Hardware Isolation: Dropping active container infrastructure stacks..." >&2
        docker-compose -f /app/docker-compose.yml down --volumes

        echo "[!] CRITICAL: Closed loop dropped open. Mainframe operations safely isolated." >&2
        exit 1
    fi

    sleep $INTERVAL_SECS
done
