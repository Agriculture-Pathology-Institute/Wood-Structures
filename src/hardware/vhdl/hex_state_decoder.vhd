-- ===================================================================================
-- UNIVAC IX Core Fabric --- 16-State Hexadecimal Analog Window Decoder Module
-- File: hex_state_decoder.vhd
-- ===================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hex_state_decoder is
    Port (
        hex_bus_input       : in  STD_LOGIC_VECTOR(3 downto 0);
        heater_trace_enable : out STD_LOGIC;
        edwards_relay_drive : out STD_LOGIC
    );
end hex_state_decoder;

architecture Behavioral of hex_state_decoder is
begin
    process(hex_bus_input)
    begin
        case hex_bus_input is
            when "1101" => -- State 0xD (0.8125V): Localized moisture accumulation warning
                heater_trace_enable <= '1'; -- Engage 10-Ohm surface heater trace
                edwards_relay_drive <= '1'; -- Maintain safe hold on FireWorks NC loop
                
            when "1110" => -- State 0xE (0.8750V): Extreme relative humidity saturation
                heater_trace_enable <= '1';
                edwards_relay_drive <= '1';
                
            when "1111" => -- State 0xF (0.9375V): Condensation convergence critical failure
                heater_trace_enable <= '0'; -- Isolate elements
                edwards_relay_drive <= '0'; -- Drop loop instantly (Relay Pops OPEN)
                
            when others => -- States 0x0 through 0xC: Nominal dry atmospheric profiles
                heater_trace_enable <= '0';
                edwards_relay_drive <= '1';
        end case;
    end process;
end Behavioral;
