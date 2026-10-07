#!/usr/bin/env python3
"""
UNIVAC IX Core Fabric --- Asynchronous Parallel & CUDA Network Bridge Gateway
Handles high-throughput 12-pin telemetry frames over TCP port 8080 and auto-exports
Microsoft Visio Data Visualizer compliant process mapping CSV records.
"""

import os
import sys
import json
import csv
import asyncio
import argparse
import numpy as np
import yaml
from numba import njit, prange, cuda

# ===================================================================================
# 🚀 SECTOR 1: MULTI-CORE CPU PARALLEL ACCELERATION (NUMBA)
# ===================================================================================
@njit(parallel=True, fastmath=True)
def parallel_quantize_telemetry(raw_array, min_val, max_val):
    """Spawns execution loops across ALL available CPU cores via prange."""
    n = raw_array.shape
    output_voltages = np.empty(n, dtype=np.float64)
    span = max_val - min_val
    
    for i in prange(n):
        val = raw_array[i]
        if val <= min_val:
            output_voltages[i] = 0.0000
        elif val >= max_val:
            output_voltages[i] = 1.0000
        else:
            fraction = (val - min_val) / span
            hex_step = round(fraction * 15.0)
            output_voltages[i] = hex_step * 0.0625
            
    return output_voltages

# ===================================================================================
# ⚡ SECTOR 2: NVIDIA CUDA HARDWARE ACCELERATION KERNEL
# ===================================================================================
@cuda.jit
def cuda_quantize_telemetry_matrix(d_input, d_output, min_val, max_val):
    """GPU Streaming Multiprocessor Kernel for high-density telemetry streaming."""
    pos = cuda.grid(1)
    if pos < d_input.size:
        val = d_input[pos]
        span = max_val - min_val
        
        if val <= min_val:
            d_output[pos] = 0.0000
        elif val >= max_val:
            d_output[pos] = 1.0000
        else:
            fraction = (val - min_val) / span
            hex_step = int((fraction * 15.0) + 0.5)
            d_output[pos] = hex_step * 0.0625

# ===================================================================================
# 🏛️ SECTOR 3: MASTER OPERATIONAL GATEWAY ARCHITECTURE WITH VISIO LOGGING
# ===================================================================================
class RealTimeNetworkGateway:
    def __init__(self, host="0.0.0.0", port=8080, config_path="config.yaml", visio_path="visio_mapping.csv", force_gpu=False):
        self.host = host
        self.port = port
        self.config_path = config_path
        self.visio_path = visio_path
        self.force_gpu = force_gpu
        self.cuda_available = cuda.is_available()
        self.baseline_atm_kpa = 101.325
        self.load_system_constraints()
        self.initialize_visio_template()
        self.initialize_hardware_acceleration()

    def load_system_constraints(self):
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r') as f:
                    config = yaml.safe_load(f) or {}
                self.setbacks = config.get("hardware_setbacks_inches", 2.0)
                print(f"[*] Configuration Found. Safety Clearance Setbacks: {self.setbacks} inches.")
            except Exception as e:
                print(f"[-] Parsing error on config.yaml: {e}. Defaulting to 2.0 inches.")
                self.setbacks = 2.0
        else:
            self.setbacks = 2.0

    def initialize_visio_template(self):
        """Pre-formats the CSV structure required by Visio Data Visualizer mapping layers."""
        self.visio_headers = [
            "Process Step ID", 
            "Step Name", 
            "Status Color", 
            "Status Description", 
            "Hex Voltage Analog Readout", 
            "Internal Pressure kPa"
        ]
        # Initialize file with headers if it does not exist
        if not os.path.exists(self.visio_path):
            try:
                with open(self.visio_path, mode='w', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(self.visio_headers)
                print(f"[+] Initialized target Microsoft Visio template at: {self.visio_path}")
            except Exception as e:
                print(f"[-] Error creating Visio CSV template: {e}")

    def initialize_hardware_acceleration(self):
        if self.force_gpu and self.cuda_available:
            print("[+] SYSTEM MODE: NVIDIA CUDA Streaming Hardware Multiprocessors Active.")
        else:
            print("[+] SYSTEM MODE: Multi-Core CPU Threads via Numba parallel execution pipeline.")

    def execute_accelerated_mapping(self, batch_data):
        np_data = np.array(batch_data, dtype=np.float64)
        if self.force_gpu and self.cuda_available:
            n = np_data.size
            threads_per_block = 256
            blocks_per_grid = (n + (threads_per_block - 1)) // threads_per_block
            d_input = cuda.to_device(np_data)
            d_output = cuda.device_array(n, dtype=np.float64)
            cuda_quantize_telemetry_matrix[blocks_per_grid, threads_per_block](d_input, d_output, 0.0, 100.0)
            return d_output.copy_to_host()
        else:
            return parallel_quantize_telemetry(np_data, 0.0, 100.0)

    def write_visio_log(self, node_id, hex_v, pressure):
        """Maps computed real-time metrics directly into Visio Data Graphics format."""
        # Determine node visualization status color matching validate-config.js rules
        if hex_v >= 0.9375:
            status_color = "Red"
            status_desc = "CRITICAL FAULT: Condensation Convergence Breach"
        elif hex_v >= 0.8750:
            status_color = "Yellow"
            status_desc = "High Humidity Warning: Trace Heater Active"
        elif pressure > 115.0 or pressure < 85.0:
            status_color = "Red"
            status_desc = "CRITICAL FAULT: Pressure Vent Clogged"
        else:
            status_color = "Green"
            status_desc = "Nominal Operations"

        try:
            with open(self.visio_path, mode='a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow([
                    node_id, 
                    "Smart Wood Barn Node Controller", 
                    status_color, 
                    status_desc, 
                    f"{hex_v:.4f}V", 
                    f"{pressure:.2f} kPa"
                ])
        except Exception as e:
            print(f"[-] Non-blocking error writing to Visio manifest: {e}")

    async def handle_node_stream(self, reader, writer):
        peer = writer.get_extra_info('peername')
        print(f"\n[+] Activated 12-pin physical line connection stream: {peer}")

        try:
            while True:
                line = await reader.readline()
                if not line:
                    break

                payload = line.decode('utf-8').strip()
                if not payload:
                    continue

                try:
                    packet = json.loads(payload)
                    node_id = packet.get("node_id", "UNKNOWN_NODE")
                    pins_present = packet.get("active_pins_detected", 0)

                    if pins_present != 12:
                        print(f" [!] INTEGRITY FAULT at [{node_id}]: Pin line mismatch! Read {pins_present}/12 lines.")

                    # Parallel/CUDA mapping execution
                    raw_humidity = float(packet.get("relative_humidity", 0.0))
                    calculated_voltages = self.execute_accelerated_mapping([raw_humidity])
                    hex_logic_v = float(calculated_voltages)
                    internal_pressure = float(packet.get("internal_pressure_kpa", self.baseline_atm_kpa))

                    # Post environmental data straight to the Visio process template records
                    self.write_visio_log(node_id, hex_logic_v, internal_pressure)

                    processed_telemetry = {
                        "node_id": node_id,
                        "twist_lock_hardware_latch": packet.get("twist_lock_hardware_latch", False),
                        "active_pins_detected": pins_present,
                        "dew_point_analog_voltage": hex_logic_v,
                        "internal_pressure_kpa": internal_pressure
                    }

                    print(f"[➔] Processed Telemetry Frame: {json.dumps(processed_telemetry)}")
                    sys.stdout.flush()

                except (json.JSONDecodeError, ValueError) as json_err:
                    print(f"[-] Malformed frame signature from {peer}: {json_err}")

        except Exception as e:
            print(f"[-] Processing exception trapped in stream: {e}")
        finally:
            writer.close()
            await writer.wait_closed()

    async def start_listener_loop(self):
        server = await asyncio.start_server(self.handle_node_stream, self.host, self.port)
        print(f"[*] UNIVAC IX Multi-Core Engine listening on -> {self.host}:{self.port}")
        async with server:
            await server.serve_forever()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UNIVAC IX Hardware-Accelerated Telemetry Listener Interface")
    parser.add_argument("--network-port", type=int, default=8080, help="Target socket port")
    parser.add_argument("--visio-csv", type=string, default="visio_mapping.csv", help="Visio output file name")
    parser.add_argument("--gpu", action="store_true", help="Force NVIDIA CUDA processing loops")
    args = parser.parse_args()

    gateway = RealTimeNetworkGateway(port=args.network_port, visio_path=args.visio_csv, force_gpu=args.gpu)
    try:
        asyncio.run(gateway.start_listener_loop())
    except KeyboardInterrupt:
        print("\n[*] Terminating hardware acceleration network loops gracefully.")
