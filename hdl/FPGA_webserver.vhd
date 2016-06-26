----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: FPGA_webserver - Behavioral
--
-- Description: Top level of my HDL webserver 
-- 
------------------------------------------------------------------------------------
-- FPGA_Webserver from https://github.com/hamsternz/FPGA_Webserver
------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2015 Michael Alan Field <hamster@snap.net.nz>
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
------------------------------------------------------------------------------------


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
    constant our_ip      : std_logic_vector(31 downto 0) := x"0A_00_00_0A";       -- NOTE octets are reversed 
    constant our_netmask : std_logic_vector(31 downto 0) := x"00_FF_FF_FF";       -- NOTE octets are reversed 
    constant our_gateway : std_logic_vector(31 downto 0) := x"FE_00_00_0A";       -- NOTE octets are reversed

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

           -- data to be sent over UDP
           udp_tx_busy          : out std_logic := '1';
           udp_tx_valid         : in  std_logic := '0';
           udp_tx_data          : in  std_logic_vector(7 downto 0) := (others => '0');
           udp_tx_src_port      : in  std_logic_vector(15 downto 0) := (others => '0');
           udp_tx_dst_mac       : in  std_logic_vector(47 downto 0) := (others => '0');
           udp_tx_dst_ip        : in  std_logic_vector(31 downto 0) := (others => '0');
           udp_tx_dst_port      : in  std_logic_vector(15 downto 0) := (others => '0');

            -- data received over TCP/IP
           tcp_rx_data_valid    : out std_logic := '0';
           tcp_rx_data          : out std_logic_vector(7 downto 0) := (others => '0');
            
           tcp_rx_hdr_valid     : out std_logic := '0';
           tcp_rx_src_ip        : out std_logic_vector(31 downto 0) := (others => '0');
           tcp_rx_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
           tcp_rx_dst_port      : out std_logic_vector(15 downto 0) := (others => '0');    
           tcp_rx_seq_num       : out std_logic_vector(31 downto 0) := (others => '0');
           tcp_rx_ack_num       : out std_logic_vector(31 downto 0) := (others => '0');
           tcp_rx_window        : out std_logic_vector(15 downto 0) := (others => '0');
           tcp_rx_checksum      : out std_logic_vector(15 downto 0) := (others => '0');
           tcp_rx_flag_urg      : out std_logic := '0';
           tcp_rx_flag_ack      : out std_logic := '0';
           tcp_rx_flag_psh      : out std_logic := '0';
           tcp_rx_flag_rst      : out std_logic := '0';
           tcp_rx_flag_syn      : out std_logic := '0';
           tcp_rx_flag_fin      : out std_logic := '0';
           tcp_rx_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0');
           
           -- data to be sent over TCP/IP
           tcp_tx_busy          : out std_logic;
           
           tcp_tx_data_valid    : in  std_logic := '0';
           tcp_tx_data          : in  std_logic_vector(7 downto 0) := (others => '0');
            
           tcp_tx_hdr_valid     : in std_logic := '0';
           tcp_tx_src_port      : in std_logic_vector(15 downto 0) := (others => '0');
           tcp_tx_dst_ip        : in std_logic_vector(31 downto 0) := (others => '0');
           tcp_tx_dst_port      : in std_logic_vector(15 downto 0) := (others => '0');    
           tcp_tx_seq_num       : in std_logic_vector(31 downto 0) := (others => '0');
           tcp_tx_ack_num       : in std_logic_vector(31 downto 0) := (others => '0');
           tcp_tx_window        : in std_logic_vector(15 downto 0) := (others => '0');
           tcp_tx_checksum      : in std_logic_vector(15 downto 0) := (others => '0');
           tcp_tx_flag_urg      : in std_logic := '0';
           tcp_tx_flag_ack      : in std_logic := '0';
           tcp_tx_flag_psh      : in std_logic := '0';
           tcp_tx_flag_rst      : in std_logic := '0';
           tcp_tx_flag_syn      : in std_logic := '0';
           tcp_tx_flag_fin      : in std_logic := '0';
           tcp_tx_urgent_ptr    : in std_logic_vector(15 downto 0) := (others => '0');

                  
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

    component udp_test_source is
    Port ( 
        clk                  : in STD_LOGIC;
        -- data to be sent over UDP
        udp_tx_busy          : in  std_logic := '0';
        udp_tx_valid         : out std_logic := '0';
        udp_tx_data          : out std_logic_vector(7 downto 0)  := (others => '0');
        udp_tx_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
        udp_tx_dst_mac       : out std_logic_vector(47 downto 0) := (others => '0');
        udp_tx_dst_ip        : out std_logic_vector(31 downto 0) := (others => '0');
        udp_tx_dst_port      : out std_logic_vector(15 downto 0) := (others => '0'));
    end component;

    component udp_test_sink is
    Port ( 
        clk                 : in  STD_LOGIC;

       -- data received over UDP
       udp_rx_valid         : in  std_logic := '0';
       udp_rx_data          : in  std_logic_vector(7 downto 0) := (others => '0');
       udp_rx_src_ip        : in  std_logic_vector(31 downto 0) := (others => '0');
       udp_rx_src_port      : in  std_logic_vector(15 downto 0) := (others => '0');
       udp_rx_dst_broadcast : in  std_logic := '0';
       udp_rx_dst_port      : in  std_logic_vector(15 downto 0) := (others => '0');

       leds                 : out std_logic_vector(7 downto 0) := (others => '0'));
    end component;

    signal udp_tx_busy          : std_logic;
    signal udp_tx_valid         : std_logic;
    signal udp_tx_data          : std_logic_vector(7 downto 0);
    signal udp_tx_src_port      : std_logic_vector(15 downto 0);
    signal udp_tx_dst_mac       : std_logic_vector(47 downto 0);
    signal udp_tx_dst_ip        : std_logic_vector(31 downto 0);
    signal udp_tx_dst_port      : std_logic_vector(15 downto 0);

            -- data received over TCP/IP
    signal tcp_rx_data_valid    : std_logic := '0';
    signal tcp_rx_data          : std_logic_vector(7 downto 0) := (others => '0');
            
    signal tcp_rx_hdr_valid     : std_logic := '0';
    signal tcp_rx_src_ip        : std_logic_vector(31 downto 0) := (others => '0');
    signal tcp_rx_src_port      : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_rx_dst_port      : std_logic_vector(15 downto 0) := (others => '0');    
    signal tcp_rx_seq_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal tcp_rx_ack_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal tcp_rx_window        : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_rx_checksum      : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_rx_flag_urg      : std_logic := '0';
    signal tcp_rx_flag_ack      : std_logic := '0';
    signal tcp_rx_flag_psh      : std_logic := '0';
    signal tcp_rx_flag_rst      : std_logic := '0';
    signal tcp_rx_flag_syn      : std_logic := '0';
    signal tcp_rx_flag_fin      : std_logic := '0';
    signal tcp_rx_urgent_ptr    : std_logic_vector(15 downto 0) := (others => '0');
            
            -- data to be sent over TCP/IP
    signal tcp_tx_busy          : std_logic := '0';
    signal tcp_tx_data_valid    : std_logic := '0';
    signal tcp_tx_data          : std_logic_vector(7 downto 0) := (others => '0');
            
    signal tcp_tx_hdr_valid     : std_logic := '0';
    signal tcp_tx_src_port      : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_tx_dst_ip        : std_logic_vector(31 downto 0) := (others => '0');
    signal tcp_tx_dst_port      : std_logic_vector(15 downto 0) := (others => '0');    
    signal tcp_tx_seq_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal tcp_tx_ack_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal tcp_tx_window        : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_tx_checksum      : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_tx_flag_urg      : std_logic := '0';
    signal tcp_tx_flag_ack      : std_logic := '0';
    signal tcp_tx_flag_psh      : std_logic := '0';
    signal tcp_tx_flag_rst      : std_logic := '0';
    signal tcp_tx_flag_syn      : std_logic := '0';
    signal tcp_tx_flag_fin      : std_logic := '0';
    signal tcp_tx_urgent_ptr    : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_engine_status    : std_logic_vector(7 downto 0) := (others => '0');
    component tcp_engine is 
    port (  clk                : in  STD_LOGIC;

            status               : out std_logic_vector(7 downto 0) := (others => '0');
            -- data received over TCP/IP
            tcp_rx_data_valid    : in  std_logic := '0';
            tcp_rx_data          : in  std_logic_vector(7 downto 0) := (others => '0');
            
            tcp_rx_hdr_valid     : in  std_logic := '0';
            tcp_rx_src_ip        : in  std_logic_vector(31 downto 0) := (others => '0');
            tcp_rx_src_port      : in  std_logic_vector(15 downto 0) := (others => '0');
            tcp_rx_dst_broadcast : in  std_logic := '0';
            tcp_rx_dst_port      : in  std_logic_vector(15 downto 0) := (others => '0');    
            tcp_rx_seq_num       : in  std_logic_vector(31 downto 0) := (others => '0');
            tcp_rx_ack_num       : in  std_logic_vector(31 downto 0) := (others => '0');
            tcp_rx_window        : in  std_logic_vector(15 downto 0) := (others => '0');
            tcp_rx_flag_urg      : in  std_logic := '0';
            tcp_rx_flag_ack      : in  std_logic := '0';
            tcp_rx_flag_psh      : in  std_logic := '0';
            tcp_rx_flag_rst      : in  std_logic := '0';
            tcp_rx_flag_syn      : in  std_logic := '0';
            tcp_rx_flag_fin      : in  std_logic := '0';
            tcp_rx_urgent_ptr    : in  std_logic_vector(15 downto 0) := (others => '0');

  	        -- data to be sent over UDP
            tcp_tx_busy          : in  std_logic := '0';
            
            tcp_tx_data_valid    : out std_logic := '0';
            tcp_tx_data          : out std_logic_vector(7 downto 0) := (others => '0');
              
            tcp_tx_hdr_valid     : out std_logic := '0';
            tcp_tx_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
            tcp_tx_dst_ip        : out std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_dst_port      : out std_logic_vector(15 downto 0) := (others => '0');    
            tcp_tx_seq_num       : out std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_ack_num       : out std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_window        : out std_logic_vector(15 downto 0) := (others => '0');
            tcp_tx_flag_urg      : out std_logic := '0';
            tcp_tx_flag_ack      : out std_logic := '0';
            tcp_tx_flag_psh      : out std_logic := '0';
            tcp_tx_flag_rst      : out std_logic := '0';
            tcp_tx_flag_syn      : out std_logic := '0';
            tcp_tx_flag_fin      : out std_logic := '0';
            tcp_tx_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0'));
    end component;
    
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

    udp_tx_busy          => udp_tx_busy,
    udp_tx_valid         => udp_tx_valid,
    udp_tx_data          => udp_tx_data,
    udp_tx_src_port      => udp_tx_src_port,
    udp_tx_dst_mac       => udp_tx_dst_mac,
    udp_tx_dst_ip        => udp_tx_dst_ip,
    udp_tx_dst_port      => udp_tx_dst_port,
 
        -- data received over TCP/IP
    tcp_tx_busy          => tcp_tx_busy,
     
    tcp_rx_data_valid    => tcp_rx_data_valid,
    tcp_rx_data          => tcp_rx_data,
    
    tcp_rx_hdr_valid     => tcp_rx_hdr_valid,
    tcp_rx_src_ip        => tcp_rx_src_ip,
    tcp_rx_src_port      => tcp_rx_src_port,
    tcp_rx_dst_port      => tcp_rx_dst_port,
    tcp_rx_seq_num       => tcp_rx_seq_num,
    tcp_rx_ack_num       => tcp_rx_ack_num,
    tcp_rx_window        => tcp_rx_window,
    tcp_rx_checksum      => tcp_rx_checksum,
    tcp_rx_flag_urg      => tcp_rx_flag_urg, 
    tcp_rx_flag_ack      => tcp_rx_flag_ack,
    tcp_rx_flag_psh      => tcp_rx_flag_psh,
    tcp_rx_flag_rst      => tcp_rx_flag_rst,
    tcp_rx_flag_syn      => tcp_rx_flag_syn,
    tcp_rx_flag_fin      => tcp_rx_flag_fin,
    tcp_rx_urgent_ptr    => tcp_rx_urgent_ptr,
    
    -- data to be sent over TCP/IP
    tcp_tx_data_valid    => tcp_tx_data_valid,
    tcp_tx_data          => tcp_tx_data,
    
    tcp_tx_hdr_valid     => tcp_tx_hdr_valid, 
    tcp_tx_src_port      => tcp_tx_src_port,
    tcp_tx_dst_ip        => tcp_tx_dst_ip,
    tcp_tx_dst_port      => tcp_tx_dst_port,    
    tcp_tx_seq_num       => tcp_tx_seq_num,
    tcp_tx_ack_num       => tcp_tx_ack_num,
    tcp_tx_window        => tcp_tx_window,
    tcp_tx_checksum      => tcp_tx_checksum,
    tcp_tx_flag_urg      => tcp_tx_flag_urg,
    tcp_tx_flag_ack      => tcp_tx_flag_ack,
    tcp_tx_flag_psh      => tcp_tx_flag_psh,
    tcp_tx_flag_rst      => tcp_tx_flag_rst,
    tcp_tx_flag_syn      => tcp_tx_flag_syn,
    tcp_tx_flag_fin      => tcp_tx_flag_fin,
    tcp_tx_urgent_ptr    => tcp_tx_urgent_ptr,

     eth_txck           => eth_txck,
     eth_txctl          => eth_txctl,
     eth_txd            => eth_txd);

    --------------------------------
    -- Modules to check UDP TX & RX 
    --------------------------------
i_udp_test_source: udp_test_source port map (
        clk => clk125MHz,
        -- Data to be sent over UDP
        udp_tx_busy          => udp_tx_busy,
        udp_tx_valid         => udp_tx_valid,
        udp_tx_data          => udp_tx_data,
        udp_tx_src_port      => udp_tx_src_port,
        udp_tx_dst_mac       => udp_tx_dst_mac,
        udp_tx_dst_ip        => udp_tx_dst_ip,
        udp_tx_dst_port      => udp_tx_dst_port);
     
i_udp_test_sink: udp_test_sink port map (
        clk => clk125MHz,
        -- data received over UDP
        udp_rx_valid         => udp_rx_valid,
        udp_rx_data          => udp_rx_data,
        udp_rx_src_ip        => udp_rx_src_ip,
        udp_rx_src_port      => udp_rx_src_port,
        udp_rx_dst_broadcast => udp_rx_dst_broadcast,
        udp_rx_dst_port      => udp_rx_dst_port,
        -- Where to show the data        
        leds                 => open);

process(clk125Mhz)
    begin
        if tcp_rx_hdr_valid = '1' then
            leds <= tcp_engine_status;
        end if;
    end process;

i_tcp_engine: tcp_engine port map ( 
        clk => clk125MHz,
            -- data received over TCP/IP
        status => tcp_engine_status,
        tcp_rx_data_valid    => tcp_rx_data_valid,
        tcp_rx_data          => tcp_rx_data,
        
        tcp_rx_hdr_valid     => tcp_rx_hdr_valid,
        tcp_rx_src_ip        => tcp_rx_src_ip,
        tcp_rx_src_port      => tcp_rx_src_port,
        tcp_rx_dst_port      => tcp_rx_dst_port,
        tcp_rx_seq_num       => tcp_rx_seq_num,
        tcp_rx_ack_num       => tcp_rx_ack_num,
        tcp_rx_window        => tcp_rx_window,
        tcp_rx_flag_urg      => tcp_rx_flag_urg, 
        tcp_rx_flag_ack      => tcp_rx_flag_ack,
        tcp_rx_flag_psh      => tcp_rx_flag_psh,
        tcp_rx_flag_rst      => tcp_rx_flag_rst,
        tcp_rx_flag_syn      => tcp_rx_flag_syn,
        tcp_rx_flag_fin      => tcp_rx_flag_fin,
        tcp_rx_urgent_ptr    => tcp_rx_urgent_ptr,
        
        -- data to be sent over TCP/IP
        tcp_tx_busy          => tcp_tx_busy,

        tcp_tx_data_valid    => tcp_tx_data_valid,
        tcp_tx_data          => tcp_tx_data,
        
        tcp_tx_hdr_valid     => tcp_tx_hdr_valid, 
        tcp_tx_src_port      => tcp_tx_src_port,
        tcp_tx_dst_ip        => tcp_tx_dst_ip,
        tcp_tx_dst_port      => tcp_tx_dst_port,    
        tcp_tx_seq_num       => tcp_tx_seq_num,
        tcp_tx_ack_num       => tcp_tx_ack_num,
        tcp_tx_window        => tcp_tx_window,
        tcp_tx_flag_urg      => tcp_tx_flag_urg,
        tcp_tx_flag_ack      => tcp_tx_flag_ack,
        tcp_tx_flag_psh      => tcp_tx_flag_psh,
        tcp_tx_flag_rst      => tcp_tx_flag_rst,
        tcp_tx_flag_syn      => tcp_tx_flag_syn,
        tcp_tx_flag_fin      => tcp_tx_flag_fin,
        tcp_tx_urgent_ptr    => tcp_tx_urgent_ptr);

end Behavioral;
