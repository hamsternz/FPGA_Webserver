----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz<
-- 
-- Module Name: arp_resolver - Behavioral
--
-- Description: 
-- 
-- Dependencies: 
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

entity arp_resolver is 
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0');
        our_ip      : std_logic_vector(31 downto 0) := (others => '0'));
    port (  clk                    : in  STD_LOGIC;
    
            -------------------------------------------------------------------- 
            -- Interface for modules to attempt to resolve an IP to a MAC address
            -- Fixed latency of less than 16 cycle.
            -------------------------------------------------------------------- 
            ch0_lookup_request     : in  std_logic;
            ch0_lookup_ip          : in  std_logic_vector(31 downto 0);
            ch0_lookup_mac         : out std_logic_vector(47 downto 0);
            ch0_lookup_found       : out std_logic;

            ch1_lookup_request     : in  std_logic;
            ch1_lookup_ip          : in  std_logic_vector(31 downto 0);
            ch1_lookup_mac         : out std_logic_vector(47 downto 0);
            ch1_lookup_found       : out std_logic;

            ch2_lookup_request     : in  std_logic;
            ch2_lookup_ip          : in  std_logic_vector(31 downto 0);
            ch2_lookup_mac         : out std_logic_vector(47 downto 0);
            ch2_lookup_found       : out std_logic;

            ch3_lookup_request     : in  std_logic;
            ch3_lookup_ip          : in  std_logic_vector(31 downto 0);
            ch3_lookup_mac         : out std_logic_vector(47 downto 0);
            ch3_lookup_found       : out std_logic;

            -------------------------------------------------------------------- 
            -- Interface from the ARP packet receiving model to update the table
            -------------------------------------------------------------------- 
            update_valid   : in  std_logic;
            update_ip      : in  std_logic_vector(31 downto 0);
            update_mac     : in  std_logic_vector(47 downto 0);
            
            -------------------------------------------------------------------- 
            -- Interface to request a new ARP packet go out on the wire
            -------------------------------------------------------------------- 
		    arp_queue_request    : out std_logic;
            arp_queue_request_ip : out std_logic_vector(31 downto 0));
end arp_resolver;

architecture Behavioral of arp_resolver is
    signal counter : unsigned(1 downto 0) := (others => '0');
    signal ch0_in_progress : std_logic := '0';
    signal ch1_in_progress : std_logic := '0';
    signal ch2_in_progress : std_logic := '0';
    signal ch3_in_progress : std_logic := '0';
    
    signal arp_lookup_ip  : std_logic_vector(31 downto 0) := (others => '0');
    
    type t_arp_table is array(0 to 255) of std_logic_vector(47 downto 0);
    type t_arp_valid is array(0 to 255) of std_logic;
    signal arp_table : t_arp_table := (255 => (others => '1'), others => (others => '0'));
    signal arp_valid : t_arp_valid := (255 => '1', others => '0');

begin

process(clk)
    begin
        if rising_edge(clk) then
            case counter is
                when  "000" =>  if ch0_lookup_request = '1' then
                                   arp_lookup_ip   <= ch0_lookup_ip;
                                   ch0_in_progress <= '1';
                                else
                                   arp_lookup_ip   <= (others => '0');
                                   ch0_in_progress <= '0';
                                end if; 

                                ch2_lookup_mac <= arp_lookup_mac;
                                ch2_lookup_ip  <= arp_lookup_valid;
                                if ch2_in_progress = '1' and arp_lookup_valid = '0' and arp_last_asked_seconds < 10
                                then
                                    arp_request    <= '1';
                                    arp_request_ip <= ch2_lookup_ip;
                                else
                                    arp_request <= '0';
                                end if; 


                when  "001" =>  if ch1_lookup_request = '1' then
                                   arp_lookup_ip   <= ch1_lookup_ip;
                                   ch1_in_progress <= '1';
                                else
                                   arp_lookup_ip   <= (others => '0');
                                   ch1_in_progress <= '0';
                                end if;

                                ch3_lookup_mac <= arp_lookup_mac;
                                ch3_lookup_ip  <= arp_lookup_valid;
                                if ch3_in_progress = '1' and arp_lookup_valid = '0' and arp_last_asked_seconds < 10
                                then
                                    arp_request    <= '1';
                                    arp_request_ip <= ch3_lookup_ip;
                                else
                                    arp_request <= '0';
                                end if; 

                when  "010" =>  if ch2_lookup_request = '1' then
                                   arp_lookup_ip   <= ch2_lookup_ip;
                                   ch2_in_progress <= '1';
                                else
                                   arp_lookup_ip   <= (others => '0');
                                   ch2_in_progress <= '0';
                                end if;
                                
                                ch0_lookup_mac <= arp_lookup_mac;
                                ch0_lookup_ip  <= arp_lookup_valid;
                                if ch0_in_progress = '1' and arp_lookup_valid = '0' and arp_last_asked_seconds < 10
                                then
                                    arp_request    <= '1';
                                    arp_request_ip <= ch0_lookup_ip;
                                else
                                    arp_request <= '0';
                                end if; 

                when others =>  if ch3_lookup_request = '1' then
                                   arp_lookup_ip   <= ch3_lookup_ip;
                                   ch3_in_progress <= '1';
                                else
                                   arp_lookup_ip   <= (others => '0');
                                   ch3_in_progress <= '0';
                                end if;
                                
                                ch1_lookup_mac <= arp_lookup_mac;
                                ch1_lookup_ip  <= arp_lookup_valid;
                                if ch1_in_progress = '1' and arp_lookup_valid = '0' and arp_last_asked_seconds < 10
                                then
                                    arp_request    <= '1';
                                    arp_request_ip <= ch1_lookup_ip;
                                else
                                    arp_request <= '0';
                                end if;
            end case;
        end if;
    end process;
end Behavioral;
