/**
 * UNIVAC IX Core Fabric --- Advanced 12-Pin Environmental Validator & Map Generator
 * Audits 12-pin telemetry layouts, pressure limits, and generates Visio layout spreadsheets.
 */

const fs = require('fs');
const path = require('path');

// 12-Pin Allocation Profile Maps for Advanced Smart Farm Devices
const PIN_CONFIGURATION_12 = {
    1:  { signal: "GND_POWER",          type: "Power Return" },
    2:  { signal: "V_SYSTEM_12V",       type: "Actuator Main Supply" },
    3:  { signal: "UNIVAC_BUS_A_HEX",    type: "16-State Logic Trace A" },
    4:  { signal: "UNIVAC_BUS_B_HEX",    type: "16-State Logic Trace B" },
    5:  { signal: "RT_GUARD_RING_REF",   type: "0V Isolation Shield" },
    6:  { signal: "SENSOR_SHT_SDA",     type: "Guarded Digital Telemetry Data" },
    7:  { signal: "SENSOR_SHT_SCL",     type: "Guarded Digital Telemetry Clock" },
    8:  { signal: "HEATER_TRACE_CTL",    type: "Condensation Element Command" },
    9:  { signal: "FAIL_SAFE_LOOP_IN",   type: "Edwards FireWorks Loop Input (NC)" },
    10: { signal: "FAIL_SAFE_LOOP_OUT",  type: "Edwards FireWorks Loop Output (NC)" },
    11: { signal: "ACTUATOR_PWM_DRIVE",  type: "Variable Speed Solenoid/Motor Drive" },
    12: { signal: "SHIELD_GROUND_EARTH", type: "Chassis Frame Ground Armor" }
};

class SmartFarmNodeValidator {
    constructor(outputCsvName = "visio_mapping.csv") {
        self.outputCsvPath = path.join(__dirname, outputCsvName);
    }

    /**
     * Complete structural audit engine of real-time incoming operational signals
     */
    validateTelemetryNode(telemetryPacket) {
        console.log(`\n[*] Initializing UNIVAC IX Fabric Telemetry Audit [Node: ${telemetryPacket.node_id}]...`);

        // Check 1: 12-Pin Twist-Lock Continuity & Pin Presence Inspection
        if (!telemetryPacket.twist_lock_hardware_latch || telemetryPacket.active_pins_detected !== 12) {
            this.triggerEmergencyShutdown(telemetryPacket.node_id, "Pin Count Fault or Twist-Lock Interrupter Open");
            return false;
        }

        // Check 2: Dielectric Hex-State Convergence Window (+/- 2mV Analog Bounds)
        const dewPointVoltage = telemetryPacket.dew_point_analog_voltage;
        let environmentStatus = "Nominal Operations";

        if (dewPointVoltage >= 0.8750 && dewPointVoltage < 0.9375) {
            console.warn(` [!] WARNING: Node ${telemetryPacket.node_id} internal humidity >85% (Hex State 0xD/0xE). Launching Trace Heating element.`);
            environmentStatus = "High Humidity Warning";
            this.toggleTraceHeaterHardware(true);
        } else if (dewPointVoltage >= 0.9375) {
            this.triggerEmergencyShutdown(telemetryPacket.node_id, `Internal Condensation Breach Vector at ${dewPointVoltage}V (State 0xF)`);
            return false;
        }

        // Check 3: Pressure Balancer Equalization Verification
        if (telemetryPacket.internal_pressure_kpa > 115.0 || telemetryPacket.internal_pressure_kpa < 85.0) {
            this.triggerEmergencyShutdown(telemetryPacket.node_id, `Pressure Equalization Vent Clogged - Differential Pressure Out of Bounds`);
            return false;
        }

        console.log(`[+] Node ${telemetryPacket.node_id} passed all architectural safety clearances.`);
        this.exportToVisioDataVisualizer(telemetryPacket.node_id, "Green", environmentStatus, dewPointVoltage);
        return true;
    }

    toggleTraceHeaterHardware(state) {
        console.log(`[*] Pin 8 Payload Transmitted: HEATER_TRACE_CTL set to -> ${state ? "HIGH_DRIVE" : "OFF"}`);
    }

    triggerEmergencyShutdown(nodeId, faultReason) {
        console.error(`\n[FATAL] INSTANT SYSTEM DISCOVERY ABORT AT NODE [${nodeId}]`);
        console.error(`[FATAL] CRITICAL INFRASTRUCTURE REASON: ${faultReason}`);
        console.error("[!] Pin 9 & Pin 10 Opened mechanically. Edwards FireWorks NC Relay dropped. Facility Drive Voltage: 0x0.");
        this.exportToVisioDataVisualizer(nodeId, "Red", `CRITICAL FAULT: ${faultReason}`, 0.0);
    }

    /**
     * Automatic creation/update of Microsoft Visio Data Visualizer formatted process map records
     */
    exportToVisioDataVisualizer(nodeId, nodeColor, statusText, currentAnalogV) {
        const csvHeader = "Process Step ID,Step Name,Status Color,Status Description,Hex Voltage Analog Readout\n";
        const csvRow = `${nodeId},Smart Wood Barn Node Controller,${nodeColor},"${statusText}",${currentAnalogV.toFixed(4)}V\n`;
        
        try {
            if (!fs.existsSync(self.outputCsvPath)) {
                fs.writeFileSync(self.outputCsvPath, csvHeader);
            }
            fs.appendFileSync(self.outputCsvPath, csvRow);
            console.log(`[+] Visio Data Visualizer manifest updated successfully: [${nodeId} -> ${nodeColor}]`);
        } catch (err) {
            console.error(`[-] Error writing Visio structural tracking maps: ${err.message}`);
        }
    }
}

// --- Execution & Multi-Scenario Node System Test Run ---
const validatorEngine = new SmartFarmNodeValidator();

const nominalPacket = {
    node_id: "NDSU_BEEF_BARN_NODE_01",
    twist_lock_hardware_latch: true,
    active_pins_detected: 12,
    dew_point_analog_voltage: 0.2500, // Safe operating step state
    internal_pressure_kpa: 101.3     // Perfectly balanced atmospheric level via Gore plug
};

const cloggedVentPacket = {
    node_id: "LSU_POULTRY_BARN_NODE_04",
    twist_lock_hardware_latch: true,
    active_pins_detected: 12,
    dew_point_analog_voltage: 0.3125,
    internal_pressure_kpa: 128.4     // Failed vent balancing boundary check
};

// Process scenarios through validation channels
validatorEngine.validateTelemetryNode(nominalPacket);
validatorEngine.validateTelemetryNode(cloggedVentPacket);
