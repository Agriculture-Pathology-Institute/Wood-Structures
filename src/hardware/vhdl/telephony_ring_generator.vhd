-- ===================================================================================
-- UNIVAC IX Core Fabric --- Automated Telephony Ring Tone & Cadence Generator
-- File: telephony_ring_generator.vhd
-- ===================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity telephony_ring_generator is
    Generic (
        CLK_FREQ_HZ   : integer := 50000000
    );
    Port (
        clk                 : in  STD_LOGIC;
        reset_n             : in  STD_LOGIC;
        execute_ring        : in  STD_LOGIC; -- Asserted high by control room loop
        ring_tone_output    : out STD_LOGIC  -- Output feeding the external line driver
    );
end telephony_ring_generator;

architecture Behavioral of telephony_ring_generator is
    -- 20 Hz Wave Generation Consts: (50,000,000 / 20) / 2 = 1,250,000 cycles per half-period
    constant HALF_PERIOD_20HZ : integer := 1250000;
    
    -- Cadence Control Consts (Based on standard 6-second total window block)
    constant TIME_1SEC_CYCLES : integer := CLK_FREQ_HZ;
    constant CADENCE_MAX      : integer := CLK_FREQ_HZ * 6; -- 6 Second Loop duration
    constant ON_DURATION      : integer := CLK_FREQ_HZ * 2; -- 2 Seconds of ringing active

    signal clk_divider_20hz   : integer range 0 to HALF_PERIOD_20HZ := 0;
    signal internal_20hz_wave : STD_LOGIC := '0';
    
    signal cadence_counter    : integer range 0 to CADENCE_MAX := 0;
    signal cadence_active     : STD_LOGIC := '0';

begin

    -- 1. Precision 20 Hz Tone Generator Loop
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            clk_divider_20hz   <= 0;
            internal_20hz_wave <= '0';
        elsif rising_edge(clk) then
            if execute_ring = '1' then
                if clk_divider_20hz >= HALF_PERIOD_20HZ - 1 then
                    clk_divider_20hz   <= 0;
                    internal_20hz_wave <= not internal_20hz_wave;
                else
                    clk_divider_20hz   <= clk_divider_20hz + 1;
                end if;
            else
                clk_divider_20hz   <= 0;
                internal_20hz_wave <= '0';
            end if;
        end if;
    end process;

    -- 2. Intermittent Cadence Logic Engine (2s ON, 4s OFF)
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            cadence_counter <= 0;
            cadence_active  <= '0';
        elsif rising_edge(clk) then
            if execute_ring = '1' then
                if cadence_counter >= CADENCE_MAX - 1 then
                    cadence_counter <= 0;
                else
                    cadence_counter <= cadence_counter + 1;
                end if;
                
                -- Check if counter is within the 2-second active ringing threshold
                if cadence_counter < ON_DURATION then
                    cadence_active <= '1';
                else
                    cadence_active <= '0';
                end if;
            else
                cadence_counter <= 0;
                cadence_active  <= '0';
            end if;
        end if;
    end process;

    -- 3. Combine Waveform and Cadence Gating Arrays
    ring_tone_output <= internal_20hz_wave and cadence_active and execute_ring;

end Behavioral;
