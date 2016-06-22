----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: tcp_extract_header - Behavioral
--
-- Description: Extract the TCP header fields 
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

entity tcp_extract_header is
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
end tcp_extract_header;

architecture Behavioral of tcp_extract_header is
    signal i_tcp_hdr_valid  : std_logic := '0';
    signal i_tcp_src_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal i_tcp_dst_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal i_tcp_seq_num    : std_logic_vector(31 downto 0) := (others => '0');
    signal i_tcp_ack_num    : std_logic_vector(31 downto 0) := (others => '0');
    signal i_tcp_window     : std_logic_vector(15 downto 0) := (others => '0');
    signal i_tcp_flag_urg   : std_logic := '0';
    signal i_tcp_flag_ack   : std_logic := '0';
    signal i_tcp_flag_psh   : std_logic := '0';
    signal i_tcp_flag_rst   : std_logic := '0';
    signal i_tcp_flag_syn   : std_logic := '0';
    signal i_tcp_flag_fin   : std_logic := '0';
    signal i_tcp_checksum   : std_logic_vector(15 downto 0) := (others => '0');
    signal i_tcp_urgent_ptr : std_logic_vector(15 downto 0) := (others => '0'); 
	signal byte_hdr_len     : unsigned(10 downto 0) := (others => '0');
	signal data_count       : unsigned(10 downto 0) := (others => '0');
	signal count            : unsigned( 4 downto 0) := (others => '0');
begin
    tcp_hdr_valid  <= i_tcp_hdr_valid;
    tcp_src_port   <= i_tcp_src_port;
    tcp_dst_port   <= i_tcp_dst_port;
    tcp_seq_num    <= i_tcp_seq_num;
    tcp_ack_num    <= i_tcp_ack_num;
    tcp_window     <= i_tcp_window;
    tcp_flag_urg   <= i_tcp_flag_urg;
    tcp_flag_ack   <= i_tcp_flag_ack;
    tcp_flag_psh   <= i_tcp_flag_psh;
    tcp_flag_rst   <= i_tcp_flag_rst;
    tcp_flag_syn   <= i_tcp_flag_syn;
    tcp_flag_fin   <= i_tcp_flag_fin;
    tcp_checksum   <= i_tcp_checksum;
    tcp_urgent_ptr <= i_tcp_urgent_ptr;
process(clk)
    begin
        if rising_edge(clk) then
		    data_valid_out  <= '0';
            data_out        <= (others => '0');
			i_tcp_hdr_valid <= '0';

            if data_valid_in = '1' then
                case count is
                    when "00000" => i_tcp_src_port(15 downto 8)   <= data_in;
                    when "00001" => i_tcp_src_port( 7 downto 0)   <= data_in;
                    when "00010" => i_tcp_dst_port(15 downto 8)   <= data_in;
                    when "00011" => i_tcp_dst_port( 7 downto 0)   <= data_in;
                    when "00100" => i_tcp_seq_num(31 downto 24)   <= data_in;
                    when "00101" => i_tcp_seq_num(23 downto 16)   <= data_in;
                    when "00110" => i_tcp_seq_num(15 downto  8)   <= data_in;
                    when "00111" => i_tcp_seq_num( 7 downto  0)   <= data_in;
                    when "01000" => i_tcp_ack_num(31 downto 24)   <= data_in;
                    when "01001" => i_tcp_ack_num(23 downto 16)   <= data_in;
                    when "01010" => i_tcp_ack_num(15 downto  8)   <= data_in;
                    when "01011" => i_tcp_ack_num( 7 downto  0)   <= data_in;
                    when "01100" => byte_hdr_len(5 downto 2)      <= unsigned(data_in( 7 downto  4));
                    when "01101" => i_tcp_flag_urg <= data_in(5);
                                    i_tcp_flag_ack <= data_in(4);
                                    i_tcp_flag_psh <= data_in(3);
                                    i_tcp_flag_rst <= data_in(2);
                                    i_tcp_flag_syn <= data_in(1);
                                    i_tcp_flag_fin <= data_in(0);
                    when "01110" => i_tcp_window(15 downto 8)     <= data_in;
                    when "01111" => i_tcp_window( 7 downto 0)     <= data_in;
                    when "10000" => i_tcp_checksum(15 downto 8)   <= data_in;
                    when "10001" => i_tcp_checksum( 7 downto 0)   <= data_in;
                    when "10010" => i_tcp_urgent_ptr(15 downto 8) <= data_in;
                    when "10011" => i_tcp_urgent_ptr( 7 downto 0) <= data_in;
                    when others => if data_count = byte_hdr_len then
                                       data_valid_out <= data_valid_in;
                                       data_out       <= data_in;
									   i_tcp_hdr_valid <= '1';
								   elsif data_count > byte_hdr_len then
                                       data_valid_out <= data_valid_in;
                                       data_out       <= data_in;
									   i_tcp_hdr_valid <= '0';
                                   end if;                                    
                end case;

                if count /= "11111" then
                    count <= count+1;
                end if;
                data_count <= data_count + 1;
            else
               -- For when TCP packets have no data
               if data_count = byte_hdr_len and byte_hdr_len /= 0 then
                   i_tcp_hdr_valid <= '1';
               end if;
               data_valid_out <= '0';
               data_out       <= data_in;
               count <= (others => '0');
               data_count <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;