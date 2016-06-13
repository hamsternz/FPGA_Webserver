----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: udp_test_source - Behavioral
--
-- Description: Generate a few UDP packets for testing. 
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

entity udp_test_source is
    Port ( 
        clk                  : in STD_LOGIC;
	    -- interface for data to be sent over UDP
        udp_tx_busy          : in  std_logic := '0';
        udp_tx_valid         : out std_logic := '0';
        udp_tx_data          : out std_logic_vector(7 downto 0)  := (others => '0');
        udp_tx_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
        udp_tx_dst_mac       : out std_logic_vector(47 downto 0) := (others => '0');
        udp_tx_dst_ip        : out std_logic_vector(31 downto 0) := (others => '0');
        udp_tx_dst_port      : out std_logic_vector(15 downto 0) := (others => '0'));
end udp_test_source;

architecture Behavioral of udp_test_source is
    type t_state is (waiting, armed, sending);
    signal state : t_state := waiting;
    signal countdown  : unsigned(23 downto 0) := to_unsigned(1000,24);
    signal data_count : unsigned(7 downto 0) := to_unsigned(0,8);
begin

process(clk)
    begin
        if rising_edge(clk) then
            udp_tx_valid    <= '0';
            udp_tx_data     <= (others => '0');
            udp_tx_src_port <= (others => '0');
            udp_tx_dst_mac  <= (others => '0');
            udp_tx_dst_ip   <= (others => '0');
            udp_tx_dst_port <= (others => '0');

            case state is
                when waiting =>
                    udp_tx_valid <= '0';
                    if countdown = 0 then
                        countdown <= to_unsigned(12_499_999,24); -- 10 packets per second
--                        countdown <= to_unsigned(499,24);
                        state <= armed;
                    else   
                        countdown <= countdown-1;
                    end if;
                when armed =>
                    udp_tx_valid <= '0';
                    if udp_tx_busy = '0' then
                        data_count <= (others => '0');
                        state <= sending;
                    end if;
                when sending =>
                    -- Broadcast data from port 4660 to port 9029 on 10.0.0.255                    
                    udp_tx_valid <= '1';
                    udp_tx_src_port <= std_logic_vector(to_unsigned(4660,16));
                    udp_tx_dst_mac  <= x"FF_FF_FF_FF_FF_FF";
                    udp_tx_dst_ip   <= x"FF_00_00_0A";
                    udp_tx_dst_port <= std_logic_vector(to_unsigned(9029,16));
                    udp_tx_data     <= std_logic_vector(data_count);

                    data_count <= data_count + 1;
                    if data_count = 2 then
                        state <= waiting;  
                    end if;
                when others =>
                    state <= waiting;
            end case; 
        end if;
    end process;
end Behavioral;