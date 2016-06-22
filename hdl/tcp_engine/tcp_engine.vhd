----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: tcp_engine - Behavioral
--
-- Description: Implement the TCP/IP session protocol.
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

entity tcp_engine is 
    port (  clk                : in  STD_LOGIC;
            -- data received over TCP/IP
            tcp_rx_data_valid    : in  std_logic := '0';
            tcp_rx_data          : in  std_logic_vector(7 downto 0) := (others => '0');
            
            tcp_rx_hdr_valid     : in  std_logic := '0';
            tcp_rx_src_ip        : in  std_logic_vector(31 downto 0) := (others => '0');
            tcp_rx_src_port      : in  std_logic_vector(15 downto 0) := (others => '0');
            tcp_rx_dst_broadcast : in  std_logic := '0';
            tcp_rx_dst_port      : in  std_logic_vector(15 downto 0) := (others => '0');    
            tcp_rx_seq_num       : in  std_logic_vector(31 downto 0) := (others => '0');
            tcp_rx_ack_num       : in  std_logic_vector(31 downto 0) := (others => '0');
            tcp_rx_window        : in  std_logic_vector(15 downto 0) := (others => '0');
            tcp_rx_flag_urg      : in  std_logic := '0';
            tcp_rx_flag_ack      : in  std_logic := '0';
            tcp_rx_flag_psh      : in  std_logic := '0';
            tcp_rx_flag_rst      : in  std_logic := '0';
            tcp_rx_flag_syn      : in  std_logic := '0';
            tcp_rx_flag_fin      : in  std_logic := '0';
            tcp_rx_urgent_ptr    : in  std_logic_vector(15 downto 0) := (others => '0');

  	        -- data to be sent over TP
            tcp_tx_busy          : in  std_logic := '0';
            tcp_tx_data_valid    : out std_logic := '0';
            tcp_tx_data          : out std_logic_vector(7 downto 0) := (others => '0');
              
            tcp_tx_hdr_valid     : out std_logic := '0';
            tcp_tx_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
            tcp_tx_dst_ip        : out std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_dst_port      : out std_logic_vector(15 downto 0) := (others => '0');    
            tcp_tx_seq_num       : out std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_ack_num       : out std_logic_vector(31 downto 0) := (others => '0');
            tcp_tx_window        : out std_logic_vector(15 downto 0) := (others => '0');
            tcp_tx_flag_urg      : out std_logic := '0';
            tcp_tx_flag_ack      : out std_logic := '0';
            tcp_tx_flag_psh      : out std_logic := '0';
            tcp_tx_flag_rst      : out std_logic := '0';
            tcp_tx_flag_syn      : out std_logic := '0';
            tcp_tx_flag_fin      : out std_logic := '0';
            tcp_tx_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0'));
end tcp_engine;

architecture Behavioral of tcp_engine is
    component tcp_engine_seq_generator is
        port (
            clk  : in  std_logic;
            seq  : out std_logic_vector(31 downto 0) := (others => '0'));
    end component;
    signal random_seq_num   : std_logic_vector(31 downto 0) := (others => '0');
    
    signal send_enable  : std_logic := '0';
    signal send_ack     : std_logic := '0';
    signal send_rst     : std_logic := '0';
    signal send_fin     : std_logic := '0';
    signal send_syn_ack : std_logic := '0';

    signal session_src_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal session_dst_ip     : std_logic_vector(31 downto 0) := (others => '0');
    signal session_dst_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal session_seq_num    : std_logic_vector(31 downto 0) := (others => '0');
    signal session_ack_num    : std_logic_vector(31 downto 0) := (others => '0');
    signal session_window     : std_logic_vector(15 downto 0) := (others => '0');
    signal session_urgent_ptr : std_logic_vector(15 downto 0) := (others => '0');
    signal session_data_addr  : std_logic_vector(15 downto 0) := (others => '0');
    signal session_data_len   : std_logic_vector(10 downto 0) := (others => '0');

    signal session_flag_urg   : std_logic := '0';
    signal session_flag_ack   : std_logic := '0';
    signal session_flag_psh   : std_logic := '0';
    signal session_flag_rst   : std_logic := '0';
    signal session_flag_syn   : std_logic := '0';
    signal session_flag_fin   : std_logic := '0';
    
    type t_state is (state_closed,      state_listen,     state_syn_rcvd,   state_syn_sent, 
                     state_established, state_fin_wait_1, state_fin_wait_2, state_closing, 
                     state_time_wait,   state_close_wait, state_last_ack);
    signal state            : t_state := state_closed;
    signal last_state       : t_state := state_closed;

    signal timeout          : std_logic := '0';
    signal timeout_counter  : unsigned(29 downto 0);

    component tcp_engine_tx_fifo is
    Port ( clk : in STD_LOGIC;
        write_en         : in  std_logic := '0';
        full             : out std_logic := '0';
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
        
        read_en           : in  std_logic := '0';
        empty             : out std_logic := '0';
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
        out_data_addr     : out std_logic_vector(15 downto 0) := (others => '0');
        out_data_len      : out std_logic_vector(10 downto 0) := (others => '0'));
    end component;

    signal fifo_read_en       : std_logic := '0';
    signal fifo_empty         : std_logic := '0';
    signal fifo_hdr_valid     : std_logic := '0';
    signal fifo_src_port      : std_logic_vector(15 downto 0) := (others => '0');
    signal fifo_dst_ip        : std_logic_vector(31 downto 0) := (others => '0');
    signal fifo_dst_port      : std_logic_vector(15 downto 0) := (others => '0');    
    signal fifo_seq_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal fifo_ack_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal fifo_window        : std_logic_vector(15 downto 0) := (others => '0');
    signal fifo_flag_urg      : std_logic := '0';
    signal fifo_flag_ack      : std_logic := '0';
    signal fifo_flag_psh      : std_logic := '0';
    signal fifo_flag_rst      : std_logic := '0';
    signal fifo_flag_syn      : std_logic := '0';
    signal fifo_flag_fin      : std_logic := '0';
    signal fifo_urgent_ptr    : std_logic_vector(15 downto 0) := (others => '0');    
    signal fifo_data_addr     : std_logic_vector(15 downto 0) := (others => '0');
    signal fifo_data_len      : std_logic_vector(10 downto 0) := (others => '0');

    component tcp_engine_add_data is 
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
    end component;
     
begin

i_tcp_engine_seq_generator: tcp_engine_seq_generator port map (
        clk => clk,
        seq => random_seq_num);

timeout_proc: process(clk)
    begin
        if rising_edge(clk) then
            timeout <= '0';
            if last_state /= state then
                timeout_counter <= to_unsigned(5*125_000_000,30); -- 5 seconds                
                timeout <= '0';
            elsif timeout_counter = 0 then
                timeout <= '1';
            else
                if state = state_syn_rcvd then
                    timeout_counter <= timeout_counter - 1;
                end if;
            end if;
            last_state <= state; 
        end if;        
    end process;

process(clk)
    begin
        if rising_edge(clk) then
            send_ack     <= '0';
            send_rst     <= '0';
            send_fin     <= '0';
            send_syn_ack <= '0';

            case state is
                when state_closed =>
                    -- Passive open
                    state <= state_listen;
                when state_listen =>
                    -- Is this a SYN packet
                    if tcp_rx_hdr_valid = '1' and tcp_rx_flag_syn = '1' then
                        if tcp_rx_dst_port = x"0016" then
                            -- Send an empty ACK
                            send_syn_ack <='1';                            
                            -- Remeber current session state
                            session_src_port <= tcp_rx_dst_port;
                            session_dst_ip   <= tcp_rx_src_ip;
                            session_dst_port <= tcp_rx_src_port;
                            session_seq_num  <= random_seq_num;
                            session_ack_num  <= tcp_rx_seq_num;
                            session_window   <= x"2000";
                            state <= state_syn_rcvd;
                        else
                            send_rst  <='1';                            
                            -- Remeber current session state
                            session_src_port <= tcp_rx_dst_port;
                            session_dst_ip   <= tcp_rx_src_ip;
                            session_dst_port <= tcp_rx_src_port;
                            session_seq_num  <= (others => '0');
                            session_ack_num  <= (others => '0');
                            session_window   <= x"2000";
                            state <= state_syn_rcvd;
                        end if;
                    end if;
                when state_syn_rcvd =>
                    -- Are we seeing a retransmit of the SYN packet
                    if tcp_rx_hdr_valid = '1' then 
                        if tcp_rx_flag_syn = '1' then                    
                            if tcp_rx_dst_port = x"0016" then
                                -- Send an empty ACK
                                send_syn_ack <='1';                            
                                -- Remeber current session state
                                session_src_port <= tcp_rx_dst_port;
                                session_dst_ip   <= tcp_rx_src_ip;
                                session_dst_port <= tcp_rx_src_port;
                                session_seq_num  <= random_seq_num;
                                session_ack_num  <= tcp_rx_seq_num;
                                session_window   <= x"2000";
                                state <= state_syn_rcvd;
                            end if;
                        elsif tcp_rx_flag_ack = '1' then
                            -- Are we getting the ACK from the other end?
                            if tcp_rx_dst_port = session_src_port and  tcp_rx_src_ip = session_dst_ip and tcp_rx_src_port = session_dst_port then 
                                if tcp_rx_ack_num = session_seq_num then
                                    state <= state_established;
                                end if;
                            end if;    
                        end if;
                    else
                        if timeoute = '1' then
                            send_syn_rst  <='1';                            
                            -- Remeber current session state
                            session_src_port <= tcp_rx_dst_port;
                            session_dst_ip   <= tcp_rx_src_ip;
                            session_dst_port <= tcp_rx_src_port;
                            session_seq_num  <= (others => '0');
                            session_ack_num  <= (others => '0');
                            session_window   <= x"2000";
                            state <= state_syn_rcvd;
                        end if;
                    end if;
                when state_syn_sent =>
                    if tcp_rx_hdr_valid = '1' then
                        if tcp_rx_dst_port = session_src_port and  tcp_rx_src_ip = session_dst_ip and tcp_rx_src_port = session_dst_port then 
                            if tcp_rx_flag_ack = '1' then
                                if tcp_rx_flag_syn = '1' then
                                    -- Syn+ACK is a simulatanious open
                                    if tcp_rx_ack_num = session_seq_num then
                                        send_ack <='1';
                                        state <= state_established;
                                    end if;
                                else
                                    -- ACK
                                    if tcp_rx_ack_num = session_seq_num then
                                        send_syn_ack <='1';
                                        state <= state_established;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                when state_established =>
                    if tcp_rx_hdr_valid = '1' then
                        if tcp_rx_dst_port = session_src_port and  tcp_rx_src_ip = session_dst_ip and tcp_rx_src_port = session_dst_port then 
                            if tcp_rx_ack_num = session_seq_num then
                                if tcp_rx_flag_ack = '1' then
                                    send_ack <='1';
                                    state <= state_close_wait;
                                end if;
                            end if;
                        end if;                                        
                    end if;                
                    
                when state_fin_wait_1  =>
                    if tcp_rx_hdr_valid = '1' then
                        if tcp_rx_dst_port = session_src_port and  tcp_rx_src_ip = session_dst_ip and tcp_rx_src_port = session_dst_port then 
                            if tcp_rx_ack_num = session_seq_num then
                                if tcp_rx_flag_ack = '1' and tcp_rx_flag_fin = '1' then
                                    send_ack <='1';
                                    state <= state_time_wait;
                                elsif tcp_rx_flag_ack = '1' then
                                    send_ack <='1';
                                    state <= state_fin_wait_2;
                                elsif tcp_rx_flag_fin = '1' then
                                    send_ack <='1';
                                    state <= state_fin_wait_2;
                                end if;
                            end if;
                        end if;                                        
                    end if;                
                when state_fin_wait_2  =>
                    if tcp_rx_dst_port = session_src_port and  tcp_rx_src_ip = session_dst_ip and tcp_rx_src_port = session_dst_port then 
                        if tcp_rx_ack_num = session_seq_num then
                            if tcp_rx_flag_fin = '1' then
                                send_ack <='1';
                                state <= state_time_wait;
                            end if;
                        end if;                                        
                    end if;                
                when state_closing     =>
                    if tcp_rx_hdr_valid = '1' then
                        if tcp_rx_dst_port = session_src_port and  tcp_rx_src_ip = session_dst_ip and tcp_rx_src_port = session_dst_port then 
                            if tcp_rx_ack_num = session_seq_num then
                                if tcp_rx_flag_ack = '1' then
                                    state <= state_time_wait;
                                end if;
                            end if;                                        
                        end if;                
                    end if;                
                when state_time_wait   =>
                    if timeout = '1' then
                        state <= state_closed;
                    end if;
                when state_close_wait  =>
                    send_fin <= '1';
                    state <= state_last_ack; 
                when state_last_ack    =>
                    if tcp_rx_hdr_valid = '1' then
                        if tcp_rx_dst_port = session_src_port and  tcp_rx_src_ip = session_dst_ip and tcp_rx_src_port = session_dst_port then 
                            if tcp_rx_ack_num = session_seq_num then
                                if tcp_rx_flag_ack = '1' then
                                    state <= state_closed;
                                end if;
                            end if;
                        end if;                                        
                    end if;                                        
            end case;
        end if;
    end process;

send_packets: process(clk)
    begin
        if rising_edge(clk) then
            send_enable  <= '0';
            if send_ack = '1' then
                send_enable        <= '1';
                session_data_addr  <= (others => '0');
                session_data_len   <= (others => '0');                        
                session_flag_urg   <= '0';
                session_flag_ack   <= '1';
                session_flag_psh   <= '0';
                session_flag_rst   <= '0';
                session_flag_syn   <= '0';
                session_flag_fin   <= '0';
            elsif send_syn_ack = '1' then
                send_enable        <= '1';
                session_data_addr  <= (others => '0');
                session_data_len   <= (others => '0');                        
                session_flag_urg   <= '0';
                session_flag_ack   <= '1';
                session_flag_psh   <= '0';
                session_flag_rst   <= '0';
                session_flag_syn   <= '1';
                session_flag_fin   <= '0';
            elsif send_fin = '1' then
                send_enable        <= '1';
                session_data_addr  <= (others => '0');
                session_data_len   <= (others => '0');                        
                session_flag_urg   <= '0';
                session_flag_ack   <= '0';
                session_flag_psh   <= '0';
                session_flag_rst   <= '0';
                session_flag_syn   <= '0';
                session_flag_fin   <= '1';
            elsif send_rst = '1' then
                send_enable        <= '1';
                session_data_addr  <= (others => '0');
                session_data_len   <= (others => '0');                        
                session_flag_urg   <= '0';
                session_flag_ack   <= '0';
                session_flag_psh   <= '0';
                session_flag_rst   <= '1';
                session_flag_syn   <= '0';
                session_flag_fin   <= '0';
            end if; 
        end if;
    end process;

i_tcp_engine_tx_fifo: tcp_engine_tx_fifo port map (
        clk            => clk,
        write_en       => send_enable,
        full           => open,
        in_src_port    => session_src_port,
        in_dst_ip      => session_dst_ip,
        in_dst_port    => session_dst_port,    
        in_seq_num     => session_seq_num,
        in_ack_num     => session_ack_num,
        in_window      => session_window,
        in_flag_urg    => session_flag_urg,
        in_flag_ack    => session_flag_ack,
        in_flag_psh    => session_flag_psh,
        in_flag_rst    => session_flag_rst,
        in_flag_syn    => session_flag_syn,
        in_flag_fin    => session_flag_fin,
        in_urgent_ptr  => session_urgent_ptr,    
        in_data_addr   => session_data_addr,
        in_data_len    => session_data_len,
        
        read_en        => fifo_read_en,
        empty          => fifo_empty,
        out_src_port   => fifo_src_port,
        out_dst_ip     => fifo_dst_ip,
        out_dst_port   => fifo_dst_port,    
        out_seq_num    => fifo_seq_num,
        out_ack_num    => fifo_ack_num,
        out_window     => fifo_window,
        out_flag_urg   => fifo_flag_urg,
        out_flag_ack   => fifo_flag_ack,
        out_flag_psh   => fifo_flag_psh,
        out_flag_rst   => fifo_flag_rst,
        out_flag_syn   => fifo_flag_syn,
        out_flag_fin   => fifo_flag_fin,
        out_urgent_ptr => fifo_urgent_ptr,    
        out_data_addr  => fifo_data_addr,
        out_data_len   => fifo_data_len);

i_tcp_engine_add_data: tcp_engine_add_data port map (
        clk            => clk,

        read_en        => fifo_read_en,
        empty          => fifo_empty,

        in_src_port    => fifo_src_port,
        in_dst_ip      => fifo_dst_ip,
        in_dst_port    => fifo_dst_port,    
        in_seq_num     => fifo_seq_num,
        in_ack_num     => fifo_ack_num,
        in_window      => fifo_window,
        in_flag_urg    => fifo_flag_urg,
        in_flag_ack    => fifo_flag_ack,
        in_flag_psh    => fifo_flag_psh,
        in_flag_rst    => fifo_flag_rst,
        in_flag_syn    => fifo_flag_syn,
        in_flag_fin    => fifo_flag_fin,
        in_urgent_ptr  => fifo_urgent_ptr,    
        in_data_addr   => fifo_data_addr,
        in_data_len    => fifo_data_len,
        
        out_hdr_valid  => tcp_tx_hdr_valid, 
        out_src_port   => tcp_tx_src_port,
        out_dst_ip     => tcp_tx_dst_ip,
        out_dst_port   => tcp_tx_dst_port,    
        out_seq_num    => tcp_tx_seq_num,
        out_ack_num    => tcp_tx_ack_num,
        out_window     => tcp_tx_window,
        out_flag_urg   => tcp_tx_flag_urg,
        out_flag_ack   => tcp_tx_flag_ack,
        out_flag_psh   => tcp_tx_flag_psh,
        out_flag_rst   => tcp_tx_flag_rst,
        out_flag_syn   => tcp_tx_flag_syn,
        out_flag_fin   => tcp_tx_flag_fin,
        out_urgent_ptr => tcp_tx_urgent_ptr,    
        out_data       => tcp_tx_data,
        out_data_valid => tcp_tx_data_valid);
          
end Behavioral;