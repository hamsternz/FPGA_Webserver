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

            status               : out std_logic_vector(7 downto 0) := (others => '0');    
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
    constant listen_port : std_logic_vector(15 downto 0) := x"0050";

    component tcp_engine_session_filter is 
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
            out_seq_num       : out std_logic_vector(31 downto 0) := (others => '0');
            out_ack_num       : out std_logic_vector(31 downto 0) := (others => '0');
            out_window        : out std_logic_vector(15 downto 0) := (others => '0');
            out_from_ip       : out std_logic_vector(31 downto 0) := (others => '0');
            out_from_port     : out std_logic_vector(15 downto 0) := (others => '0');
            out_flag_urg      : out std_logic := '0';
            out_flag_ack      : out std_logic := '0';
            out_flag_psh      : out std_logic := '0';
            out_flag_rst      : out std_logic := '0';
            out_flag_syn      : out std_logic := '0';
            out_flag_fin      : out std_logic := '0';
            out_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0'));
    end component;

    signal session_data_valid : std_logic := '0';
    signal session_data       : std_logic_vector(7 downto 0) := (others => '0');
    signal session_hdr_valid  : std_logic := '0';
    signal session_from_ip    : std_logic_vector(31 downto 0) := (others => '0');
    signal session_from_port  : std_logic_vector(15 downto 0) := (others => '0');
    signal session_seq_num    : std_logic_vector(31 downto 0) := (others => '0');
    signal session_ack_num    : std_logic_vector(31 downto 0) := (others => '0');
    signal session_window     : std_logic_vector(15 downto 0) := (others => '0');
    signal session_flag_urg   : std_logic := '0';
    signal session_flag_ack   : std_logic := '0';
    signal session_flag_psh   : std_logic := '0';
    signal session_flag_rst   : std_logic := '0';
    signal session_flag_syn   : std_logic := '0';
    signal session_flag_fin   : std_logic := '0';
    signal session_urgent_ptr : std_logic_vector(15 downto 0) := (others => '0');

    component tcp_engine_seq_generator is
        port (
            clk  : in  std_logic;
            seq  : out std_logic_vector(31 downto 0) := (others => '0'));
    end component;
    signal random_seq_num   : std_logic_vector(31 downto 0) := (others => '0');
    
    signal send_enable    : std_logic := '0';
    signal send_ack       : std_logic := '0';
    signal send_some_data : std_logic := '0';
    signal send_rst       : std_logic := '0';
    signal send_fin       : std_logic := '0';
    signal send_syn_ack   : std_logic := '0';
    signal send_fin_ack   : std_logic := '0';
    
    -- For sending packets
    signal tosend_seq_num      : std_logic_vector(31 downto 0) := (others => '0');
    signal tosend_ack_num      : std_logic_vector(31 downto 0) := (others => '0');
    signal tosend_seq_num_next : std_logic_vector(31 downto 0) := (others => '0');

    signal tosend_data_addr  : std_logic_vector(15 downto 0) := (others => '0');
    signal tosend_data_len   : std_logic_vector(10 downto 0) := (others => '0');
    signal tosend_urgent_ptr : std_logic_vector(15 downto 0) := (others => '0');
    signal tosend_flag_urg   : std_logic := '0';
    signal tosend_flag_ack   : std_logic := '0';
    signal tosend_flag_psh   : std_logic := '0';
    signal tosend_flag_rst   : std_logic := '0';
    signal tosend_flag_syn   : std_logic := '0';
    signal tosend_flag_fin   : std_logic := '0';
    signal tosend_window     : std_logic_vector(15 downto 0) := x"2000";
    
    type t_state is (state_dropping,    state_closed,     state_listen,     state_syn_rcvd,   state_syn_sent, 
                     state_established, state_rx_data,    state_fin_wait_1, state_fin_wait_2, 
                     state_closing,     state_time_wait,  state_close_wait, state_last_ack);
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
    
    COMPONENT ila_0
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT  ;
    signal session_connected : std_logic := '0';
    signal drop_connection   : std_logic := '0';
begin

process(clK)
    begin
        if rising_edge(clk) then
            case state is
                when state_dropping    => status <= x"01";
                when state_closed      => status <= x"02";
                when state_listen      => status <= x"03";
                when state_syn_rcvd    => status <= x"04";
                when state_syn_sent    => status <= x"05";
                when state_established => status <= x"06";
                when state_rx_data     => status <= x"07";
                when state_fin_wait_1  => status <= x"08";
                when state_fin_wait_2  => status <= x"09";
                when state_closing     => status <= x"0A";
                when state_time_wait   => status <= x"0B";
                when state_close_wait  => status <= x"0C";
                when state_last_ack    => status <= x"0D";
                when others            => status <= x"FF";
            end case;
            status(7) <= session_connected;
        end if;
    end process;
 debug : ila_0
  PORT MAP (
	clk => clk,

	probe0(0) => session_hdr_valid, 
	probe1    => session_data, 
	probe2(0) => session_data_valid, 
	probe3(0) => session_flag_ack, 
	probe4(0) => session_flag_rst,
	probe5 => fifo_data_len(7 downto 0));

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

i_tcp_engine_session_filter: tcp_engine_session_filter port map ( 
        clk => clk,

        listen_port      => listen_port,
        drop_connection  => drop_connection,
        connected        => session_connected,
            
        in_data_valid    => tcp_rx_data_valid,
        in_data          => tcp_rx_data,
        
        in_hdr_valid     => tcp_rx_hdr_valid,
        in_src_ip        => tcp_rx_src_ip,
        in_src_port      => tcp_rx_src_port,
        in_dst_port      => tcp_rx_dst_port,    
        in_seq_num       => tcp_rx_seq_num,
        in_ack_num       => tcp_rx_ack_num,
        in_window        => tcp_rx_window,
        in_flag_urg      => tcp_rx_flag_urg,
        in_flag_ack      => tcp_rx_flag_ack,
        in_flag_psh      => tcp_rx_flag_psh,
        in_flag_rst      => tcp_rx_flag_rst,
        in_flag_syn      => tcp_rx_flag_syn,
        in_flag_fin      => tcp_rx_flag_fin,
        in_urgent_ptr    => tcp_rx_urgent_ptr,

        out_data_valid   => session_data_valid,
        out_data         => session_data,

        out_hdr_valid    => session_hdr_valid,
        out_from_ip      => session_from_ip,
        out_from_port    => session_from_port,    
        out_seq_num      => session_seq_num,
        out_ack_num      => session_ack_num,
        out_window       => session_window,
        out_flag_urg     => session_flag_urg,
        out_flag_ack     => session_flag_ack,
        out_flag_psh     => session_flag_psh,
        out_flag_rst     => session_flag_rst,
        out_flag_syn     => session_flag_syn,
        out_flag_fin     => session_flag_fin,
        out_urgent_ptr   => session_urgent_ptr);

process(clk)
    begin
        if rising_edge(clk) then
            drop_connection <= '0';
            send_ack        <= '0';
            send_rst        <= '0';
            send_fin        <= '0';
            send_syn_ack    <= '0';
            send_some_data  <= '0';
            case state is
                when state_dropping =>
                    drop_connection <= '1';
                    state <= state_closed;
                when state_closed =>
                    -- Passive open
                    if session_connected = '0' then
                        state <= state_listen;
                    end if;

                when state_listen =>
                    -- Is this a SYN packet
                    if session_connected = '1' then
                        send_syn_ack    <='1';                
                        tosend_ack_num  <= std_logic_vector(unsigned(session_seq_num) + 1);
                        state           <= state_syn_rcvd;
                    end if;

                when state_syn_rcvd => 
                    if session_hdr_valid = '1' then 
                        if session_flag_syn = '1' then                    
                           -- We are seeing a retransmit of the SYN packet
                            tosend_ack_num  <= std_logic_vector(unsigned(session_seq_num) + 1);
                            send_syn_ack <='1';                            
                        elsif session_flag_ack = '1' then
                            -- We are getting the ACK from the other end
                            if unsigned(session_ack_num) = unsigned(tosend_seq_num)+1 then
                                state <= state_established;
                            end if;
                        end if;
                    elsif timeout = '1' then
                        -- We haven't seen an ACK
                        send_rst  <= '1';                            
                        state <= state_closing;
                    end if;

                when state_syn_sent =>
                    -- This is only used for active opens, so we don't use it.
                    NULL;

                when state_established =>
                    if session_hdr_valid = '1' then
                        if session_flag_ack = '1' then
                            if session_ack_num = tosend_seq_num then
                                if session_data_valid = '1' then
                                    tosend_ack_num  <= std_logic_vector(unsigned(tosend_ack_num) + 1);
                                    state <= state_rx_data;
                                end if;
                                if  session_flag_fin = '1' then
                                    send_fin_ack    <= '1';                            
                                    tosend_ack_num  <= std_logic_vector(unsigned(tosend_ack_num) + 1);
                                    state <= state_fin_wait_1;
                                end if;
                            end if;
                        end if;                                        
                    end if;     

                when state_rx_data =>
                    -- Receive a byte, and when finished send an ACK and wait for more.
                    if session_data_valid = '1' then
                        tosend_ack_num  <= std_logic_vector(unsigned(tosend_ack_num) + 1);
                    else
                        send_ack         <= '1';
                        send_some_data   <= '1';                        
                        -- Send with the sequence we have acked up to
                        state            <= state_established;
                    end if;
                    
                when state_fin_wait_1  =>
                    if session_hdr_valid = '1' then
                        if session_ack_num = tosend_seq_num then
                            if session_flag_ack = '1' and session_flag_fin = '1' then
                                send_ack <='1';
                                state <= state_time_wait;
                            elsif session_flag_ack = '1' then
                                send_ack <='1';
                                state <= state_fin_wait_2;
                            elsif session_flag_fin = '1' then
                                send_ack <='1';
                                state <= state_fin_wait_2;
                            end if;
                        end if;
                    end if;                                        

                when state_fin_wait_2  =>
                    if session_hdr_valid = '1' then
                        if session_ack_num = tosend_seq_num then
                            if session_flag_fin = '1' then
                                send_ack <='1';
                                state <= state_time_wait;
                            end if;
                        end if;                                        
                    end if;                

                when state_closing     =>
                    if tcp_rx_hdr_valid = '1' then
                        if session_ack_num = tosend_seq_num then
                            if tcp_rx_flag_ack = '1' then
                                state <= state_time_wait;
                            end if;
                        end if;                                        
                    end if;                

                when state_time_wait   =>
                    if timeout = '1' then
                        state <= state_closing;
                    end if;

                when state_close_wait  =>
                    send_fin <= '1';
                    state <= state_last_ack; 

                when state_last_ack    =>
                    if tcp_rx_hdr_valid = '1' then
                        if session_ack_num = tosend_seq_num then
                            if tcp_rx_flag_ack = '1' then
                                state <= state_dropping;
                            end if;
                        end if;                                        
                    end if;                                        
            end case;
        end if;
    end process;

send_packets: process(clk)
    begin
        if rising_edge(clk) then
            -------------------------------------------------
            -- This block is to set up the initial sequence  
            -- numbers during the initial three-way handshake
            -------------------------------------------------
            if state = state_listen then
                if session_connected = '1' then
                    tosend_seq_num       <= random_seq_num;
                    tosend_seq_num_next  <= random_seq_num;
                end if;
            elsif state = state_syn_rcvd then
                if session_hdr_valid = '1' then 
                    if session_flag_syn = '0' and session_flag_ack = '1' then
                        -- We are seing a ACK with the correct sequence number
                        if unsigned(session_ack_num) = unsigned(tosend_seq_num) + 1 then
                            tosend_seq_num      <= std_logic_vector(unsigned(tosend_seq_num) + 1);
                            tosend_seq_num_next <= std_logic_vector(unsigned(tosend_seq_num) + 1);
                        end if;
                    end if;
                end if;
            end if;

            -------------------------------------------------
            -- Sending out packets
            -------------------------------------------------
            send_enable  <= '0';
            if send_ack = '1' then
                send_enable        <= '1';
                
                -- Send a few bytes of data with every ACK
                tosend_data_addr  <= (others => '0');
                if send_some_data = '1' then
                    -- This won't work, as we are notupdating the sequence number correctly 
                   tosend_data_len  <= "00000000100";
                   tosend_seq_num_next <= std_logic_vector(unsigned(tosend_seq_num)+4); 
                else
                   tosend_data_len   <= (others => '0');
                end if;                    
                
                tosend_flag_urg   <= '0';
                tosend_flag_ack   <= '1';
                tosend_flag_psh   <= '0';
                tosend_flag_rst   <= '0';
                tosend_flag_syn   <= '0';
                tosend_flag_fin   <= '0';
            elsif send_syn_ack = '1' then
                send_enable        <= '1';
                tosend_data_addr  <= (others => '0');
                tosend_data_len   <= (others => '0');                        
                tosend_flag_urg   <= '0';
                tosend_flag_ack   <= '1';
                tosend_flag_psh   <= '0';
                tosend_flag_rst   <= '0';
                tosend_flag_syn   <= '1';
                tosend_flag_fin   <= '0';
            elsif send_fin_ack = '1' then
                send_enable        <= '1';
                tosend_data_addr  <= (others => '0');
                tosend_data_len   <= (others => '0');                        
                tosend_flag_urg   <= '0';
                tosend_flag_ack   <= '1';
                tosend_flag_psh   <= '0';
                tosend_flag_rst   <= '0';
                tosend_flag_syn   <= '0';
                tosend_flag_fin   <= '1';
            elsif send_fin = '1' then
                send_enable        <= '1';
                tosend_data_addr  <= (others => '0');
                tosend_data_len   <= (others => '0');                        
                tosend_flag_urg   <= '0';
                tosend_flag_ack   <= '0';
                tosend_flag_psh   <= '0';
                tosend_flag_rst   <= '0';
                tosend_flag_syn   <= '0';
                tosend_flag_fin   <= '1';
            elsif send_rst = '1' then
                send_enable        <= '1';
                tosend_data_addr  <= (others => '0');
                tosend_data_len   <= (others => '0');                        
                tosend_flag_urg   <= '0';
                tosend_flag_ack   <= '0';
                tosend_flag_psh   <= '0';
                tosend_flag_rst   <= '1';
                tosend_flag_syn   <= '0';
                tosend_flag_fin   <= '0';
                tosend_seq_num       <= (others => '0');
                tosend_seq_num_next  <= (others => '0');
            end if; 
        end if;
    end process;

i_tcp_engine_tx_fifo: tcp_engine_tx_fifo port map (
        clk            => clk,
        write_en       => send_enable,
        full           => open,
        in_src_port    => listen_port,
        in_dst_ip      => session_from_ip,
        in_dst_port    => session_from_port,    
        in_seq_num     => tosend_seq_num,
        in_ack_num     => tosend_ack_num,
        in_window      => tosend_window,
        in_flag_urg    => tosend_flag_urg,
        in_flag_ack    => tosend_flag_ack,
        in_flag_psh    => tosend_flag_psh,
        in_flag_rst    => tosend_flag_rst,
        in_flag_syn    => tosend_flag_syn,
        in_flag_fin    => tosend_flag_fin,
        in_urgent_ptr  => tosend_urgent_ptr,    
        in_data_addr   => tosend_data_addr,
        in_data_len    => tosend_data_len,
        
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