----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.03.2026 10:50:58
-- Design Name: 
-- Module Name: tb_uart_rx - tb
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_uart_rx is
--  Port ( );
end tb_uart_rx;

architecture tb of tb_uart_rx is
    
    constant MULTIPLIER : integer :=4;
    constant CLK_PERIOD : time := 10 ns;
    constant BIT_TIME   : time := (CLK_PERIOD * MULTIPLIER) * MULTIPLIER;  -- 1 UART bit = 2 clock periods
    
    signal clk_tb : std_logic := '0';
    signal reset_tb : std_logic := '0';
    signal baud_tick_tb : std_logic := '0';

    signal rx_serial_tb : std_logic := '1';
    signal rx_ready_tb : std_logic := '0';

    signal rx_valid_tb : std_logic := '0';
    signal rx_data_tb : std_logic_vector(7 downto 0):= (others => '0');

    

begin

    -- entity
    uuu: entity work.uart_rx
        generic map(
            MULTIPLIER => MULTIPLIER  -- oversampling
        )
        port map(
            clk => clk_tb,
            reset => reset_tb,
            baud_tick => baud_tick_tb,
            rx_serial => rx_serial_tb,
            rx_ready => rx_ready_tb,
            rx_valid => rx_valid_tb,
            rx_data => rx_data_tb
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Baud tick generation
    baud_tick_process : process
        variable count : integer := 0;
    begin
        wait until rising_edge(clk_tb);

        if count = (MULTIPLIER - 1) then
            baud_tick_tb <= '1';
            count := 0;
        else
            baud_tick_tb <= '0';
            count := count + 1;
        end if;
    end process;

   -- Stimulus
    stim_process : process

        procedure send_uart_byte(
            signal rx_line : out std_logic;
            constant data  : in  std_logic_vector(7 downto 0)
        ) is
        begin
            -- Start bit
            rx_line <= '0';
            wait for BIT_TIME;

            -- Data bits (LSB first)
            for i in 0 to 7 loop
                rx_line <= data(i);
                wait for BIT_TIME;
            end loop;

            -- Stop bit
            rx_line <= '1';
            wait for BIT_TIME;
        end procedure;

    begin
        -- Idle line
        rx_serial_tb <= '1';
        rx_ready_tb  <= '0';

        -- Reset
        reset_tb <= '1';
        wait for 30 ns;
        reset_tb <= '0';
        
        -- to Sync with baud
        wait for 45 ns;

        -- Send one byte
        send_uart_byte(rx_serial_tb, x"55");

        -- Wait until RX says data is valid
        loop
            wait until rising_edge(clk_tb);
            exit when rx_valid_tb = '1';
        end loop;

        -- Check received byte
        assert rx_data_tb = x"55"
            report "ERROR: received byte is not 0x55"
            severity failure;

        -- Handshake
        rx_ready_tb <= '1';
        wait for CLK_PERIOD;
        rx_ready_tb <= '0';

        wait for 30 ns;

        -- Send another byte
        send_uart_byte(rx_serial_tb, x"A3");

        loop
            wait until rising_edge(clk_tb);
            exit when rx_valid_tb = '1';
        end loop;

        assert rx_data_tb = x"A3"
            report "ERROR: received byte is not 0xA3"
            severity failure;

        rx_ready_tb <= '1';
        wait for CLK_PERIOD;
        rx_ready_tb <= '0';

        wait for 50 ns;

        assert false report "Simulation successfully ended" severity failure;
        wait;
    end process;


end tb;
