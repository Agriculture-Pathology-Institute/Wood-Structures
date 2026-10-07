#!/usr/bin/env python3
"""
UNIVAC IX Core Fabric --- Asynchronous Parallel & CUDA Network Bridge Gateway
Ingests 12-pin telemetry frames over TCP port 8080, applies Numba parallel multi-core
sorting routines on string data matrices, and writes Visio CSV records.
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
# 🚀 SECTOR 1: MULTI-CORE CPU PARALLEL ACCELERATION & SORTING (NUMBA)
# ===================================================================================
@njit(parallel=True, fastmath=True)
def parallel_quantize_telemetry(raw_array, min_val, max_val):
    """Spawns execution loops across ALL available CPU cores via prange."""
    n = raw_array.shape[0]
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

@njit(fastmath=True)
def numba_int_argsort(char_matrix):
    """
    Numba-optimized sorting algorithm. Evaluates rows of ASCII integer tokens 
    to sort text records without calling Python runtime libraries.
    """
    num_rows = char_matrix.shape[0]
    num_cols = char_matrix.shape[1]
    indices = np.arange(num_rows)
    
    # Standard stable sorting pass inside native execution threads
    for i in range(num_rows - 1):
        for j in range(i + 1, num_rows):
            row_a = indices[i]
            row_b = indices[j]
            
            # Row comparison logic loop
            for k in range(num_cols):
                if char_matrix[row_a, k] > char_matrix[row_b, k]:
                    # Swap pointer metrics
                    indices[i], indices[j] = indices[j], indices[i]
                    break
                elif char_matrix[row_a, k] < char_matrix[row_b, k]:
                    break
    return indices

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
# 🏛️ SECTOR 3: MASTER OPERATIONAL GATEWAY ARCHITECTURE
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
        self.log_batch_buffer = []  # Cache memory pool for sequence blocks
        self.load_system_constraints()
        self.initialize_visio_template()
        self.initialize_hardware_acceleration()
# --- Add this inside the __init__ of RealTimeNetworkGateway ---
self.health_file = "/tmp/bridge_health.state"
with open(self.health_file, "w") as hf:
    hf.write("HEALTHY") # Initialize nominal state on system boot

# --- Ingested inside the handle_node_stream loop of rt_json_network_bridge.py ---
raw_dust_profile = packet.get("dust_density_profile", "LIGHT")

# Map text configuration profiles directly to the 2-bit VHDL binary pin matrix representation
if raw_dust_profile == "CAKED":
    vhdl_dust_bits = "11"
elif raw_dust_profile == "HEAVY":
    vhdl_dust_bits = "10"
elif raw_dust_profile == "MEDIUM":
    vhdl_dust_bits = "01"
else:
    vhdl_dust_bits = "00" # Defaults to nominal light poultry profile

print(f"[➔] Node Acceleration Engine: Routing VHDL Profile Bits [{vhdl_dust_bits}] to Logic Controllers.")

# --- Add this step inside the handle_node_stream() processing loop ---
twist_lock_secured = packet.get("twist_lock_hardware_latch", False)
pins_present = packet.get("active_pins_detected", 0)

if not twist_lock_secured or pins_present != 12:
    print(f" [!!!] CRITICAL: SUSTAINED HARDWARE CONNECTIVITY AIR-GAP DETECTED AT NODE [{node_id}]")
    with open(self.health_file, "w") as hf:
        hf.write("FAULT_AIR_GAP_BREACH") # Force the container state to un-healthy instantly


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
        self.visio_headers = [
            "Process Step ID", 
            "Step Name", 
            "Status Color", 
            "Status Description", 
            "Hex Voltage Analog Readout", 
            "Internal Pressure kPa"
        ]
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

    def process_and_flush_visio_buffer(self):
        """Transforms node list strings into ASCII data blocks for Numba sorting execution."""
        if not self.log_batch_buffer:
            return

        print(f"[*] Preparing buffer block optimization payload ({len(self.log_batch_buffer)} steps)...")

        # Determine string padding array requirements
        max_str_len = max(len(row[0]) for row in self.log_batch_buffer)
        ascii_matrix = np.zeros((len(self.log_batch_buffer), max_str_len), dtype=np.uint8)

        # Convert Node Identifiers string sequences into numeric vectors
        for idx, row in enumerate(self.log_batch_buffer):
            ascii_chars = list(row[0].encode('ascii', errors='ignore'))
            ascii_matrix[idx, :len(ascii_chars)] = ascii_chars

        # Dispatch numeric block mapping array to high-speed sorter module
        sorted_indices = numba_int_argsort(ascii_matrix)

        try:
            with open(self.visio_path, mode='a', newline='') as f:
                writer = csv.writer(f)
                for index in sorted_indices:
                    writer.writerow(self.log_batch_buffer[index])
            print("[+] Buffer array sequence written to filesystem ordered alphabetically.")
        except Exception as e:
            print(f"[-] Non-blocking error writing sorted records to Visio: {e}")
        finally:
            self.log_batch_buffer.clear()

    def stage_visio_log(self, node_id, hex_v, pressure):
        """Evaluates node metrics and adds them to the buffered array cache memory pool."""
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

        self.log_batch_buffer.append([
            node_id, 
            "Smart Wood Barn Node Controller", 
            status_color, 
            status_desc, 
            f"{hex_v:.4f}V", 
            f"{pressure:.2f} kPa"
        ])

        # Automatic memory dump every 5 packets
        if len(self.log_batch_buffer) >= 5:
            self.process_and_flush_visio_buffer()

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
                    hex_logic_v = float(calculated_voltages[0])
                    internal_pressure = float(packet.get("internal_pressure_kpa", self.baseline_atm_kpa))

                    # Stage telemetry for compilation pass
self.stage_visio_log(node_id, hex_logic_v, internal_pressure)

processed_telemetry = {\
"node_id": node_id,\
"twist_lock_hardware_latch": packet.get("twist_lock_hardware_latch", False),\
"active_pins_detected": pins_present,\
"dew_point_analog_voltage": hex_logic_v,\
"internal_pressure_kpa": internal_pressure\
}

print(f"[➔] Processed Telemetry Frame: {json.dumps(processed_telemetry)}")\
sys.stdout.flush()

except (json.JSONDecodeError, ValueError) as json_err:\
print(f"[-] Malformed frame signature from {peer}: {json_err}")

except Exception as e:\
print(f"[-] Processing exception trapped in stream: {e}")\
finally:\
# Safe operational teardown flush check\
self.process_and_flush_visio_buffer()\
writer.close()\
await writer.wait_closed()

async def start_listener_loop(self):\
server = await asyncio.start_server(self.handle_node_stream, self.host, self.port)\
print(f"[*] UNIVAC IX Multi-Core Engine listening on -> {self.host}:{self.port}")\
async with server:\
await server.serve_forever()

if **name** == "**main**":\
parser = argparse.ArgumentParser(description="UNIVAC IX Hardware-Accelerated Telemetry Listener Interface")\
parser.add_argument("--network-port", type=int, default=8080, help="Target socket port")\
parser.add_argument("--visio-csv", type=str, default="visio_mapping.csv", help="Visio output file name")\
parser.add_argument("--gpu", action="store_true", help="Force NVIDIA CUDA processing loops")\
args = parser.parse_args()

gateway = RealTimeNetworkGateway(port=args.network_port, visio_path=args.visio_csv, force_gpu=args.gpu)\
try:\
asyncio.run(gateway.start_listener_loop())\
except KeyboardInterrupt:\
print("\n[*] Terminating hardware acceleration network loops gracefully.")
