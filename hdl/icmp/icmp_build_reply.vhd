----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: icmp_build_reply - Behavioral
--
-- Description: Build the ICMP reply packet by adding headers to the data. 
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

entity icmp_build_reply is
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0');
        our_ip      : std_logic_vector(31 downto 0) := (others => '0'));
    Port ( clk                : in  STD_LOGIC;
       data_valid_in      : in  STD_LOGIC;
       data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
       data_valid_out     : out STD_LOGIC;
       data_out           : out STD_LOGIC_VECTOR (7 downto 0);

       ether_is_ipv4      : in  STD_LOGIC; 
       ether_src_mac      : in  STD_LOGIC_VECTOR (47 downto 0);

       ip_version         : in  STD_LOGIC_VECTOR (3 downto 0);
       ip_type_of_service : in  STD_LOGIC_VECTOR (7 downto 0);
       ip_length          : in  STD_LOGIC_VECTOR (15 downto 0);
       ip_identification  : in  STD_LOGIC_VECTOR (15 downto 0);
       ip_flags           : in  STD_LOGIC_VECTOR (2 downto 0);
       ip_fragment_offset : in  STD_LOGIC_VECTOR (12 downto 0);
       ip_ttl             : in  STD_LOGIC_VECTOR (7 downto 0);
       ip_protocol        : in  STD_LOGIC_VECTOR (7 downto 0);
       ip_checksum        : in  STD_LOGIC_VECTOR (15 downto 0);
       ip_src_ip          : in  STD_LOGIC_VECTOR (31 downto 0);
       ip_dest_ip         : in  STD_LOGIC_VECTOR (31 downto 0);           
       
       icmp_type          : in  STD_LOGIC_VECTOR (7 downto 0);
       icmp_code          : in  STD_LOGIC_VECTOR (7 downto 0);
       icmp_checksum      : in  STD_LOGIC_VECTOR (15 downto 0);
       icmp_identifier    : in  STD_LOGIC_VECTOR (15 downto 0);
       icmp_sequence      : in  STD_LOGIC_VECTOR (15 downto 0));           
end icmp_build_reply;

architecture Behavioral of icmp_build_reply is
    signal count : unsigned(5 downto 0) := (others => '0');
    type t_delay is array( 0 to 42) of std_logic_vector(8 downto 0);
    signal delay : t_delay := (others => (others => '0'));

    signal flipped_src_ip       : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal flipped_our_ip       : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal h_ip_length          : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal h_ether_src_mac      : STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
    signal h_ip_identification  : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal h_ip_checksum        : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal h_ip_src_ip          : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal h_icmp_checksum      : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal h_icmp_identifier    : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal h_icmp_sequence      : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');           

    signal checksum_static1 : unsigned(19 downto 0) := x"04500"; 
    signal checksum_static2 : unsigned(19 downto 0) := x"08001"; 
    signal checksum_part1   : unsigned(19 downto 0) := (others => '0'); 
    signal checksum_part2   : unsigned(19 downto 0) := (others => '0'); 
    signal checksum_part3   : unsigned(19 downto 0) := (others => '0'); 
    signal checksum_part4   : unsigned(19 downto 0) := (others => '0');
    signal checksum_final   : unsigned(15 downto 0) := (others => '0');

begin
    flipped_src_ip <= h_ip_src_ip(7 downto 0) & h_ip_src_ip(15 downto 8) & h_ip_src_ip(23 downto 16) & h_ip_src_ip(31 downto 24);    
    flipped_our_ip <= our_ip(7 downto 0)      & our_ip(15 downto 8)      & our_ip(23 downto 16)      & our_ip(31 downto 24);    

process(clk)
    variable v_icmp_check : unsigned (16 downto 0); 
    begin
        if rising_edge(clk) then
            -- This splits the IP checksumming over four cycles
            checksum_part1 <= checksum_static1 + unsigned(h_ip_identification)
                            + unsigned(flipped_src_ip(31 downto 16))
                            + unsigned(flipped_src_ip(15 downto 0));
            checksum_part2 <= checksum_static2 + unsigned(h_ip_length)         
                            + unsigned(flipped_our_ip(31 downto 16))
                            + unsigned(flipped_our_ip(15 downto 0));
            checksum_part3 <= to_unsigned(0,20) + checksum_part1(15 downto 0) +  checksum_part1(19 downto 16) 
                            + checksum_part2(15 downto 0) +  checksum_part2(19 downto 16);
            checksum_part4 <= to_unsigned(0,20) + checksum_part3(15 downto 0) + checksum_part3(19 downto 16);  
            checksum_final <= not(checksum_part4(15 downto 0) + checksum_part4(19 downto 16));  

            if data_valid_in = '1' then
                if count /= "101011" then
                    count <= count+1;
                end if;
            else
                if count = "000000" or count = "101011" then
                    count <= (others => '0');
                else
                    count <= count+1;
                end if;
            end if;

            if count = 0 and data_valid_in = '1' then
                v_icmp_check(15 downto 0) := unsigned(icmp_checksum);
                v_icmp_check(16)          := '0';
                v_icmp_check              := v_icmp_check + 8;
                v_icmp_check              := v_icmp_check + v_icmp_check(16 downto 16);
                 
                h_ether_src_mac   <= ether_src_mac;
                h_ip_src_ip       <= ip_src_ip;
                h_ip_length       <= ip_length;
                h_icmp_checksum   <= std_logic_vector(v_icmp_check(15 downto 0));
                h_icmp_identifier <= icmp_identifier;
                h_icmp_sequence   <= icmp_sequence;
            end if;
            
            if count /= "000000" then
                data_valid_out <= '1';
            end if;

            case count is
                -----------------------------
                -- Ethernet Header 
                -----------------------------
                -- Destination MAC address
--                when "000000" => data_out <= (others => '0'); data_valid_out <= '0';  
                when "000001" => data_out <= h_ether_src_mac( 7 downto  0);
                when "000010" => data_out <= h_ether_src_mac(15 downto  8);
                when "000011" => data_out <= h_ether_src_mac(23 downto 16);
                when "000100" => data_out <= h_ether_src_mac(31 downto 24);
                when "000101" => data_out <= h_ether_src_mac(39 downto 32);
                when "000110" => data_out <= h_ether_src_mac(47 downto 40);
                -- Source MAC address
                when "000111" => data_out <= our_mac( 7 downto  0);
                when "001000" => data_out <= our_mac(15 downto  8);
                when "001001" => data_out <= our_mac(23 downto 16);
                when "001010" => data_out <= our_mac(31 downto 24);
                when "001011" => data_out <= our_mac(39 downto 32);
                when "001100" => data_out <= our_mac(47 downto 40);
                -- Ethernet frame tyoe
                when "001101" => data_out <= x"08"; -- Ether Type 08:00 - IP
                when "001110" => data_out <= x"00";
                ------------------------ 
                -- IP Header 
                ------------------------                                 
                when "001111" => data_out <= x"45";                        -- Protocol & Header Len
                when "010000" => data_out <= x"00";
                when "010001" => data_out <= h_ip_length(15 downto 8);        -- Length
                when "010010" => data_out <= h_ip_length(7 downto 0);
                when "010011" => data_out <= h_ip_identification(15 downto 8); -- Identificaiton
                when "010100" => data_out <= h_ip_identification(7 downto 0);
                when "010101" => data_out <= x"00";                        -- Flags and offset
                when "010110" => data_out <= x"00";
                when "010111" => data_out <= x"80";                        -- TTL
                when "011000" => data_out <= x"01";                        -- Protocol
                when "011001" => data_out <= std_logic_vector(checksum_final(15 downto 8));  
                when "011010" => data_out <= std_logic_vector(checksum_final(7 downto 0)); 
                when "011011" => data_out <= our_ip( 7 downto 0);          -- Source IP Address
                when "011100" => data_out <= our_ip(15 downto 8);
                when "011101" => data_out <= our_ip(23 downto 16);
                when "011110" => data_out <= our_ip(31 downto 24);
                when "011111" => data_out <= h_ip_src_ip( 7 downto 0);       -- Destination IP address
                when "100000" => data_out <= h_ip_src_ip(15 downto 8);       -- (bounce back to the source)
                when "100001" => data_out <= h_ip_src_ip(23 downto 16); 
                when "100010" => data_out <= h_ip_src_ip(31 downto 24);  
                -------------------------------------
                -- ICMP Header
                -------------------------------------
                when "100011" => data_out <= x"00";                          -- ICMP Type = reply
                when "100100" => data_out <= x"00";                          -- Code 
                when "100101" => data_out <= h_icmp_checksum(7 downto 0);    -- Checksum 
                when "100110" => data_out <= h_icmp_checksum(15 downto 8);   
                when "100111" => data_out <= h_icmp_identifier(7 downto 0);  -- Identifier
                when "101000" => data_out <= h_icmp_identifier(15 downto 8);
                when "101001" => data_out <= h_icmp_sequence(7 downto 0);    -- Sequence
                when "101010" => data_out <= h_icmp_sequence(15 downto 8);

                when others => data_valid_out <= delay(0)(8);
                               data_out       <= delay(0)(7 downto 0);
            end case;  
            delay(0 to delay'high-1) <= delay(1 to delay'high);
            delay(delay'high)      <= data_valid_in & data_in;
        end if;
    end process;
end Behavioral;
