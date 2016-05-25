----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.05.2016 22:30:18
-- Design Name: 
-- Module Name: rx_arp_request - Behavioral
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

entity rx_arp is
    Port ( clk               : in  STD_LOGIC;
           packet_data       : in  STD_LOGIC_VECTOR (7 downto 0);
           packet_data_valid : in  STD_LOGIC;
           
           arp_de         : out STD_LOGIC;
           arp_op_request : out STD_LOGIC;
           arp_sender_hw  : out STD_LOGIC_VECTOR(47 downto 0);
           arp_sender_ip  : out STD_LOGIC_VECTOR(31 downto 0);
           arp_target_hw  : out STD_LOGIC_VECTOR(47 downto 0);
           arp_target_ip  : out STD_LOGIC_VECTOR(31 downto 0));
end rx_arp;

architecture Behavioral of rx_arp is
    signal ethertype_data  : std_logic_vector(15 downto 0)      := (others => '0');
    signal data            : std_logic_vector(8*28-1 downto 0) := (others => '0');
    signal hwtype          : std_logic_vector(15 downto 0)      := (others => '0');
    signal ptype           : std_logic_vector(15 downto 0)      := (others => '0');
    signal hlen            : std_logic_vector(7 downto 0)       := (others => '0');
    signal plen            : std_logic_vector(7 downto 0)       := (others => '0');
    signal op              : std_logic_vector(15 downto 0)      := (others => '0');
    signal sender_hw       : std_logic_vector(47 downto 0)      := (others => '0');
    signal sender_ip       : std_logic_vector(31 downto 0)      := (others => '0');
    signal target_hw       : std_logic_vector(47 downto 0)      := (others => '0');
    signal target_ip       : std_logic_vector(31 downto 0)      := (others => '0');
    
    signal ethertype_valid : std_logic := '0';
    signal hwtype_valid    : std_logic := '0';
    signal ptype_valid     : std_logic := '0';
    signal len_valid       : std_logic := '0';
    signal op_valid        : std_logic := '0';
    signal op_request      : std_logic := '0';
    
    signal packet_valid_delay  : std_logic := '0';
    
    signal valid_count     : unsigned(5 downto 0) := (others => '0');
begin
    ---------------------------------------------
    -- Breaking out fields for easy reference
    -------------------------------------------
	hwtype      <= data( 7+8*0+8  downto 0+8*0+8) & data(15+8*0+8  downto 8+8*0+8);
	ptype       <= data( 7+8*2+8  downto 0+8*2+8) & data(15+8*2+8  downto 8+8*2+8);
	hlen        <= data( 7+8*4+8  downto 0+8*4+8);
	plen        <= data(15+8*4+8  downto 8+8*4+8);
	op          <= data( 7+8*6+8  downto 0+8*6+8) & data(15+8*6+8  downto 8+8*6+8);

	
process(clk)
    begin
        if rising_edge(clk) then
            arp_de           <= '0';
            arp_op_request   <= op_request;
            arp_sender_hw    <= sender_hw;
            arp_sender_ip    <= sender_ip;
            arp_target_hw    <= target_hw;
            arp_target_ip    <= target_ip;
            if ethertype_valid = '1' and hwtype_valid = '1' and ptype_valid = '1' and   
               len_valid       = '1' and op_valid     = '1' and valid_count = 41  then
               arp_de           <= '1';
            end if;

            sender_hw  <= data(15+8*12+8 downto 0+8*8+8);
            sender_ip  <= data(15+8*16+8 downto 0+8*14+8);
            target_hw  <= data(15+8*22+8 downto 0+8*18+8);
            target_ip  <= packet_data & data(15+8*26 downto 0+8*24+8);

            ethertype_valid <= '0';
            hwtype_valid    <= '0';
            ptype_valid     <= '0';
            op_valid        <= '0';
            op_request      <= '0';
            len_valid       <= '0';

            ---------------------------------
            -- Validate the ethernet protocol 
            ---------------------------------
            if ethertype_data = x"0806" then
                ethertype_valid <= '1';
            end if;

            ----------------------------
            -- Validate operation code
            ----------------------------
            if hwtype = x"0001" then
                hwtype_valid <= '1';
            end if;

            if ptype = x"0800" then
                ptype_valid <= '1';
            end if;
            
            ----------------------------
            -- Validate operation code
            ----------------------------
            if op = x"0001" then
                op_valid      <= '1';
                op_request <= '1';
            end if;
            
            if op = x"0002" then
                op_valid      <= '1';
                op_request <= '0';
            end if;

            if hlen = x"06" and plen = x"04" then
                len_valid <= '1';
            end if;
            -------------------------------------------
            -- Move the data through the shift register
            -------------------------------------------
            ethertype_data <= ethertype_data(7 downto 0) & data(15 downto 8);
            data      <= packet_data & data(data'high downto 8);
            if packet_valid_delay = '1' then
                if valid_count /= 63 then  -- Clamp at max value
                   valid_count <= valid_count+1;
                end if;
            else
                valid_count <= (others => '0');
            end if;
            packet_valid_delay <= packet_data_valid;
        end if;
    end process;
end Behavioral;
