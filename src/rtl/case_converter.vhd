----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.03.2026 16:38:00
-- Design Name: 
-- Module Name: case_converter - rtl
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

entity case_converter is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        
        -- input stream
        data_in : in std_logic_vector(7 downto 0);
        valid_in : in STD_LOGIC;
        ready_in : out STD_LOGIC;
        
        -- output stream
        data_out : out std_logic_vector(7 downto 0);
        valid_out : out STD_LOGIC;
        ready_out : in STD_LOGIC
    );
end case_converter;

architecture rtl of case_converter is

    signal data_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_reg : std_logic := '0';

begin

    process(clk, rst)
        
        -- Its necessary?
        variable byte_v : unsigned(7 downto 0);
        
    begin 
        if rst = '1' then
            data_reg <= (others => '0');
            valid_reg <= '0';
        
        elsif rising_edge(clk) then
           
           -- Input transfer happens when input is valid and this block can accept it
            if (valid_in = '1') and ((valid_reg = '0') or (ready_out = '1')) then
            
                byte_v := unsigned(data_in);
                
                -- 'A' to 'Z' -> Lower Case
                if (byte_v >= x"41") and (byte_v <= x"5A")then
                    byte_v := byte_v + x"20";
                
                --`'a' to 'z' -> Upper Case
                elsif (byte_v >= x"61") and (byte_v <= x"7A") then
                    byte_v := byte_v - x"20";
                
                end if;
                -- else -> Any
                
                -- Store processed data
                data_reg  <= std_logic_vector(byte_v);
                valid_reg <= '1';
            
            -- Output transfer happens and no new input arrives
            elsif ready_out = '1' and valid_reg = '1' then 
                valid_reg <= '0';
            
            end if;
       end if;

    end process;
    
    -- Outputs
    
    data_out <= data_reg;
    valid_out <= valid_reg;
    
    -- This block can accept new input when:
    -- 1) its internal register is empty
    -- 2) or the current output is consumed in this cycle   
    ready_in <= '1' when valid_reg = '0' or ready_out = '1' else '0';


end rtl;
