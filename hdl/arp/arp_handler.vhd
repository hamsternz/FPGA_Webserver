----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.05.2016 22:29:27
-- Design Name: 
-- Module Name: arp_handler - Behavioral
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
        our_ip      : std_logic_vector(31 downto 0) := (others => '0'));
    port (  clk              : in  STD_LOGIC;
            packet_in_valid  : in  STD_LOGIC;
            packet_in_data   : in  STD_LOGIC_VECTOR (7 downto 0);
            -- For receiving data from the PHY        
            packet_out_req   : out std_logic := '0';
            packet_out_grant : in  std_logic := '0';
            packet_out_valid : out std_logic;         
            packet_out_data  : out std_logic_vector(7 downto 0);         
             -- to enable IP->MAC lookup for outbound packets
            lookup_request   : in  std_logic;
            lookup_ip        : in  std_logic_vector(31 downto 0);
            lookup_mac       : out std_logic_vector(47 downto 0);
            lookup_found     : out std_logic;
            lookup_reply     : out std_logic);
end arp_handler;

architecture Behavioral of arp_handler is
    type t_arp_table is array(0 to 255) of std_logic_vector(47 downto 0);
    type t_arp_valid is array(0 to 255) of std_logic;
    signal arp_table : t_arp_table := (255 => (others => '1'), others => (others => '0'));
    signal arp_valid : t_arp_valid := (255 => '1', others => '0');

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

    signal arp_in_write       : STD_LOGIC;
    signal arp_in_full        : STD_LOGIC;
    signal arp_in_op_request  : STD_LOGIC;
    signal arp_in_src_hw      : STD_LOGIC_VECTOR(47 downto 0);
    signal arp_in_src_ip      : STD_LOGIC_VECTOR(31 downto 0);
    signal arp_in_tgt_hw      : STD_LOGIC_VECTOR(47 downto 0);
    signal arp_in_tgt_ip      : STD_LOGIC_VECTOR(31 downto 0);

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
        packet_req    : out std_logic := '0';
        packet_grant  : in  std_logic := '0';
        packet_de     : out std_logic := '0'; 
        packet_valid  : out std_logic;
        packet_data   : out std_logic_vector(7 downto 0));
    end component;


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
            ------------------------------------------------------------
            -- Process any MAC lookups
            ------------------------------------------------------------
            if lookup_request = '1' then
                if lookup_ip(23 downto 0) = our_ip(23 downto 0) then
                    lookup_mac   <= arp_table(to_integer(unsigned(lookup_ip(31 downto 24))));
                    lookup_found <= arp_valid(to_integer(unsigned(lookup_ip(31 downto 24))));
                    lookup_reply <= '1';
                else
                    lookup_found <= '0';
                    lookup_reply <= '1';
                end if;
            else
                lookup_reply <= '0';
            end if;
        
            ------------------------------------------------------------
            -- Process any requests or replys
            ------------------------------------------------------------
            if arp_in_write = '0' then
                arp_tx_write           <= '0';
            elsif arp_in_src_ip(23 downto 0) /= our_ip(23 downto 0) or arp_in_src_ip(7 downto 0) = x"FF" then
                arp_tx_write           <= '0';
            else
                arp_table(to_integer(unsigned(arp_in_src_ip(31 downto 24)))) <= arp_in_src_hw;
                arp_valid(to_integer(unsigned(arp_in_src_ip(31 downto 24)))) <= '1';
                if arp_in_op_request = '1' and arp_in_tgt_ip = our_ip and arp_tx_full = '0' then
                    -- Queue any outbound replys
                    arp_tx_write      <= '1';
                    arp_tx_op_request <= '0';
                    arp_tx_src_hw     <= our_mac;
                    arp_tx_src_ip     <= our_ip;                                         
                    arp_tx_tgt_hw     <= arp_in_src_hw;
                    arp_tx_tgt_ip     <= arp_in_src_ip;                   
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
           
        packet_req      => packet_out_req,
        packet_grant    => packet_out_grant,
        packet_data     => packet_out_data, 
        packet_valid    => packet_out_valid);

end Behavioral;
