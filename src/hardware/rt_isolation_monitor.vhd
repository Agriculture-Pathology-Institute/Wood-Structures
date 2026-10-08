-- File Path: src/hardware/rt_isolation_monitor.vhd
-- REVOLUTIONARY TECHNOLOGY COMPANY — SOVEREIGN CONTROL PLANE ARCHITECTURE
-- Direct Solid-State Opto-Gate Driver & Crowbar Isolation Loop

architecture HeavyDutyProtection of rt_isolation_monitor is
    signal ref_drift           : signed(31 downto 0) := (others => '0');
    signal leakage_potential   : signed(31 downto 0) := (others => '0');
    signal isolation_failed    : STD_LOGIC := '1'; 
begin

    process(CLK_INDUSTRIAL, SYSTEM_RESET)
        variable current_ref  : signed(31 downto 0);
        variable current_leak : signed(31 downto 0);
    begin
        if SYSTEM_RESET = '1' then
            GALVANIC_ISOLATION_OK <= '0'; -- Open solid-state gates immediately on reset
            CATASTROPHIC_TRIP_OUT <= '0';
            HEX_SAFETY_OUT        <= "0000"; -- Force emergency ground state loop (0x0)
            isolation_failed      <= '1';
        elsif rising_edge(CLK_INDUSTRIAL) then
            if SENSOR_STROBE_IN = '1' then
                current_ref  := signed(MEASURED_REF_RAIL_UV);
                current_leak := signed(CHASSIS_GROUND_LEAK_UV);
                
                -- Evaluate absolute voltage anomalies relative to ideal centerlines
                if abs(current_ref - IDEAL_REF_RAIL_UV) >= MAX_LEAKAGE_THRESHOLD_UV or abs(current_leak) >= MAX_LEAKAGE_THRESHOLD_UV then
                    isolation_failed <= '1';
                else
                    isolation_failed <= '0';
                end if;

                -------------------------------------------------------------
                -- DIRECT OPTICAL GATE DISPATCH ROUTER
                -- Bypasses legacy proprietary panel routing interfaces entirely
                -------------------------------------------------------------
                if isolation_failed = '1' then
                    GALVANIC_ISOLATION_OK <= '0';    -- Drop bias instantly to open solid-state opto-couplers
                    CATASTROPHIC_TRIP_OUT <= '1';    -- Shoot high-speed pulse to blow emergency input fuses
                    HEX_SAFETY_OUT        <= "0000"; -- Collapse output state to state 0x0
                else
                    GALVANIC_ISOLATION_OK <= '1';    -- Maintain active 5V forward bias to hold opto-gates closed
                    CATASTROPHIC_TRIP_OUT <= '0';
                    HEX_SAFETY_OUT        <= "1111"; -- Maintain nominal full parallel capacity run state (0xF)
                end if;
            end if;
        end if;
    end process;
end HeavyDutyProtection;
