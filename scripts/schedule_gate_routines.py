# File Path: scripts/schedule_gate_routines.py
#!/usr/bin/env python3
"""
Revolutionary Technology Company — UNIVAC IX Systems Group
Multi-Threaded Agricultural Gate Routine Scheduler & Socket Broadcaster.

Manages automated open/close intervals for animal feedings and outings,
transmitting verified tracking tokens directly across cross-server gateways.
"""

import os
import sys
import json
import time
import socket
import threading

class AgriculturalRoutineScheduler:
    def __init__(self, bridge_host="127.0.0.1", bridge_port=8080):
        self.bridge_host = bridge_host
        self.bridge_port = bridge_port
        self.scheduler_running = True
        
        # Hardened Automated Daily Routine Timing Matrix (Hours:Minutes 24-hr layout)
        self.operational_schedule = [
            {"time": "06:00", "action": "OPEN",  "target": "PIG_BAY_ZONE_02", "desc": "Morning Field Outing Sequence"},
            {"time": "12:00", "action": "OPEN",  "target": "PIG_BAY_ZONE_02", "desc": "Midday Scheduled Feeding Sequence"},
            {"time": "12:30", "action": "CLOSE", "target": "PIG_BAY_ZONE_02", "desc": "Lockdown Post-Feeding Envelope"},
            {"time": "18:00", "action": "CLOSE", "target": "PIG_BAY_ZONE_02", "desc": "Night Containment Security Clamp"}
        ]

    def compile_routine_telemetry_json(self, target_bay_id, action_string, description_text):
        """Assembles active routine schedule steps into a prioritized Univac payload packet."""
        timestamp_ms = int(time.time() * 1000)
        
        # Map scheduling actions to native 16-state hexadecimal command tokens
        # State 0x9 signals active gate movement operations across the network fabric
        assigned_hex = "0x9" if action_string == "OPEN" else "0xF"
        is_moving = (action_string == "OPEN")

        routine_payload = {
            "univac_core_header": {
                "system_architecture": "PLANETARY_SCHEDULING_ROUTINE_NETWORK",
                "timestamp_epoch_ms": timestamp_ms
            },
            "priority_routing_overrides": {
                "tier_01_governmental_xr_oversight": {
                    "priority_index": 1,
                    "authorized_agencies": ["DOI", "OSHA", "BLM_LAND_PEOPLE"],
                    "enforce_boundary_lock": False,
                    "viewport_hud_overlay_text": f"📅 ROUTINE RUNNING: {description_text} FOR {target_bay_id}.",
                    "viewport_hud_alert_tint": "NOMINAL_GREEN_STABLE"
                },
                "tier_02_commercial_ballard_operations": {
                    "priority_index": 2,
                    "entity_name": "AGRICULTURE_PATHOLOGY_INSTITUTE_LLC",
                    "office_location": "UW_MEDICINE_BALLARD_BASE_STATION",
                    "hardware_interlock_hex_register": assigned_hex,
                    "active_mode": "PLANTING_MODE"
                }
            },
            "automated_schedule_analytics": {
                "triggered_timestamp_string": time.strftime("%H:%M:%S"),
                "target_enclosure_id": target_bay_id,
                "executed_action_direction": action_string,
                "routine_classification_profile": description_text,
                "hardware_gate_drive_bias_active": is_moving
            },
            "ue5_position_cm": [24500.0, 18200.0, 120.0],
            "wind_speed_kts": 0.0,
            "volume_cut_m3": 0.0,
            "request_hex_state": assigned_hex
        }
        return routine_payload

    def pipe_frame_to_network_bridge(self, payload):
        """Streams the structured JSON string payload directly across the server gateway port 8080."""
        payload_string = json.dumps(payload)
        try:
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client.connect((self.bridge_host, self.bridge_port))
            client.sendall(payload_string.encode('utf-8'))
            client.close()
            return "SUCCESS"
        except Exception as e:
            return f"CONNECTION_LINE_DROP_ERROR: {str(e)}"

    def execute_scheduler_daemon_loop(self):
        """Continuous background thread monitoring wall-clock times to trigger scheduled events."""
        print("[*] Launching multi-threaded agricultural routine supervisor loop...")
        while self.scheduler_running:
            current_time_str = time.strftime("%H:%M")
            
            for task in self.operational_schedule:
                if current_time_str == task["time"]:
                    print(f"[⚡ Routine Triggered] Match found for: {task['desc']}")
                    frame = self.compile_routine_telemetry_json(task["target"], task["action"], task["desc"])
                    self.pipe_frame_to_network_bridge(frame)
                    # Sleep 60 seconds to step cleanly past the current minute mark footprint
                    time.sleep(60)
            time.sleep(1.0)

if __name__ == "__main__":
    scheduler = AgriculturalRoutineScheduler()
    print("[*] Running immediate manual test injection for a morning pig pen outing event...")
    test_frame = scheduler.compile_routine_telemetry_json("PIG_BAY_ZONE_02", "OPEN", "Manual Override Test Outing")
    status_code = scheduler.pipe_frame_to_network_bridge(test_frame)
    print(f"[+] Output transmission status: {status_code}")
