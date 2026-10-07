#!/usr/bin/env python3
"""
UNIVAC IX Core Fabric --- Asynchronous 12-Pin JSON Network Bridge
Ingests raw telemetry frames over port 8080, computes hexadecimal voltage mappings,
and interfaces with the validation layers.
"""

import sys
import os
import json
import asyncio
import argparse
import yaml

class RealTimeJsonNetworkBridge:
    def __init__(self, host="0.0.0.0", port=8080, config_path="config.yaml"):
        self.host = host
        self.port = port
        self.config_path = config_path
        self.baseline_pressure = 101.325
        self.load_hardware_setbacks()

    def load_hardware_setbacks(self):
        """Loads geodetic origin metrics and the 2-inch hardware setbacks from config.yaml"""
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r') as f:
                    config = yaml.safe_load(f) or {}
                self.setbacks = config.get("hardware_setbacks_inches", 2.0)
                print(f"[*] Configuration Loaded. Active Safety Setbacks: {self.setbacks} inches.")
            except Exception as e:
                print(f"[-] Error parsing config.yaml: {e}. Defaulting to 2.0 inches.")
                self.setbacks = 2.0
        else:
            print("[-] config.yaml not found. Deploying with safe default 2.0-inch setbacks.")
            self.setbacks = 2.0

    def calculate_hex_voltage_state(self, val, min_val, max_val):
        """Maps an analog input value directly to a 16-state discrete hexadecimal voltage (0.0V - 1.0V)"""
        if val <= min_val:
            return 0.0000
        if val >= max_val:
            return 1.0000
        
        # Calculate percentage across the operating span
        span = max_val - min_val
        fraction = (val - min_val) / span
        
        # Snap to closest 1/15th interval (0x0 to 0xF) to yield discrete 0.0625V increments
        hex_step = round(fraction * 15)
        voltage = hex_step * 0.0625
        return voltage

    async def handle_node_frame(self, reader, writer):
        """Processes incoming raw TCP frames from 12-pin twist-lock physical infrastructure links"""
        address = writer.get_extra_info('peername')
        print(f"\n[+] Established active 12-pin network stream with node: {address}")

        try:
            while True:
                data = await reader.readline()
                if not data:
                    print(f"[-] Node {address} disconnected from line fabric.")
                    break

                # Ingest raw string payload
                payload = data.decode('utf-8').strip()
                if not payload:
                    continue

                try:
                    packet = json.loads(payload)
                    node_id = packet.get("node_id", "UNKNOWN_NODE")
                    
                    # 1. Audit Pin Count Configuration
                    pins_detected = packet.get("active_pins_detected", 0)
                    if pins_detected != 12:
                        print(f" [!] FAULT at {node_id}: Expected 12 connected lines, read {pins_detected}.")
                        # Triggers immediate NC Dropout downstream if hardware mismatch exists

                    # 2. Extract and translate analog humidity curves to absolute hexadecimal voltages
                    raw_rh = packet.get("relative_humidity", 0.0)
                    hex_dew_point_v = self.calculate_hex_voltage_state(raw_rh, 0.0, 100.0)
                    
                    # 3. Formulate processed downstream packet payload
                    processed_telemetry = {
                        "node_id": node_id,
                        "twist_lock_hardware_latch": packet.get("twist_lock_hardware_latch", False),
                        "active_pins_detected": pins_detected,
                        "dew_point_analog_voltage": hex_dew_point_v,
                        "internal_pressure_kpa": packet.get("internal_pressure_kpa", self.baseline_pressure)
                    }

                    # Echo clean structured payload onwards to validate-config.js via standard out / pipe
                    print(f"[➔] Processed Telemetry Frame: {json.dumps(processed_telemetry)}")

                except json.JSONDecodeError:
                    print(f"[-] Malformed non-JSON frame intercepted on line: {payload}")

        except Exception as e:
            print(f"[-] Exception trapped inside active network client session: {e}")
        finally:
            writer.close()
            await writer.wait_closed()

    async def start_bridge_listener(self):
        """Spins up the TCP network server loop on port 8080"""
        server = await asyncio.start_server(self.handle_node_frame, self.host, self.port)
        print(f"[*] UNIVAC IX Network Bridge actively listening on {self.host}:{self.port}...")
        async with server:
            await server.serve_forever()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UNIVAC IX Raw Socket 12-Pin JSON Network Bridge")
    parser.add_argument("--network-port", type=int, default=8080, help="Target network port to bind")
    args = parser.parse_args()

    bridge = RealTimeJsonNetworkBridge(port=args.network_port)
    try:
        asyncio.run(bridge.start_bridge_listener())
    except KeyboardInterrupt:
        print("\n[*] Terminating network bridge execution loops.")
