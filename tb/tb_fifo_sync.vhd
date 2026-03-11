----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.03.2026 21:40:21
-- Design Name: 
-- Module Name: tb_fifo_sync - tb
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

entity tb_fifo_sync is
-- Port ( );
end tb_fifo_sync;

architecture tb of tb_fifo_sync is

    constant CLK_PERIOD : time := 10 ns;
    constant DATA_WIDTH : integer := 8;
    constant DEPTH : integer := 16;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal write_en : std_logic := '0';
    signal write_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal read_en : std_logic := '0';
    signal read_data : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal full : std_logic;
    signal empty : std_logic;

    --------------------------------------------------------------------------
    -- Procedures
    --------------------------------------------------------------------------

    -- Reset
    procedure fifo_reset(
        signal clk : in std_logic;
        signal rst : out std_logic;
        signal write_en : out std_logic;
        signal read_en : out std_logic;
        signal write_data : out std_logic_vector
    ) is
    begin
        rst <= '1';
        write_en <= '0';
        read_en <= '0';
        write_data <= (others => '0');

        wait until rising_edge(clk);
        wait until rising_edge(clk);

        rst <= '0';
        wait until rising_edge(clk);
    end procedure;

    -- Write
    procedure fifo_write(
        signal clk : in std_logic;
        signal write_en : out std_logic;
        signal write_data : out std_logic_vector;
        constant data : std_logic_vector
    ) is 
    begin
        write_data <= data;
        write_en <= '1';
        wait until rising_edge(clk);
        write_en <= '0';
        wait until rising_edge(clk);
    end procedure;

    -- REad
    procedure fifo_read_check(
        signal clk : in std_logic;
        signal read_en : out std_logic;
        signal read_data : in std_logic_vector;
        constant expected : std_logic_vector
    ) is
    begin
       read_en <= '1';
        wait until rising_edge(clk);
        read_en <= '0';

        wait until rising_edge(clk);

        assert read_data = expected
            report "ERROR: FIFO read data mismatc"
            severity failure;
    end procedure;

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------

    -- DUT (Device Under Test) --
    -- UUT (Unit Under Test) --

    uut: entity work.fifo_sync
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            DEPTH => DEPTH
        )
        port map(
            clk => clk,
            rst => rst,
            write_en => write_en,
            write_data => write_data,
            read_en => read_en,
            read_data => read_data,
            full => full,
            empty => empty
        );

    --------------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------------

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------

    stim_proc : process
    begin

        -- Test 0 --

        report "Test 0: Reset";

        fifo_reset(clk, rst, write_en, read_en, write_data);

        -- Check FIFO status
        assert empty = '1'
            report "ERROR: FIFO should be empty after reset"
            severity failure;

        assert full = '0'
            report "ERROR: FIFO should not be full after reset"
            severity failure;

        -- Test 1 --
        
        report "Test 1: write 4 values";

        fifo_write(clk, write_en, write_data, x"11");
        fifo_write(clk, write_en, write_data, x"22");
        fifo_write(clk, write_en, write_data, x"33");
        fifo_write(clk, write_en, write_data, x"44");

        -- Check FIFO status
        assert empty = '0'
            report "ERROR: FIFO should not be empty after writes"
            severity failure;

        assert full = '0'
            report "ERROR: FIFO should not be full after 4 writes"
            severity failure;

        -- Test 2 --

        report "Test 2: read and check values";

        fifo_read_check(clk, read_en, read_data, x"11");
        fifo_read_check(clk, read_en, read_data, x"22");
        fifo_read_check(clk, read_en, read_data, x"33");
        fifo_read_check(clk, read_en, read_data, x"44");

        assert empty = '1'
            report "ERROR: FIFO should be empty after reading all values"
            severity failure;

        assert full = '0'
            report "ERROR: FIFO should not be full after reading all values"
            severity failure;

        -- Test 3
        
        report "Test 3: Full FIFO";

        for i in 0 to DEPTH-1 loop
            fifo_write(clk, write_en, write_data, std_logic_vector(to_unsigned(i, DATA_WIDTH)));
        end loop;

        assert full = '1'
            report "ERROR: FIFO should be full after writing DEPTH elements"
            severity failure;

        assert empty = '0'
            report "ERROR: FIFO should not be empty when full"
            severity failure;
        
        -- One extra write attempt when FIFO is already full

        report "Extra: Overflow";

        fifo_write(clk, write_en, write_data, x"99");

        assert full = '1'
            report "ERROR: FIFO should remain full after extra write attempt"
            severity failure;

        assert empty = '0'
            report "ERROR: FIFO should not become empty after extra write attempt"
            severity failure;

        -- Test 4

        report "Test 4: Empty FIFO";

        for i in 0 to DEPTH-1 loop
            fifo_read_check(clk, read_en, read_data, std_logic_vector(to_unsigned(i, DATA_WIDTH)));
        end loop;

        assert empty = '1'
            report "ERROR: FIFO should be empty after reading DEPTH elements"
            severity failure;

        assert full = '0'
            report "ERROR: FIFO should not be full when empty"
            severity failure;

        -- Extra read attempt (FIFO already empty)

        report "Extra: Underflow";

        read_en <= '1';
        wait until rising_edge(clk);
        read_en <= '0';
        wait until rising_edge(clk);

        assert empty = '1'
            report "ERROR: FIFO should remain empty after extra read attempt"
            severity failure;

        assert full = '0'
            report "ERROR: FIFO should not become full after extra read attempt"
            severity failure;

        -- Test 5

        report "Test 5: Simultaneous write and read";

        -- Fill FIFO with 3 values
        fifo_write(clk, write_en, write_data, x"A1");
        fifo_write(clk, write_en, write_data, x"B2");
        fifo_write(clk, write_en, write_data, x"C3");

        -- Simultaneous read and write
        write_data <= x"D4";
        write_en <= '1';
        read_en <= '1';

        wait until rising_edge(clk);

        write_en <= '0';
        read_en <= '0';
        write_data <= (others => '0');

        -- Give one extra cycle for registered read_data
        wait until rising_edge(clk);

        assert read_data = x"A1"
            report "ERROR: simultaneous read/write should return A1"
            severity failure;

        -- FIFO should now contain B2, C3, D4
        fifo_read_check(clk, read_en, read_data, x"B2");
        fifo_read_check(clk, read_en, read_data, x"C3");
        fifo_read_check(clk, read_en, read_data, x"D4");

        assert empty = '1'
            report "ERROR: FIFO should be empty after reading remaining values"
            severity failure;

        assert full = '0'
            report "ERROR: FIFO should not be full at end of simultaneous read/write test"
            severity failure;

        
        report "All FIFO tests passed";
        
        wait;
    end process;

     

end tb;
