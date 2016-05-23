----------------------------------------------------------------------------------
-- Engineer:  Mike Field <hamster@snap.net.nz> 
-- 
-- Create Date:    21:33:42 09/25/2014 
--
-- Module Name:    my_fifo - Behavioral 
-- Description: A 32 x 9 FIFO using inferred storage
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
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
        
           arp_out_empty       : out std_logic;
           arp_out_read        : in  std_logic                    := '0';
           arp_out_op_request  : out std_logic;
           arp_out_tgt_hw      : out std_logic_vector(47 downto 0);
           arp_out_tgt_ip      : out std_logic_vector(31 downto 0));
end arp_tx_fifo;

architecture Behavioral of arp_tx_fifo is
   signal i_full  : std_logic;
   signal i_empty : std_logic;
   
   type mem_array is array(31 downto 0) of std_logic_vector(80 downto 0);
   signal memory : mem_array;
   
   signal wr_ptr : unsigned(4 downto 0) := (others => '0');
   signal rd_ptr : unsigned(4 downto 0) := (others => '0');
   
begin
    arp_in_full   <= i_full;
    arp_out_empty <= i_empty;

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
            if arp_out_read = '1' then
                if arp_in_write = '1' then
                    if i_empty = '0' then
                        arp_out_op_request <= memory(to_integer(rd_ptr))(80);
                        arp_out_tgt_hw     <= memory(to_integer(rd_ptr))(79 downto 32);
                        arp_out_tgt_ip     <= memory(to_integer(rd_ptr))(31 downto 0);
                        rd_ptr <= rd_ptr + 1;
                    end if;
                    memory(to_integer(wr_ptr)) <= arp_in_op_request & arp_in_tgt_hw & arp_in_tgt_ip;
                    wr_ptr <= wr_ptr + 1;
                elsif i_empty = '0' then
                    arp_out_op_request <= memory(to_integer(rd_ptr))(80);
                    arp_out_tgt_hw     <= memory(to_integer(rd_ptr))(79 downto 32);
                    arp_out_tgt_ip     <= memory(to_integer(rd_ptr))(31 downto 0);
                    rd_ptr <= rd_ptr + 1;
                end if;
            elsif arp_in_write = '1' then
                if i_full = '0' then
                    memory(to_integer(wr_ptr)) <= arp_in_op_request & arp_in_tgt_hw & arp_in_tgt_ip;
                    wr_ptr <= wr_ptr + 1;
                end if;           
            end if;
        end if;
    end process;
end Behavioral;