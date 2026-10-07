#!/usr/bin/env python3
"""
UNIVAC IX Core Fabric --- Parallel & CUDA Accelerated 12-Pin JSON Network Bridge
Utilizes @njit Numba parallel optimization and NVIDIA CUDA kernel maps to offload 
high-throughput matrix math and bit-morphology quantization routines.
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
# 🚀 NUMBA ACCELERATED CPU PARALLEL CORES SECTOR
# ===================================================================================
@njit(parallel=True, fastmath=True)
def parallel_quantize_humidity_array(raw_data_array, min_val, max_val):
    """
    Numba parallel multi-threaded loop mapping raw inputs into discrete 16-state 
    hexadecimal voltages (0.0V to 1.0V in 0.0625V quantization increments).
    """
    n = raw_data_array.shape[0]
    output_voltages = np.empty(n, dtype=np.float64)
    span = max_val - min_val
    
    for i in prange(n):
        val = raw_data_array[i]
        if val <= min_val:
            output_voltages[i] = 0.0000
        elif val >= max_val:
            output_voltages[i] = 1.0000
        else:
            fraction = (val - min_val) / span
            # Native 16-state step rounding
            hex_step = round(fraction * 15.0)
            output_voltages[i] = hex_step * 0.0625
            
    return output_voltages

# ===================================================================================
# ⚡ NVIDIA CUDA HARDWARE ACCELERATION KERNEL SECTOR
# ===================================================================================
@cuda.jit
def cuda_process_dielectric_matrix(d_input_metrics, d_output_voltages, min_val, max_val):
    """
    NVIDIA CUDA GPU Streaming Multiprocessor Kernel for massive, high-throughput
    matrix parsing across thread grids.
    """
    pos = cuda.grid(1)
    if pos < d_input_metrics.size:
        val = d_input_metrics[pos]
        span = max_val - min_val
        
        if val <= min_val:
            d_output_voltages[pos] = 0.0000
        elif val >= max_val:
            d_output_voltages[pos] = 1.0000
        else:
            fraction = (val - min_val) / span
            # Fixed rounding math logic safe for device registers
            hex_step = int((fraction * 15.0) + 0.5)
            d_output_voltages[pos] = hex_step * 0.0625

# ===================================================================================
# 🏛️ MASTER OPERATIONAL BRIDGE ARCHITECTURE
# ===================================================================================
class AcceleratedSmartFarmBridge:
    def __init__(self, host="0.0.0.0", port=8080, config_path="config.yaml", use_gpu=False):
        self.host = host
        self.port = port
        self.config_path = config_path
        self.use_gpu = use_gpu
        self.cuda_available = cuda.is_available()
        self.baseline_pressure = 101.325
        self.load_hardware_setbacks()
        self.initialize_acceleration_hardware()

    def load_hardware_setbacks(self):
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r') as f:
                    config = yaml.safe_load(f) or {}
                self.setbacks = config.get("hardware_setbacks_inches", 2.0)
                print(f"[*] Configuration Loaded. Active Safety Setbacks: {self.setbacks} inches.")
            except Exception as e:
                print(f"[-] Error reading config.yaml: {e}. Defaulting to 2.0 inches.")
                self.setbacks = 2.0
        else:
            self.setbacks = 2.0

    def initialize_acceleration_hardware(self):
        if self.use_gpu and self.cuda_available:
            print("[*] NVIDIA CUDA Device Verified! System set to offload math onto streaming GPU grids.")
        else:
            print("[*] Deploying @njit Numba parallel compilation layer over all available CPU execution threads.")

    def run_accelerated_quantization(self, input_list):
        """Dispatches data blocks to the selected hardware acceleration lane"""
        np_input = np.array(input_list, dtype=np.float64)
        
        if self.use_gpu and self.cuda_available:
            # Spawning GPU block dimensions dynamically
            n = np_input.size
            threads_per_block = 256
            blocks_per_grid = (n + (threads_per_block - 1)) // threads_per_block
            
            d_input = cuda.to_device(np_input)
            d_output = cuda.device_array(n, dtype=np.float64)
            
            cuda_process_dielectric_matrix[blocks_per_grid, threads_per_block](d_input, d_output, 0.0, 100.0)
            return d_output.copy_to_host()
        else:
            # Parallel multi-core CPU mapping
            return parallel_quantize_humidity_array(np_input, 0.0, 100.0)

    async def handle_node_frame(self, reader, writer):
        address = writer.get_extra_info('peername')
        try:
            while True:
                data = await reader.readline()
                if not data:
                    break

                payload = data.decode('utf-8').strip()
                if not payload:
                    continue

                try:
                    packet = json.loads(payload)
                    node_id = packet.get("node_id", "UNKNOWN_NODE")
                    pins_detected = packet.get("active_pins_detected", 0)

                    # Structural 12-pin verification check
                    if pins_detected != 12:
                        print(f" [!] FAULT at {node_id}: Expected 12 connected lines, read {pins_detected}.")

                    # Batch or stream processing of input values via high-performance layers
                    raw_rh = float(packet.get("relative_humidity", 0.0))
                    accelerated_results = self.run_accelerated_quantization([raw_rh])
                    hex_dew_point_v = float(accelerated_results[0])

                    processed_telemetry = {
                        "node_id": node_id,
                        "twist_lock_hardware_latch": packet.get("twist_lock_hardware_latch", False),
                        "active_pins_detected": pins_detected,
                        "dew_point_analog_voltage": hex_dew_point_v,
                        "internal_pressure_kpa": float(packet.get("internal_pressure_kpa", self.baseline_pressure))
                    }

                    # Stream clean JSON block to your downstream validate-config.js validator loop
                    print(f"[➔] Processed Telemetry Frame: {json.dumps(processed_telemetry)}")

                except (json.JSONDecodeError, ValueError) as err:
                    print(f"[-] Telemetry conversion frame error: {err}")

        except Exception as e:
            print(f"[-] Exception inside processing thread session: {e}")
        finally:
            writer.close()
            await writer.wait_closed()

    async def start_bridge_listener(self):
        server = await asyncio.start_server(self.handle_node_frame, self.host, self.port)
        print(f"[*] UNIVAC IX High-Performance Bridge listening on {self.host}:{self.port}...")
        async with server:
            await server.serve_forever()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UNIVAC IX Hardware-Accelerated Telemetry Listener")
    parser.add_argument("--network-port", type=int, default=8080, help="Network target bind port")
    parser.add_argument("--gpu", action="store_true", help="Force NVIDIA CUDA processing loops")
    args = parser.parse_args()

    bridge = AcceleratedSmartFarmBridge(port=args.network_port, use_gpu=args.gpu)
    try:
        asyncio.run(bridge.start_bridge_listener())
    except KeyboardInterrupt:
        print("\n[*] Terminating high-throughput execution networks.")
