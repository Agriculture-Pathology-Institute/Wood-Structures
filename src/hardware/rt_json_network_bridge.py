#!/usr/bin/env python3
"""
UNIVAC IX Core Fabric --- Asynchronous Parallel & CUDA Network Bridge Gateway
Handles high-throughput 12-pin telemetry frames over TCP port 8080.
"""

import os
import sys
import json
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
    """
    Spawns execution loops across ALL available CPU cores.
    Maps raw metrics to discrete 16-state hexadecimal analog voltage levels.
    """
    n = raw_array.shape[0]
    output_voltages = np.empty(n, dtype=np.float64)
    span = max_val - min_val
    
    # prange automatically slices and parallelizes the array across your multi-core architecture
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
    """
    GPU Streaming Multiprocessor Kernel for massive high-density stream arrays.
    """
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
    def __init__(self, host="0.0.0.0", port=8080, config_path="config.yaml", force_gpu=False):
        self.host = host
        self.port = port
        self.config_path = config_path
        self.force_gpu = force_gpu
        self.cuda_available = cuda.is_available()
        self.baseline_atm_kpa = 101.325
        self.load_system_constraints()
        self.initialize_hardware_acceleration()

    def load_system_constraints(self):
        """Loads safety setbacks and configuration limits from config.yaml"""
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
            print("[-] config.yaml missing. Falling back to default 2.0-inch setbacks.")
            self.setbacks = 2.0

    def initialize_hardware_acceleration(self):
        """Validates computing architecture profiles on launch"""
        if self.force_gpu and self.cuda_available:
            print("[+] SYSTEM MODE: NVIDIA CUDA Streaming Hardware Multiprocessors Active.")
        else:
            if self.force_gpu and not self.cuda_available:
                print("[-] WARNING: GPU execution requested but CUDA is unavailable. Falling back to multi-core.")
            print("[+] SYSTEM MODE: Multi-Core CPU Threads via Numba parallel execution pipeline.")

    def execute_accelerated_mapping(self, batch_data):
        """Dispatches data batches to either Multi-Core or GPU streams"""
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

    async def handle_node_stream(self, reader, writer):
        """Asynchronous, non-blocking TCP socket line processing callback loop"""
        peer = writer.get_extra_info('peername')
        print(f"\n[+] Activated 12-pin physical line connection stream: {peer}")

        try:
            while True:
                line = await reader.readline()
                if not line:
                    print(f"[-] 12-Pin line fabric drop detected at node: {peer}")
                    break

                payload = line.decode('utf-8').strip()
                if not payload:
                    continue

                try:
                    packet = json.loads(payload)
                    node_id = packet.get("node_id", "UNKNOWN_NODE")
                    pins_present = packet.get("active_pins_detected", 0)

                    # Structural 12-pin physical infrastructure integrity check
                    if pins_present != 12:
                        print(f" [!] INTEGRITY FAULT at [{node_id}]: Pin line mismatch! Read {pins_present}/12 lines.")

                    # Route incoming humidity data array straight through the active parallel hardware layers
                    raw_humidity = float(packet.get("relative_humidity", 0.0))
                    calculated_voltages = self.execute_accelerated_mapping([raw_humidity])
                    hex_logic_v = float(calculated_voltages[0])

                    # Build structured package for downstream validate-config.js ingestion
                    processed_telemetry = {
                        "node_id": node_id,
                        "twist_lock_hardware_latch": packet.get("twist_lock_hardware_latch", False),
                        "active_pins_detected": pins_present,
                        "dew_point_analog_voltage": hex_logic_v,
                        "internal_pressure_kpa": float(packet.get("internal_pressure_kpa", self.baseline_atm_kpa))
                    }

                    # Stream stdout string out to the process pipeline
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
        """Binds TCP socket listener to target network interfaces"""
        server = await asyncio.start_server(self.handle_node_stream, self.host, self.port)
        print(f"[*] UNIVAC IX Multi-Core Engine listening on -> {self.host}:{self.port}")
        async with server:
            await server.serve_forever()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UNIVAC IX Hardware-Accelerated Telemetry Listener Interface")
    parser.add_argument("--network-port", type=int, default=8080, help="Target socket port")
    parser.add_argument("--gpu", action="store_true", help="Force NVIDIA CUDA processing loops")
    args = parser.parse_args()

    gateway = RealTimeNetworkGateway(port=args.network_port, force_gpu=args.gpu)
    try:
        asyncio.run(gateway.start_listener_loop())
    except KeyboardInterrupt:
        print("\n[*] Terminating hardware acceleration network loops gracefully.")
