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
    
    signal arp_src_hw      : std_logic_vector(47 downto 0) := x"A0B3CC4CF9EF";
    signal arp_src_ip      : std_logic_vector(31 downto 0) := x"0A000001";
    signal arp_tgt_hw      : std_logic_vector(47 downto 0) := x"000000000000";
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

i_main_design: main_design port map (
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
            if count < 72 then 
                input_empty <= '0';
            else
                input_empty <= '1';
            end if;

            if count2 = 200 then
                count <= 0;
                count2 <= 0;
            else
                count2 <= count2+1;
            end if;

            if input_read = '1' then
                if count = 73 then
                    count <= 0;
                else
                    count <= count + 1;
                end if;
                
                case count is
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
                    when      8 => input_data <= x"FF";
                    when      9 => input_data <= x"FF";
                    when     10 => input_data <= x"FF";
                    when     11 => input_data <= x"FF";
                    when     12 => input_data <= x"FF";
                    when     13 => input_data <= x"FF";
                   -- Source MAC address
                    when     14 => input_data <= x"A0";
                    when     15 => input_data <= x"B3";
                    when     16 => input_data <= x"CC";
                    when     17 => input_data <= x"4C";
                    when     18 => input_data <= x"F9";
                    when     19 => input_data <= x"EF";
                    ------------------------ 
                    -- ARP packet
                    ------------------------ 
                    when 20 => input_data <= x"08"; -- Ether Type 08:06  << ARP!
                    when 21 => input_data <= x"06";
    
                    when 22 => input_data <= x"00"; -- Media type
                    when 23 => input_data <= x"01";
    
                    when 24 => input_data <= x"08"; -- Protocol (IP)
                    when 25 => input_data <= x"00";
    
                    when 26 => input_data <= x"06"; -- Hardware address length
                    when 27 => input_data <= x"04"; -- Protocol address length
                    -- Operation
                    when 28 => input_data <= x"00";
                    when 29 => input_data <= x"01"; -- request
                    -- Target MAC 
                    when 30 => input_data <= arp_src_hw(47 downto 40);
                    when 31 => input_data <= arp_src_hw(39 downto 32);
                    when 32 => input_data <= arp_src_hw(31 downto 24);
                    when 33 => input_data <= arp_src_hw(23 downto 16);
                    when 34 => input_data <= arp_src_hw(15 downto  8);
                    when 35 => input_data <= arp_src_hw( 7 downto  0);
                    -- Target IP
                    when 36 => input_data <= arp_src_ip(31 downto 24);
                    when 37 => input_data <= arp_src_ip(23 downto 16);
                    when 38 => input_data <= arp_src_ip(15 downto  8);
                    when 39 => input_data <= arp_src_ip( 7 downto  0);
                    -- Source MAC
                    when 40 => input_data <= arp_tgt_hw(47 downto 40);
                    when 41 => input_data <= arp_tgt_hw(39 downto 32);
                    when 42 => input_data <= arp_tgt_hw(31 downto 24);
                    when 43 => input_data <= arp_tgt_hw(23 downto 16);
                    when 44 => input_data <= arp_tgt_hw(15 downto  8);
                    when 45 => input_data <= arp_tgt_hw( 7 downto  0);
                    -- Source IP
                    when 46 => input_data <= arp_tgt_ip(31 downto 24);
                    when 47 => input_data <= arp_tgt_ip(23 downto 16);
                    when 48 => input_data <= arp_tgt_ip(15 downto  8);
                    when 49 => input_data <= arp_tgt_ip( 7 downto  0);
                    -- We can release the bus now and go back to the idle state.
                    when 50 => input_data <= x"00";
                    when 51 => input_data <= x"00";
                    when 52 => input_data <= x"00";
                    when 53 => input_data <= x"00";
                    when 54 => input_data <= x"00";
                    when 55 => input_data <= x"00";
                    when 56 => input_data <= x"00";
                    when 57 => input_data <= x"00";
                    when 58 => input_data <= x"00";
                    when 59 => input_data <= x"00";
                    when 60 => input_data <= x"00";
                    when 61 => input_data <= x"00";
                    when 62 => input_data <= x"00";
                    when 63 => input_data <= x"00";
                    when 64 => input_data <= x"00";
                    when 65 => input_data <= x"00";
                    when 66 => input_data <= x"00";
                    when 67 => input_data <= x"12";
                    when 68 => input_data <= x"12";
                    when 69 => input_data <= x"12";
                    when 70 => input_data <= x"12";
                    when 71 => input_data <= x"DD"; input_data_present <= '0'; 
                    when others => input_data <= x"DD"; input_data_present <= '0';
                end case;
                count2 <= 0;
            end if;

        end if;
    end process;
end Behavioral;
