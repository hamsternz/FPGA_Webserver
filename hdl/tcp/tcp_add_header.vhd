----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: tcp_add_header - Behavioral
-- 
-- Description: Add the TCP header to a data stream 
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
use IEEE.NUMERIC_STD.ALL;

entity tcp_add_header is
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
end tcp_add_header;

architecture Behavioral of tcp_add_header is
    type a_data_delay is array(0 to 20) of std_logic_vector(8 downto 0);
    signal data_delay      : a_data_delay := (others => (others => '0'));
    
    ----------------------------------------------------------------
    -- Note: Set the initial state to pass the data striaght through
    ----------------------------------------------------------------
    signal count              : unsigned(4 downto 0) := (others => '1');
    signal data_valid_in_last : std_logic            := '0';

    signal tcp_length         : std_logic_vector(15 downto 0);
    signal tcp_checksum_u1a   : unsigned(19 downto 0);
    signal tcp_checksum_u1b   : unsigned(19 downto 0);
    signal tcp_checksum_u2    : unsigned(16 downto 0);
    signal tcp_checksum_u3    : unsigned(15 downto 0);
    signal tcp_checksum       : std_logic_vector(15 downto 0);
    
    --------------------------------------------------------------------
    -- TCP checksum is calculated based on a pseudo header that 
    -- includes the source and destination IP addresses
    --------------------------------------------------------------------
    signal pseudohdr_00        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_01        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_02        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_03        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_04        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_05        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_06        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_07        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_08        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_09        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_10        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_11        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_12        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_13        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_14        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_15        : std_logic_vector(15 downto 0) := (others => '0');
begin
    tcp_length      <= std_logic_vector(unsigned(data_length)+20);

    pseudohdr_00 <= ip_src_ip( 7 downto  0) & ip_src_ip(15 downto  8);
    pseudohdr_01 <= ip_src_ip(23 downto 16) & ip_src_ip(31 downto 24);
    pseudohdr_02 <= ip_dst_ip( 7 downto  0) & ip_dst_ip(15 downto  8);
    pseudohdr_03 <= ip_dst_ip(23 downto 16) & ip_dst_ip(31 downto 24);
    pseudohdr_04 <= x"0006";  -- TCP Protocol
    pseudohdr_05 <= tcp_length; 
    
    pseudohdr_06 <= tcp_src_port; 
    pseudohdr_07 <= tcp_dst_port; 

    pseudohdr_08 <= tcp_seq_num(31 downto 16);
    pseudohdr_09 <= tcp_seq_num(15 downto  0);
    pseudohdr_10 <= tcp_ack_num(31 downto 16);
    pseudohdr_11 <= tcp_ack_num(15 downto  0);

    pseudohdr_12 <= "01010000" & "00"  
                    & tcp_flag_urg & tcp_flag_ack
                    & tcp_flag_psh & tcp_flag_rst
                    & tcp_flag_syn & tcp_flag_fin;

    pseudohdr_13 <= tcp_window;
    pseudohdr_14 <= (others => '0'); -- checksum
    pseudohdr_15 <= tcp_urgent_ptr;
         
    
process(clk)
    begin
        if rising_edge(clk) then
            
            case count is
                when "00000" => data_out <= pseudohdr_06(15 downto 8);  data_valid_out <= '1';
                when "00001" => data_out <= pseudohdr_06( 7 downto 0);  data_valid_out <= '1';
                when "00010" => data_out <= pseudohdr_07(15 downto 8);  data_valid_out <= '1';
                when "00011" => data_out <= pseudohdr_07( 7 downto 0);  data_valid_out <= '1';
                when "00100" => data_out <= pseudohdr_08(15 downto 8);  data_valid_out <= '1';
                when "00101" => data_out <= pseudohdr_08( 7 downto 0);  data_valid_out <= '1';                    
                when "00110" => data_out <= pseudohdr_09(15 downto 8);  data_valid_out <= '1';
                when "00111" => data_out <= pseudohdr_09( 7 downto 0);  data_valid_out <= '1';
                when "01000" => data_out <= pseudohdr_10(15 downto 8);  data_valid_out <= '1';
                when "01001" => data_out <= pseudohdr_10( 7 downto 0);  data_valid_out <= '1';
                when "01010" => data_out <= pseudohdr_11(15 downto 8);  data_valid_out <= '1';
                when "01011" => data_out <= pseudohdr_11( 7 downto 0);  data_valid_out <= '1';
                when "01100" => data_out <= pseudohdr_12(15 downto 8);  data_valid_out <= '1';
                when "01101" => data_out <= pseudohdr_12( 7 downto 0);  data_valid_out <= '1';                    
                when "01110" => data_out <= pseudohdr_13(15 downto 8);  data_valid_out <= '1';
                when "01111" => data_out <= pseudohdr_13( 7 downto 0);  data_valid_out <= '1';
                when "10000" => data_out <= pseudohdr_14(15 downto 8);  data_valid_out <= '1';
                when "10001" => data_out <= pseudohdr_14( 7 downto 0);  data_valid_out <= '1';
                when "10010" => data_out <= pseudohdr_15(15 downto 8);  data_valid_out <= '1';
                when "10011" => data_out <= pseudohdr_15( 7 downto 0);  data_valid_out <= '1';
                when others  => data_out <= data_delay(0)(7 downto 0);  data_valid_out <= data_delay(0)(8);
            end case;

            data_delay(0 to data_delay'high-1) <= data_delay(1 to data_delay'high);
            if data_valid_in = '1' then
                data_delay(data_delay'high) <= '1' & data_in;
                if data_valid_in_last = '0' then
                    count <= (others => '0');
                elsif count /= "11111" then
                    count <= count + 1;
                end if;
            else
                data_delay(data_delay'high) <= (others => '0');
                if count /= "11111" then
                    count <= count + 1;
                end if;
            end if;     
            data_valid_in_last <= data_valid_in;
        
            -- Pipelined checksum calculation    
            tcp_checksum_u1a <= to_unsigned(0,20) + unsigned(pseudohdr_00) + unsigned(pseudohdr_01) 
                                                  + unsigned(pseudohdr_02) + unsigned(pseudohdr_03) 
                                                  + unsigned(pseudohdr_04) + unsigned(pseudohdr_05)
                                                  + unsigned(pseudohdr_06) + unsigned(pseudohdr_07); 
            tcp_checksum_u1b <= to_unsigned(0,20) + unsigned(pseudohdr_08) + unsigned(pseudohdr_09) 
                                                  + unsigned(pseudohdr_10) + unsigned(pseudohdr_11) 
                                                  + unsigned(pseudohdr_12) + unsigned(pseudohdr_13)
                                                  + unsigned(pseudohdr_14) + unsigned(pseudohdr_15);   
            tcp_checksum_u2 <= to_unsigned(0,17) + tcp_checksum_u1a(15 downto 0) + tcp_checksum_u1a(19 downto 16) 
                                                 + tcp_checksum_u1b(15 downto 0) + tcp_checksum_u1b(19 downto 16);
            tcp_checksum_u3 <= tcp_checksum_u2(15 downto 0) + tcp_checksum_u2(16 downto 16);
            tcp_checksum    <= not std_logic_vector(tcp_checksum_u3);
            
        end if;
    end process;
end Behavioral;