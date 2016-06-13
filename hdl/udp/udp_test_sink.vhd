----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: udp_test_sink - Behavioral
--
-- Description: Receive UDP packets for testing. 
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

entity udp_test_sink is
    Port ( 
        clk                 : in  STD_LOGIC;

       -- data received over UDP
       udp_rx_valid         : in  std_logic := '0';
       udp_rx_data          : in  std_logic_vector(7 downto 0) := (others => '0');
       udp_rx_src_ip        : in  std_logic_vector(31 downto 0) := (others => '0');
       udp_rx_src_port      : in  std_logic_vector(15 downto 0) := (others => '0');
       udp_rx_dst_broadcast : in  std_logic := '0';
       udp_rx_dst_port      : in  std_logic_vector(15 downto 0) := (others => '0');

       leds                 : out std_logic_vector(7 downto 0) := (others => '0'));
end udp_test_sink;

architecture Behavioral of udp_test_sink is
    signal udp_rx_valid_last : std_logic := '0';
begin

udp_test_sink: process(clk) 
    begin
        if rising_edge(clk) then
            -- assign any data on UDP port 5140 (0x1414) to the LEDs
            if udp_rx_valid = '1' and udp_rx_dst_port = std_logic_vector(to_unsigned(4660, 16)) then  
                leds <= udp_rx_data;
            end if;
            udp_rx_valid_last <= udp_rx_valid;
        end if;
    end process;

end Behavioral;