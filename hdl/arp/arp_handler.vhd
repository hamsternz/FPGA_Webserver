----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: arp_handler - Behavioral
--
-- Description: Processing for ARP packets. 
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
------------------------------------------------------------------------------------

------------- From the RFC ---------------------------------------
-- 1: ?Do I have the hardware type in ar$hrd?
-- 2: Yes: (almost definitely)
-- 3:  [optionally check the hardware length ar$hln] 
-- 4:  ?Do I speak the protocol in ar$pro?
-- 5:  Yes:
-- 6:    [optionally check the protocol length ar$pln]
-- 7:    Merge_flag := false
-- 8:    If the pair <protocol type, sender protocol address> is
-- 9:        already in my translation table, update the sender
--10:        hardware address field of the entry with the new
--11:        information in the packet and set Merge_flag to true. 
--12:    ?Am I the target protocol address?
--13:    Yes:
--14:      If Merge_flag is false, add the triplet <protocol type,
--15:          sender protocol address, sender hardware address> to
--16:          the translation table.
--17:      ?Is the opcode ares_op$REQUEST?  (NOW look at the opcode!!)
--18:      Yes:
--20:        Swap hardware and protocol fields, putting the local
--21:        hardware and protocol addresses in the sender fields.
--22:        Set the ar$op field to ares_op$REPLY
--23:        Send the packet to the (new) target hardware address on
--24:	      the same hardware on which the request was received.
-------------------------------------------------------------------
-- Lines 1 - 6 : Has already been checked in the RX_ARP module.
-- Lines 7 & 11: Any ARP packet that comes through will update the 256-entry table, 
--               always forcing Merge_flag to be true.
-- Line 12     : Need to compare against my IP address - if match then
-- Lines 14-16 : Can be ignored as Merge Flag is true
-- Lines 17    : The op_request field can be used as the CE for the outbound FIFO
-- Lines 20-24 : Requires the our MAC address to place in the etherent and ARP header

--	To send an ARP reply we need to queue the following:
--		ce                  <= (op_request)
--		dest eth MAC        <= src eth MAC
--      src eth MAC         <= our eth MAC
--      src hw address      <= our eth MAC
--      src prot address    <= our IP address
--		op                  <= REPLY
--      target hw address   <= src hw address
--      target prot address <= src prot address
--
--	To start ARP discovery we need to queue the following:
--		ce                  <= '1'
--		dest eth MAC        <= FF:FF:FF:FF:FF:FF
--      src eth MAC         <= our eth MAC
--      src hw address      <= our eth MAC
--      src prot address    <= our IP address
--	    op                  <= REQUEST
--      target hw address   <= Desired IP Address
--      target prot address <= 00:00:00:00:00:00


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity arp_handler is 
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0');
        our_ip      : std_logic_vector(31 downto 0) := (others => '0');
        our_netmask : std_logic_vector(31 downto 0) := (others => '0'));
    port (  clk                : in  STD_LOGIC;
            packet_in_valid    : in  STD_LOGIC;
            packet_in_data     : in  STD_LOGIC_VECTOR (7 downto 0);
            -- For receiving data from the PHY        
            packet_out_request : out std_logic := '0';
            packet_out_granted : in  std_logic := '0';
            packet_out_valid   : out std_logic;         
            packet_out_data    : out std_logic_vector(7 downto 0);
            
            -- For the wider design to send any ARP on the wire 
		    queue_request    : in  std_logic;
            queue_request_ip : in  std_logic_vector(31 downto 0);
                     
             -- to enable IP->MAC lookup for outbound packets
            update_valid       : out std_logic := '0';
            update_ip          : out std_logic_vector(31 downto 0) := (others => '0');
            update_mac         : out std_logic_vector(47 downto 0) := (others => '0'));
end arp_handler;

architecture Behavioral of arp_handler is
    component rx_arp is
    Port ( clk               : in  STD_LOGIC;
           packet_data_valid : in  STD_LOGIC;
           packet_data       : in  STD_LOGIC_VECTOR (7 downto 0);
           
           arp_de             : out STD_LOGIC;
           arp_op_request     : out STD_LOGIC;
           arp_sender_hw      : out STD_LOGIC_VECTOR(47 downto 0);
           arp_sender_ip      : out STD_LOGIC_VECTOR(31 downto 0);
           arp_target_hw      : out STD_LOGIC_VECTOR(47 downto 0);
           arp_target_ip      : out STD_LOGIC_VECTOR(31 downto 0));
    end component;

    signal arp_tx_write    : std_logic                     := '0';
    signal arp_tx_full     : std_logic                     := '0';
    signal arp_tx_op_request  : std_logic                     := '0';
    signal arp_tx_src_hw   : std_logic_vector(47 downto 0) := our_mac;
    signal arp_tx_src_ip   : std_logic_vector(31 downto 0) := our_ip;
    signal arp_tx_tgt_hw   : std_logic_vector(47 downto 0) := (others => '0');
    signal arp_tx_tgt_ip   : std_logic_vector(31 downto 0) := our_ip;

    signal arp_in_write       : STD_LOGIC := '0';
    signal arp_in_full        : STD_LOGIC := '0';
    signal arp_in_op_request  : STD_LOGIC := '0';
    signal arp_in_src_hw      : STD_LOGIC_VECTOR(47 downto 0) := (others => '0');
    signal arp_in_src_ip      : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal arp_in_tgt_hw      : STD_LOGIC_VECTOR(47 downto 0) := (others => '0');
    signal arp_in_tgt_ip      : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    component arp_tx_fifo
        Port ( clk                : in  STD_LOGIC;

               arp_in_write       : in  STD_LOGIC;
               arp_in_full        : out STD_LOGIC;
               arp_in_op_request  : in  STD_LOGIC;
               arp_in_tgt_hw      : in  STD_LOGIC_VECTOR(47 downto 0);
               arp_in_tgt_ip      : in  STD_LOGIC_VECTOR(31 downto 0);

               arp_out_empty      : out std_logic;
               arp_out_read       : in  std_logic                    := '0';
               arp_out_op_request : out std_logic;
               arp_out_tgt_hw     : out std_logic_vector(47 downto 0);
               arp_out_tgt_ip     : out std_logic_vector(31 downto 0));
    end component;

    signal arp_out_empty      : std_logic;
    signal arp_out_read       : std_logic                    := '0';
    signal arp_out_op_request : std_logic;
    signal arp_out_src_hw     : std_logic_vector(47 downto 0);
    signal arp_out_src_ip     : std_logic_vector(31 downto 0);
    signal arp_out_tgt_hw     : std_logic_vector(47 downto 0);
    signal arp_out_tgt_ip     : std_logic_vector(31 downto 0);

    component arp_send_packet 
	Port ( clk            : in  STD_LOGIC;
        -- Interface to the outgoing ARP queue
        arp_fifo_empty : in  std_logic;
        arp_fifo_read  : out std_logic := '0';
        arp_op_request : in  std_logic;
        arp_src_hw     : in  std_logic_vector(47 downto 0);
        arp_src_ip     : in  std_logic_vector(31 downto 0);
        arp_tgt_hw     : in  std_logic_vector(47 downto 0);
        arp_tgt_ip     : in  std_logic_vector(31 downto 0);
        -- Interface into the Ethernet TX subsystem
        packet_request  : out std_logic := '0';
        packet_granted  : in  std_logic := '0';
        packet_valid  : out std_logic;
        packet_data   : out std_logic_vector(7 downto 0));
    end component;

    signal hold_request    : std_logic := '0';
    signal hold_request_ip : std_logic_vector(31 downto 0) := (others => '0');
    
begin

i_rx_arp: rx_arp Port map ( 
        clk               => clk,

        packet_data_valid => packet_in_valid,
        packet_data       => packet_in_data,
           
        arp_de           => arp_in_write,
        arp_op_request   => arp_in_op_request,
        arp_sender_hw    => arp_in_src_hw,
        arp_sender_ip    => arp_in_src_ip,
        arp_target_hw    => arp_in_tgt_hw,
        arp_target_ip    => arp_in_tgt_ip);


process(clk) 
    begin
        if rising_edge(clk) then
            if arp_in_write = '0' or ((arp_in_src_ip and our_netmask) /= (our_ip and our_netmask))then
                -- If there is no write , or it is not for our IP subnet then ignore it
                -- and queue any request for a new ARP broadcast
                update_valid <= '0';
                arp_tx_write <= '0';
                if queue_request = '1' then
                    arp_tx_write      <= '1';
                    arp_tx_op_request <= '1';
                    arp_tx_src_hw     <= our_mac;
                    arp_tx_src_ip     <= our_ip;                                         
                    arp_tx_tgt_hw     <= (others => '0');
                    arp_tx_tgt_ip     <= queue_request_ip;
                elsif hold_request = '1' then
                    -- if a request was delayed, then write it. 
                    arp_tx_write      <= '1';
                    arp_tx_op_request <= '1';
                    arp_tx_src_hw     <= our_mac;
                    arp_tx_src_ip     <= our_ip;                                         
                    arp_tx_tgt_hw     <= (others => '0');
                    arp_tx_tgt_ip     <= hold_request_ip;
                    hold_request      <= '0';
                end if;
            else
                -- It is a write for our subnet, so update the ARP resolver table.
                update_valid <= '1';
                update_ip    <= arp_in_src_ip;
                update_mac   <= arp_in_src_hw;
                if arp_in_op_request = '1' and arp_in_tgt_ip = our_ip and arp_tx_full = '0' then
                    -- And if it is a request for our MAC, then send it
                    -- by queuing the outbound reply
                    arp_tx_write      <= '1';
                    arp_tx_op_request <= '0';
                    arp_tx_src_hw     <= our_mac;
                    arp_tx_src_ip     <= our_ip;                                         
                    arp_tx_tgt_hw     <= arp_in_src_hw;
                    arp_tx_tgt_ip     <= arp_in_src_ip;
                    -- If the request to send an ARP packet gets gazumped by a request
                    -- from the wire, then hold onto it to and send it next.
                    hold_request      <= queue_request;
                    hold_request_ip   <= queue_request_ip;
                end if; 
            end if;
        end if;
    end process;

i_arp_tx_fifo: arp_tx_fifo Port map ( 
        clk                => clk,            
        arp_in_write       => arp_tx_write,
        arp_in_full        => arp_tx_full,
        arp_in_op_request  => arp_tx_op_request,
        arp_in_tgt_hw      => arp_tx_tgt_hw,
        arp_in_tgt_ip      => arp_tx_tgt_ip,
    
        arp_out_empty      => arp_out_empty,
        arp_out_read       => arp_out_read,
        arp_out_op_request => arp_out_op_request,
        arp_out_tgt_hw     => arp_out_tgt_hw,
        arp_out_tgt_ip     => arp_out_tgt_ip);

i_arp_send_packet: arp_send_packet port map (
        clk             => clk,

        arp_fifo_empty  => arp_out_empty,
        arp_fifo_read   => arp_out_read,
        arp_op_request  => arp_out_op_request,
        arp_src_hw      => our_mac,
        arp_src_ip      => our_ip,
        arp_tgt_hw      => arp_out_tgt_hw,
        arp_tgt_ip      => arp_out_tgt_ip,
           
        packet_request  => packet_out_request,
        packet_granted  => packet_out_granted,
        packet_data     => packet_out_data, 
        packet_valid    => packet_out_valid);

end Behavioral;
