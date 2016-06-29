----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: tcp_handler - Behavioral
--
-- Description: Provide the processing for TCP packets.
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

entity tcp_handler is 
    generic (
        our_mac       : std_logic_vector(47 downto 0) := (others => '0');
        our_ip        : std_logic_vector(31 downto 0) := (others => '0'));
    port (  clk                : in  STD_LOGIC;
            -- For receiving data from the PHY        
            packet_in_valid    : in  STD_LOGIC;
            packet_in_data     : in  STD_LOGIC_VECTOR (7 downto 0);

            -- data received over TCP/IP
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
            tcp_rx_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0');

  	        -- data to be sent over UDP
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
            tcp_tx_flag_urg      : in std_logic := '0';
            tcp_tx_flag_ack      : in std_logic := '0';
            tcp_tx_flag_psh      : in std_logic := '0';
            tcp_tx_flag_rst      : in std_logic := '0';
            tcp_tx_flag_syn      : in std_logic := '0';
            tcp_tx_flag_fin      : in std_logic := '0';
            tcp_tx_urgent_ptr    : in std_logic_vector(15 downto 0) := (others => '0');

            -- For sending data to the PHY        
            packet_out_request : out std_logic := '0';
            packet_out_granted : in  std_logic;
            packet_out_valid   : out std_logic := '0';         
            packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
end tcp_handler;

architecture Behavioral of tcp_handler is
    component tcp_rx_packet is
    generic (
        our_ip      : std_logic_vector(31 downto 0) := (others => '0');
        our_broadcast : std_logic_vector(31 downto 0) := (others => '0');
        our_mac     : std_logic_vector(47 downto 0) := (others => '0'));
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
    end component;

    component tcp_tx_packet is
    generic (
        our_ip      : std_logic_vector(31 downto 0) := (others => '0');
        our_mac     : std_logic_vector(47 downto 0) := (others => '0'));
    port(
        clk                  : in  STD_LOGIC;
        tcp_tx_busy          : out std_logic;

        tcp_tx_data_valid    : in  std_logic;
        tcp_tx_data          : in  std_logic_vector(7 downto 0);
        
        tcp_tx_hdr_valid     : in std_logic := '0';
        tcp_tx_dst_mac       : in std_logic_vector(47 downto 0);
        tcp_tx_dst_ip        : in std_logic_vector(31 downto 0);
        tcp_tx_src_port      : in std_logic_vector(15 downto 0);
        tcp_tx_dst_port      : in std_logic_vector(15 downto 0);    
        tcp_tx_seq_num       : in std_logic_vector(31 downto 0);
        tcp_tx_ack_num       : in std_logic_vector(31 downto 0);
        tcp_tx_window        : in std_logic_vector(15 downto 0);
        tcp_tx_flag_urg      : in std_logic;
        tcp_tx_flag_ack      : in std_logic;
        tcp_tx_flag_psh      : in std_logic;
        tcp_tx_flag_rst      : in std_logic;
        tcp_tx_flag_syn      : in std_logic;
        tcp_tx_flag_fin      : in std_logic;
        tcp_tx_urgent_ptr    : in std_logic_vector(15 downto 0);

        packet_out_request : out std_logic := '0';
        packet_out_granted : in  std_logic := '0';
        packet_out_valid   : out std_logic := '0';         
        packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
    end component;
    
    signal i_packet_out_valid : std_logic := '0';
begin
    --==============================================
    -- Start of UDP RX processing
    --==============================================
i_tcp_rx_packet: tcp_rx_packet generic map (
        our_ip        => our_ip,
        our_mac       => our_mac
    ) port map (
        clk                  => clk,

        packet_in_valid      => packet_in_valid,
        packet_in_data       => packet_in_data,
    
        tcp_rx_data_valid    => tcp_rx_data_valid,
        tcp_rx_data          => tcp_rx_data,
        
        tcp_rx_hdr_valid     => tcp_rx_hdr_valid,
        tcp_rx_src_ip        => tcp_rx_src_ip,
        tcp_rx_src_port      => tcp_rx_src_port,
        tcp_rx_dst_broadcast => tcp_rx_dst_broadcast, 
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
        tcp_rx_urgent_ptr    => tcp_rx_urgent_ptr);

    --==============================================
    -- End of TCP RX processing
    --==============================================
    -- Start of TCP TX processing
    --==============================================
i_tcp_tx_packet : tcp_tx_packet generic map (
        our_ip  => our_ip,
        our_mac => our_mac
    ) port map (    
        clk                  => clk,
        tcp_tx_busy          => tcp_tx_busy,     
        tcp_tx_hdr_valid     => tcp_tx_hdr_valid,
        tcp_tx_dst_mac       => tcp_tx_dst_mac,
        tcp_tx_dst_ip        => tcp_tx_dst_ip,
        tcp_tx_src_port      => tcp_tx_src_port,
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
        tcp_tx_urgent_ptr    => tcp_tx_urgent_ptr,
        
        tcp_tx_data_valid    => tcp_tx_data_valid, 
        tcp_tx_data          => tcp_tx_data, 
            
        packet_out_request   => packet_out_request, 
        packet_out_granted   => packet_out_granted,
        packet_out_valid     => packet_out_valid,         
        packet_out_data      => packet_out_data);
    --==============================================
    -- End of TCP TX processing
    --==============================================
end Behavioral;