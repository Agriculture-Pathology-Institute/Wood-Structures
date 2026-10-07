-- ===================================================================================
-- UNIVAC IX Core Fabric --- Top-Level Structural Hardware Wrapper (PWM Version)
-- File: univac_ix_node_top.vhd
-- ===================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity univac_ix_node_top is
    Generic (
        CLK_FREQ_HZ       : integer := 50000000;  -- 50MHz Master Oscillator Input
        PULSE_DURATION_MS : integer := 250        -- 250ms Back-Flush Valve Opening
    );
    Port (
        clk_50m             : in  STD_LOGIC;  -- Physical Pin Entry for Clock
        master_reset_n      : in  STD_LOGIC;  -- Hardware Reset Line
        twist_lock_latch_n  : in  STD_LOGIC;  -- Pin 9/10 Interlock (Active Low, Open = Breach)
        hex_bus_input       : in  STD_LOGIC_VECTOR(3 downto 0); -- 4-Bit Parallel Hex Representation
        trigger_purge_cmd   : in  STD_LOGIC;  -- Software Loop Back-Flush Push Trigger
        dust_density_select : in  STD_LOGIC_VECTOR(1 downto 0); -- 00: Light, 01: Med, 10: Heavy, 11: Caked
        
        -- Physical Hardware Drive Outputs
        heater_trace_enable : out STD_LOGIC;  -- Direct Drive to 10-Ohm Enclosure Heating Element
        gate_driver_output  : out STD_LOGIC;  -- Pin 11: PWM Gate Drive to Purge MOSFET Solenoid
        edwards_relay_drive : out STD_LOGIC   -- Pin 9/10: Edwards FireWorks NC Relay Control Line
    );
end univac_ix_node_top;

architecture Structural of univac_ix_node_top is

    -- Component Declaration: Low-Side Solenoid Driver Core with Dynamic PWM Modulator
    component low_side_solenoid_driver is
        Generic (
            CLK_FREQ_HZ   : integer;
            PULSE_TIME_MS : integer
        );
        Port (
            clk                 : in  STD_LOGIC;
            reset_n             : in  STD_LOGIC;
            trigger_flush       : in  STD_LOGIC;
            dust_density        : in  STD_LOGIC_VECTOR(1 downto 0);
            gate_driver_output  : out STD_LOGIC
        );
    end component;

    -- Component Declaration: Hexadecimal State Decoder Core
    component hex_state_decoder is
        Port (
            hex_bus_input       : in  STD_LOGIC_VECTOR(3 downto 0);
            heater_trace_enable : out STD_LOGIC;
            edwards_relay_drive : out STD_LOGIC
        );
    end component;

    signal internal_reset_n : STD_LOGIC;

begin

    -- Hardware-Enforced Air-Gap Interlock: Drop power instantly on twist lock breach
    internal_reset_n <= master_reset_n and (not twist_lock_latch_n);

    -- Instantiation 1: Variable Frequency PWM Pneumatic Driver Core Module
    solenoid_actuator_inst : low_side_solenoid_driver
        generic map (
            CLK_FREQ_HZ   => CLK_FREQ_HZ,
            PULSE_TIME_MS => PULSE_DURATION_MS
        )
        port map (
            clk                 => clk_50m,
            reset_n             => internal_reset_n,
            trigger_flush       => trigger_purge_cmd,
            dust_density        => dust_density_select,
            gate_driver_output  => gate_driver_output
        );

    -- Instantiation 2: 16-State Hexadecimal Logic Decoder Matrix Module
    decoder_matrix_inst : hex_state_decoder
        port map (
            hex_bus_input       => hex_bus_input,
            heater_trace_enable => heater_trace_enable,
            edwards_relay_drive => edwards_relay_drive
        );

end Structural;
