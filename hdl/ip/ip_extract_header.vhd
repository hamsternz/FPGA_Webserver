----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: ip_extract_header - Behavioral
--
-- Description: Extract the IP header fields 
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

entity ip_extract_header is
    generic (
        our_ip        : std_logic_vector(31 downto 0) := (others => '0');
        our_broadcast : std_logic_vector(31 downto 0) := (others => '0'));
    Port ( clk                : in  STD_LOGIC;

           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC := '0';
           data_out           : out STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');

           filter_protocol    : in  STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
           
           ip_version         : out STD_LOGIC_VECTOR ( 3 downto 0)  := (others => '0');
           ip_type_of_service : out STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
           ip_length          : out STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_identification  : out STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_flags           : out STD_LOGIC_VECTOR ( 2 downto 0)  := (others => '0');
           ip_fragment_offset : out STD_LOGIC_VECTOR (12 downto 0)  := (others => '0');
           ip_ttl             : out STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
           ip_checksum        : out STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_src_ip          : out STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dest_ip         : out STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dest_broadcast  : out STD_LOGIC);           
end ip_extract_header;

architecture Behavioral of ip_extract_header is
    signal count          : unsigned(6 downto 0)         := (others => '0');
    signal header_len     : unsigned(6 downto 0)         := (others => '0');

    signal i_ip_version         : STD_LOGIC_VECTOR ( 3 downto 0)  := (others => '0');
    signal i_ip_type_of_service : STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
    signal i_ip_length          : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal i_ip_identification  : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal i_ip_flags           : STD_LOGIC_VECTOR ( 2 downto 0)  := (others => '0');
    signal i_ip_fragment_offset : STD_LOGIC_VECTOR (12 downto 0)  := (others => '0');
    signal i_ip_ttl             : STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
    signal i_ip_protocol        : STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
    signal i_ip_checksum        : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal i_ip_src_ip          : STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
    signal i_ip_dest_ip         : STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');           
    signal data_count           : UNSIGNED(10 downto 0)   := (others => '0');
begin

    ip_version         <= i_ip_version;
    ip_type_of_service <= i_ip_type_of_service;
    ip_length          <= i_ip_length;
    ip_identification  <= i_ip_identification;
    ip_flags           <= i_ip_flags;
    ip_fragment_offset <= i_ip_fragment_offset;
    ip_ttl             <= i_ip_ttl;
    ip_checksum        <= i_ip_checksum;
    ip_src_ip          <= i_ip_src_ip;
    ip_dest_ip         <= i_ip_dest_ip;
    ip_dest_broadcast  <= '1' when i_ip_dest_ip = our_broadcast else '0'; 

process(clk)
    begin
        if rising_edge(clk) then
            data_out       <= data_in;
            if data_valid_in = '1' then
                -- Note, at count of zero,  
                data_count <= data_count + 1;
                case count is
                    when "0000000" => i_ip_version                      <= data_in(7 downto 4);
                                      header_len(5 downto 2)            <= unsigned(data_in(3 downto 0));
                    when "0000001" => i_ip_type_of_service              <= data_in;
                    when "0000010" => i_ip_length(15 downto 8)          <= data_in;
                    when "0000011" => i_ip_length( 7 downto 0)          <= data_in;
                    when "0000100" => i_ip_identification(15 downto 8)  <= data_in;
                    when "0000101" => i_ip_identification( 7 downto 0)  <= data_in;
                    when "0000110" => i_ip_fragment_offset(12 downto 8) <= data_in(4 downto 0);
                                      i_ip_flags                        <= data_in(7 downto 5);
                    when "0000111" => i_ip_fragment_offset( 7 downto 0) <= data_in;
                    when "0001000" => i_ip_ttl                          <= data_in;
                    when "0001001" => i_ip_protocol                     <= data_in;
                    when "0001010" => i_ip_checksum(15 downto 8)        <= data_in;
                    when "0001011" => i_ip_checksum( 7 downto 0)        <= data_in;
                    when "0001100" => i_ip_src_ip( 7 downto 0)          <= data_in;
                    when "0001101" => i_ip_src_ip(15 downto 8)          <= data_in;
                    when "0001110" => i_ip_src_ip(23 downto 16)         <= data_in;
                    when "0001111" => i_ip_src_ip(31 downto 24)         <= data_in;
                    when "0010000" => i_ip_dest_ip( 7 downto 0)         <= data_in;
                    when "0010001" => i_ip_dest_ip(15 downto 8)         <= data_in;
                    when "0010010" => i_ip_dest_ip(23 downto 16)        <= data_in;
                    when "0010011" => i_ip_dest_ip(31 downto 24)        <= data_in;
                    when others    => null; 
                end case;
                -- So that additional IP options get dropped
                if unsigned(count) >= unsigned(header_len) and unsigned(count) > 4
                    and i_ip_version = x"4" and i_ip_protocol = filter_protocol
                    and (i_ip_dest_ip = our_ip or i_ip_dest_ip = our_broadcast) then
                     
                    if data_count < unsigned(i_ip_length) then
                        data_valid_out                   <= data_valid_in;
                    else
                        data_valid_out                   <= '0';
                    end if;
                    data_out                         <= data_in;
                end if;
                if count /= "1111111" then
                    count <= count+1;
                end if;
            else
               data_valid_out <= '0';
               data_out       <= data_in;
               count          <= (others => '0');
               data_count <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;
