#!/usr/bin/env bash
# ===================================================================================
# UNIVAC IX Infrastructure Watch - Host NVIDIA Hardware Status Daemon
# Purpose: Detects GPU driver detachment, triggers audio alarms, and drops stack.
# File Class: Host-Level Non-Virtualised Environmental Monitor Loop
# ===================================================================================

HEALTH_STATE_FILE="/tmp/bridge_health.state"
INTERVAL_SECS=2

echo "[*] Initializing Host-Level NVIDIA GPU PCIe Watchdog Loop with Audio Alerts..."

trigger_control_room_audio_horns() {
    echo -e "\n[!!!] HOST_WATCHDOG: BROADCASTING CRITICAL HARDWARE FAULT OVER ALARM HORN TRANSMITTERS..." >&2
    
    # Loop an audible warning pattern to pierce high ambient barn/mainframe noise
    for i in {1..5}; do
        # 1. Inject an absolute terminal audio bell directly into the core system TTY
        echo -e "\a" > /dev/tty1
        
        # 2. Fire high-frequency systemic alarm pulses over physical audio channels using ALSA
        if command -v aplay > /dev/null 2>&1; then
            # Uses built-in system sound maps to ring audio line-out horns loud and clear
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
        echo "[-] Operating status code $DRIVER_STATUS returned via kernel driver space." >&2
        
        # Ingress the hardware failure footprint immediately for the Docker healthcheck loop
        if [ -d "/tmp" ]; then
            echo "FAULT_HOST_GPU_DETACHED" > "$HEALTH_STATE_FILE"
        fi

        # Fire high-volume control room alert horns instantly
        trigger_control_room_audio_horns

        # Drop active container networks to isolate processing lines cleanly
        echo "[!] Hardware Isolation: Dropping active container infrastructure stacks..." >&2
        if command -v docker-compose > /dev/null 2>&1; then
            docker-compose -f /app/docker-compose.yml down --volumes
        elif command -v docker > /dev/null 2>&1; then
            docker compose -f /app/docker-compose.yml down --volumes
        fi

        echo "[!] CRITICAL: Closed loop dropped open. Mainframe operations safely isolated." >&2
        exit 1
    fi

    sleep $INTERVAL_SECS
done
