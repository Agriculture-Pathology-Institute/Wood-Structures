-- File Path: src/hardware/univac_gate_actuators.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity univac_gate_actuators is
    Port (
        -- High-Speed Timing & Control Interface Rails
        CLK_INDUSTRIAL         : in  STD_LOGIC; -- Synchronized to 10.0 MHz clock line
        SYSTEM_RESET           : in  STD_LOGIC;
        
        -- Inbound Parallel Ingestion Tokens from validate-config.js (State 0xA)
        REQUESTED_HEX_STATE    : in  STD_LOGIC_VECTOR(3 downto 0);
        ASSET_CLASS_TOKEN      : in  STD_LOGIC_VECTOR(3 downto 0); -- 0x1: Staff, 0x2: Animal, 0x3: Tractor, 0x4: Drone
        SIGNAL_STROBE_IN       : in  STD_LOGIC;
        
        -- Physical Limit Switches (Active-Low Safety Interlocks)
        LIMIT_FULLY_OPENED     : in  STD_LOGIC;
        LIMIT_FULLY_CLOSED     : in  STD_LOGIC;
        SAFETY_OBSTACLE_BUMPER : in  STD_LOGIC; -- Spikes high if motor hits obstruction
        
        -- Solid-State Output Gate Drivers Routed to DIN-Rail Opto-SSRs
        MOTOR_FORWARD_ENGAGE   : out STD_LOGIC; -- Held high to drive open cycle
        MOTOR_REVERSE_ENGAGE   : out STD_LOGIC; -- Held high to drive close cycle
        BRAKE_CLAMP_RELEASE    : out STD_LOGIC; -- Magnetic brake safety bypass coil line
        
        -- Dynamic Visual Status Indicator Signals
        HUD_MOTION_STATUS      : out STD_LOGIC_VECTOR(1 downto 0); -- 00: Idle, 01: Opening, 10: Closing, 11: Fault
        HEX_SAFETY_OUT         : out STD_LOGIC_VECTOR(3 downto 0)
    );
end univac_gate_actuators;

architecture StructuralActuation of univac_gate_actuators is
    type State_Type is (ST_IDLE, ST_OPENING, ST_HOLD_OPEN, ST_CLOSING, ST_CRITICAL_FAULT);
    signal current_state : State_Type := ST_IDLE;
begin

    process(CLK_INDUSTRIAL, SYSTEM_RESET)
    begin
        if SYSTEM_RESET = '1' then
            current_state        <= ST_IDLE;
            MOTOR_FORWARD_ENGAGE <= '0';
            MOTOR_REVERSE_ENGAGE <= '0';
            BRAKE_CLAMP_RELEASE  <= '0';
            HUD_MOTION_STATUS    <= "00";
            HEX_SAFETY_OUT       <= "0000"; -- Safe state 0x0
        elsif rising_edge(CLK_INDUSTRIAL) then
            if SAFETY_OBSTACLE_BUMPER = '1' then
                current_state <= ST_CRITICAL_FAULT;
            end if;

            case current_state is
                when ST_IDLE =>
                    MOTOR_FORWARD_ENGAGE <= '0';
                    MOTOR_REVERSE_ENGAGE <= '0';
                    BRAKE_CLAMP_RELEASE  <= '0'; -- Lock mechanical spring brakes
                    HUD_MOTION_STATUS    <= "00";
                    HEX_SAFETY_OUT       <= "1111";

                    if SIGNAL_STROBE_IN = '1' and REQUESTED_HEX_STATE = "1010" then -- State 0xA utility signal
                        if LIMIT_FULLY_OPENED = '0' then
                            current_state <= ST_OPENING;
                        end if;
                    end if;

                when ST_OPENING =>
                    MOTOR_FORWARD_ENGAGE <= '1'; -- Energize forward drive solid-state line
                    MOTOR_REVERSE_ENGAGE <= '0';
                    BRAKE_CLAMP_RELEASE  <= '1'; -- Release magnetic storage brake coil
                    HUD_MOTION_STATUS    <= "01";
                    HEX_SAFETY_OUT       <= "1010"; -- Transmit operational token 0xA

                    if LIMIT_FULLY_OPENED = '1' then
                        current_state <= ST_HOLD_OPEN;
                    end if;

                when ST_HOLD_OPEN =>
                    MOTOR_FORWARD_ENGAGE <= '0';
                    MOTOR_REVERSE_ENGAGE <= '0';
                    BRAKE_CLAMP_RELEASE  <= '1'; -- Keep brake off during transit window
                    HUD_MOTION_STATUS    <= "00";
                    
                    -- Stay open if valid tracking vectors remain active, otherwise transition to close loop
                    if SIGNAL_STROBE_IN = '1' and REQUESTED_HEX_STATE = "1111" then
                        current_state <= ST_CLOSING;
                    end if;

                when ST_CLOSING =>
                    MOTOR_FORWARD_ENGAGE <= '0';
                    MOTOR_REVERSE_ENGAGE <= '1'; -- Energize reverse drive solid-state line
                    BRAKE_CLAMP_RELEASE  <= '1';
                    HUD_MOTION_STATUS    <= "10";
                    HEX_SAFETY_OUT       <= "1010";

                    if LIMIT_FULLY_CLOSED = '1' then
                        current_state <= ST_IDLE;
                    end if;

                when ST_CRITICAL_FAULT =>
                    -- Obstacle hit or boundary breach: Kill all gate current profiles in <100ns
                    MOTOR_FORWARD_ENGAGE <= '0';
                    MOTOR_REVERSE_ENGAGE <= '0';
                    BRAKE_CLAMP_RELEASE  <= '0'; -- Snap mechanical brakes shut instantly
                    HUD_MOTION_STATUS    <= "11";
                    HEX_SAFETY_OUT       <= "0000"; -- Collapse bus down to state 0x0

                    if SIGNAL_STROBE_IN = '1' and REQUESTED_HEX_STATE = "1111" then
                        current_state <= ST_IDLE; -- Clear latch flag if reset code passes down-line
                    end if;
            end case;
        end if;
    end process;
end StructuralActuation;
