----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.05.2016 21:14:53
-- Design Name: 
-- Module Name: tb_main_design - Behavioral
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
use IEEE.NUMERIC_STD.ALL;


entity tb_main_design_tcp is
end tb_main_design_tcp;

architecture Behavioral of tb_main_design_tcp is
    signal clk125Mhz          : STD_LOGIC := '0';
    signal clk125Mhz90        : STD_LOGIC := '0';
    signal phy_ready          : STD_LOGIC := '1';
    signal status             : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    
    signal input_empty        : STD_LOGIC := '0';           
    signal input_read         : STD_LOGIC := '0';           
    signal input_data         : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal input_data_present : STD_LOGIC := '0';
    signal input_data_error   : STD_LOGIC := '0';

    component main_design is
    generic (
        our_mac       : std_logic_vector(47 downto 0) := (others => '0');
        our_netmask   : std_logic_vector(31 downto 0) := (others => '0');
        our_ip        : std_logic_vector(31 downto 0) := (others => '0'));
    Port ( 
           clk125Mhz          : in  STD_LOGIC;
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
           tcp_tx_busy          : out std_logic := '0';
    
           tcp_tx_data_valid    : in  std_logic := '0';
           tcp_tx_data          : in  std_logic_vector(7 downto 0) := (others => '0');
           
           tcp_tx_hdr_valid     : in std_logic := '0';
           tcp_tx_src_port      : in std_logic_vector(15 downto 0) := (others => '0');
           tcp_tx_dst_mac       : in std_logic_vector(47 downto 0) := (others => '0');
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

    signal udp_tx_busy          : std_logic := '0';
    signal udp_tx_valid         : std_logic := '0';
    signal udp_tx_data          : std_logic_vector(7 downto 0) := (others => '0');
    signal udp_tx_src_port      : std_logic_vector(15 downto 0) := (others => '0');
    signal udp_tx_dst_mac       : std_logic_vector(47 downto 0) := (others => '0');
    signal udp_tx_dst_ip        : std_logic_vector(31 downto 0) := (others => '0');
    signal udp_tx_dst_port      : std_logic_vector(15 downto 0) := (others => '0');
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
    
    signal eth_txck           : std_logic := '0';
    signal eth_txctl          : std_logic := '0';
    signal eth_txd            : std_logic_vector(3 downto 0) := (others => '0');

    signal count  : integer := 999;
    signal count2 : integer := 180;
    
    signal arp_src_hw      : std_logic_vector(47 downto 0) := x"A0B3CC4CF9EF";
    signal arp_src_ip      : std_logic_vector(31 downto 0) := x"0A000001";
    signal arp_tgt_hw      : std_logic_vector(47 downto 0) := x"000000000000";
    signal arp_tgt_ip      : std_logic_vector(31 downto 0) := x"0A00000A";

    constant our_mac     : std_logic_vector(47 downto 0) := x"AB_89_67_45_23_02"; -- NOTE this is 02:23:45:67:89:AB
    constant our_ip      : std_logic_vector(31 downto 0) := x"0A_00_00_0A";
    constant our_netmask : std_logic_vector(31 downto 0) := x"00_FF_FF_FF";

    component tcp_engine is 
        port (  clk                : in  STD_LOGIC;
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
    
                  -- data to be sent over TP
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

process
    begin
        clk125Mhz <= '1';
        wait for 2 ns;
        clk125Mhz90 <= '1';
        wait for 2 ns;
        clk125Mhz <= '0';
        wait for 2 ns;
        clk125Mhz90 <= '0';
        wait for 2 ns;
    end process;

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
       status             => status,
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

i_tcp_engine: tcp_engine port map ( 
        clk => clk125MHz,
            -- data received over TCP/IP
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

process(clk125MHz)
    begin
        if rising_edge(clk125MHz) then
            if count < 78 then 
                input_empty <= '0';
            else
                input_empty <= '1';
            end if;

            if count2 = 2000 then
                count <= 0;
                count2 <= 0;
            else
                count2 <= count2+1;
            end if;

            if input_read = '1' then
                if count = 79 then
                    count <= 0;
                else
                    count <= count + 1;
                end if;
                
                case count is
                    when      0 => input_data <= x"55"; input_data_present <= '1';
                    when      1 => input_data <= x"55"; 
                    when      2 => input_data <= x"55"; 
                    when      3 => input_data <= x"55"; 
                    when      4 => input_data <= x"55"; 
                    when      5 => input_data <= x"55";
                    when      6 => input_data <= x"55";
                    when      7 => input_data <= x"D5";
                    -----------------------------
                    -- Ethernet Header 
                    -----------------------------
                    -- Destination MAC address
                    when      8 => input_data <= x"02";
                    when      9 => input_data <= x"23";
                    when     10 => input_data <= x"45";
                    when     11 => input_data <= x"67";
                    when     12 => input_data <= x"89";
                    when     13 => input_data <= x"ab";
                   -- Source MAC address
                    when     14 => input_data <= x"A0";
                    when     15 => input_data <= x"B3";
                --
                    when     16 => input_data <= x"CC";
                    when     17 => input_data <= x"4C";
                    when     18 => input_data <= x"F9";
                    when     19 => input_data <= x"EF";
                    -- Ether Type 08:06  << ARP!
                    when 20 => input_data <= x"08"; 
                    when 21 => input_data <= x"00";
                    ------------------------ 
                    -- TCP packet
                    ------------------------
                    -- IP Header 
                    when 22 => input_data <= x"45";
                    when 23 => input_data <= x"00";
                --  
                    when 24 => input_data <= x"00";
                    when 25 => input_data <= x"34";
                    when 26 => input_data <= x"23";
                    when 27 => input_data <= x"93";
                    when 28 => input_data <= x"40";
                    when 29 => input_data <= x"00"; 
                    when 30 => input_data <= x"80";
                    when 31 => input_data <= x"06";
                --    
                    when 32 => input_data <= x"00";
                    when 33 => input_data <= x"00";
                    when 34 => input_data <= x"0a";
                    when 35 => input_data <= x"00";
                    when 36 => input_data <= x"00";
                    when 37 => input_data <= x"01";
                    when 38 => input_data <= x"0a";
                    when 39 => input_data <= x"00";
                 --
                    when 40 => input_data <= x"00";                   
                    when 41 => input_data <= x"0a";
                    -- TCP Header                     
                    when 42 => input_data <= x"c5";
                    when 43 => input_data <= x"81";
                    when 44 => input_data <= x"00";
                    when 45 => input_data <= x"16";
                    when 46 => input_data <= x"6f";
                    when 47 => input_data <= x"22";
                --
                    when 48 => input_data <= x"be";
                    when 49 => input_data <= x"2c";
                    when 50 => input_data <= x"00";
                    when 51 => input_data <= x"00";
                    when 52 => input_data <= x"00";
                    when 53 => input_data <= x"00";
                    when 54 => input_data <= x"80";
                    when 55 => input_data <= x"02";

                    when 56 => input_data <= x"20";
                    when 57 => input_data <= x"00";
                    when 58 => input_data <= x"48";
                    when 59 => input_data <= x"1F";
                    when 60 => input_data <= x"00";
                    when 61 => input_data <= x"00";
                    when 62 => input_data <= x"02";
                    when 63 => input_data <= x"04";
                    
                    when 64 => input_data <= x"05";
                    when 65 => input_data <= x"b4";
                    when 66 => input_data <= x"01";
                    when 67 => input_data <= x"03";
                    when 68 => input_data <= x"03";
                    when 69 => input_data <= x"08";
                    when 70 => input_data <= x"01";
                    when 71 => input_data <= x"01";

                    when 72 => input_data <= x"04";
                    when 73 => input_data <= x"02";
                    --- FCS
                    when 74 => input_data <= x"01";
                    when 75 => input_data <= x"01";
                    when 76 => input_data <= x"04";
                    when 77 => input_data <= x"02";
                    
                    when 78 => input_data <= x"DD"; input_data_present <= '0'; 
                    when others => input_data <= x"DD"; input_data_present <= '0';
                end case;
                count2 <= 0;
            end if;

        end if;
    end process;
end Behavioral;
