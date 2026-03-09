----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.03.2026 12:14:15
-- Design Name: 
-- Module Name: uart_tx - rtl
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

entity uart_tx is
    generic (
        MULTIPLIER : integer := 16  -- oversampling
    );
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        baud_tick : in STD_LOGIC;
        tx_valid : in STD_LOGIC;
        tx_data : in STD_LOGIC_VECTOR (7 downto 0);
        tx_serial : out STD_LOGIC;
        tx_ready : out STD_LOGIC); -- tx_ready pulses high when input data is accepted
end uart_tx;

architecture rtl of uart_tx is
    type state_type is (IDLE, ARMED, START, DATA, STOP);

    signal state_reg, next_state_reg : state_type := IDLE;

    -- Register that stores the byte currently being transmitted
    signal data_reg, next_data_reg : std_logic_vector(7 downto 0) := (others => '0');
    -- Index of the data bit currently being transmitted (LSB first)
    signal bit_reg, next_bit_reg : integer range 0 to 7 := 0;
    -- Oversampling counter used to keep each bit on the line for MULTIPLIER baud ticks
    signal oversampling_counter, next_oversampling_counter : integer range 0 to MULTIPLIER - 1 := 0;

begin

    -- Register process
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

    -- combinational process
    process(state_reg, data_reg, bit_reg, oversampling_counter, baud_tick, tx_valid, tx_data)
        begin
            -- default values: prevents latches
            next_state_reg <= state_reg;
            next_data_reg <= data_reg;
            next_bit_reg <= bit_reg;
            next_oversampling_counter <= oversampling_counter;

            -- Out default values
            tx_serial <= '1';
            tx_ready <= '0';

            case state_reg is
                when IDLE =>
                    -- Out
                    tx_serial <= '1';
                    tx_ready <= '0';

                    -- comb
                    -- Handshake occurs when tx_valid = '1' and tx_ready = '1'
                    if tx_valid = '1' then
                        next_data_reg <= tx_data;
                        next_bit_reg <= 0;
                        next_oversampling_counter <= 0;
                        tx_ready <= '1'; -- Input data accepted
                        next_state_reg <= ARMED;

                    end if;
                
                -- Transmission armed; start will occur on the next valid baud tick
                when ARMED =>
                    -- Out
                    tx_serial <= '1';
                    tx_ready <= '0';
                    
                    if baud_tick = '1' then
                        next_state_reg <= START;
                    end if;
                    
              -- Start
                when START =>
                    -- Out
                    tx_serial <= '0';
                    tx_ready <= '0';

                    -- Comb
                    if baud_tick = '1' then
                        if oversampling_counter = (MULTIPLIER - 1) then
                            next_bit_reg <= 0;
                            next_oversampling_counter <= 0;

                            next_state_reg <= DATA;
                        else
                            next_oversampling_counter <= oversampling_counter + 1;
                        
                        end if;
                    end if;
                    

                when DATA =>
                    -- Out
                    tx_serial <= data_reg(bit_reg);
                    tx_ready <= '0';

                    -- Comb
                    if baud_tick = '1' then
                        if oversampling_counter = (MULTIPLIER - 1) then
                            next_oversampling_counter <= 0;

                            if bit_reg = 7 then
                                next_state_reg <= STOP;
                            else
                                next_bit_reg <= bit_reg + 1;
                            end if;

                        else
                            next_oversampling_counter <= oversampling_counter + 1;
                        end if;
                    end if;

                when STOP =>
                    -- Out
                    tx_serial <= '1';
                    tx_ready <= '0';

                    -- Comb
                    if baud_tick = '1' then
                        if oversampling_counter = (MULTIPLIER - 1) then
                            next_oversampling_counter <= 0;
                            next_state_reg <= IDLE;
                        else
                            next_oversampling_counter <= oversampling_counter + 1;
                        
                        end if;
                    end if;
                
                when others =>
                    next_state_reg <= IDLE;

                end case;
        end process;

end rtl;
