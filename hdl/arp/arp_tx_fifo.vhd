----------------------------------------------------------------------------------
-- Engineer:  Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name:    my_fifo - Behavioral
-- 
-- Description: A 32 entry FIFO using inferred storage
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

entity arp_tx_fifo is
    Port ( clk                 : in  STD_LOGIC;
           arp_in_write        : in  STD_LOGIC;
           arp_in_full         : out STD_LOGIC;
           arp_in_op_request   : in  STD_LOGIC;
           arp_in_tgt_hw       : in  STD_LOGIC_VECTOR(47 downto 0);
           arp_in_tgt_ip       : in  STD_LOGIC_VECTOR(31 downto 0);
        
           arp_out_empty       : out std_logic := '0';
           arp_out_read        : in  std_logic := '0';
           arp_out_op_request  : out std_logic := '0';
           arp_out_tgt_hw      : out std_logic_vector(47 downto 0) := (others => '0');
           arp_out_tgt_ip      : out std_logic_vector(31 downto 0) := (others => '0'));
end arp_tx_fifo;

architecture Behavioral of arp_tx_fifo is
   component fifo_32 is
   port (
       clk      : in  std_logic;
       
       full     : out std_logic;
       write_en : in  std_logic;
       data_in  : in  std_logic_vector;
       
       empty    : out std_logic;
       read_en  : in  std_logic; 
       data_out : out  std_logic_vector);
   end component;

   signal data_in  : std_logic_vector(80 downto 0) := (others => '0');
   signal data_out : std_logic_vector(80 downto 0) := (others => '0');
begin
    arp_out_op_request <= data_out(80);
    arp_out_tgt_hw     <= data_out(79 downto 32);
    arp_out_tgt_ip     <= data_out(31 downto 0);
    
    data_in <= arp_in_op_request & arp_in_tgt_hw & arp_in_tgt_ip;

i_generic_fifo: fifo_32
    port map (
        clk      => clk,
        full     => arp_in_full,
        write_en => arp_in_write,
        data_in  => data_in,
        empty    => arp_out_empty,
        read_en  => arp_out_read, 
        data_out => data_out);
end Behavioral;