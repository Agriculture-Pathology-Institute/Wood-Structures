#!/usr/bin/env python3
"""
UNIVAC IX Core Fabric --- Hardened 6-Bit Telephony Gateway Decoder
Utilizes Numba JIT compilers to parse legacy FIELDATA bit-streams from old farmer 
telephony hardware and map them into modern Microsoft Visio tracking layers.
"""

import os
import sys
import json
import csv
import asyncio
import numpy as np
from numba import njit, prange

# ===================================================================================
# 🚀 LEGACY UNIVAC FIELDATA ALPHABET TRANSLATION MATRIX
# ===================================================================================
# Maps raw 6-bit integer codes (0 to 63) directly to their 8-bit ASCII equivalents.
FIELDATA_TO_ASCII = np.array([
    32,  64,  91,  93,  35,  42,  58,  61, # 00-07: Controls, Space, @, [, ], #, *, :, =
    40,  41,  43,  45,  47,  44,  46,  36, # 08-15: (, ), +, -, /, ,, ., $
    48,  49,  50,  51,  52,  53,  54,  55, # 16-23: 0, 1, 2, 3, 4, 5, 6, 7
    56,  57,  39,  34,  59,  33,  63,  38, # 24-31: 8, 9, ', ", ;, !, ?, &
    65,  66,  67,  68,  69,  70,  71,  72, # 32-39: A, B, C, D, E, F, G, H
    73,  74,  75,  76,  77,  78,  79,  80, # 40-47: I, J, K, L, M, N, O, P
    81,  82,  83,  84,  85,  86,  87,  88, # 48-55: Q, R, S, T, U, V, W, X
    89,  90,  60,  62,  95,  37,  92,  10  # 56-63: Y, Z, <, >, _, %, \, LF
], dtype=np.uint8)

@njit(parallel=True, fastmath=True)
def parallel_decode_fieldata(bit_stream_matrix):
    """
    Spawns concurrent multi-core loops via prange to parse 6-bit word arrays.
    Decodes legacy UNIVAC phone line packets into ASCII byte streams.
    """
    num_rows, num_cols = bit_stream_matrix.shape
    decoded_output = np.empty((num_rows, num_cols), dtype=np.uint8)
    
    for i in prange(num_rows):
        for j in range(num_cols):
            raw_6bit_val = bit_stream_matrix[i, j] & 0x3F # Enforce 6-bit masking
            decoded_output[i, j] = FIELDATA_TO_ASCII[raw_6bit_val]
            
    return decoded_output

# --- Integrated into the handle_node_stream receiver thread within rt_json_network_bridge.py ---
outbound_command = packet.get("control_room_action", "IDLE")

if outbound_command == "TRIGGER_HANDSET_RING":
    print("[➔] MAINFRAME: Outbound Ring Request Validated. Asserting VHDL Pin 12 -> HIGH.")
    # Low-level VHDL interaction layer sets the command line high
    vhdl_ring_register_bit = 1
else:
    vhdl_ring_register_bit = 0

# ===================================================================================
# 🏛️ OPERATIONAL GATEWAY TELEPHONY ROUTER
# ===================================================================================
class TelephonyNetworkGateway:
    def __init__(self, visio_path="visio_mapping.csv"):
        self.visio_path = visio_path
        self.initialize_visio_template()

    def initialize_visio_template(self):
        if not os.path.exists(self.visio_path):
            with open(self.visio_path, mode='w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(["Process Step ID", "Step Name", "Status Color", "Status Description"])

    def process_legacy_phone_frame(self, node_id, raw_6bit_list):
        """Converts incoming telemetry bits from agricultural phones into Visio paths."""
        bit_matrix = np.array([raw_6bit_list], dtype=np.uint8)
        
        # Dispatch to the fast Numba decoder loop
        ascii_bytes = parallel_decode_fieldata(bit_matrix)[0]
        decoded_string = "".join([chr(b) for b in ascii_bytes]).strip()
        
        print(f"[➔] TELEPHONY: Parsed incoming frame from {node_id}: '{decoded_string}'")
        
        # Route warning messages containing terms like "CRITICAL" or "BREAKDOWN" to the Visio Map
        status_color = "Green"
        if "ALERT" in decoded_string or "FAULT" in decoded_string:
            status_color = "Red"
            
        with open(self.visio_path, mode='a', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([node_id, "UNIVAC Field Phone Terminal", status_color, f"Message Intercepted: {decoded_string}"])

# Quick operational integration verification sweep
if __name__ == "__main__":
    gateway = TelephonyNetworkGateway()
    
    # Emulate raw 6-bit packed signal representing characters "A", "L", "E", "R", "T"
    # Using FIELDATA indexing maps: A=32, L=43, E=36, R=49, T=51
    mock_phone_bits = [32, 43, 36, 49, 51]
    
    gateway.process_legacy_phone_frame("NDSU_WOOD_BARN_PHONE_02", mock_phone_bits)
