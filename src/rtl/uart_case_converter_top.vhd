----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2026 21:47:32
-- Design Name: 
-- Module Name: uart_case_converter_top - structural
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

entity uart_case_converter_top is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           serial_rx : in STD_LOGIC;
           serial_tx : out STD_LOGIC);
end uart_case_converter_top;

architecture structural of uart_case_converter_top is
    constant CLK_FREQ : integer := 100_000_000;
    constant BAUD_RATE : integer := 115200;
    constant MULTIPLIER : integer := 16;

    constant DATA_WIDTH : integer := 8;
    constant DEPTH : integer := 16;

    signal rst : std_logic := '1';
    signal rst_sync : std_logic := '1';

    signal baud_tick : std_logic := '0';

    -- UART RX
    
    signal rx_valid : std_logic := '0'; -- RX data is valid and ready to be read
    signal rx_data : std_logic_vector(7 downto 0) := (others => '0');

    -- RX FIFO

    signal rx_fifo_write_en : std_logic := '0';
    signal rx_fifo_read_en : std_logic := '0';
    signal rx_fifo_full : std_logic := '0';
    signal rx_fifo_empty : std_logic := '0';
    signal rx_fifo_read_data : std_logic_vector(7 downto 0) := (others => '0');

    -- Case Converter

    signal case_conv_ready : std_logic := '0';
    signal case_conv_valid : std_logic := '0';
    signal case_conv_data : std_logic_vector(7 downto 0) := (others => '0');

    -- TX FIFO

    signal tx_fifo_write_en : std_logic := '0';
    signal tx_fifo_read_en : std_logic := '0';
    signal tx_fifo_full : std_logic := '0';
    signal tx_fifo_empty : std_logic := '0';
    signal tx_fifo_read_data : std_logic_vector(7 downto 0) := (others => '0');
    
    -- UART TX

    signal tx_ready : std_logic := '0'; -- TX data has been taken

begin

    -- RESET --

    rst <= not rst_n;

    u_reset_sync: entity work.reset_synchronizer
        port map(
            clk => clk,
            rst_async => rst,
            rst_sync => rst_sync
        );

    -- BAUD tick generator --

    u_baud_generator: entity work.baud_generator
        generic map(
            CLK_FREQ => CLK_FREQ,
            BAUD_RATE => BAUD_RATE,
            MULTIPLIER => MULTIPLIER  -- oversampling
        )
        port map(
            clk => clk,
            reset => rst_sync,
            tick => baud_tick
        );
    
    -- UART RX --
    
    u_uart_rx : entity work.uart_rx
        generic map(
            MULTIPLIER => MULTIPLIER
        )
        port map(
            clk => clk,
            reset => rst_sync,
            baud_tick => baud_tick,
            serial_rx => serial_rx,
            rx_ready => not rx_fifo_full,
            rx_valid => rx_valid,
            rx_data => rx_data
        );

    -- RX FIFO CONTROL --

    rx_fifo_write_en <= rx_valid and (not rx_fifo_full);
    rx_fifo_read_en <= case_conv_ready and (not rx_fifo_empty);

    -- FIFO RX --

    u_fifo_rx : entity work.fifo_fwft
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            DEPTH => DEPTH
        )
        port map(
            clk => clk,
            rst => rst_sync,
            write_en => rx_fifo_write_en,
            write_data => rx_data,
            read_en => rx_fifo_read_en,
            read_data => rx_fifo_read_data,
            full => rx_fifo_full,
            empty => rx_fifo_empty
        );

    -- CASE CONVERTER --

    u_case_converter : entity work.case_converter
        port map (
            clk => clk,
            rst => rst_sync,
            data_in => rx_fifo_read_data,
            valid_in => not rx_fifo_empty,
            ready_in => case_conv_ready,
            data_out => case_conv_data,
            valid_out => case_conv_valid,
            ready_out => not tx_fifo_full
        );

    -- TX FIFO CONTROL --

    tx_fifo_write_en <= case_conv_valid and (not tx_fifo_full);
    tx_fifo_read_en <= tx_ready and (not tx_fifo_empty);

    -- FIFO TX --

    u_fifo_tx : entity work.fifo_fwft
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            DEPTH => DEPTH
        )
        port map(
            clk => clk,
            rst => rst_sync,
            write_en => tx_fifo_write_en,
            write_data => case_conv_data,
            read_en => tx_fifo_read_en,
            read_data => tx_fifo_read_data,
            full => tx_fifo_full,
            empty => tx_fifo_empty
        );

    -- UART TX --

     u_uart_tx : entity work.uart_tx
        generic map(
            MULTIPLIER => MULTIPLIER
        )
        port map(
            clk => clk,
            reset => rst_sync,
            baud_tick => baud_tick,
            tx_valid => not tx_fifo_empty,
            tx_data => tx_fifo_read_data,
            serial_tx => serial_tx,
            tx_ready => tx_ready
        );

end structural;
