----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2026 20:25:11
-- Design Name: 
-- Module Name: tb_case_converter - tb
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

entity tb_case_converter is
--  Port ( );
end tb_case_converter;

architecture tb of tb_case_converter is

    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';

    -- input stream
    signal data_in_tb  : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_in_tb : std_logic := '0';
    signal ready_in_tb : std_logic;

    -- output stream
    signal data_out_tb  : std_logic_vector(7 downto 0);
    signal valid_out_tb : std_logic;
    signal ready_out_tb : std_logic := '0';

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    uut : entity work.case_converter
        port map (
            clk       => clk_tb,
            rst       => rst_tb,
            data_in   => data_in_tb,
            valid_in  => valid_in_tb,
            ready_in  => ready_in_tb,
            data_out  => data_out_tb,
            valid_out => valid_out_tb,
            ready_out => ready_out_tb
        );

    --------------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------
    stim_proc : process

        procedure send_byte(
            constant input_byte : in std_logic_vector(7 downto 0)
        ) is
        begin
            -- Wait until DUT can accept input
            wait until rising_edge(clk_tb) and ready_in_tb = '1';

            data_in_tb  <= input_byte;
            valid_in_tb <= '1';

            wait until rising_edge(clk_tb);
            valid_in_tb <= '0';
        end procedure;

        procedure check_output(
            constant expected_byte : in std_logic_vector(7 downto 0);
            constant msg          : in string
        ) is
        begin
            wait until rising_edge(clk_tb);

            assert valid_out_tb = '1'
                report "ERROR: valid_out_tb = '0' | " & msg
                severity failure;

            assert data_out_tb = expected_byte
                report "ERROR: unexpected output | " & msg
                severity failure;
        end procedure;

        procedure send_and_check(
            constant input_byte    : in std_logic_vector(7 downto 0);
            constant expected_byte : in std_logic_vector(7 downto 0);
            constant msg           : in string
        ) is
        begin
            send_byte(input_byte);
            check_output(expected_byte, msg);
        end procedure;

    begin
        ----------------------------------------------------------------------
        -- Reset
        ----------------------------------------------------------------------
        rst_tb       <= '1';
        data_in_tb   <= (others => '0');
        valid_in_tb  <= '0';
        ready_out_tb <= '0';

        wait for 30 ns;
        rst_tb <= '0';
        ready_out_tb <= '1';

        wait until rising_edge(clk_tb);

        ----------------------------------------------------------------------
        -- Basic conversion tests
        ----------------------------------------------------------------------
        send_and_check(x"41", x"61", "'A' should become 'a'");
        send_and_check(x"5A", x"7A", "'Z' should become 'z'");
        send_and_check(x"61", x"41", "'a' should become 'A'");
        send_and_check(x"7A", x"5A", "'z' should become 'Z'");
        send_and_check(x"6D", x"4D", "'m' should become 'M'");
        send_and_check(x"35", x"35", "'5' should remain unchanged");
        send_and_check(x"21", x"21", "'!' should remain unchanged");

        ----------------------------------------------------------------------
        -- Backpressure test
        ----------------------------------------------------------------------
        wait until rising_edge(clk_tb);
        ready_out_tb <= '0';

        send_byte(x"5A"); -- 'Z' -> 'z'

        wait until rising_edge(clk_tb);

        assert valid_out_tb = '1'
            report "ERROR: valid_out_tb should stay high during backpressure"
            severity failure;

        assert data_out_tb = x"7A"
            report "ERROR: data_out_tb should hold 'z' during backpressure"
            severity failure;

        assert ready_in_tb = '0'
            report "ERROR: ready_in_tb should be '0' during backpressure"
            severity failure;

        wait until rising_edge(clk_tb);

        assert valid_out_tb = '1'
            report "ERROR: valid_out_tb should still be high while blocked"
            severity failure;

        assert data_out_tb = x"7A"
            report "ERROR: data_out_tb should remain stable while blocked"
            severity failure;

        ----------------------------------------------------------------------
        -- Release backpressure
        ----------------------------------------------------------------------
        wait until rising_edge(clk_tb);
        ready_out_tb <= '1';

        wait until rising_edge(clk_tb);

        assert ready_in_tb = '1'
            report "ERROR: ready_in_tb should return to '1' after release"
            severity failure;

        ----------------------------------------------------------------------
        -- Test after backpressure
        ----------------------------------------------------------------------
        send_and_check(x"41", x"61", "Post-backpressure test: 'A' should become 'a'");

        report "TB PASSED";
        wait;
    end process;

end tb;