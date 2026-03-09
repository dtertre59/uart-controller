----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.03.2026 17:40:10
-- Design Name: 
-- Module Name: reset_synchronizer - rtl
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

entity reset_synchronizer is
    Port ( clk : in STD_LOGIC;
           rst_async : in STD_LOGIC;
           rst_sync : out STD_LOGIC);
end reset_synchronizer;

architecture rtl of reset_synchronizer is

    signal ff1, ff2 : std_logic := '1'; -- init as 1 (reset)

begin
    process(clk, rst_async)
    begin
        if rst_async = '1' then
            ff1 <= '1';
            ff2 <= '1';
        elsif rising_edge(clk) then
            ff1 <= '0';
            ff2 <= ff1;
        end if;
    end process;
    
    rst_sync <= ff2;


end rtl;
