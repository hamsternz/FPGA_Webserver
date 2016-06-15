----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: tx_arbiter - Behavioral
--
-- Description: Control who has access to the transmit queue
--              The higher number bit in "request" have higher priority
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

entity tx_arbiter is
	generic (idle_time : std_logic_vector(5 downto 0));
    Port ( clk               : in  STD_LOGIC;
           ready          : in  STD_LOGIC;
    
           ch0_request    : in  STD_LOGIC;
           ch0_granted    : out STD_LOGIC;
           ch0_valid      : in  STD_LOGIC;
           ch0_data       : in  STD_LOGIC_VECTOR (7 downto 0);

           ch1_request    : in  STD_LOGIC;
           ch1_granted    : out STD_LOGIC;
           ch1_valid      : in  STD_LOGIC;
           ch1_data       : in  STD_LOGIC_VECTOR (7 downto 0);

           ch2_request    : in  STD_LOGIC;
           ch2_granted    : out STD_LOGIC;
           ch2_valid      : in  STD_LOGIC;
           ch2_data       : in  STD_LOGIC_VECTOR (7 downto 0);
    
           ch3_request    : in  STD_LOGIC;
           ch3_granted    : out STD_LOGIC;
           ch3_valid      : in  STD_LOGIC;
           ch3_data       : in  STD_LOGIC_VECTOR (7 downto 0);
    
           merged_data_valid  : out STD_LOGIC;
           merged_data        : out STD_LOGIC_VECTOR (7 downto 0));
end tx_arbiter;

architecture Behavioral of tx_arbiter is
    signal   count     : unsigned(5 downto 0) := (others => '0');
	signal   request   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal   grant     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
begin
    request(0)  <= ch0_request;
	ch0_granted <= grant(0) and request(0);

    request(1)  <= ch1_request;
	ch1_granted <= grant(1) and request(1);

    request(2)  <= ch2_request;
    ch2_granted <= grant(2) and request(2);

    request(3)  <= ch3_request;
    ch3_granted <= grant(3) and request(3);
	
	merged_data_valid <= ch0_valid or ch1_valid or ch2_valid or ch3_valid; 
	merged_data       <= ch0_data  or ch1_data  or ch2_data  or ch3_data; 

process(clk)
    begin  
        if rising_edge(clk) then
			grant <= grant and request;
            if count = 0 and ready = '1' then
				if request(3) = '1' then
					grant(3) <= '1';
					count <= unsigned(idle_time);
				elsif request(2) = '1' then
					grant(2) <= '1';
					count <= unsigned(idle_time);
				elsif request(1) = '1' then
					grant(1) <= '1';
					count <= unsigned(idle_time);
				elsif request(0) = '1' then
					grant(0) <= '1';
					count <= unsigned(idle_time);
				end if;				
            elsif (grant and request) /= "00000000" then
                count <= unsigned(idle_time)-2;
            else
				count <= count-1;
            end if;
        end if;
    end process;
end Behavioral;