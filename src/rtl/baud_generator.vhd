----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.03.2026 10:52:53
-- Design Name: 
-- Module Name: baud_generator - Behavioral
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

entity baud_generator is
    generic (
        CLK_FREQ : integer := 100_000_000;
        BAUD_RATE : integer := 115200;
        MULTIPLIER : integer := 16  -- oversampling
    );
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           tick : out STD_LOGIC
    );
end baud_generator;

architecture rtl of baud_generator is
    constant MAX_COUNT : integer := CLK_FREQ / (BAUD_RATE * MULTIPLIER); -- truncate
    -- constant MAX_COUNT : integer := (CLK_FREQ + (BAUD_RATE * MULTIPLIER)/2) / (BAUD_RATE * MULTIPLIER); -- round to nearest
    signal counter : integer range 0 to (MAX_COUNT - 1) := 0; -- This helps syncthesizer infer minimum number of bits required for the counter

begin

    process(clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
            tick <= '0';
        elsif rising_edge(clk) then
            if counter = (MAX_COUNT - 1) then
                counter <= 0;
                tick <= '1';
            else
                counter <= counter + 1;
                tick <= '0';
            end if;
        end if;
    end process;
end rtl;
