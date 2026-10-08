-- ===================================================================================
-- UNIVAC IX Core Fabric --- Automated Facility Utilities Logic Matrix Decoder
-- File: univac_facility_decoder.vhd
-- ===================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity univac_facility_decoder is
    Port (
        hex_bus_input       : in  STD_LOGIC_VECTOR(3 downto 0); -- 16 Discrete States
        
        -- Mechanical Access Outputs
        turnstile_release   : out STD_LOGIC;  -- Livestock counter indexing latch
        door_opener_actuate : out STD_LOGIC;  -- Main walkthrough barn door latch
        gate_opener_actuate : out STD_LOGIC;  -- Pasture perimeter gate solenoid
        garage_door_trigger : out STD_LOGIC;  -- Machinery bay overhead door toggle
        
        -- Environmental Resource Outputs
        water_valve_open    : out STD_LOGIC;  -- Hydroponic & animal trough feed valve
        maintenance_alert   : out STD_LOGIC;  -- General system loop fault indicator lamp
        heating_element_on  : out STD_LOGIC;  -- Sub-floor frost prevention heat strip
        hvac_compressor_on  : out STD_LOGIC   -- Main barn air exchange exhaust/chiller
    );
end univac_facility_decoder;

architecture Behavioral of univac_facility_decoder is
begin
    process(hex_bus_input)
    begin
        -- Default all isolation relays to safe, de-energized (0) states to prevent loops
        turnstile_release   <= '0';
        door_opener_actuate <= '0';
        gate_opener_actuate <= '0';
        garage_door_trigger <= '0';
        water_valve_open    <= '0';
        maintenance_alert   <= '0';
        heating_element_on  <= '0';
        hvac_compressor_on  <= '0';

        case hex_bus_input is
            when "0001" => turnstile_release   <= '1'; -- State 0x1 (0.0625V)
            when "0010" => door_opener_actuate <= '1'; -- State 0x2 (0.1250V)
            when "0011" => gate_opener_actuate <= '1'; -- State 0x3 (0.1875V)
            when "0100" => garage_door_trigger <= '1'; -- State 0x4 (0.2500V)
            
            when "0101" => water_valve_open    <= '1'; -- State 0x5 (0.3125V)
            when "0110" => heating_element_on  <= '1'; -- State 0x6 (0.3750V)
            when "0111" => hvac_compressor_on  <= '1'; -- State 0x7 (0.4375V)
            
            when "1000" => -- State 0x8 (0.5000V): Combined Climate Mode
                heating_element_on  <= '1';
                water_valve_open    <= '1';
                
            when "1001" => -- State 0x9 (0.5625V): Active Flush Clean cycle
                water_valve_open    <= '1';
                turnstile_release   <= '1';

            when "1100" => maintenance_alert   <= '1'; -- State 0xC (0.7500V): Scheduled Service Mode
            when "1101" => maintenance_alert   <= '1'; -- State 0xD (0.8125V): Environmental Warning
            when "1110" => maintenance_alert   <= '1'; -- State 0xE (0.8750V): Critical Saturation Warning
            
            when others =>
                -- States 0x0 (0.0V) and 0xF (0.9375V) represent safe shutdown lines
                null;
        end case;
    end process;
end Behavioral;
