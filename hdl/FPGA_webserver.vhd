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
end FPGA_webserver;

architecture Behavioral of FPGA_webserver is
    constant our_mac     : std_logic_vector(47 downto 0) := x"AB_89_67_45_23_02"; -- NOTE this is 02:23:45:67:89:AB
    constant our_ip      : std_logic_vector(31 downto 0) := x"0A_00_00_0A";
    constant our_netmask : std_logic_vector(31 downto 0) := x"00_FF_FF_FF";
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
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0');
        our_netmask : std_logic_vector(31 downto 0) := (others => '0');
        our_ip      : std_logic_vector(31 downto 0) := (others => '0'));
    Port ( clk125Mhz          : in  STD_LOGIC;
           clk125Mhz90        : in  STD_LOGIC;
           input_empty        : in  STD_LOGIC;           
           input_read         : out STD_LOGIC;           
           input_data         : in  STD_LOGIC_VECTOR (7 downto 0);
           input_data_present : in  STD_LOGIC;
           input_data_error   : in  STD_LOGIC;

           phy_ready          : in  STD_LOGIC;
           status             : out STD_LOGIC_VECTOR (3 downto 0);

           -- data received over UDP
           udp_rx_valid         : out std_logic := '0';
           udp_rx_data          : out std_logic_vector(7 downto 0) := (others => '0');
           udp_rx_src_ip        : out std_logic_vector(31 downto 0) := (others => '0');
           udp_rx_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
           udp_rx_dst_broadcast : out std_logic := '0';
           udp_rx_dst_port      : out std_logic_vector(15 downto 0) := (others => '0');
                  
           eth_txck           : out std_logic := '0';
           eth_txctl          : out std_logic := '0';
           eth_txd            : out std_logic_vector(3 downto 0) := (others => '0'));
    end component;

    signal udp_rx_valid         : std_logic := '0';
    signal udp_rx_data          : std_logic_vector(7 downto 0) := (others => '0');
    signal udp_rx_src_ip        : std_logic_vector(31 downto 0) := (others => '0');
    signal udp_rx_src_port      : std_logic_vector(15 downto 0) := (others => '0');
    signal udp_rx_dst_broadcast : std_logic := '0';
    signal udp_rx_dst_port      : std_logic_vector(15 downto 0) := (others => '0');
    signal udp_rx_valid_last    : std_logic := '0';
begin

i_clocking: clocking port map (
    clk100MHz   => clk100MHz,
    clk125MHz   => clk125MHz,
    clk125MHz90 => clk125MHz90); 

    ----------------------------------------
    -- Control reseting the PHY
    ----------------------------------------
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

i_main_design: main_design generic map (
        our_mac     => our_mac,
        our_netmask => our_netmask, 
        our_ip      => our_ip
     ) port map (
     clk125Mhz          => clk125Mhz,
     clk125Mhz90        => clk125Mhz90,

     input_empty        => input_empty,           
     input_read         => input_read,           
     input_data         => input_data,
     input_data_present => input_data_present,
     input_data_error   => input_data_error,
     
     phy_ready          => phy_ready, 
     status             => open,

    -- data received over UDP
    udp_rx_valid         => udp_rx_valid,
    udp_rx_data          => udp_rx_data,
    udp_rx_src_ip        => udp_rx_src_ip,
    udp_rx_src_port      => udp_rx_src_port,
    udp_rx_dst_broadcast => udp_rx_dst_broadcast,
    udp_rx_dst_port      => udp_rx_dst_port,

              
     eth_txck           => eth_txck,
     eth_txctl          => eth_txctl,
     eth_txd            => eth_txd);
     
process(clk125Mhz) 
    begin
        if rising_edge(clk125Mhz) then
            -- assign any data on UDP port 5140 (0x1414) to the LEDs
            if udp_rx_valid_last = '0'  and udp_rx_valid = '1' and udp_rx_dst_port = x"1414" then  
                leds <= udp_rx_data;
            end if;
            udp_rx_valid_last <= udp_rx_valid;
        end if;
    end process;
end Behavioral;
