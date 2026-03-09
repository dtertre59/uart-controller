----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.03.2026 13:56:15
-- Design Name: 
-- Module Name: tb_uart_tx - tb
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

entity tb_uart_tx is
--  Port ( );
end tb_uart_tx;

architecture tb of tb_uart_tx is

    constant CLK_PERIOD : time := 10 ns;
    
    signal clk_tb : std_logic := '0';
    signal reset_tb : std_logic := '0';
    signal baud_tick_tb : std_logic := '0';
    signal tx_valid_tb : std_logic := '0';
    signal tx_data_tb : std_logic_vector(7 downto 0):= (others => '0');

    signal serial_tx_tb : std_logic := '0';
    signal tx_ready_tb : std_logic := '0';

begin

    -- entity
    u_uart_tx: entity work.uart_tx
        generic map(
            MULTIPLIER => 2  -- oversampling
        )
        port map(
            clk => clk_tb,
            reset => reset_tb,
            baud_tick => baud_tick_tb,
            tx_valid => tx_valid_tb,
            tx_data => tx_data_tb,
            serial_tx => serial_tx_tb,
            tx_ready => tx_ready_tb
        );

    -- clock gen
    clk_process : process
    begin
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
    end process;

    -- baud tick gen x multiplier
    baud_tick_process : process
    begin
        baud_tick_tb <= '1';
        wait for CLK_PERIOD; -- odd number
        baud_tick_tb <= '0';
        wait for CLK_PERIOD * 2;
    end process;

    -- Stimulation
    stim_process: process
    begin		
        -- Init reset
        reset_tb <= '1';
        wait for 30 ns;
        reset_tb <= '0';

        wait for 30 ns;

        -- Start bit
        tx_valid_tb <= '1';
        tx_data_tb <= "10010101";
        wait for 10 ns;

        -- Read data
        tx_valid_tb <= '0';

        -- Stop
        wait for 750 ns;
        
        -- Start bit
        tx_valid_tb <= '1';
        tx_data_tb <= "00101101";
        wait for 10 ns;

        -- Read data
        tx_valid_tb <= '0';
        wait for 80 ns;

        -- Stop
        wait for 10 ns;

        -- Sim End
        assert false report "Simulation Succesfully ended" severity failure;
        wait;
    end process;


end tb;
