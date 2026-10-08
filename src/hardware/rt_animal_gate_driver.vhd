-- File Path: src/hardware/rt_animal_gate_driver.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rt_animal_gate_driver is
    Port (
        -- High-Speed Timing & Control Interface Rails
        CLK_INDUSTRIAL         : in  STD_LOGIC; -- Synchronized to 10.0 MHz clock line
        SYSTEM_RESET           : in  STD_LOGIC;
        
        -- Inbound Execution Token Signals from the Network Core (State 0x9)
        REQUESTED_HEX_STATE    : in  STD_LOGIC_VECTOR(3 downto 0);
        MANUAL_GUI_OPEN_REQ    : in  STD_LOGIC; -- Strobed high if operator clicks target bay icon
        SIGNAL_STROBE_IN       : in  STD_LOGIC;
        
        -- DYNAMIC SCALE FACTOR HARDWARE SWITCH
        -- 0 = Light Duty Pig/Sheep Pen current metrics, 1 = Heavy Duty High-Torque Timber Barn Gate parameters
        SCALE_FACTOR_TIE_INPUT : in  STD_LOGIC; 
        
        -- Grocery-Store Style Infrared Presence Barriers & Obstacle Traps
        INFRARED_BEAM_BROKEN   : in  STD_LOGIC; -- Spikes high if animal is standing in doorway path
        MOTOR_OVERCURRENT_TRIP : in  STD_LOGIC; -- High flag from current sensors if gate hits block
        
        -- Solid-State Output Gate Drivers Routed to DIN-Rail Opto-SSRs
        GATE_DRIVE_MOTOR_OPEN  : out STD_LOGIC; -- Forward drive line
        GATE_DRIVE_MOTOR_CLOSE : out STD_LOGIC; -- Reverse drive line
        GATE_DRIVE_BRAKE_COIL  : out STD_LOGIC; -- Held high to release spring brakes
        
        -- Active Current Limit Output Selection Lines (Sent straight to power amplification stage)
        AMPERAGE_LIMIT_HIGH_BIT: out STD_LOGIC; -- Latch high to authorize maximum torque grids
        HEX_SAFETY_OUT         : out STD_LOGIC_VECTOR(3 downto 0)
    );
end rt_animal_gate_driver;

architecture SolidStateAnimalSafety of rt_animal_gate_driver is
    type OperationalState is (ST_LOCKED_CLOSED, ST_DRIVING_OPEN, ST_HOLD_OPEN, ST_DRIVING_CLOSE, ST_SAFETY_ABORT);
    signal current_gate_state : OperationalState := ST_LOCKED_CLOSED;
begin

    process(CLK_INDUSTRIAL, SYSTEM_RESET)
        variable presence_hazard : STD_LOGIC;
    begin
        if SYSTEM_RESET = '1' then
            current_gate_state      <= ST_LOCKED_CLOSED;
            GATE_DRIVE_MOTOR_OPEN   <= '0';
            GATE_DRIVE_MOTOR_CLOSE  <= '0';
            GATE_DRIVE_BRAKE_COIL   <= '0';
            AMPERAGE_LIMIT_HIGH_BIT <= '0';
            HEX_SAFETY_OUT          <= "0000"; -- Safe state 0x0
        elsif rising_edge(CLK_INDUSTRIAL) then
            
            -- Evaluate immediate hardware-level presence hazard triggers
            presence_hazard := INFRARED_BEAM_BROKEN or MOTOR_OVERCURRENT_TRIP;
            
            -----------------------------------------------------------------
            -- POWER CONFIGURATION SCALING REGISTER
            -- Dynamically routes output current metrics to match mechanical dimensions
            -----------------------------------------------------------------
            if SCALE_FACTOR_TIE_INPUT = '1' then
                AMPERAGE_LIMIT_HIGH_BIT <= '1'; -- Authorize High Current Range for massive timber structures
            else
                AMPERAGE_LIMIT_HIGH_BIT <= '0'; -- Restrict current to safe low-torque thresholds for pig pens
            end if;

            -----------------------------------------------------------------
            -- ZERO-LAENCY ACCESS MOTION FINITE STATE MACHINE
            -----------------------------------------------------------------
            if presence_hazard = '1' then
                -- Presence beam broken: Force immediate solid-state motor shutdown in <100ns
                GATE_DRIVE_MOTOR_OPEN  <= '0';
                GATE_DRIVE_MOTOR_CLOSE <= '0';
                GATE_DRIVE_BRAKE_COIL  <= '0'; -- Snap mechanical safety brakes shut instantly
                HEX_SAFETY_OUT         <= "0000"; -- Collapse state register to 0x0
                current_gate_state     <= ST_SAFETY_ABORT;
                
            else
                case current_gate_state is
                    when ST_LOCKED_CLOSED =>
                        GATE_DRIVE_MOTOR_OPEN  <= '0';
                        GATE_DRIVE_MOTOR_CLOSE <= '0';
                        GATE_DRIVE_BRAKE_COIL  <= '0'; -- Brake locked
                        HEX_SAFETY_OUT         <= "1111"; -- Nominal baseline state (0xF)
                        
                        -- Initiate open pass cycle if network code arrives or manual GUI icon is clicked
                        if SIGNAL_STROBE_IN = '1' and (REQUESTED_HEX_STATE = "1001" or MANUAL_GUI_OPEN_REQ = '1') then
                            current_gate_state <= ST_DRIVING_OPEN;
                        end if;
                        
                    when ST_DRIVING_OPEN =>
                        GATE_DRIVE_MOTOR_OPEN  <= '1'; -- Energize solid-state opening lines
                        GATE_DRIVE_MOTOR_CLOSE <= '0';
                        GATE_DRIVE_BRAKE_COIL  <= '1'; -- Release magnetic storage brake coil
                        HEX_SAFETY_OUT         <= "1001"; -- Transmit active motion index 0x9
                        
                        -- Structural delay simulation endpoint step bypass (In practice hooked to micro-switches)
                        current_gate_state <= ST_HOLD_OPEN;
                        
                    when ST_HOLD_OPEN =>
                        GATE_DRIVE_MOTOR_OPEN  <= '0';
                        GATE_DRIVE_MOTOR_CLOSE <= '0';
                        GATE_DRIVE_BRAKE_COIL  <= '1'; -- Hold brake off during wait frame
                        HEX_SAFETY_OUT         <= "1111";
                        
                        -- Automatically drop back to closing loop if active requests are cleared
                        if SIGNAL_STROBE_IN = '1' and REQUESTED_HEX_STATE = "1111" and MANUAL_GUI_OPEN_REQ = '0' then
                            current_gate_state <= ST_DRIVING_CLOSE;
                        end if;
                        
                    when ST_DRIVING_CLOSE =>
                        GATE_DRIVE_MOTOR_OPEN  <= '0';
                        GATE_DRIVE_MOTOR_CLOSE <= '1'; -- Energize solid-state reversing lines
                        GATE_DRIVE_BRAKE_COIL  <= '1';
                        HEX_SAFETY_OUT         <= "1001";
                        
                        current_gate_state <= ST_LOCKED_CLOSED;
                        
                    when ST_SAFETY_ABORT =>
                        -- Stay locked inside safe abort mode until the presence hazard clears completely
                        if presence_hazard = '0' then
                            current_gate_state <= ST_LOCKED_CLOSED; -- Return to closed monitoring posture
                        end if;
                end case;
            end if;
        end if;
    end process;
end SolidStateAnimalSafety;
