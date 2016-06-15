----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: transport_commit_buffer - Behavioral
--
-- Description: Somewhere to hold the data outbound packet while waiting to
--              be granted access to the TX interface.
--              If the buffer gets over-run with data (e.g. if the TX interface is 
--              busy) then it drops the packet.  
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

entity transport_commit_buffer is
    Port ( clk                : in  STD_LOGIC;
           data_valid_in      : in  STD_LOGIC;
       data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
       packet_out_request : out std_logic := '0';
       packet_out_granted : in  std_logic;
       packet_out_valid   : out std_logic := '0';         
       packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
end transport_commit_buffer;

architecture Behavioral of transport_commit_buffer is
    type a_data_buffer is array(0 to 2047) of std_logic_vector(8 downto 0);
    signal data_buffer : a_data_buffer := (others => (others => '0'));
    attribute ram_style : string;
    attribute ram_style of data_buffer : signal is "block";
        
    signal read_addr      : unsigned(10 downto 0) := (others => '1');
    signal write_addr     : unsigned(10 downto 0) := (others => '0');
    signal committed_addr : unsigned(10 downto 0) := (others => '1');
    
    type s_read_state is (read_idle, read_reading1, read_reading, read_waiting);
    signal read_state : s_read_state  := read_idle;
    
    type s_write_state is (write_idle, write_writing, write_aborted);
    signal write_state : s_write_state  := write_idle;
    
    signal i_packet_out_valid      : std_logic := '0'; 
    signal i_packet_out_valid_last : std_logic := '0';
    signal i_packet_out_data    : std_logic_vector(7 downto 0) := (others => '0');

    constant fcs_length        : integer := 4;
    constant interpacket_gap   : integer := 12; 
    constant for_next_preamble : integer := 8; 

    -- counter for the delay between packets
    signal read_pause : unsigned(5 downto 0) := to_unsigned(fcs_length + interpacket_gap + for_next_preamble-1,6);

    signal write_data   : std_logic_vector(8 downto 0);
    signal read_data    : std_logic_vector(8 downto 0);    
begin
    with data_valid_in select write_data   <= data_valid_in & data_in when '1',  
                                              (others => '0') when others;
    i_packet_out_valid <= read_data(8);
    i_packet_out_data  <= read_data(7 downto 0);
    
    packet_out_valid <= i_packet_out_valid;
    packet_out_data  <= i_packet_out_data;
infer_dp_mem_process: process(clk)
    variable this_read_addr : unsigned(10 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            if write_state = write_writing or data_valid_in = '1' then 
                data_buffer(to_integer(write_addr)) <= write_data;
            end if;

            this_read_addr := read_addr;
            if i_packet_out_valid = '0' then
                if read_addr = committed_addr or i_packet_out_valid_last = '1' then
                   packet_out_request <= '0';
                else
                   packet_out_request <= '1';
                   if packet_out_granted = '1' then  
                       this_read_addr := read_addr + 1;
                   end if;
                end if;
            else
                this_read_addr := read_addr + 1;
            end if;                   

            i_packet_out_valid_last <= i_packet_out_valid;
            read_data <= data_buffer(to_integer(this_read_addr));
            read_addr <= this_read_addr;
        end if;
    end process;

process(clk) 
    variable write_data : std_logic_vector(8 downto 0);    
    begin
        if rising_edge(clk) then
            -------------------------------------------------
            -- Writing the data into the buffer. If the buffer
            -- would overrun the then packet is dropped (i.e.
            -- committed_addr will not be updated).
            ------------------------------------------------
            case write_state is
                when write_writing =>                  
                    if write_addr+1 = read_addr then
                        -------------------------------------------------------
                        -- If we would wrap around? Is so then abort the packet
                        -------------------------------------------------------
                        write_addr  <= committed_addr; 
                        write_state <= write_aborted;                     
                    else
                        write_addr <= write_addr + 1;
                        if data_valid_in = '0' then
                            committed_addr <= write_addr;
                            write_state    <= write_idle;
                        end if;
                    end if;
                when write_aborted =>
                    ---------------------------------------------------------
                    -- Wait until the data_valid_in drop at the end of packet
                    ---------------------------------------------------------
                    if data_valid_in = '0' then
                        write_state <= write_idle;
                    end if;

                when others => -- write_idle state 
                    if data_valid_in = '1' then   
                        write_addr <= write_addr + 1;
                        write_state <= write_writing;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;