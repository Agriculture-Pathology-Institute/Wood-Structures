# File Path: scripts/parse_rfid_telemetry.py
#!/usr/bin/env python3
"""
Revolutionary Technology Company — UNIVAC IX Systems Group
Asynchronous RFID Security Ingestion Core & Access Control Router.

Evaluates field transponder tags for staff, livestock, and autonomous equipment,
transmitting verified tracking tokens directly across cross-server gateways.
"""

import os
import sys
import json
import time
import socket

class RfidTelemetryParser:
    def __init__(self, bridge_host="127.0.0.1", bridge_port=8080):
        self.bridge_host = bridge_host
        self.bridge_port = bridge_port
        
        # Cryptographic Asset Registry Database Profiles
        self.verified_tags = {
            "TAG_STAFF_99A":  {"class": "0x1", "desc": "Ballard Senior Engineering Staff Member"},
            "TAG_CATTLE_402": {"class": "0x2", "desc": "Livestock Cohort — Registered Breeding Bull"},
            "TAG_TRACTOR_05": {"class": "0x3", "desc": "Caterpillar Command Autonomous Earthmover"},
            "TAG_DRONE_14B":  {"class": "0x4", "desc": "Northrop Grumman Weatherproof Upper Air Array"}
        }

    def compose_access_control_json(self, rfid_raw_string, gate_location_id, open_command=True):
        """Cross-references transponder tags and structures a prioritized Univac payload packet."""
        timestamp_ms = int(time.time() * 1000)
        asset_profile = self.verified_tags.get(rfid_raw_string)
        
        if asset_profile is None:
            # Illegal/un-whitelisted transponder signature caught near timber boundaries
            assigned_hex = "0x0"
            overlay_text = f"🚨 SECURITY ACCESS DENIED: UNKNOWN TRANSPONDER SIGNATURE AT {gate_location_id}."
            asset_class = "0x0"
            desc_text = "UNAUTHORIZED_ACTOR_BLOCKED"
        else:
            assigned_hex = "0xA" if open_command else "0xF"
            asset_class = asset_profile["class"]
            desc_text = asset_profile["desc"]
            overlay_text = f"🔓 ACCESS GRANTED AT {gate_location_id} FOR: {desc_text}."

        # Compile unified open-source JSON payload tracking block
        access_payload = {
            "univac_core_header": {
                "system_architecture": "PLANETARY_RFID_ACCESS_NETWORK",
                "timestamp_epoch_ms": timestamp_ms
            },
            "priority_routing_overrides": {
                "tier_01_governmental_xr_oversight": {
                    "priority_index": 1,
                    "authorized_agencies": ["DOI", "OSHA", "BLM_LAND_PEOPLE"],
                    "enforce_boundary_lock": assigned_hex == "0x0",
                    "viewport_hud_overlay_text": overlay_text,
                    "viewport_hud_alert_tint": "CRITICAL_CRIMSON_REVERT" if assigned_hex == "0x0" else "NOMINAL_GREEN_STABLE"
                },
                "tier_02_commercial_ballard_operations": {
                    "priority_index": 2,
                    "entity_name": "AGRICULTURE_PATHOLOGY_INSTITUTE_LLC",
                    "office_location": "UW_MEDICINE_BALLARD_BASE_STATION",
                    "hardware_interlock_hex_register": assigned_hex,
                    "active_mode": "PLANTING_MODE" if asset_class == "0x2" else "EXCAVATION_MODE"
                }
            },
            "rfid_proximity_analytics": {
                "scanned_tag_identity": rfid_raw_string,
                "asset_classification_hex": asset_class,
                "asset_description_string": desc_text,
                "target_gate_perimeter_id": gate_location_id,
                "actuator_valve_open_command": open_command and assigned_hex != "0x0"
            },
            "ue5_position_cm": [24000.0, 18500.0, 450.0],
            "wind_speed_kts": 0.0,
            "volume_cut_m3": 0.0,
            "request_hex_state": assigned_hex
        }
        return access_payload

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

# =========================================================================
# TEST SYSTEM INJECTION WORKER
# =========================================================================
if __name__ == "__main__":
    parser = RfidTelemetryParser()
    print("[*] Simulating proximity sensor scanning across timber gate tracking lines...")
    
    # Mock data emulating an autonomous drone tractor arriving at the lower vehicle lock,
    # followed immediately by an unauthenticated rogue transponder attempt.
    simulated_scans = [
        {"tag": "TAG_TRACTOR_05", "gate": "BARN_LOWER_MAIN_SLIDER", "open": True},
        {"tag": "TAG_ROGUE_777",  "gate": "UPPER_SKYLIGHT_DRONE_HATCH", "open": True}
    ]
    
    for idx, scan in enumerate(simulated_scans):
        frame = parser.compose_access_control_json(scan["tag"], scan["gate"], scan["open"])
        status = parser.pipe_frame_to_network_bridge(frame)
        print(f"[Scan Node {idx:02d}] Telemetry frames routed to core. Response code: {status}")
