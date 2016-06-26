----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.06.2016 16:36:27
-- Design Name: 
-- Module Name: tcp_engine_session_filter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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

entity tcp_engine_session_filter is
port (  clk              : in  STD_LOGIC;

        listen_port      : in  std_logic_vector(15 downto 0) := (others => '0');
        drop_connection  : in  STD_LOGIC;
        connected        : out STD_LOGIC;
        
        -- data received over TCP/IP
        in_data_valid    : in  std_logic := '0';
        in_data          : in  std_logic_vector(7 downto 0) := (others => '0');
        
        in_hdr_valid     : in  std_logic := '0';
        in_src_ip        : in  std_logic_vector(31 downto 0) := (others => '0');
        in_src_port      : in  std_logic_vector(15 downto 0) := (others => '0');
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

        out_data_valid    : out std_logic := '0';
        out_data          : out std_logic_vector(7 downto 0) := (others => '0');
        
        out_hdr_valid     : out std_logic := '0';
        out_from_ip       : out std_logic_vector(31 downto 0) := (others => '0');
        out_from_port     : out std_logic_vector(15 downto 0) := (others => '0');
        out_seq_num       : out std_logic_vector(31 downto 0) := (others => '0');
        out_ack_num       : out std_logic_vector(31 downto 0) := (others => '0');
        out_window        : out std_logic_vector(15 downto 0) := (others => '0');
        out_flag_urg      : out std_logic := '0';
        out_flag_ack      : out std_logic := '0';
        out_flag_psh      : out std_logic := '0';
        out_flag_rst      : out std_logic := '0';
        out_flag_syn      : out std_logic := '0';
        out_flag_fin      : out std_logic := '0';
        out_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0'));
end tcp_engine_session_filter;

architecture Behavioral of tcp_engine_session_filter is
    signal i_connected : std_logic := '0';
    signal do_drop     : std_logic := '0';
    
    signal session_src_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal session_src_ip     : std_logic_vector(31 downto 0) := (others => '0');    
begin
    connected <= i_connected;
    out_from_ip   <= session_src_ip;
    out_from_port <= session_src_port;
        
clk_proc: process(clk)
    begin
        if rising_edge(clk) then
            if i_connected = '1' then
                if do_drop  = '1' and in_data_valid = '0' and in_hdr_valid = '0' then
                    -- Drop the connection
                    i_connected <= '0';
                    out_data_valid   <= '0';
                    out_hdr_valid    <= '0';
                    do_drop <= '0';
                else     
                    out_data_valid <= in_data_valid;
                    out_hdr_valid  <= in_hdr_valid;
                end if;
            else
                if in_hdr_valid = '1' then
                    if in_dst_port = listen_port and in_flag_syn = '1' then
                        i_connected <= '1';
                        session_src_port <= in_src_port;
                        session_src_ip   <= in_src_ip;

                        out_data_valid <= in_data_valid;
                        out_hdr_valid  <= in_hdr_valid;
                    end if;                    
                end if;
            end if;
            -- Copy non-key data over anyway (just don't assert the valid siganls!
            out_data       <= in_data;
            out_seq_num    <= in_seq_num;
            out_ack_num    <= in_ack_num;
            out_window     <= in_window;
            out_flag_urg   <= in_flag_urg;
            out_flag_ack   <= in_flag_ack;
            out_flag_psh   <= in_flag_psh;
            out_flag_rst   <= in_flag_rst;
            out_flag_syn   <= in_flag_syn;
            out_flag_fin   <= in_flag_fin;
            out_urgent_ptr <= in_urgent_ptr;
            
            -- Remember if we are asked to drop the connection
            if do_drop = '0' then
               do_drop <= drop_connection;
            end if;
        end if;
    end process;
end Behavioral;
