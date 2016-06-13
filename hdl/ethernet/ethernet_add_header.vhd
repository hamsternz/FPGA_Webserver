----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: ethernet_add_header - Behavioral
--
-- Description: Add the Ethernet header to a data frame 
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

entity ethernet_add_header is
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC := '0';
           data_out       : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
         
           ether_type     : in STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 
           ether_dst_mac  : in STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
           ether_src_mac  : in STD_LOGIC_VECTOR (47 downto 0) := (others => '0'));
end ethernet_add_header;

architecture Behavioral of ethernet_add_header is
    type a_data_delay is array(0 to 14) of std_logic_vector(8 downto 0);
    signal data_delay      : a_data_delay := (others => (others => '0'));
    -------------------------------------------------------
    -- Note: Set the initial state to pass the data through
    -------------------------------------------------------
    signal count              : unsigned(3 downto 0) := (others => '1');
    signal data_valid_in_last : std_logic            := '0';
begin
process(clk)
    begin
        if rising_edge(clk) then
            case count is
                when "0000" => data_out <= ether_dst_mac( 7 downto  0); data_valid_out <= '1';
                when "0001" => data_out <= ether_dst_mac(15 downto  8); data_valid_out <= '1';
                when "0010" => data_out <= ether_dst_mac(23 downto 16); data_valid_out <= '1';
                when "0011" => data_out <= ether_dst_mac(31 downto 24); data_valid_out <= '1';
                when "0100" => data_out <= ether_dst_mac(39 downto 32); data_valid_out <= '1';
                when "0101" => data_out <= ether_dst_mac(47 downto 40); data_valid_out <= '1';
                    
                when "0110" => data_out <= ether_src_mac( 7 downto  0); data_valid_out <= '1';
                when "0111" => data_out <= ether_src_mac(15 downto  8); data_valid_out <= '1';
                when "1000" => data_out <= ether_src_mac(23 downto 16); data_valid_out <= '1';
                when "1001" => data_out <= ether_src_mac(31 downto 24); data_valid_out <= '1';
                when "1010" => data_out <= ether_src_mac(39 downto 32); data_valid_out <= '1';
                when "1011" => data_out <= ether_src_mac(47 downto 40); data_valid_out <= '1';
                when "1100" => data_out <= ether_type(15 downto 8);     data_valid_out <= '1';
                when "1101" => data_out <= ether_type( 7 downto 0);     data_valid_out <= '1';
                when others => data_out <= data_delay(0)(7 downto 0);   data_valid_out <= data_delay(0)(8);
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
        end if;
    end process;
end Behavioral;
