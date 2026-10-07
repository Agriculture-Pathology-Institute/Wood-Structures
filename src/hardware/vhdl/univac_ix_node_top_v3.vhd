-- ===================================================================================
-- UNIVAC IX Core Fabric --- Top-Level Structural Hardware Wrapper (Ring Gen Version)
-- File: univac_ix_node_top.vhd
-- ===================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity univac_ix_node_top is
    Generic (
        CLK_FREQ_HZ       : integer := 50000000;  -- 50MHz Master Clock Input
        PULSE_DURATION_MS : integer := 250        
    );
    Port (
        clk_50m             : in  STD_LOGIC;  
        master_reset_n      : in  STD_LOGIC;  
        twist_lock_latch_n  : in  STD_LOGIC;  
        hex_bus_input       : in  STD_LOGIC_VECTOR(3 downto 0); 
        trigger_purge_cmd   : in  STD_LOGIC;  
        dust_density_select : in  STD_LOGIC_VECTOR(1 downto 0); 
        
        -- Telephony Ring Line Input Control
        trigger_ring_cmd    : in  STD_LOGIC;  -- Command from Central Control to ring field handset
        
        -- Physical Hardware Drive Outputs
        heater_trace_enable : out STD_LOGIC;  
        gate_driver_output  : out STD_LOGIC;  -- Pin 11: Back-flush PWM
        edwards_relay_drive : out STD_LOGIC;  -- Pin 9/10: Edwards Loop
        telephony_ring_out  : out STD_LOGIC   -- Pin 12: 20Hz Electromechanical Bell Drive Output
    );
end univac_ix_node_top;

architecture Structural of univac_ix_node_top is

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

    component hex_state_decoder is
        Port (
            hex_bus_input       : in  STD_LOGIC_VECTOR(3 downto 0);
            heater_trace_enable : out STD_LOGIC;
            edwards_relay_drive : out STD_LOGIC
        );
    end component;

    -- Component Declaration: Missing Automated Audio Ring Generator Block
    component telephony_ring_generator is
        Generic (
            CLK_FREQ_HZ   : integer := 50000000
        );
        Port (
            clk                 : in  STD_LOGIC;
            reset_n             : in  STD_LOGIC;
            execute_ring        : in  STD_LOGIC;
            ring_tone_output    : out STD_LOGIC
        );
    end component;

    signal internal_reset_n : STD_LOGIC;

begin

    internal_reset_n <= master_reset_n and (not twist_lock_latch_n);

    solenoid_actuator_inst : low_side_solenoid_driver
        generic map (CLK_FREQ_HZ => CLK_FREQ_HZ, PULSE_TIME_MS => PULSE_DURATION_MS)
        port map (
            clk => clk_50m, reset_n => internal_reset_n,
            trigger_flush => trigger_purge_cmd, dust_density => dust_density_select,
            gate_driver_output => gate_driver_output
        );

    decoder_matrix_inst : hex_state_decoder
        port map (
            hex_bus_input => hex_bus_input,
            heater_trace_enable => heater_trace_enable,
            edwards_relay_drive => edwards_relay_drive
        );

    -- Instantiation 3: Complete 20Hz Intermittent Ring Generator
    ring_generator_inst : telephony_ring_generator
        generic map (CLK_FREQ_HZ => CLK_FREQ_HZ)
        port map (
            clk              => clk_50m,
            reset_n          => internal_reset_n,
            execute_ring     => trigger_ring_cmd,
            ring_tone_output => telephony_ring_out
        );

end Structural;
