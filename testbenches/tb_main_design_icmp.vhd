----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.05.2016 21:14:53
-- Design Name: 
-- Module Name: tb_main_design_icmp - Behavioral
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
--
-- 16:24:47.966461 IP (tos 0x0, ttl 128, id 15103, offset 0, flags [none],
-- proto: ICMP (1), length: 60) 192.168.146.22 > 192.168.144.5: ICMP echo request,
-- id 1, seq 38, length 40
--        0x0000:  4500 003c 3aff 0000 8001 5c55 c0a8 9216  E..<:.....\U....
--        0x0010:  c0a8 9005 0800 4d35 0001 0026 6162 6364  ......M5...&abcd
--        0x0020:  6566 6768 696a 6b6c 6d6e 6f70 7172 7374  efghijklmnopqrst
--        0x0030:  7576 7761 6263 6465 6667 6869            uvwabcdefghi
--
-----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity tb_main_design_icmp is
end tb_main_design_icmp;

architecture Behavioral of tb_main_design_icmp is
    signal clk125Mhz          : STD_LOGIC := '0';
    signal clk125Mhz90        : STD_LOGIC := '0';
    signal phy_ready          : STD_LOGIC := '1';
    signal status             : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    
    signal input_empty        : STD_LOGIC := '0';           
    signal input_read         : STD_LOGIC := '0';           
    signal input_data         : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal input_data_present : STD_LOGIC := '0';
    signal input_data_error   : STD_LOGIC := '0';

    component main_design is
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0');
        our_ip      : std_logic_vector(31 downto 0) := (others => '0'));
    Port ( 
       clk125Mhz          : in  STD_LOGIC;
       clk125Mhz90        : in  STD_LOGIC;
       input_empty        : in  STD_LOGIC;           
       input_read         : out STD_LOGIC;           
       input_data         : in  STD_LOGIC_VECTOR (7 downto 0);
       input_data_present : in  STD_LOGIC;
       input_data_error   : in  STD_LOGIC;

       phy_ready          : in  STD_LOGIC;
       status             : out STD_LOGIC_VECTOR (3 downto 0);
       
       eth_txck           : out std_logic := '0';
       eth_txctl          : out std_logic := '0';
       eth_txd            : out std_logic_vector(3 downto 0) := (others => '0'));
    end component;
    
    signal eth_txck           : std_logic := '0';
    signal eth_txctl          : std_logic := '0';
    signal eth_txd            : std_logic_vector(3 downto 0) := (others => '0');

    signal count  : integer := 999;
    signal count2 : integer := 180;
    
    signal arp_src_hw      : std_logic_vector(47 downto 0) := x"a0b3cc4cf9ef";
    signal arp_src_ip      : std_logic_vector(31 downto 0) := x"0A000001";
    signal arp_tgt_hw      : std_logic_vector(47 downto 0) := x"ab8967452301";
    signal arp_tgt_ip      : std_logic_vector(31 downto 0) := x"0A00000A";

begin

process
    begin
        clk125Mhz <= '1';
        wait for 2 ns;
        clk125Mhz90 <= '1';
        wait for 2 ns;
        clk125Mhz <= '0';
        wait for 2 ns;
        clk125Mhz90 <= '0';
        wait for 2 ns;
    end process;

i_main_design: main_design
    generic map (
        our_mac => arp_tgt_hw,
        our_ip => arp_tgt_ip) 
    port map (
       clk125Mhz          => clk125Mhz,
       clk125Mhz90        => clk125Mhz90,
       
       input_empty        => input_empty,           
       input_read         => input_read,           
       input_data         => input_data,
       input_data_present => input_data_present,
       input_data_error   => input_data_error,

       phy_ready          => phy_ready,
       status             => status,
       
       eth_txck           => eth_txck,
       eth_txctl          => eth_txctl,
       eth_txd            => eth_txd);

process(clk125MHz)
    begin
        if rising_edge(clk125MHz) then
            if count < 86 then 
                input_empty <= '0';
            else
                input_empty <= '1';
            end if;

            if count2 = 200 then
                count  <= 0;
                count2 <= 0;
            else
                count2 <= count2+1;
            end if;

            if input_read = '1' then
                if count = 87 then
                    count <= 0;
                else
                    count <= count + 1;
                end if;
                
                case count is
                    -----------------------------
                    -- Ethernet preamble
                    -----------------------------
                    when      0 => input_data <= x"55"; input_data_present <= '1';
                    when      1 => input_data <= x"55"; 
                    when      2 => input_data <= x"55"; 
                    when      3 => input_data <= x"55"; 
                    when      4 => input_data <= x"55"; 
                    when      5 => input_data <= x"55";
                    when      6 => input_data <= x"55";
                    when      7 => input_data <= x"D5";
                    -----------------------------
                    -- Ethernet Header 
                    -----------------------------
                    -- Destination MAC address
                    when      8 => input_data <= arp_tgt_hw(47 downto 40);
                    when      9 => input_data <= arp_tgt_hw(39 downto 32);
                    when     10 => input_data <= arp_tgt_hw(31 downto 24);
                    when     11 => input_data <= arp_tgt_hw(23 downto 16);
                    when     12 => input_data <= arp_tgt_hw(15 downto  8);
                    when     13 => input_data <= arp_tgt_hw( 7 downto  0);
                   -- Source MAC address
                    when     14 => input_data <= arp_src_hw(47 downto 40);
                    when     15 => input_data <= arp_src_hw(39 downto 32);
                    when     16 => input_data <= arp_src_hw(31 downto 24);
                    when     17 => input_data <= arp_src_hw(23 downto 16);
                    when     18 => input_data <= arp_src_hw(15 downto  8);
                    when     19 => input_data <= arp_src_hw( 7 downto  0);
					-- Ethernet frame tyoe
                    when     20 => input_data <= x"08"; -- Ether Type 08:00 - IP
                    when     21 => input_data <= x"00";
                    ------------------------ 
                    -- IP Header 
                    ------------------------ 
                    when     22 => input_data <= x"45";  -- Protocol & Header Len
                    when     23 => input_data <= x"00";
                    when     24 => input_data <= x"00";  -- Length
                    when     25 => input_data <= x"3C";
                    when     26 => input_data <= x"5d";  -- Identificaiton
                    when     27 => input_data <= x"15";
                    when     28 => input_data <= x"00";  -- Flags and offset
                    when     29 => input_data <= x"00";
                    when     30 => input_data <= x"80";  -- TTL
                    when     31 => input_data <= x"01";  -- Protocol
                    when     32 => input_data <= x"c9";  -- Checksum
                    when     33 => input_data <= x"a1";
                    when     34 => input_data <= x"0A";  -- Source IP Address
                    when     35 => input_data <= x"00";
                    when     36 => input_data <= x"00";
                    when     37 => input_data <= x"01";
                    when     38 => input_data <= x"0A";  -- Destination IP address
                    when     39 => input_data <= x"00";
                    when     40 => input_data <= x"00"; 
                    when     41 => input_data <= x"0A";  
					-------------------------------------
					-- ICMP Header
					-------------------------------------
                    when     42 => input_data <= x"08";  -- ICMP Tyoe
                    when     43 => input_data <= x"00";  -- Code 
                    when     44 => input_data <= x"47";  -- Checksum
                    when     45 => input_data <= x"ee";   
                    when     46 => input_data <= x"00";  -- Identifier
                    when     47 => input_data <= x"01";
                    when     48 => input_data <= x"05";  -- Sequence
                    when     49 => input_data <= x"6d";
					-------------------------------------
					-- ICMP Ping data
					-------------------------------------
                    when     50 => input_data <= x"61";  
                    when     51 => input_data <= x"62";
                    when     52 => input_data <= x"63";
                    when     53 => input_data <= x"64";
                    when     54 => input_data <= x"65";
                    when     55 => input_data <= x"66";
                    when     56 => input_data <= x"67";
                    when     57 => input_data <= x"68";
                    when     58 => input_data <= x"69";
                    when     59 => input_data <= x"6A";
                    when     60 => input_data <= x"6B";
                    when     61 => input_data <= x"6C";
                    when     62 => input_data <= x"6D";
                    when     63 => input_data <= x"6E";
                    when     64 => input_data <= x"6F";
                    when     65 => input_data <= x"70";
                    when     66 => input_data <= x"71";
                    when     67 => input_data <= x"72";
                    when     68 => input_data <= x"73";
                    when     69 => input_data <= x"74";
                    when     70 => input_data <= x"75";
                    when     71 => input_data <= x"76";
                    when     72 => input_data <= x"77";
                    when     73 => input_data <= x"61";
                    when     74 => input_data <= x"62";
                    when     75 => input_data <= x"63";
                    when     76 => input_data <= x"64";
                    when     77 => input_data <= x"65";
                    when     78 => input_data <= x"66";
                    when     79 => input_data <= x"67";
                    when     80 => input_data <= x"68";
                    when     81 => input_data <= x"FF";
                    when     82 => input_data <= x"FF";
                    when     83 => input_data <= x"FF";
                    when     84 => input_data <= x"FF";
					-----------------------------------
					-- END OF PACKET
					-----------------------------------
                    when     85 => input_data <= x"DD"; input_data_present <= '0'; 
                    when others => input_data <= x"DD"; input_data_present <= '0';
                end case;
                count2 <= 0;
            end if;

        end if;
    end process;
end Behavioral;