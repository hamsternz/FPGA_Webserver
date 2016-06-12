----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.06.2016 21:51:44
-- Design Name: 
-- Module Name: udp_rx_packet - Behavioral
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

entity udp_rx_packet is
generic (
    our_ip        : std_logic_vector(31 downto 0) := (others => '0');
    our_broadcast : std_logic_vector(31 downto 0) := (others => '0');
    our_mac       : std_logic_vector(47 downto 0) := (others => '0'));
port(
    clk                  : in  STD_LOGIC;

    packet_in_valid    : in  STD_LOGIC;
    packet_in_data     : in  STD_LOGIC_VECTOR (7 downto 0);

    udp_rx_valid         : out std_logic := '0';
    udp_rx_data          : out std_logic_vector(7 downto 0) := (others => '0');
    udp_rx_src_ip        : out std_logic_vector(31 downto 0) := (others => '0');
    udp_rx_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
    udp_rx_dst_broadcast : out std_logic := '0';
    udp_rx_dst_port      : out std_logic_vector(15 downto 0) := (others => '0'));
end udp_rx_packet;

architecture Behavioral of udp_rx_packet is

    component ethernet_extract_header
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0'));
    Port ( clk               : in  STD_LOGIC;
           filter_ether_type : in STD_LOGIC_VECTOR (15 downto 0);
           data_valid_in     : in  STD_LOGIC;
           data_in           : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out    : out STD_LOGIC := '0';
           data_out          : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    
           ether_dst_mac  : out STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
           ether_src_mac  : out STD_LOGIC_VECTOR (47 downto 0) := (others => '0'));
    end component;
    signal ether_extracted_data_valid : STD_LOGIC := '0';
    signal ether_extracted_data       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal ether_is_ipv4             : STD_LOGIC := '0'; 
    signal ether_src_mac             : STD_LOGIC_VECTOR (47 downto 0) := (others => '0');

    component ip_extract_header 
    generic (
        our_ip        : std_logic_vector(31 downto 0) := (others => '0');
        our_broadcast : std_logic_vector(31 downto 0) := (others => '0'));
    Port ( clk                : in  STD_LOGIC;
           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC;
           data_out           : out STD_LOGIC_VECTOR (7 downto 0);

           filter_protocol    : in  STD_LOGIC_VECTOR (7 downto 0);
           
           ip_version         : out STD_LOGIC_VECTOR (3 downto 0);
           ip_type_of_service : out STD_LOGIC_VECTOR (7 downto 0);
           ip_length          : out STD_LOGIC_VECTOR (15 downto 0);
           ip_identification  : out STD_LOGIC_VECTOR (15 downto 0);
           ip_flags           : out STD_LOGIC_VECTOR (2 downto 0);
           ip_fragment_offset : out STD_LOGIC_VECTOR (12 downto 0);
           ip_ttl             : out STD_LOGIC_VECTOR (7 downto 0);
           ip_checksum        : out STD_LOGIC_VECTOR (15 downto 0);
           ip_src_ip          : out STD_LOGIC_VECTOR (31 downto 0);
           ip_dest_ip         : out STD_LOGIC_VECTOR (31 downto 0);
           ip_dest_broadcast  : out STD_LOGIC);           
    end component;
    signal ip_extracted_data_valid : STD_LOGIC := '0';
    signal ip_extracted_data       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    signal ip_version         : STD_LOGIC_VECTOR (3 downto 0)  := (others => '0');
    signal ip_type_of_service : STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');
    signal ip_length          : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal ip_identification  : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal ip_flags           : STD_LOGIC_VECTOR (2 downto 0)  := (others => '0');
    signal ip_fragment_offset : STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
    signal ip_ttl             : STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');
    signal ip_checksum        : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal ip_src_ip          : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal ip_dest_ip         : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');           
    signal ip_dest_broadcast  : STD_LOGIC := '0';

    component udp_extract_udp_header 
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC;
           data_out       : out STD_LOGIC_VECTOR (7 downto 0);
           
           udp_src_port   : out STD_LOGIC_VECTOR (15 downto 0);
           udp_dst_port   : out STD_LOGIC_VECTOR (15 downto 0);
           udp_length     : out STD_LOGIC_VECTOR (15 downto 0);
           udp_checksum   : out STD_LOGIC_VECTOR (15 downto 0));           
    end component;
    signal udp_extracted_data_valid : STD_LOGIC := '0';
    signal udp_extracted_data       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    signal udp_checksum  : STD_LOGIC_VECTOR (15 downto 0);
    signal udp_src_port  : STD_LOGIC_VECTOR (15 downto 0);           
    signal udp_dst_port  : STD_LOGIC_VECTOR (15 downto 0);           
    signal udp_length    : STD_LOGIC_VECTOR (15 downto 0);           

begin
i_ethernet_extract_header: ethernet_extract_header generic map (
        our_mac => our_mac)
    port map (
        clk               => clk,
        data_valid_in     => packet_in_valid,
        data_in           => packet_in_data,
        data_valid_out    => ether_extracted_data_valid,
        data_out          => ether_extracted_data,
       
        filter_ether_type => x"0800",
        ether_dst_mac     => open, 
        ether_src_mac     => ether_src_mac);

    
i_ip_extract_header: ip_extract_header generic map (
        our_ip        => our_ip,
        our_broadcast => our_broadcast)
    port map ( 
        clk            => clk,
        data_valid_in  => ether_extracted_data_valid,
        data_in        => ether_extracted_data,
        data_valid_out => ip_extracted_data_valid,
        data_out       => ip_extracted_data,
        filter_protocol => x"11",
        
        ip_version         => ip_version,
        ip_type_of_service => ip_type_of_service,
        ip_length          => ip_length,
        ip_identification  => ip_identification,
        ip_flags           => ip_flags,
        ip_fragment_offset => ip_fragment_offset,
        ip_ttl             => ip_ttl,
        ip_checksum        => ip_checksum,
        ip_src_ip          => ip_src_ip,
        ip_dest_ip         => ip_dest_ip,
        ip_dest_broadcast  => ip_dest_broadcast);           

i_udp_extract_udp_header : udp_extract_udp_header port map ( 
        clk            => clk,
 
        data_valid_in  => ip_extracted_data_valid,
        data_in        => ip_extracted_data,
        data_valid_out => udp_extracted_data_valid,
        data_out       => udp_extracted_data,
           
        udp_src_port   => udp_src_port,
        udp_dst_port   => udp_dst_port,
        udp_length     => udp_length,
        udp_checksum   => udp_checksum);           

    ----------------------------------------------
    -- Pass the received data stream to the  
    -- rest of the FPGA desig.
    ----------------------------------------------
    udp_rx_valid         <= udp_extracted_data_valid;
    udp_rx_data          <= udp_extracted_data;
    udp_rx_src_ip        <= ip_src_ip;
    udp_rx_src_port      <= udp_src_port;
    udp_rx_dst_broadcast <= ip_dest_broadcast;
    udp_rx_dst_port      <= udp_dst_port;

end Behavioral;
