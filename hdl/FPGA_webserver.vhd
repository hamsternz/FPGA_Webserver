----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.05.2016 15:19:15
-- Design Name: 
-- Module Name: FPGA_webserver - Behavioral
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

entity FPGA_webserver is
    Port (  clk100MHz : in    std_logic; -- system clock
            switches  : in    std_logic_vector(3 downto 0);
            leds      : out   std_logic_vector(3 downto 0);
            
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
end FPGA_webserver;

architecture Behavioral of FPGA_webserver is
    constant our_mac     : std_logic_vector(47 downto 0) := x"01_23_45_67_89_AB";
    constant our_ip      : std_logic_vector(31 downto 0) := x"02_0A_0A_0A";
    signal phy_ready     : std_logic := '0';
    -----------------------------
    -- For the clocking 
    -----------------------------
    component clocking is
    Port ( clk100MHz : in STD_LOGIC;
           clk125MHz : out STD_LOGIC;
           clk125MHz90 : out STD_LOGIC);
    end component;
    signal clk125MHz   : STD_LOGIC;
    signal clk125MHz90 : STD_LOGIC;

    component reset_controller is
    Port ( clk125mhz : in STD_LOGIC;
           phy_ready : out STD_LOGIC;
           eth_rst_b : out STD_LOGIC);
    end component;
    --------------------------------------
    -- To receive the raw data from the PHY
    -- (runs in the eth_rxck clock domain)
    --------------------------------------
    component receive_raw_data is
    Port ( eth_rxck        : in  STD_LOGIC;
           eth_rxctl       : in  STD_LOGIC;
           eth_rxd         : in  STD_LOGIC_VECTOR (3 downto 0);
           rx_data_enable  : out STD_LOGIC;
           rx_data         : out STD_LOGIC_VECTOR (7 downto 0);
           rx_data_present : out STD_LOGIC;
           rx_data_error   : out STD_LOGIC);
    end component ;

    signal rx_data_enable  : STD_LOGIC;
    signal rx_data         : STD_LOGIC_VECTOR (7 downto 0);
    signal rx_data_present : STD_LOGIC;
    signal rx_data_error   : STD_LOGIC;

    -------------------------------------------------------
    -- A FIFO to pass the data into the 125MHz clock domain
    -------------------------------------------------------
    component fifo_rxclk_to_clk125MHz is
    Port ( rx_clk          : in  STD_LOGIC;
           rx_write        : in  STD_LOGIC                     := '1';           
           rx_data         : in  STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           rx_data_present : in  STD_LOGIC                     := '0';
           rx_data_error   : in  STD_LOGIC                     := '0';
           
           clk125Mhz       : in  STD_LOGIC;
           empty           : out STD_LOGIC;           
           read            : in  STD_LOGIC;           
           data            : out STD_LOGIC_VECTOR (7 downto 0);
           data_present    : out STD_LOGIC;
           data_error      : out STD_LOGIC);
    end component;
    
    signal input_empty        : STD_LOGIC;           
    signal input_read         : STD_LOGIC;           
    signal input_data         : STD_LOGIC_VECTOR (7 downto 0);
    signal input_data_present : STD_LOGIC;
    signal input_data_error   : STD_LOGIC;

    component main_design is
    Port ( clk125Mhz          : in  STD_LOGIC;
           input_empty        : in  STD_LOGIC;           
           input_read         : out STD_LOGIC;           
           input_data         : in  STD_LOGIC_VECTOR (7 downto 0);
           input_data_present : in  STD_LOGIC;
           input_data_error   : in  STD_LOGIC;

           phy_ready          : in  STD_LOGIC;
           status             : out STD_LOGIC_VECTOR (3 downto 0);
           
           eth_txck           : out std_logic := '0';
           eth_txctl          : out std_logic := '0';
           eth_txd            : out std_logic_vector(3 downto 0) := (others => '0'));
    end component;

begin

i_clocking: clocking port map (
    clk100MHz   => clk100MHz,
    clk125MHz   => clk125MHz,
    clk125MHz90 => clk125MHz90); 

i_reset_controller: reset_controller port map (
    clk125mhz => clk125mhz,
    phy_ready => phy_ready,
    eth_rst_b => eth_rst_b);

i_receive_raw_data: receive_raw_data port map (
    eth_rxck        => eth_rxck,
    eth_rxctl       => eth_rxctl,
    eth_rxd         => eth_rxd,
    rx_data_enable  => rx_data_enable,
    rx_data         => rx_data,
    rx_data_present => rx_data_present,
    rx_data_error   => rx_data_error);

i_fifo_rxclk_to_clk125MHz: fifo_rxclk_to_clk125MHz port map (
    rx_clk          => eth_rxck,
    rx_write        => rx_data_enable,           
    rx_data         => rx_data,
    rx_data_present => rx_data_present,
    rx_data_error   => rx_data_error,
           
    clk125Mhz       => clk125Mhz,
    empty           => input_empty,           
    read            => input_read,           
    data            => input_data,
    data_present    => input_data_present,
    data_error      => input_data_error);

i_main_design: main_design port map (
     clk125Mhz          => clk125Mhz,

     input_empty        => input_empty,           
     input_read         => input_read,           
     input_data         => input_data,
     input_data_present => input_data_present,
     input_data_error   => input_data_error,
     
     phy_ready          => phy_ready, 
     status             => leds,
           
     eth_txck           => eth_txck,
     eth_txctl          => eth_txctl,
     eth_txd            => eth_txd);
    ----------------------------------------
     -- Control reseting the PHY
     ----------------------------------------


end Behavioral;
