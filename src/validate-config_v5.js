/**
 * UNIVAC IX Core Fabric --- Utility Adapter Handshake & Process Mapping Interface
 * Validates utility matrix states and outputs real-time metrics logs to Visio sheets.
 */

const fs = require('fs');
const path = require('path');

const VISIO_PATH = "/app/data/visio_mapping.csv";

const ADAPTER_STATES = {
    0x1: "Turnstile Release Latch Engaged",
    0x2: "Walkthrough Barn Door Actuator Opened",
    0x3: "Pasture Perimeter Gate Solenoid Active",
    0x4: "Machinery Bay Overhead Garage Toggle Fired",
    0x5: "Hydroponic Feeding Water Valve Opened",
    0x6: "Sub-floor Frost Prevention Heating Strip Active",
    0x7: "Exhaust HVAC Compressor Active",
    0x8: "Climate Recovery Configuration Block Latched",
    0x9: "Sanitisation Wash Down Cycle Active",
    0xC: "Scheduled Infrastructure Maintenance Mode"
};

function processUtilityHandshake(telemetryPacket) {
    const hexStateInt = Math.round(telemetryPacket.dew_point_analog_voltage / 0.0625);
    const nodeId = telemetryPacket.node_id;
    
    let description = "Facility Utilities Loop Rest State";
    let color = "Green";

    if (ADAPTER_STATES[hexStateInt]) {
        description = ADAPTER_STATES[hexStateInt];
    } else if (hexStateInt === 0xF || hexStateInt === 0x0) {
        description = "EMERGENCY SAFETY DROPOUT INTERLOCK ENGAGED";
        color = "Red";
    }

    console.log(`[*] Facility Adapter Event Tracker -> Node: ${nodeId} | State: 0x${hexStateInt.toString(16).toUpperCase()} | ${description}`);
    
    // Append entry safely into your running Visio process layout chart tracking database
    appendVisioRow(nodeId, description, color, telemetryPacket.dew_point_analog_voltage);
}

function appendVisioRow(nodeId, actionText, statusColor, currentV) {
    const csvRow = `${nodeId}_UTIL_EVENT,Smart Adapter Node,${statusColor},"${actionText}",${currentV.toFixed(4)}V,101.325 kPa\n`;
    try {
        fs.appendFileSync(VISIO_PATH, csvRow);
    } catch (err) {
        console.error(`[-] Error updating Visio infrastructure matrix logs: ${err.message}`);
    }
}

// Emulate an incoming water/irrigation action packet
processUtilityHandshake({
    node_id: "LSU_DAIRY_BARN_ZONE_03",
    dew_point_analog_voltage: 0.3125 // State 0x5 Map
});
