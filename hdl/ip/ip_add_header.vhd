----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: ip_add_header - Behavioral
--
-- Description: Add the IP header fields to a data stream 
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

entity ip_add_header is
    Port ( clk                : in  STD_LOGIC;

           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC := '0';
           data_out           : out STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');
           
           ip_data_length    : in STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_protocol       : in STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
           ip_src_ip         : in STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dst_ip         : in STD_LOGIC_VECTOR (31 downto 0)  := (others => '0'));           
end ip_add_header;

architecture Behavioral of ip_add_header is
    type a_data_delay is array(0 to 20) of std_logic_vector(8 downto 0);
    signal data_delay      : a_data_delay := (others => (others => '0'));
    -------------------------------------------------------
    -- Note: Set the initial state to pass the data through
    -------------------------------------------------------
    signal count              : unsigned(4 downto 0) := (others => '1');
    signal data_valid_in_last : std_logic            := '0';
    
    constant ip_version         : STD_LOGIC_VECTOR ( 3 downto 0)  := x"4";
    constant ip_header_len      : STD_LOGIC_VECTOR ( 3 downto 0)  := x"5";
    constant ip_type_of_service : STD_LOGIC_VECTOR ( 7 downto 0)  := x"00";           --zzz
    constant ip_identification  : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0'); --zzz
    constant ip_flags           : STD_LOGIC_VECTOR ( 2 downto 0)  := (others => '0'); --zzz
    constant ip_fragment_offset : STD_LOGIC_VECTOR (12 downto 0)  := (others => '0'); --zzz
    constant ip_ttl             : STD_LOGIC_VECTOR ( 7 downto 0)  := x"FF";
    signal   ip_length          : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');

    signal ip_checksum_1a       : unsigned(19 downto 0)  := (others => '0');
    signal ip_checksum_1b       : unsigned(19 downto 0)  := (others => '0');
    signal ip_checksum_2        : unsigned(19 downto 0)  := (others => '0');
    signal ip_checksum_3        : unsigned(16 downto 0)  := (others => '0');
    signal ip_checksum          : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_0            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_1            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_2            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_3            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_4            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_5            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_6            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_7            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_8            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_word_9            : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
begin
    ip_length <= std_logic_vector(unsigned(ip_data_length)+20);

    ip_word_0 <= ip_version & ip_header_len & ip_type_of_service;
    ip_word_1 <= ip_length;
    ip_word_2 <= ip_identification;
    ip_word_3 <= ip_flags & ip_fragment_offset;
    ip_word_4 <= ip_ttl & ip_protocol;
    ip_word_5 <= ip_checksum;
    ip_word_6 <= ip_src_ip( 7 downto 0) & ip_src_ip(15 downto 8);
    ip_word_7 <= ip_src_ip(23 downto 16) & ip_src_ip(31 downto 24);
    ip_word_8 <= ip_dst_ip( 7 downto 0)  & ip_dst_ip(15 downto 8);
    ip_word_9 <= ip_dst_ip(23 downto 16) & ip_dst_ip(31 downto 24);

process(clk)
    begin
        if rising_edge(clk) then
            case count is
                when "00000" => data_out <= ip_word_0(15 downto 8);    data_valid_out <= '1';
                when "00001" => data_out <= ip_word_0( 7 downto 0);    data_valid_out <= '1';
                when "00010" => data_out <= ip_word_1(15 downto 8);    data_valid_out <= '1';
                when "00011" => data_out <= ip_word_1( 7 downto 0);    data_valid_out <= '1';
                when "00100" => data_out <= ip_word_2(15 downto 8);    data_valid_out <= '1';
                when "00101" => data_out <= ip_word_2( 7 downto 0);    data_valid_out <= '1';
                when "00110" => data_out <= ip_word_3(15 downto 8);    data_valid_out <= '1';
                when "00111" => data_out <= ip_word_3( 7 downto 0);    data_valid_out <= '1';
                when "01000" => data_out <= ip_word_4(15 downto 8);    data_valid_out <= '1';
                when "01001" => data_out <= ip_word_4( 7 downto 0);    data_valid_out <= '1';
                when "01010" => data_out <= ip_word_5(15 downto 8);    data_valid_out <= '1';
                when "01011" => data_out <= ip_word_5( 7 downto 0);    data_valid_out <= '1';
                when "01100" => data_out <= ip_word_6(15 downto 8);    data_valid_out <= '1';
                when "01101" => data_out <= ip_word_6( 7 downto 0);    data_valid_out <= '1';
                when "01110" => data_out <= ip_word_7(15 downto 8);    data_valid_out <= '1';
                when "01111" => data_out <= ip_word_7( 7 downto 0);    data_valid_out <= '1';
                when "10000" => data_out <= ip_word_8(15 downto 8);    data_valid_out <= '1';
                when "10001" => data_out <= ip_word_8( 7 downto 0);    data_valid_out <= '1';
                when "10010" => data_out <= ip_word_9(15 downto 8);    data_valid_out <= '1';
                when "10011" => data_out <= ip_word_9( 7 downto 0);    data_valid_out <= '1';                         
                when others  => data_out <= data_delay(0)(7 downto 0); data_valid_out <= data_delay(0)(8);
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
            --------------------------------------------------------------------------------
            -- Checksum is calculated in a pipeline, it will be ready by the time we need it
            --------------------------------------------------------------------------------
            ip_checksum_1a <= to_unsigned(0,20) 
                            + unsigned(ip_word_0)
                            + unsigned(ip_word_1) 
                            + unsigned(ip_word_2)
                            + unsigned(ip_word_3)
                            + unsigned(ip_word_4);
            ip_checksum_1b <= to_unsigned(0,20) 
                            + unsigned(ip_word_6)
                            + unsigned(ip_word_7)
                            + unsigned(ip_word_8)
                            + unsigned(ip_word_9);
            ip_checksum_2 <= ip_checksum_1a + ip_checksum_1b;
            ip_checksum_3 <=  to_unsigned(0,17) + ip_checksum_2(15 downto 0) + ip_checksum_2(19 downto 16); 
            ip_checksum   <= not std_logic_vector(ip_checksum_3(15 downto 0) + ip_checksum_3(16 downto 16)); 
            data_valid_in_last <= data_valid_in;

        end if;
    end process;
end Behavioral;
