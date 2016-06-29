----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: buffer_count_and_checksum_data - Behavioral
-- 
-- Description: Count and checksum the data to be put into a UDP or TCP packet 
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

entity buffer_count_and_checksum_data is
    generic (min_length    : natural);
    Port ( 
       clk             : in  STD_LOGIC;
       hdr_valid_in    : in  STD_LOGIC;
       data_valid_in   : in  STD_LOGIC;
       data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
       data_valid_out  : out STD_LOGIC                     := '0';
       data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
       data_length     : out std_logic_vector(15 downto 0) := (others => '0');
       data_checksum   : out std_logic_vector(15 downto 0) := (others => '0'));  
end buffer_count_and_checksum_data;

architecture Behavioral of buffer_count_and_checksum_data is
    type a_data_buffer is array (0 to 2047) of std_logic_vector(8 downto 0);

    signal write_ptr          : unsigned(10 downto 0) := (others => '0');
    signal read_ptr           : unsigned(10 downto 0) := (others => '1');
    signal checkpoint         : unsigned(10 downto 0) := (others => '1');
    signal data_buffer        : a_data_buffer := (others =>( others => '0'));
    attribute ram_style : string;
    attribute ram_style of data_buffer : signal is "block";

    signal data_count         : unsigned(10 downto 0) := to_unsigned(128,11);
    signal wrote_valid_data   : std_logic := '0';
    signal data_valid_in_last : std_logic := '0';
    signal checksum           : unsigned(16 downto 0) := (others => '0');
    
    signal read_data    : std_logic_vector(8 downto 0) := (others => '0');
begin
    data_valid_out <= read_data(8);
    data_out       <= read_data(7 downto 0);
    
infer_dp_mem_process: process(clk)
    variable write_data   : std_logic_vector(8 downto 0) := (others => '0');
    variable write_enable : std_logic; 
    begin
         if rising_edge(clk) then
            write_enable := '0';
            
            if data_valid_in = '1' then
                write_data       := data_valid_in & data_in;
                write_enable     := '1';
                wrote_valid_data <= '1';
            elsif hdr_valid_in = '1' then
                write_data       := '1'& x"00";
                write_enable     := '1';            
                wrote_valid_data <= '0';
            elsif data_count < min_length-4 then  -- Minimum UDP datasize to make minimum ethernet frame
                -- Padding to make minimum packet size
                write_data       := '1'& x"00";
                write_enable     := '1';
                wrote_valid_data <= '1';
            else
                write_data       := '0'& x"00";
                write_enable     := wrote_valid_data;
                wrote_valid_data <= '0';
            end if;          

            if write_enable = '1' then
                data_buffer(to_integer(write_ptr)) <= write_data;
            end if;
            read_data <= data_buffer(to_integer(read_ptr));
        end if;
    end process;
    
main_proc: process(clk) 
    variable v_checksum : unsigned(16 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            if data_valid_in = '1' or hdr_valid_in = '1' or data_valid_in_last = '1' or data_count < min_length-3 then
                write_ptr <= write_ptr + 1; 
            end if;


            if data_valid_in = '1' then
                if data_valid_in_last = '0' then
                    data_count <= to_unsigned(1,11);
                else
                    data_count <= data_count + 1;
                end if;
            elsif hdr_valid_in = '1' then
                -----------------------------------------------------
                --For when there is no data to be sent, just a packet
                -----------------------------------------------------
                data_count <= to_unsigned(1,11);
            end if;
            
            
            if data_valid_in = '1' then
                --- Update the checksum here
                if data_count(0) = '0' or data_valid_in_last = '0' then
                    checksum <= to_unsigned(0,17) + checksum(15 downto 0) + checksum(16 downto 16) + (unsigned(data_in) & to_unsigned(0,8));
                else
                    checksum <= to_unsigned(0,17) + checksum(15 downto 0) + checksum(16 downto 16) + unsigned(data_in); 
                end if;
            else  -- data_valid_in  = '0'
                if hdr_valid_in = '1' and data_valid_in = '0' then
                    data_length   <= (others => '0');
                    data_checksum <= (others =>'0'); 
                elsif data_valid_in_last = '1' then
                    -- End of packet
                    v_checksum    := to_unsigned(0,17) + checksum(15 downto 0) + checksum(16 downto 16);
                    data_checksum <= std_logic_vector(v_checksum(15 downto 0) + v_checksum(16 downto 16));
                    data_length   <= "00000" & std_logic_vector(data_count);
                end if;

                -- This is where padding is added
                if data_count < min_length-3 then
                    data_count <= data_count + 1;
                else
                    -- Enough data so checkpoint it
                    checkpoint <= write_ptr-1;
                end if;

                checksum   <= (others => '0');
            end if;

            data_valid_in_last <= data_valid_in;
            
            if read_ptr /= checkpoint then
                read_ptr <= read_ptr+1;
            end if;
        end if;
    end process;
end Behavioral;
