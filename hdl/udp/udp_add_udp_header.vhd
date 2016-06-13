----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: udp_add_udp_header - Behavioral
-- 
-- Description: Add the UDP header to a data stream 
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

entity udp_add_udp_header is
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC := '0';
           data_out       : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

           ip_src_ip     : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dst_ip     : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');           
         
           udp_src_port  : in  std_logic_vector(15 downto 0);
           udp_dst_port  : in  std_logic_vector(15 downto 0);
           data_length   : in  std_logic_vector(15 downto 0);
           data_checksum : in  std_logic_vector(15 downto 0));
end udp_add_udp_header;

architecture Behavioral of udp_add_udp_header is
    type a_data_delay is array(0 to 8) of std_logic_vector(8 downto 0);
    signal data_delay      : a_data_delay := (others => (others => '0'));
    
    ----------------------------------------------------------------
    -- Note: Set the initial state to pass the data striaght through
    ----------------------------------------------------------------
    signal count              : unsigned(3 downto 0) := (others => '1');
    signal data_valid_in_last : std_logic            := '0';

    signal udp_length         : std_logic_vector(15 downto 0);
    signal udp_checksum_u1a   : unsigned(19 downto 0);
    signal udp_checksum_u1b   : unsigned(19 downto 0);
    signal udp_checksum_u2    : unsigned(16 downto 0);
    signal udp_checksum_u3    : unsigned(15 downto 0);
    signal udp_checksum       : std_logic_vector(15 downto 0);
    
    --------------------------------------------------------------------
    -- UDP checksum is calculated based on a pseudo header that includes
    -- the source and destination IP addresses
    --------------------------------------------------------------------
    signal pseudohdr_0        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_1        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_2        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_3        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_4        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_5        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_6        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_7        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_8        : std_logic_vector(15 downto 0) := (others => '0');
    signal pseudohdr_9        : std_logic_vector(15 downto 0) := (others => '0');
begin
    udp_length      <= std_logic_vector(unsigned(data_length)+8);

    pseudohdr_0 <= ip_src_ip( 7 downto  0) & ip_src_ip(15 downto  8);
    pseudohdr_1 <= ip_src_ip(23 downto 16) & ip_src_ip(31 downto 24);
    pseudohdr_2 <= ip_dst_ip( 7 downto  0) & ip_dst_ip(15 downto  8);
    pseudohdr_3 <= ip_dst_ip(23 downto 16) & ip_dst_ip(31 downto 24);
    pseudohdr_4 <= x"0011";  -- UDP Protocol
    pseudohdr_5 <= udp_length; 
    pseudohdr_6 <= udp_src_port; 
    pseudohdr_7 <= udp_dst_port; 
    pseudohdr_8 <= udp_length; 
    pseudohdr_9 <= udp_checksum; 
    
process(clk)
    begin
        if rising_edge(clk) then
            
            case count is
                when "0000" => data_out <= udp_src_port(15 downto 8);  data_valid_out <= '1';
                when "0001" => data_out <= udp_src_port( 7 downto 0);  data_valid_out <= '1';
                when "0010" => data_out <= udp_dst_port(15 downto 8);  data_valid_out <= '1';
                when "0011" => data_out <= udp_dst_port( 7 downto 0);  data_valid_out <= '1';
                when "0100" => data_out <= udp_length(15 downto 8);    data_valid_out <= '1';
                when "0101" => data_out <= udp_length( 7 downto 0);    data_valid_out <= '1';                    
                when "0110" => data_out <= udp_checksum(15 downto 8);  data_valid_out <= '1';
                when "0111" => data_out <= udp_checksum( 7 downto 0);  data_valid_out <= '1';
                when others => data_out <= data_delay(0)(7 downto 0);  data_valid_out <= data_delay(0)(8);
            end case;

            data_delay(0 to data_delay'high-1) <= data_delay(1 to data_delay'high);
            if data_valid_in = '1' then
                data_delay(data_delay'high) <= '1' & data_in;
                if data_valid_in_last = '0' then
                    count <= (others => '0');
                elsif count /= "1111" then
                    count <= count + 1;
                end if;
            else
                data_delay(data_delay'high) <= (others => '0');
                if count /= "1111" then
                    count <= count + 1;
                end if;
            end if;     
            data_valid_in_last <= data_valid_in;
        
            -- Pipelined checksum calculation    
            udp_checksum_u1a <= to_unsigned(0,20) + unsigned(pseudohdr_0) + unsigned(pseudohdr_1) 
                                                  + unsigned(pseudohdr_2) + unsigned(pseudohdr_3) 
                                                  + unsigned(pseudohdr_4); 
            udp_checksum_u1b <= to_unsigned(0,20) + unsigned(pseudohdr_5) 
                                                  + unsigned(pseudohdr_6) + unsigned(pseudohdr_7) 
                                                  + unsigned(pseudohdr_8) + unsigned(data_checksum); 
            udp_checksum_u2 <= to_unsigned(0,17) + udp_checksum_u1a(15 downto 0) + udp_checksum_u1a(19 downto 16) 
                                                 + udp_checksum_u1b(15 downto 0) + udp_checksum_u1b(19 downto 16);
            udp_checksum_u3 <= udp_checksum_u2(15 downto 0) + udp_checksum_u2(16 downto 16);
            udp_checksum    <= not std_logic_vector(udp_checksum_u3);
            
        end if;
    end process;
end Behavioral;