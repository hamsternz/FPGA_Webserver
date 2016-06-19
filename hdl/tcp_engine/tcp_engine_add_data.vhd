----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: tcp_engine_add_data - Behavioral
--
-- Description: Add the data stream alongsude the packet header
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

entity tcp_engine_add_data is
    Port ( clk : in STD_LOGIC;
        read_en          : out std_logic := '0';
        empty            : in  std_logic := '0';
        
        in_src_port      : in  std_logic_vector(15 downto 0) := (others => '0');
        in_dst_ip        : in  std_logic_vector(31 downto 0) := (others => '0');
        in_dst_port      : in  std_logic_vector(15 downto 0) := (others => '0');    
        in_seq_num       : in  std_logic_vector(31 downto 0) := (others => '0');
        in_ack_num       : in  std_logic_vector(31 downto 0) := (others => '0');
        in_window        : in  std_logic_vector(15 downto 0) := (others => '0');
        in_flag_urg      : in  std_logic := '0';
        in_flag_ack      : in  std_logic := '0';
        in_flag_psh      : in  std_logic := '0';
        in_flag_rst      : in  std_logic := '0';
        in_flag_syn      : in  std_logic := '0';
        in_flag_fin      : in  std_logic := '0';
        in_urgent_ptr    : in  std_logic_vector(15 downto 0) := (others => '0');    
        in_data_addr     : in  std_logic_vector(15 downto 0) := (others => '0');
        in_data_len      : in  std_logic_vector(10 downto 0) := (others => '0');
        
        out_hdr_valid     : out  std_logic := '0';
        out_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
        out_dst_ip        : out std_logic_vector(31 downto 0) := (others => '0');
        out_dst_port      : out std_logic_vector(15 downto 0) := (others => '0');    
        out_seq_num       : out std_logic_vector(31 downto 0) := (others => '0');
        out_ack_num       : out std_logic_vector(31 downto 0) := (others => '0');
        out_window        : out std_logic_vector(15 downto 0) := (others => '0');
        out_flag_urg      : out std_logic := '0';
        out_flag_ack      : out std_logic := '0';
        out_flag_psh      : out std_logic := '0';
        out_flag_rst      : out std_logic := '0';
        out_flag_syn      : out std_logic := '0';
        out_flag_fin      : out std_logic := '0';
        out_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0');    
        out_data_valid    : out std_logic := '0';
        out_data          : out std_logic_vector(7 downto 0) := (others => '0'));
end tcp_engine_add_data;

architecture Behavioral of tcp_engine_add_data is
    type t_state is (waiting, reading, new_packet, first_data, adding_data, no_data);
    signal state : t_state := waiting;
    signal address         : std_logic_vector(15 downto 0) := (others => '0');
    signal data_left_to_go : unsigned(10 downto 0) := (others => '0');
    component tcp_engine_content_memory is
        port (
            clk     : in std_logic;
            address : in std_logic_vector(15 downto 0);
            data    : out std_logic_vector(7 downto 0));
    end component;
begin

process(clk)
    begin
        if rising_edge(clk) then
            read_en <= '0';
            out_hdr_valid <= '0';
            out_data_valid <= '0';
            address <= std_logic_vector(unsigned(address)+1);
            data_left_to_go <= data_left_to_go-1;
            case state is
                when waiting     =>
                    if empty = '1' then
                        read_en <= '1';
                        state <= reading;
                     end if;
                when reading     =>
                     state <= new_packet;
                when new_packet  =>
                     if unsigned(in_data_len) = 0 then
                        state <= no_data;
                     else
                        state   <= first_data;
                        address <= in_data_addr;
                        data_left_to_go <= unsigned(in_data_len)-1;
                     end if;                     
                when first_data => 
                    out_hdr_valid  <= '1';
                    out_data_valid <= '1';
                    if data_left_to_go = 0 then
                        state <= waiting;
                    else
                        state <= adding_data;
                    end if;
                when adding_data =>
                    out_data_valid <= '1';
                    if data_left_to_go = 0 then
                        state <= waiting;
                    else
                        state <= adding_data;
                    end if;
                when no_data =>
                    out_hdr_valid <= '1';
                    state        <= waiting;
                when others => 
                    state        <= waiting;
            end case;
        end if;
        
        -- Can't be bothered coding a memory at the moment
        out_data <= std_logic_vector(address(7 downto 0));
    end process;
i_tcp_engine_content_memory: tcp_engine_content_memory port map (
    clk => clk,
    address => address,
    data    => out_data );
end Behavioral;
