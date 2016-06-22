----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Create Date: 05.06.2016 22:31:14
-- Module Name: tcp_tx_packet - Behavioral
-- 
-- Description: Construct and send out TCP packets 
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
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tcp_tx_packet is
    generic (
        our_ip      : std_logic_vector(31 downto 0) := (others => '0');
        our_mac     : std_logic_vector(47 downto 0) := (others => '0'));
    port(
            clk                  : in  STD_LOGIC;
            tcp_tx_busy          : out std_logic;

            tcp_tx_data_valid    : in  std_logic := '0';
            tcp_tx_data          : in  std_logic_vector(7 downto 0) := (others => '0');
            
            tcp_tx_hdr_valid     : in std_logic := '0';
            tcp_tx_dst_mac       : in std_logic_vector(47 downto 0) := (others => '0');
            tcp_tx_dst_ip        : in std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_src_port      : in std_logic_vector(15 downto 0) := (others => '0');
            tcp_tx_dst_port      : in std_logic_vector(15 downto 0) := (others => '0');    
            tcp_tx_seq_num       : in std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_ack_num       : in std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_window        : in std_logic_vector(15 downto 0) := (others => '0');
            tcp_tx_flag_urg      : in std_logic := '0';
            tcp_tx_flag_ack      : in std_logic := '0';
            tcp_tx_flag_psh      : in std_logic := '0';
            tcp_tx_flag_rst      : in std_logic := '0';
            tcp_tx_flag_syn      : in std_logic := '0';
            tcp_tx_flag_fin      : in std_logic := '0';
            tcp_tx_urgent_ptr    : in std_logic_vector(15 downto 0) := (others => '0');
    
            packet_out_request : out std_logic := '0';
            packet_out_granted : in  std_logic := '0';
            packet_out_valid   : out std_logic := '0';         
            packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
end tcp_tx_packet;

architecture Behavioral of tcp_tx_packet is
    signal busy_countdown    : unsigned(7 downto 0) := (others => '0');
    -- For holding the destination and port details on the first data transfer
    signal tcp_tx_hdr_valid_last : STD_LOGIC := '0';
    signal tx_src_port       : std_logic_vector(15 downto 0) := (others => '0');
    signal tx_dst_mac        : std_logic_vector(47 downto 0) := (others => '0');
    signal tx_dst_ip         : std_logic_vector(31 downto 0) := (others => '0');
    signal tx_dst_port       : std_logic_vector(15 downto 0) := (others => '0');

    signal tcp_tx_length   : std_logic_vector(15 downto 0) := (others => '0');
    signal tcp_tx_checksum : std_logic_vector(15 downto 0) := (others => '0');

    signal pre_tcp_valid   : STD_LOGIC := '0';
    signal pre_tcp_data    : STD_LOGIC_VECTOR (7 downto 0);

    component buffer_count_and_checksum_data is
    generic (min_length    : natural);
    Port ( clk             : in  STD_LOGIC;
           hdr_valid_in    : in  STD_LOGIC;
           data_valid_in   : in  STD_LOGIC;
           data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out  : out STD_LOGIC := '0';
           data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           data_length     : out std_logic_vector(15 downto 0);
           data_checksum   : out std_logic_vector(15 downto 0));           
    end component;
    signal data_length     : std_logic_vector(15 downto 0);
    signal data_checksum   : std_logic_vector(15 downto 0);           
    
    component tcp_add_header is
    Port ( clk               : in  STD_LOGIC;
           data_valid_in     : in  STD_LOGIC;
           data_in           : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out    : out STD_LOGIC := '0';
           data_out          : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

           ip_src_ip         : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dst_ip         : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');           
         
           tcp_src_port      : in  std_logic_vector(15 downto 0);
           tcp_dst_port      : in  std_logic_vector(15 downto 0);
           tcp_seq_num    : in std_logic_vector(31 downto 0) := (others => '0');
           tcp_ack_num    : in std_logic_vector(31 downto 0) := (others => '0');
           tcp_window     : in std_logic_vector(15 downto 0) := (others => '0');
           tcp_flag_urg   : in std_logic := '0';
           tcp_flag_ack   : in std_logic := '0';
           tcp_flag_psh   : in std_logic := '0';
           tcp_flag_rst   : in std_logic := '0';
           tcp_flag_syn   : in std_logic := '0';
           tcp_flag_fin   : in std_logic := '0';
           tcp_urgent_ptr : in std_logic_vector(15 downto 0) := (others => '0');

           data_length   : in  std_logic_vector(15 downto 0);
           data_checksum : in  std_logic_vector(15 downto 0));
    end component;

    signal pre_ip_valid   : STD_LOGIC := '0';
    signal pre_ip_data    : STD_LOGIC_VECTOR (7 downto 0);
    signal ip_length      : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_data_length : std_logic_vector(15 downto 0);

    component ip_add_header is
    Port ( clk                : in  STD_LOGIC;

           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC := '0';
           data_out           : out STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');

           ip_data_length    : in  STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_protocol        : in  STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
           ip_src_ip          : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dst_ip          : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0'));           
    end component;

    signal pre_header_valid  : STD_LOGIC := '0';
    signal pre_header_data   : STD_LOGIC_VECTOR (7 downto 0);

    component ethernet_add_header is
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
    
    component transport_commit_buffer
    Port ( clk                : in  STD_LOGIC;
           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           packet_out_request : out std_logic := '0';
           packet_out_granted : in  std_logic := '0';
           packet_out_valid   : out std_logic := '0';         
           packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
    end component;
begin

process(clk)
    begin
        if rising_edge(clk) then
            -- Capture the destination address data on the first cycle of the data packet 
            if tcp_tx_hdr_valid = '1' then
                if tcp_tx_hdr_valid_last = '0' then 
                    tx_src_port      <= tcp_tx_src_port;
                    tx_dst_mac       <= tcp_tx_dst_mac;
                    tx_dst_ip        <= tcp_tx_dst_ip;
                    tx_dst_port      <= tcp_tx_dst_port;
                    busy_countdown   <= to_unsigned(8+64+12-4,8);
                            -- 8  = preamble
                            -- 64 = minimum ethernet header
                            -- 12 = minimum inter-packet gap
                            -- and -4 is a fix for latency
                    tcp_tx_busy <= '1';
                else
                    -- Allow for the bytes that will be added
                    if busy_countdown > 8+14+20+8+4+12 -3  then
                        -- allow for premable (8)
                        -- and ethernet Header(14)
                        -- and ip header (20)
                        -- and udp hereader (8)
                        -- and ethernet FCS (4)
                        -- and minimum inter-packet gap
                        -- and -3 is a fix for latency
                        busy_countdown  <= busy_countdown-1;
                    end if; 
                end if;
            else 
                -- Keep udp_tx_busy asserted to allow for 
                -- everything to be wrapped around the data
                if busy_countdown > 0 then
                    busy_countdown <= busy_countdown - 1;
                else               
                    tcp_tx_busy <= '0';
                end if;
            end if;
            
            tcp_tx_hdr_valid_last <= tcp_tx_hdr_valid;
        end if;
    end process;
    
    
i_buffer_count_and_checksum_data: buffer_count_and_checksum_data generic map (
        min_length => 64-14-20-20
    ) port map (
        clk            => clk,
        hdr_valid_in   => tcp_tx_hdr_valid,
        data_valid_in  => tcp_tx_data_valid,
        data_in        => tcp_tx_data,
        data_valid_out => pre_tcp_valid,
        data_out       => pre_tcp_data,
        
        data_length    => data_length,
        data_checksum  => data_checksum);    
    
i_tcp_add_header: tcp_add_header port map (
        clk             => clk,
        data_valid_in   => pre_tcp_valid,
        data_in         => pre_tcp_data,
        data_valid_out  => pre_ip_valid,
        data_out        => pre_ip_data,
    
        data_length     => data_length,
        data_checksum   => data_checksum,

        ip_src_ip         => our_ip,
        ip_dst_ip         => tcp_tx_dst_ip,
        tcp_src_port   => tcp_tx_src_port,
        tcp_dst_port   => tcp_tx_dst_port,
        tcp_seq_num    => tcp_tx_seq_num,
        tcp_ack_num    => tcp_tx_ack_num,
        tcp_window     => tcp_tx_window,
        tcp_flag_urg   => tcp_tx_flag_urg,
        tcp_flag_ack   => tcp_tx_flag_ack,
        tcp_flag_psh   => tcp_tx_flag_psh,
        tcp_flag_rst   => tcp_tx_flag_rst,
        tcp_flag_syn   => tcp_tx_flag_syn,
        tcp_flag_fin   => tcp_tx_flag_fin,
        tcp_urgent_ptr => tcp_tx_urgent_ptr);

    ip_data_length <= std_logic_vector(unsigned(data_length)+20);
i_ip_add_header: ip_add_header port map (
        clk             => clk,
        data_valid_in   => pre_ip_valid,
        data_in         => pre_ip_data,
        data_valid_out  => pre_header_valid,
        data_out        => pre_header_data,
    
        ip_data_length => ip_data_length,
        ip_protocol    => x"06",
        ip_src_ip      => our_ip,
        ip_dst_ip      => tx_dst_ip);           

i_ethernet_add_header: ethernet_add_header port map (
        clk            => clk,
        data_valid_in  => pre_header_valid,
        data_in        => pre_header_data,
        data_valid_out => complete_valid,
        data_out       => complete_data,         
        ether_type     => x"0800",
        ether_dst_mac  => tx_dst_mac,
        ether_src_mac  => our_mac);

i_transport_commit_buffer: transport_commit_buffer port map (
        clk                => clk,
        data_valid_in      => complete_valid,
        data_in            => complete_data,
        packet_out_request => packet_out_request,
        packet_out_granted => packet_out_granted,
        packet_out_valid   => packet_out_valid,         
        packet_out_data    => packet_out_data);

end Behavioral;