----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.06.2016 22:56:59
-- Design Name: 
-- Module Name: tb_FPGA_webserver - Behavioral
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

entity tb_FPGA_webserver is
end tb_FPGA_webserver;

architecture Behavioral of tb_FPGA_webserver is
    component FPGA_webserver is
    Port (  clk100MHz : in    std_logic; -- system clock
            switches  : in    std_logic_vector(3 downto 0);
            leds      : out   std_logic_vector(7 downto 0);
            
            -- Ethernet Control signals
            eth_int_b : in    std_logic; -- interrupt
            eth_pme_b : in    std_logic; -- power management event
            eth_rst_b : out   std_logic := '0'; -- reset
            -- Ethernet Management interface
            eth_mdc   : out   std_logic := '0'; 
            eth_mdio  : inout std_logic := '0';
            -- Ethernet Receive interface
            eth_rxck  : in    std_logic; 
            eth_rxctl : in    std_logic;
            eth_rxd   : in    std_logic_vector(3 downto 0);
            -- Ethernet Transmit interface
            eth_txck  : out   std_logic := '0';
            eth_txctl : out   std_logic := '0';
            eth_txd   : out   std_logic_vector(3 downto 0) := (others => '0')
    );
    end component;

    signal clk100MHz : std_logic; -- system clock
    signal switches  : std_logic_vector(3 downto 0);
    signal leds      : std_logic_vector(7 downto 0);
            
            -- Ethernet Control signals
    signal eth_int_b : std_logic := '0'; -- interrupt
    signal eth_pme_b : std_logic := '0'; -- power management event
    signal eth_rst_b : std_logic := '0'; -- reset
            -- Ethernet Management interface
    signal eth_mdc   : std_logic := '0'; 
    signal eth_mdio  : std_logic := '0';
            -- Ethernet Receive interface
    signal eth_rxck  : std_logic := '0'; 
    signal eth_rxctl : std_logic := '0';
    signal eth_rxd   : std_logic_vector(3 downto 0) := (others => '0');
            -- Ethernet Transmit interface
    signal eth_txck  : std_logic := '0';
    signal eth_txctl : std_logic := '0';
    signal eth_txd   : std_logic_vector(3 downto 0) := (others => '0');

begin

process
    begin
        clk100MHz <= '1';
        wait for 5.0 ns;
        clk100Mhz <= '0';
        wait for 5.0 ns;
    end process;

uut: FPGA_webserver port map (
        clk100MHz => clk100MHz,
        switches  => switches,
        leds      => leds,
                
        -- Ethernet Control signals
        eth_int_b => eth_int_b,
        eth_pme_b => eth_pme_b,
        eth_rst_b => eth_rst_b,
        
        -- Ethernet Management interface
        eth_mdc   => eth_mdc, 
        eth_mdio  => eth_mdio,
        -- Ethernet Receive interface
        eth_rxck  => eth_rxck, 
        eth_rxctl => eth_rxctl,
        eth_rxd   => eth_rxd,
     
        -- Ethernet Transmit interface
        eth_txck           => eth_txck,
        eth_txctl          => eth_txctl,
        eth_txd            => eth_txd
    );

end Behavioral;
