-- ===================================================================================
-- UNIVAC IX Core Fabric --- Global Infrastructure Testbench Verification Layer
-- File: univac_ix_node_tb.vhd
-- ===================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity univac_ix_node_tb is
-- Testbenches do not contain physical port maps
end univac_ix_node_tb;

architecture Behavior of univac_ix_node_tb is

    component univac_ix_node_top
        Port (
            clk_50m             : in  STD_LOGIC;
            master_reset_n      : in  STD_LOGIC;
            twist_lock_latch_n  : in  STD_LOGIC;
            hex_bus_input       : in  STD_LOGIC_VECTOR(3 downto 0);
            trigger_purge_cmd   : in  STD_LOGIC;
            heater_trace_enable : out STD_LOGIC;
            gate_driver_output  : out STD_LOGIC;
            edwards_relay_drive : out STD_LOGIC
        );
    end component;

    -- Local Sim Signal Interconnect Lines
    signal clk_50m             : STD_LOGIC := '0';
    signal master_reset_n      : STD_LOGIC := '0';
    signal twist_lock_latch_n  : STD_LOGIC := '0';
    signal hex_bus_input       : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal trigger_purge_cmd   : STD_LOGIC := '0';
    
    signal heater_trace_enable : STD_LOGIC;
    signal gate_driver_output  : STD_LOGIC;
    signal edwards_relay_drive : STD_LOGIC;

    constant CLK_PERIOD : time := 20 ns; -- 50MHz Clock Emulation Base

begin

    -- UUT (Unit Under Test) Hook Matrix Placement
    uut: univac_ix_node_top PORT MAP (
          clk_50m             => clk_50m,
          master_reset_n      => master_reset_n,
          twist_lock_latch_n  => twist_lock_latch_n,
          hex_bus_input       => hex_bus_input,
          trigger_purge_cmd   => trigger_purge_cmd,
          heater_trace_enable => heater_trace_enable,
          gate_driver_output  => gate_driver_output,
          edwards_relay_drive => edwards_relay_drive
        );

    -- Clock Signal Generator Wave Loop
    clk_process :process
    begin
        clk_50m <= '0'; wait for CLK_PERIOD/2;
        clk_50m <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Stimulus Vector Logic Pathway Sweeps
    stim_proc: process
    begin		
        master_reset_n     <= '0'; twist_lock_latch_n <= '1'; wait for 100 ns;
        master_reset_n     <= '1'; wait for 100 ns;

        -- Scenario 1: Drive Nominal Voltage States (State 0x4)
        hex_bus_input      <= "0100"; wait for 200 ns;
        
        -- Scenario 2: Command Back-Flush Air Purge Solenoid Pulse
        trigger_purge_cmd  <= '1'; wait for 500 ns;
        trigger_purge_cmd  <= '0'; wait for 200 ns;

        -- Scenario 3: Simulate Dielectric Saturation Warning (State 0xE)
        hex_bus_input      <= "1110"; wait for 300 ns;

        -- Scenario 4: Trigger Critical Condensation Breach Limit (State 0xF)
        hex_bus_input      <= "1111"; wait for 300 ns;

        -- Scenario 5: Simulate Twist-Lock Connector Physical Air-Gap Drop
        hex_bus_input      <= "0000";
        twist_lock_latch_n <= '1'; wait; -- Lock state execution
    end process;

end Behavior;
