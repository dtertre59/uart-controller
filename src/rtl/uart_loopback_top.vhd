----------------------------------------------------------------------------------
-- Company: 
-- Engineer: David Tertre
-- 
-- Create Date: 09.03.2026 17:33:19
-- Design Name: 
-- Module Name: uart_loopback_top - structural
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

entity uart_loopback_top is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;  -- reset active low
           serial_rx : in STD_LOGIC;
           serial_tx : out STD_LOGIC);
end uart_loopback_top;

architecture structural of uart_loopback_top is

    constant CLK_FREQ : integer := 100_000_000;
    constant BAUD_RATE : integer := 115200;
    constant MULTIPLIER : integer := 16;


    signal rst : std_logic := '1';
    signal rst_sync : std_logic := '1';

    signal baud_tick : std_logic := '0';
    
    signal rx_ready : std_logic := '0'; -- RX data has been taken
    signal rx_valid : std_logic := '0'; -- RX data is valid and ready to be read
    signal rx_data : std_logic_vector(7 downto 0) := (others => '0');
    

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
    
    -- UART RX (serial_rx is synchronized internally) --
    
    u_uart_rx : entity work.uart_rx
        generic map(
            MULTIPLIER => MULTIPLIER
        )
        port map(
            clk => clk,
            reset => rst_sync,
            baud_tick => baud_tick,
            serial_rx => serial_rx,
            rx_ready => rx_ready,
            rx_valid => rx_valid,
            rx_data => rx_data
        );
    
    -- LOOPBACK --
    
    -- Directly connect RX handshake/data to TX
    
    -- UART TX --
    
    u_uart_tx : entity work.uart_tx
        generic map(
            MULTIPLIER => MULTIPLIER
        )
        port map(
            clk => clk,
            reset => rst_sync,
            baud_tick => baud_tick,
            tx_valid => rx_valid,
            tx_data => rx_data,
            serial_tx => serial_tx,
            tx_ready => rx_ready
        );

end structural;
