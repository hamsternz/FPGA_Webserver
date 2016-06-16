----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snpa.net.nz> 
-- 
-- Module Name: udp_rx_packet - Behavioral
--
-- Description: For receiving UDP packets 
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
--
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tcp_rx_packet is
    generic (
        our_ip        : std_logic_vector(31 downto 0) := (others => '0');
        our_broadcast : std_logic_vector(31 downto 0) := (others => '0');
        our_mac       : std_logic_vector(47 downto 0) := (others => '0'));
    port(
        clk                  : in  STD_LOGIC;
    
        packet_in_valid    : in  STD_LOGIC;
        packet_in_data     : in  STD_LOGIC_VECTOR (7 downto 0);
    
        tcp_rx_data_valid    : out std_logic := '0';
        tcp_rx_data          : out std_logic_vector(7 downto 0) := (others => '0');
        
        tcp_rx_hdr_valid     : out std_logic := '0';
        tcp_rx_src_ip        : out std_logic_vector(31 downto 0) := (others => '0');
        tcp_rx_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
        tcp_rx_dst_broadcast : out std_logic := '0';
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
        tcp_rx_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0')
        );
end tcp_rx_packet;

architecture Behavioral of tcp_rx_packet is

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

    component tcp_extract_header 
    port(
        clk            : in std_logic;
        
        data_in        : in std_logic_vector(7 downto 0) := (others => '0');
        data_valid_in  : in std_logic := '0';
        
        data_out       : out std_logic_vector(7 downto 0) := (others => '0');
        data_valid_out : out std_logic := '0';
        
        tcp_hdr_valid  : out std_logic := '0';
        tcp_src_port   : out std_logic_vector(15 downto 0) := (others => '0');
        tcp_dst_port   : out std_logic_vector(15 downto 0) := (others => '0');
        tcp_seq_num    : out std_logic_vector(31 downto 0) := (others => '0');
        tcp_ack_num    : out std_logic_vector(31 downto 0) := (others => '0');
        tcp_window     : out std_logic_vector(15 downto 0) := (others => '0');
        tcp_flag_urg   : out std_logic := '0';
        tcp_flag_ack   : out std_logic := '0';
        tcp_flag_psh   : out std_logic := '0';
        tcp_flag_rst   : out std_logic := '0';
        tcp_flag_syn   : out std_logic := '0';
        tcp_flag_fin   : out std_logic := '0';
        tcp_checksum   : out std_logic_vector(15 downto 0) := (others => '0');
        tcp_urgent_ptr : out std_logic_vector(15 downto 0) := (others => '0')); 
    end component;
    signal tcp_extracted_data_valid : STD_LOGIC := '0';
    signal tcp_extracted_data       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    signal tcp_hdr_valid  : std_logic := '0';
    signal tcp_src_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_dst_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_seq_num    : std_logic_vector(31 downto 0) := (others => '0');
    signal tcp_ack_num    : std_logic_vector(31 downto 0) := (others => '0');
    signal tcp_window     : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_flag_urg   : std_logic := '0';
    signal tcp_flag_ack   : std_logic := '0';
    signal tcp_flag_psh   : std_logic := '0';
    signal tcp_flag_rst   : std_logic := '0';
    signal tcp_flag_syn   : std_logic := '0';
    signal tcp_flag_fin   : std_logic := '0';
    signal tcp_checksum   : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_urgent_ptr : std_logic_vector(15 downto 0) := (others => '0'); 
               
    COMPONENT ila_0
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT  ;

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
        filter_protocol => x"06",
        
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

i_ila_0: ila_0 port map (
    clk       => clk,
    probe0(0) => ip_extracted_data_valid, 
    probe1    => ip_extracted_data,
    probe2(0) => ip_extracted_data_valid, 
    probe3(0) => tcp_hdr_valid,
    probe4(0) => tcp_extracted_data_valid,
    probe5    => tcp_extracted_data);

i_tcp_extract_header: tcp_extract_header port map ( 
        clk            => clk,
 
        data_valid_in  => ip_extracted_data_valid,
        data_in        => ip_extracted_data,
        data_valid_out => tcp_extracted_data_valid,
        data_out       => tcp_extracted_data,
           
        tcp_hdr_valid  => tcp_hdr_valid,
        tcp_src_port   => tcp_src_port,
        tcp_dst_port   => tcp_dst_port,
        tcp_seq_num    => tcp_seq_num,
        tcp_ack_num    => tcp_ack_num,
        tcp_window     => tcp_window,
        tcp_flag_urg   => tcp_flag_urg,
        tcp_flag_ack   => tcp_flag_ack, 
        tcp_flag_psh   => tcp_flag_psh,
        tcp_flag_rst   => tcp_flag_rst,
        tcp_flag_syn   => tcp_flag_syn,
        tcp_flag_fin   => tcp_flag_fin,
        tcp_checksum   => tcp_checksum,
        tcp_urgent_ptr => tcp_urgent_ptr); 

    ----------------------------------------------
    -- Pass the received data stream to the  
    -- rest of the FPGA desig.
    ----------------------------------------------
    tcp_rx_data_valid    <= tcp_extracted_data_valid;
    tcp_rx_data          <= tcp_extracted_data;

    tcp_rx_src_ip        <= ip_src_ip;
    tcp_rx_dst_broadcast <= ip_dest_broadcast;

    tcp_rx_hdr_valid  <= tcp_hdr_valid;
    tcp_rx_src_port   <= tcp_src_port;
    tcp_rx_dst_port   <= tcp_dst_port;
    tcp_rx_seq_num    <= tcp_seq_num;
    tcp_rx_ack_num    <= tcp_ack_num;
    tcp_rx_window     <= tcp_window;
    tcp_rx_flag_urg   <= tcp_flag_urg;
    tcp_rx_flag_ack   <= tcp_flag_ack; 
    tcp_rx_flag_psh   <= tcp_flag_psh;
    tcp_rx_flag_rst   <= tcp_flag_rst;
    tcp_rx_flag_syn   <= tcp_flag_syn;
    tcp_rx_flag_fin   <= tcp_flag_fin;
    tcp_rx_checksum   <= tcp_checksum;
    tcp_rx_urgent_ptr <= tcp_urgent_ptr;
end Behavioral;
