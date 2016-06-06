----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Create Date: 05.06.2016 22:31:14
-- Module Name: udp_tx_packet - Behavioral
-- 
-- Dependencies: Contruct and send out UDP packets 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity udp_tx_packet is
    generic (
        our_ip      : std_logic_vector(31 downto 0) := (others => '0');
        our_mac     : std_logic_vector(47 downto 0) := (others => '0'));
    port(  clk               : in  STD_LOGIC;
        udp_tx_busy          : out std_logic := '0';
        udp_tx_valid         : in  std_logic;
        udp_tx_data          : in  std_logic_vector(7 downto 0);
        udp_tx_src_port      : in  std_logic_vector(15 downto 0);
        udp_tx_dst_mac       : in  std_logic_vector(47 downto 0);
        udp_tx_dst_ip        : in  std_logic_vector(31 downto 0);
        udp_tx_dst_port      : in  std_logic_vector(15 downto 0);

        packet_out_request : out std_logic := '0';
        packet_out_granted : in  std_logic := '0';
        packet_out_valid   : out std_logic := '0';         
        packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
end udp_tx_packet;

architecture Behavioral of udp_tx_packet is

    signal udp_tx_length   : std_logic_vector(15 downto 0) := (others => '0');
    signal udp_tx_checksum : std_logic_vector(15 downto 0) := (others => '0');

    signal pre_udp_valid   : STD_LOGIC := '0';
    signal pre_udp_data    : STD_LOGIC_VECTOR (7 downto 0);

    component udp_add_udp_header is
    Port ( clk             : in  STD_LOGIC;
           data_valid_in   : in  STD_LOGIC;
           data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out  : out STD_LOGIC := '0';
           data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

           udp_length   : in  std_logic_vector(15 downto 0);
           udp_checksum : in  std_logic_vector(15 downto 0);
           udp_src_port : in  std_logic_vector(15 downto 0);
           udp_dst_port : in  std_logic_vector(15 downto 0));
    end component;

    signal pre_ip_valid  : STD_LOGIC := '0';
    signal pre_ip_data   : STD_LOGIC_VECTOR (7 downto 0);
    signal ip_length     : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_checksum   : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');

    component udp_add_ip_header is
    Port ( clk                : in  STD_LOGIC;

           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC := '0';
           data_out           : out STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');

           ip_length          : in  STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_checksum        : in  STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_src_ip          : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dest_ip         : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0'));           
    end component;

    signal pre_header_valid  : STD_LOGIC := '0';
    signal pre_header_data   : STD_LOGIC_VECTOR (7 downto 0);

    component udp_add_ethernet_header is
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC := '0';
           data_out       : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
         
           ether_type     : in STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 
           ether_dst_mac  : in STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
           ether_src_mac  : in STD_LOGIC_VECTOR (47 downto 0) := (others => '0'));
    end component;

    signal complete_valid    : STD_LOGIC  := '0';
    signal complete_data     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    
    component udp_commit_buffer
    Port ( clk                : in  STD_LOGIC;
           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           packet_out_request : out std_logic := '0';
           packet_out_granted : in  std_logic := '0';
           packet_out_valid   : out std_logic := '0';         
           packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
    end component;

begin
    pre_udp_valid <= udp_tx_valid;
    pre_udp_data  <= udp_tx_data;
    
i_udp_add_udp_header: udp_add_udp_header port map (
    clk            => clk,
    data_valid_in  => pre_udp_valid,
    data_in        => pre_udp_data,
    data_valid_out => pre_ip_valid,
    data_out       => pre_ip_data,

    udp_length   => udp_tx_length,
    udp_checksum => udp_tx_checksum,
    udp_src_port => udp_tx_src_port,
    udp_dst_port => udp_tx_dst_port);

i_udp_add_ip_header: udp_add_ip_header port map (
        clk            => clk,
        data_valid_in  => pre_ip_valid,
        data_in        => pre_ip_data,
        data_valid_out => pre_header_valid,
        data_out       => pre_header_data,
    
        ip_length      => ip_length,
        ip_checksum    => ip_checksum,
        ip_src_ip      => our_ip,
        ip_dest_ip     => udp_tx_dst_ip);           

i_udp_add_ethernet_header: udp_add_ethernet_header port map (
    clk            => clk,
    data_valid_in  => pre_header_valid,
    data_in        => pre_header_data,
    data_valid_out => complete_valid,
    data_out       => complete_data,         
    ether_type     => x"0800",
    ether_dst_mac  => udp_tx_dst_mac,
    ether_src_mac  => our_mac);

i_udp_commit_buffer: udp_commit_buffer port map (
        clk                => clk,
        data_valid_in      => complete_valid,
        data_in            => complete_data,
        packet_out_request => packet_out_request,
        packet_out_granted => packet_out_granted,
        packet_out_valid   => packet_out_valid,         
        packet_out_data    => packet_out_data);

end Behavioral;