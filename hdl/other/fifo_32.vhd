----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: fifo_32 - Behavioral
--
-- Description: A 32-entry singla-clock FIFO of unknown data width. 
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

entity fifo_32 is
    port (
        clk      : in  std_logic;
    
        full     : out std_logic;
        write_en : in  std_logic;
        data_in  : in  std_logic_vector;
        
        empty    : out std_logic;
        read_en  : in  std_logic; 
        data_out : out  std_logic_vector);
end fifo_32;

architecture Behavioral of fifo_32 is
   signal i_full  : std_logic := '0';
   signal i_empty : std_logic := '0';
   
   type mem_array is array(31 downto 0) of std_logic_vector(data_in'high downto 0);
   signal memory : mem_array;
   
   signal wr_ptr : unsigned(4 downto 0) := (others => '0');
   signal rd_ptr : unsigned(4 downto 0) := (others => '0');
   
begin
    full   <= i_full;
    empty <= i_empty;

flag_proc: process(wr_ptr, rd_ptr)
    begin
        if wr_ptr = rd_ptr then
            i_empty <= '1';
        else
            i_empty <= '0';
        end if;

        if wr_ptr+1 = rd_ptr then
            i_full <= '1';
        else
            i_full <= '0';
        end if;
    end process;

clk_proc: process(clk)
    begin
        if rising_edge(clk) then
            if read_en = '1' then
                if write_en = '1' then
                    if i_empty = '0' then
                        data_out <= memory(to_integer(rd_ptr));
                        rd_ptr <= rd_ptr + 1;
                    end if;
                    memory(to_integer(wr_ptr)) <= data_in;
                    wr_ptr <= wr_ptr + 1;
                elsif i_empty = '0' then
                    data_out <= memory(to_integer(rd_ptr));
                    rd_ptr <= rd_ptr + 1;
                end if;
            elsif write_en = '1' then
                if i_full = '0' then
                    memory(to_integer(wr_ptr)) <= data_in;
                    wr_ptr <= wr_ptr + 1;
                end if;           
            end if;
        end if;
    end process;
end Behavioral;
