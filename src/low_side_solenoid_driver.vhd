-- ===================================================================================
-- UNIVAC IX Core Fabric --- Pulse Duration Execution Module Component
-- Component: low_side_solenoid_driver
-- ===================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity low_side_solenoid_driver is
    Generic (
        CLK_FREQ_HZ   : integer := 50000000;
        PULSE_TIME_MS : integer := 250
    );
    Port (
        clk                 : in  STD_LOGIC;
        reset_n             : in  STD_LOGIC;
        trigger_flush       : in  STD_LOGIC;
        gate_driver_output  : out STD_LOGIC
    );
end low_side_solenoid_driver;

architecture Behavioral of low_side_solenoid_driver is
    constant MAX_CYCLES : integer := (CLK_FREQ_HZ / 1000) * PULSE_TIME_MS;
    type state_type is (IDLE, ENERGIZE_BURST, COOL_DOWN);
    signal current_state, next_state : state_type;
    signal cycle_counter : integer range 0 to MAX_CYCLES := 0;
begin
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            current_state <= IDLE;
            cycle_counter <= 0;
        elsif rising_edge(clk) then
            current_state <= next_state;
            if current_state = ENERGIZE_BURST then
                cycle_counter <= cycle_counter + 1;
            else
                cycle_counter <= 0;
            end if;
        end if;
    end process;

    process(current_state, trigger_flush, cycle_counter)
    begin
        next_state <= current_state;
        gate_driver_output <= '0';
        case current_state is
            when IDLE =>
                if trigger_flush = '1' then
                    next_state <= ENERGIZE_BURST;
                end if;
            when ENERGIZE_BURST =>
                gate_driver_output <= '1';
                if cycle_counter >= MAX_CYCLES then
                    next_state <= COOL_DOWN;
                end if;
            when COOL_DOWN =>
                gate_driver_output <= '0';
                if trigger_flush = '0' then
                    next_state <= IDLE;
                end if;
            when others =>
                next_state <= IDLE;
        end case;
    end process;
end Behavioral;
