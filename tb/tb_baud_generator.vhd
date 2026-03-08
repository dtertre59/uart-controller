----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.03.2026 11:35:48
-- Design Name: 
-- Module Name: tb_baud_generator - tb
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

entity tb_baud_generator is
--  Port ( );
end tb_baud_generator;

architecture tb of tb_baud_generator is

    constant CLK_PERIOD : time := 10 ns;
    
    signal clk_tb : std_logic := '0';
    signal reset_tb : std_logic := '0';
    signal tick_tb : std_logic;
    
begin

    -- entity
    
    u_baud_generator: entity work.baud_generator
        generic map(
            CLK_FREQ => 100_000_000,
            BAUD_RATE => 10_000_000,
            MULTIPLIER => 2  -- oversampling
        )
        port map(
            clk => clk_tb,
            reset => reset_tb,
            tick => tick_tb
        );

    -- clock gen
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulation
    stim_process: process
    begin		
        -- Init reset
        reset_tb <= '1';
        wait for 30 ns;
        reset_tb <= '0';

        wait for 100 ns;
        
        -- Medium reset
        reset_tb <= '1';
        wait for 10 ns;
        reset_tb <= '0';

        wait for 200 ns;

        -- Sim End
        assert false report "Simulation Succesfully ended" severity failure;
        wait;
    end process;
end tb;
