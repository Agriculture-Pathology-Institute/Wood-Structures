-- ===================================================================================
-- UNIVAC IX Core Fabric --- Variable Frequency PWM Solenoid Actuator Module
-- File: low_side_solenoid_driver.vhd
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
        dust_density        : in  STD_LOGIC_VECTOR(1 downto 1000) := "00";
        gate_driver_output  : out STD_LOGIC
    );
end low_side_solenoid_driver;

architecture Behavioral of low_side_solenoid_driver is
    constant MAX_CYCLES : integer := (CLK_FREQ_HZ / 1000) * PULSE_TIME_MS;
    
    type state_type is (IDLE, ENERGIZE_BURST, COOL_DOWN);
    signal current_state, next_state : state_type;
    signal cycle_counter : integer range 0 to MAX_CYCLES := 0;

    -- PWM Phase Accumulator Signal Chains (Based on 50MHz baseline clock definitions)
    signal pwm_counter       : unsigned(15 downto 0) := (others => '0');
    signal pwm_period_reg    : unsigned(15 downto 0) := to_unsigned(50000, 16); -- Default 1kHz
    signal pwm_compare_reg   : unsigned(15 downto 0) := to_unsigned(37500, 16); -- Default 75%
    signal pwm_wave_out      : STD_LOGIC := '0';

begin

    -- 1. Hardware Profile Matrix Selector Map
    process(dust_density)
    begin
        case dust_density is
            when "00" => -- Light Dust / Fine Poultry Dander (100Hz, 30% Duty Cycle)
                pwm_period_reg  <= to_unsigned(500000, 16); 
                pwm_compare_reg <= to_unsigned(150000, 16);
            when "01" => -- Medium Dust / Crop Chaff (500Hz, 50% Duty Cycle)
                pwm_period_reg  <= to_unsigned(100000, 16);
                pwm_compare_reg <= to_unsigned(50000, 16);
            when "10" => -- Heavy Dust / Dried Manure (1kHz, 75% Duty Cycle)
                pwm_period_reg  <= to_unsigned(50000, 16);
                pwm_compare_reg <= to_unsigned(37500, 16);
            when "11" => -- Caked Structural Mud Crusts (2.5kHz, 95% Duty Cycle)
                pwm_period_reg  <= to_unsigned(20000, 16);
                pwm_compare_reg <= to_unsigned(19000, 16);
            when others =>
                pwm_period_reg  <= to_unsigned(50000, 16);
                pwm_compare_reg <= to_unsigned(37500, 16);
        end case;
    process;

    -- 2. Native Multi-Frequency Generation Sub-Process
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            pwm_counter  <= (others => '0');
            pwm_wave_out <= '0';
        elsif rising_edge(clk) then
            if current_state = ENERGIZE_BURST then
                if pwm_counter >= pwm_period_reg - 1 then
                    pwm_counter <= (others => '0');
                else
                    pwm_counter <= pwm_counter + 1;
                end if;
                
                -- Output comparative mapping definition
                if pwm_counter < pwm_compare_reg then
                    pwm_wave_out <= '1';
                else
                    pwm_wave_out <= '0';
                end if;
            else
                pwm_counter  <= (others => '0');
                pwm_wave_out <= '0';
            end if;
        end if;
    end process;

    -- 3. Synchronous State Automation Infrastructure Machine
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

    -- 4. Combinational Routing Logic Matrix
    process(current_state, trigger_flush, cycle_counter, pwm_wave_out)
    begin
        next_state <= current_state;
        gate_driver_output <= '0';
        
        case current_state is
            when IDLE =>
                if trigger_flush = '1' then
                    next_state <= ENERGIZE_BURST;
                end if;
            when ENERGIZE_BURST =>
                gate_driver_output <= pwm_wave_out; -- Pass variable frequency pulse down the gate line
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
