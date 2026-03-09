----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.03.2026 16:59:53
-- Design Name: 
-- Module Name: uart_rx - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_rx is
    generic (
        MULTIPLIER : integer := 16  -- oversampling
    );
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        baud_tick : in STD_LOGIC;
        serial_rx : in STD_LOGIC;

        rx_ready : in STD_LOGIC; -- RX output data has been consumed
        rx_valid : out STD_LOGIC; -- RX output data is valid
        rx_data : out STD_LOGIC_VECTOR (7 downto 0)
    );
end uart_rx;

architecture rtl of uart_rx is

    type state_type is (IDLE, START, DATA, STOP, DONE);

    signal state_reg, next_state_reg : state_type := IDLE;

    signal data_reg, next_data_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_reg, next_bit_reg : integer range 0 to 7 := 0;
    signal oversampling_counter, next_oversampling_counter : integer range 0 to MULTIPLIER - 1 := 0;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= IDLE;
            data_reg <= (others => '0');
            bit_reg <= 0;
            oversampling_counter <= 0;

        elsif rising_edge(clk) then
            state_reg <= next_state_reg;
            data_reg <= next_data_reg;
            bit_reg <= next_bit_reg;
            oversampling_counter <= next_oversampling_counter;
        end if;
    end process;

    process(state_reg, baud_tick, serial_rx, rx_ready, oversampling_counter, bit_reg, data_reg)
    begin
        -- default values: prevents latches
        next_state_reg <= state_reg;
        next_data_reg <= data_reg;
        next_bit_reg <= bit_reg;
        next_oversampling_counter <= oversampling_counter;

        -- Out default value
        rx_valid <= '0';
        rx_data <= data_reg;

        case state_reg is
        
            when IDLE =>
                rx_valid <= '0';
                rx_data <= data_reg;

                if serial_rx = '0' then
                    -- next_data_reg <= "00000000";
                    next_bit_reg <= 0;
                    next_oversampling_counter <= 0;

                    next_state_reg <= START;
                end if;


            when START =>
                rx_valid <= '0';

                if baud_tick = '1' then

                    if oversampling_counter = (MULTIPLIER / 2) - 1 then -- middle bit time
                        next_oversampling_counter <= 0;

                        if serial_rx = '0' then -- start bit confirmation
                            next_bit_reg <= 0;
                            next_state_reg <= DATA;
                        else -- wrong bit
                            next_state_reg <= IDLE;
                        end if;

                    else
                        next_oversampling_counter <= oversampling_counter + 1;
                    end if;
                end if;
                    

            when DATA =>
                rx_valid <= '0';
                
                if baud_tick = '1' then
                    if oversampling_counter = (MULTIPLIER - 1) then
                        next_oversampling_counter <= 0;
                        next_data_reg(bit_reg) <= serial_rx;
                        if bit_reg = 7 then
                            -- next_bit_reg <= 0; -- is not necessary
                            next_state_reg <= STOP;
                        else
                            next_bit_reg <= bit_reg + 1;
                        end if;

                    else
                        next_oversampling_counter <= oversampling_counter + 1;
                    end if;
                end if;

            when STOP =>
                rx_valid <= '0';

                if baud_tick = '1' then
                    if oversampling_counter = (MULTIPLIER - 1) then
                        next_oversampling_counter <= 0;

                        if serial_rx = '1' then
                            next_state_reg <= DONE;

                        else -- discard byte
                            next_state_reg <= IDLE;
                        end if;

                    else
                        next_oversampling_counter <= oversampling_counter + 1;
                    end if;
                end if;

            when DONE =>
                rx_valid <= '1';
                rx_data <= data_reg;

                -- Wait until the external logic acknowledges the received byte
                if rx_ready = '1' then -- Handshake
                    next_state_reg <= IDLE;
                end if;

            when others =>
                next_state_reg <= IDLE;
        
        end case ;
    
    end process;


end rtl;
