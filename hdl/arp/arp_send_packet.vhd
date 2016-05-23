-----------------------------------------------------------------------
-- arp_send_packet.vhd 
--
-- When we need to send a packet packet_req is asserted
-- When packet grant is asserted, the data is emitted.
-- Once all data is emitted, packet_req is no longer asserted
--
-- The expectation is that if the interface is running slower than
-- 8x the clock rate (e.g. in 100BaseT mode) then this will stream into
-- a FIFO, which will then be sent out at a slower rate.
--
-- The src hardware address and protocol address will most likely
-- be constants, so it should be a lot smaller than you would expect.
-----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity arp_send_packet is
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
end arp_send_packet;

architecture Behavioral of arp_send_packet is
    signal counter : unsigned(7 downto 0) := (others => '0');    
begin

generate_fifo_read: process(counter, arp_fifo_empty, packet_grant)
	begin
		arp_fifo_read <= '0';
		-- Read from the FIFO the same cycle that we are granted to use the output data bus.
		if counter = 0 and arp_fifo_empty = '0' then 
			-- As soon as granted, the counter will be incremented,
			-- so there will only be a one cycle pulse.
			arp_fifo_read <= packet_grant;
		end if;
	end process;

generate_data: process (clk) 
    begin
        if rising_edge(clk) then
			-- Do we need to request the output interface
			if counter = x"00" and arp_fifo_empty = '0' then           
				packet_req <= '1';
			end if;	

			-- Are we in the middle of a packet? 
			if counter /= x"00" then
				counter <= counter + 1;
			end if;	
			
			-- Have we just been allowed to start sending the packet?
			if counter = x"00" and packet_grant = '1' then
				counter <= counter + 1;
			end if;

            -- Note, this uses the current value of counter, not the one assigned above!
            case to_integer(counter) is 
				when  0 => packet_data <= "00000000";	-- We pause at 0 count when idle 
				-----------------------------
				-- Ethernet Header 
				-----------------------------
				-- Destination MAC address
				when  1 => packet_data <= arp_tgt_hw(47 downto 40); packet_valid <= '1';
				when  2 => packet_data <= arp_tgt_hw(39 downto 32);
				when  3 => packet_data <= arp_tgt_hw(31 downto 24);
				when  4 => packet_data <= arp_tgt_hw(23 downto 16);
				when  5 => packet_data <= arp_tgt_hw(15 downto  8);
				when  6 => packet_data <= arp_tgt_hw( 7 downto  0);
				-- Source MAC address
				when  7 => packet_data <= arp_src_hw(47 downto 40);
				when  8 => packet_data <= arp_src_hw(39 downto 32);
				when  9 => packet_data <= arp_src_hw(31 downto 24);
				when 10 => packet_data <= arp_src_hw(23 downto 16);
				when 11 => packet_data <= arp_src_hw(15 downto  8);
				when 12 => packet_data <= arp_src_hw( 7 downto  0);
				------------------------ 
				-- ARP packet
				------------------------ 
				when 13 => packet_data <= x"08"; -- Ether Type 08:06  << ARP!
				when 14 => packet_data <= x"06";

				when 15 => packet_data <= x"00"; -- Media type
				when 16 => packet_data <= x"01";

				when 17 => packet_data <= x"08"; -- Protocol (IP)
				when 18 => packet_data <= x"00";

				when 19 => packet_data <= x"06"; -- Hardware address length
				when 20 => packet_data <= x"04"; -- Protocol address length
				-- Operation
				when 21 => packet_data <= x"00";
				when 22 => if arp_op_request = '1' then
			                   packet_data <= x"01"; -- request
						   else
			                   packet_data <= x"02"; -- reply
						   end if;
				-- Target MAC 
				when 23 => packet_data <= arp_tgt_hw(47 downto 40);
				when 24 => packet_data <= arp_tgt_hw(39 downto 32);
				when 25 => packet_data <= arp_tgt_hw(31 downto 24);
				when 26 => packet_data <= arp_tgt_hw(23 downto 16);
				when 27 => packet_data <= arp_tgt_hw(15 downto  8);
				when 28 => packet_data <= arp_tgt_hw( 7 downto  0);
				-- Target IP
				when 29 => packet_data <= arp_tgt_ip(31 downto 24);
				when 30 => packet_data <= arp_tgt_ip(23 downto 16);
				when 31 => packet_data <= arp_tgt_ip(15 downto  8);
				when 32 => packet_data <= arp_tgt_ip( 7 downto  0);
				-- Source MAC
				when 33 => packet_data <= arp_src_hw(47 downto 40);
				when 34 => packet_data <= arp_src_hw(39 downto 32);
				when 35 => packet_data <= arp_src_hw(31 downto 24);
				when 36 => packet_data <= arp_src_hw(23 downto 16);
				when 37 => packet_data <= arp_src_hw(15 downto  8);
				when 38 => packet_data <= arp_src_hw( 7 downto  0);
				-- Source IP
				when 39 => packet_data <= arp_src_ip(31 downto 24);
				when 40 => packet_data <= arp_src_ip(23 downto 16);
				when 41 => packet_data <= arp_src_ip(15 downto  8);
				when 42 => packet_data <= arp_src_ip( 7 downto  0);
				-- We can release the bus now and go back to the idle state.
				when 43 => counter <= (others => '0'); packet_valid <= '0'; packet_req <= '0';
                when others => NULL;
            end case;
         end if;    
    end process;
end Behavioral;