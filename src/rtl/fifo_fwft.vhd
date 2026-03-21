----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2026 09:26:23
-- Design Name: 
-- Module Name: fifo_fwft - rtl
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

entity fifo_fwft is
    generic(
        DATA_WIDTH : integer := 8;  -- 1Byte
        DEPTH : integer := 16       -- Buffer max size: 16 Bytes     
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           write_en : in STD_LOGIC;
           write_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
           read_en : in STD_LOGIC;
           read_data : out std_logic_vector(DATA_WIDTH - 1 downto 0);
           full : out STD_LOGIC;
           empty : out STD_LOGIC
           );
end fifo_fwft;

architecture rtl of fifo_fwft is
    
    -- Buffer (array)
    type memory_type is array (0 to DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal memory : memory_type;
    
    -- Pointers
    signal write_ptr : integer range 0 to DEPTH - 1 := 0;
    signal read_ptr : integer range 0 to DEPTH - 1 := 0;
    
    signal count : integer range 0 to DEPTH := 0;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;

        elsif rising_edge(clk) then
            
            -- Write only
            if write_en = '1' and read_en = '0' then
               
                -- FIFO is not full
                if count < DEPTH then
                    memory(write_ptr) <= write_data;
                    
                    -- Update pointer
                    if write_ptr = DEPTH - 1 then
                        write_ptr <= 0;
                    else
                        write_ptr <= write_ptr + 1;
                    end if;
                    
                    -- Update counter
                    count <= count + 1;
                
                end if;
                -- Else: overflow
                    
            -- Read only
            elsif write_en = '0' and read_en = '1' then
                
                -- FIFO is not empty
                if count > 0 then                    
                    -- Update pointer
                    if read_ptr = DEPTH - 1 then
                        read_ptr <= 0;
                    else
                        read_ptr <= read_ptr + 1;
                    end if;
                    
                    -- Update counter (decrease)
                    count <= count - 1;
                
                end if;
                -- Else: underflow / No read
            
            -- Read and Write
            elsif write_en = '1' and read_en = '1' then
            
                -- empty: cant read, only write
                if count = 0 then
                    memory(write_ptr) <= write_data;
                    
                    -- Update pointer
                    if write_ptr = DEPTH - 1 then
                        write_ptr <= 0;
                    else
                        write_ptr <= write_ptr + 1;
                    end if;
                    
                    -- Update counter
                    count <= count + 1;
                
                else -- Count > 0
                    -- Normal simultaneous read and write
                    memory(write_ptr) <= write_data;

                    -- Read
                    if read_ptr = DEPTH - 1 then
                        read_ptr <= 0;
                    else
                        read_ptr <= read_ptr + 1;
                    end if;
                    
                    -- Write
                    if write_ptr = DEPTH - 1 then
                        write_ptr <= 0;
                    else
                        write_ptr <= write_ptr + 1;
                    end if;
                
                -- count unchanged
                end if;
               
            -- IDLE 
            else
                -- No operation
                null;
            end if;
        end if;
    end process;
    
    -- Out

    -- FIFO Show Ahead
    read_data <= memory(read_ptr) when count > 0 else (others => '0');

    empty <= '1' when count = 0 else '0';
    full <= '1' when count = DEPTH else '0';

end rtl;
